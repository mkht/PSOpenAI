#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    Import-Module (Join-Path $script:ModuleRoot 'PSOpenAI.psd1') -Force
}

Describe 'Agents API commands' -Tag 'Offline' {
    BeforeAll {
        Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
    }

    BeforeEach {
        Mock -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest {
            '{"id":"agent_123","object":"agent","model":"gpt-5.6"}'
        }
    }

    It 'creates a reusable agent with the beta header and raw body' {
        $Result = New-Agent -Body @{ model = 'gpt-5.6'; tools = @(@{ type = 'function'; name = 'lookup' }) }
        $Result.id | Should -BeExactly 'agent_123'
        $Result.psobject.TypeNames | Should -Contain 'PSOpenAI.Agent'
        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'Post' -and $Uri.AbsolutePath -eq '/v1/agents' -and
            $Headers.'OpenAI-Beta' -eq 'agents=v1' -and $Body.model -eq 'gpt-5.6'
        }
    }

    It 'updates and deletes a reusable agent using the documented routes' {
        $null = Set-Agent agent_123 -Body @{ name = 'updated' } -Confirm:$false
        $null = Remove-Agent agent_123 -Confirm:$false
        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -ParameterFilter { $Method -eq 'Post' -and $Uri.AbsolutePath -eq '/v1/agents/agent_123' -and $Body.name -eq 'updated' }
        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -ParameterFilter { $Method -eq 'Delete' -and $Uri.AbsolutePath -eq '/v1/agents/agent_123' }
    }

    It 'follows cursor pagination when listing all agents' {
        $script:Page = 0
        Mock -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest {
            $script:Page++
            if ($script:Page -eq 1) { '{"object":"list","data":[{"id":"agent_1"}],"has_more":true,"last_id":"agent_1"}' }
            else { '{"object":"list","data":[{"id":"agent_2"}],"has_more":false}' }
        }
        @(Get-Agent -All).id | Should -Be @('agent_1','agent_2')
        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -Times 2 -Exactly
        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -ParameterFilter { $Uri.Query -match 'after=agent_1' }
    }

    It 'creates a session and posts input events' {
        Mock -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest { '{"id":"session_123","object":"agent.session"}' }
        $Session = New-AgentSession -Body @{ agent_id = 'agent_123'; environment = @{ type = 'none' } }
        $null = Add-AgentSessionEvent session_123 -Event @{ type = 'message'; role = 'user'; content = @(@{type='input_text';text='hello'}) } -IdempotencyKey key_123
        $Session.id | Should -BeExactly 'session_123'
        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -ParameterFilter { $Method -eq 'Post' -and $Uri.AbsolutePath -eq '/v1/agents/sessions' -and $Body.agent_id -eq 'agent_123' -and $Body.environment.type -eq 'none' }
        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -ParameterFilter { $Method -eq 'Post' -and $Uri.AbsolutePath -eq '/v1/agents/sessions/session_123/events' -and $Body.events.Count -eq 1 -and $AdditionalHeaders.'Idempotency-Key' -eq 'key_123' }
    }

    It 'parses the session event SSE data stream' {
        Mock -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest -ParameterFilter { $Stream } {
            '{"type":"session.created","session":{"id":"session_123"}}'
            '{"type":"session.completed","session":{"id":"session_123"}}'
        }
        $Events = @(Get-AgentSessionEvent session_123)
        $Events.type | Should -Be @('session.created','session.completed')
        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -ParameterFilter { $Stream -and $Method -eq 'Get' -and $Uri.AbsolutePath -eq '/v1/agents/sessions/session_123/events' }
    }

    It 'requests a streamed session in both the JSON body and HTTP transport' {
        Mock -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest -ParameterFilter { $Stream } { '{"type":"agent.session.created"}' }
        $Body = @{ agent_id = 'agent_123'; environment = @{ type = 'none' } }
        $null = New-AgentSession -Body $Body -Stream
        $Body.ContainsKey('stream') | Should -BeFalse
        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -ParameterFilter { $Stream -and $Body.stream -eq $true -and $Uri.AbsolutePath -eq '/v1/agents/sessions' }
    }

    It 'addresses root and subagent inspection routes' {
        $null = Get-AgentSessionItem session_123 -SubagentId sub_123 -TurnId turn_123
        $null = Get-AgentSessionTurn session_123 -SubagentId sub_123 -TurnId turn_123
        $null = Get-AgentSessionSubagent session_123 -SubagentId sub_123
        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -ParameterFilter { $Uri.AbsolutePath -eq '/v1/agents/sessions/session_123/subagents/sub_123/turns/turn_123/items' }
        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -ParameterFilter { $Uri.AbsolutePath -eq '/v1/agents/sessions/session_123/subagents/sub_123/turns/turn_123' }
        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -ParameterFilter { $Uri.AbsolutePath -eq '/v1/agents/sessions/session_123/subagents/sub_123' }
    }

    It 'uses artifact metadata, content, and deletion routes' {
        $null = Get-AgentSessionArtifact session_123 -ArtifactId artifact_123
        $null = Get-AgentSessionArtifactContent session_123 artifact_123 -OutFile (Join-Path $TestDrive artifact.bin)
        $null = Remove-AgentSessionArtifact session_123 artifact_123 -Confirm:$false
        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -ParameterFilter { $Method -eq 'Get' -and $Uri.AbsolutePath -eq '/v1/agents/sessions/session_123/artifacts/artifact_123' }
        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -ParameterFilter { $Method -eq 'Get' -and $Uri.AbsolutePath -eq '/v1/agents/sessions/session_123/artifacts/artifact_123/content' -and $OutFile }
        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -ParameterFilter { $Method -eq 'Delete' -and $Uri.AbsolutePath -eq '/v1/agents/sessions/session_123/artifacts/artifact_123' }
    }

    It 'returns artifact content as one byte array when OutFile is omitted' {
        Mock -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest { [byte[]](1, 2, 3) }

        $Content = Get-AgentSessionArtifactContent session_123 artifact_123

        $Content.GetType() | Should -Be ([byte[]])
        $Content | Should -HaveCount 3
        $Content[0] | Should -Be 1
    }

    It 'supports environment templates, environment files, vaults, and credentials' {
        $null = New-AgentEnvironmentTemplate -Body @{ name = 'dev' }
        $null = Add-AgentEnvironmentFile env_123 -Body @{ path = 'README.md'; content = 'hello' }
        $null = New-AgentVault -Body @{ name = 'secrets' }
        $null = New-AgentVaultCredential vault_123 -Body @{ name='token'; auth=@{type='static_bearer';token='secret';mcp_server_url='https://mcp.example'} }
        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -ParameterFilter { $Uri.AbsolutePath -eq '/v1/agents/environments/templates' -and $Method -eq 'Post' }
        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -ParameterFilter { $Uri.AbsolutePath -eq '/v1/agents/environments/env_123/files' -and $Method -eq 'Post' }
        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -ParameterFilter { $Uri.AbsolutePath -eq '/v1/vaults' -and $Method -eq 'Post' }
        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -ParameterFilter { $Uri.AbsolutePath -eq '/v1/vaults/vault_123/credentials' -and $Body.auth.token -eq 'secret' }
    }

    It 'rejects Azure because the Agents API is OpenAI-only' {
        { Get-Agent -ApiType Azure -ApiKey ([securestring]::new()) -ErrorAction Stop } | Should -Throw -ExceptionType ([System.NotSupportedException])
    }
}
