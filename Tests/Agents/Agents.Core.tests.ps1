#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    Import-Module (Join-Path $script:ModuleRoot 'PSOpenAI.psd1') -Force
}

Describe 'Agents API PowerShell-friendly commands' -Tag 'Offline' {
    BeforeAll {
        Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
    }

    BeforeEach {
        Mock -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest {
            '{"id":"agent_123","object":"agent","model":"gpt-5.6"}'
        }
    }

    It 'constructs an agent from named PowerShell parameters' {
        $Parameters = @{
            Model        = 'gpt-5.6'
            Name         = 'repository assistant'
            Instructions = 'Inspect the repository.'
            Metadata     = @{ team = 'platform' }
            MultiAgent   = @{ enabled = $true; max_concurrent_subagents = 2 }
            Reasoning    = @{ effort = 'medium'; summary = 'concise' }
            ServiceTier  = 'default'
            Text         = @{ verbosity = 'low' }
            Tool         = @(@{ type = 'function'; name = 'lookup' })
        }

        $Result = New-Agent @Parameters

        $Result.psobject.TypeNames | Should -Contain 'PSOpenAI.Agent'
        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'Post' -and
            $Uri.AbsolutePath -eq '/v1/agents' -and
            $Body.GetType().FullName -eq 'System.Collections.Specialized.OrderedDictionary' -and
            $Body.model -eq 'gpt-5.6' -and
            $Body.name -eq 'repository assistant' -and
            $Body.instructions -eq 'Inspect the repository.' -and
            $Body.metadata.team -eq 'platform' -and
            $Body.multi_agent.enabled -eq $true -and
            $Body.reasoning.effort -eq 'medium' -and
            $Body.service_tier -eq 'default' -and
            $Body.text.verbosity -eq 'low' -and
            $Body.tools[0].name -eq 'lookup'
        }
    }

    It 'retains raw body compatibility when creating an agent' {
        $RawBody = @{ model = 'future-model'; future_option = @{ enabled = $true } }

        $null = New-Agent -Body $RawBody

        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter {
            $Body -eq $RawBody -and $Body.future_option.enabled -eq $true
        }
    }

    It 'updates an agent from a pipeline object and named parameters' {
        $Agent = [pscustomobject]@{ id = 'agent_pipeline' }
        $Agent.psobject.TypeNames.Insert(0, 'PSOpenAI.Agent')

        $null = $Agent | Set-Agent -Name 'updated' -Metadata @{ stage = 'review' } -Confirm:$false

        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter {
            $Uri.AbsolutePath -eq '/v1/agents/agent_pipeline' -and
            $Body.name -eq 'updated' -and
            $Body.metadata.stage -eq 'review' -and
            -not $Body.Contains('model')
        }
    }

    It 'creates a session from named parameters' {
        Mock -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest {
            '{"id":"session_123","object":"agent.session"}'
        }

        $null = New-AgentSession `
            -Environment @{ type = 'none' } `
            -AgentId 'agent_123' `
            -Input 'Inspect this repository.' `
            -Metadata @{ task = 'review' } `
            -VaultId 'vault_1', 'vault_2'

        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter {
            $Uri.AbsolutePath -eq '/v1/agents/sessions'
        }
        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter {
            $Body.GetType().FullName -eq 'System.Collections.Specialized.OrderedDictionary' -and
            $Body.environment.type -eq 'none' -and $Body.agent_id -eq 'agent_123'
        }
        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter {
            $Body.input -eq 'Inspect this repository.' -and $Body.metadata.task -eq 'review'
        }
        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter {
            $Body.vault_ids.Count -eq 2 -and
            $Body.vault_ids[0] -eq 'vault_1' -and
            $Body.vault_ids[1] -eq 'vault_2'
        }
    }

    It 'defaults to no execution environment and supports a hosted template' {
        Mock -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest {
            '{"id":"session_123","object":"agent.session"}'
        }

        $null = New-AgentSession -AgentId 'agent_123' -Input 'hello'
        $null = New-AgentSession -AgentId 'agent_123' -Input 'hello' -EnvironmentTemplateId 'envtmpl_123'

        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -ParameterFilter {
            $Body.environment.type -eq 'none'
        }
        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -ParameterFilter {
            $Body.environment.type -eq 'openai_hosted' -and
            $Body.environment.environment_template_id -eq 'envtmpl_123'
        }
    }

    It 'accepts a PSOpenAI.Agent object from the pipeline and streams the session' {
        Mock -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest -ParameterFilter { $Stream } {
            '{"type":"agent.session.created"}'
        }
        $Agent = [pscustomobject]@{ id = 'agent_pipeline' }
        $Agent.psobject.TypeNames.Insert(0, 'PSOpenAI.Agent')

        $null = $Agent | New-AgentSession -Environment @{ type = 'none' } -Input 'Run checks.' -Stream

        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter {
            $Stream -and
            $Uri.AbsolutePath -eq '/v1/agents/sessions' -and
            $Body.agent_id -eq 'agent_pipeline' -and
            $Body.stream -eq $true -and
            -not $Body.Contains('agent')
        }
    }

    It 'retains raw body compatibility without mutating the caller body for streaming' {
        Mock -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest -ParameterFilter { $Stream } {
            '{"type":"agent.session.created"}'
        }
        $RawBody = @{ environment = @{ type = 'none' }; agent_id = 'agent_123' }

        $null = New-AgentSession -Body $RawBody -Stream

        $RawBody.ContainsKey('stream') | Should -BeFalse
        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter {
            $Stream -and $Body.stream -eq $true -and $Body.agent_id -eq 'agent_123'
        }
    }

    It 'updates a session from a pipeline object' {
        Mock -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest {
            '{"id":"session_pipeline","object":"agent.session"}'
        }
        $Session = [pscustomobject]@{ id = 'session_pipeline' }
        $Session.psobject.TypeNames.Insert(0, 'PSOpenAI.Agent.Session')

        $null = $Session | Set-AgentSession -Agent @{ model = 'gpt-5.6'; reasoning = @{ effort = 'high' } } -Metadata @{ stage = 'updated' } -Confirm:$false

        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter {
            $Uri.AbsolutePath -eq '/v1/agents/sessions/session_pipeline' -and
            $Body.agent.model -eq 'gpt-5.6' -and
            $Body.agent.reasoning.effort -eq 'high' -and
            $Body.metadata.stage -eq 'updated'
        }
    }

    It 'converts a friendly message to a session input event and preserves additional headers' {
        Mock -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest { $null }

        $null = Add-AgentSessionEvent `
            -SessionId 'session_123' `
            -Message 'Continue the review.' `
            -IdempotencyKey 'event_123' `
            -AdditionalHeaders @{ 'X-Test' = 'value' }

        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'Post' -and
            $Uri.AbsolutePath -eq '/v1/agents/sessions/session_123/events' -and
            $Body.events.Count -eq 1 -and
            $Body.events[0].type -eq 'agent.session.input.message' -and
            $Body.events[0].input[0].type -eq 'message' -and
            $Body.events[0].input[0].role -eq 'user' -and
            $Body.events[0].input[0].content[0].type -eq 'input_text' -and
            $Body.events[0].input[0].content[0].text -eq 'Continue the review.' -and
            $AdditionalHeaders.'Idempotency-Key' -eq 'event_123' -and
            $AdditionalHeaders.'X-Test' -eq 'value'
        }
    }

    It 'retains raw event compatibility' {
        Mock -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest { $null }
        $RawEvent = @{ type = 'agent.session.input.cancel' }

        $null = Add-AgentSessionEvent session_123 -Event $RawEvent

        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter {
            $Body.events.Count -eq 1 -and $Body.events[0] -eq $RawEvent
        }
    }
}
