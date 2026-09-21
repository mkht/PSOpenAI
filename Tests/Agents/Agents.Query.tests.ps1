#Requires -Modules @{ ModuleName = "Pester"; ModuleVersion = "5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    Import-Module (Join-Path $script:ModuleRoot 'PSOpenAI.psd1') -Force
}

Describe 'Agents API query and removal commands' -Tag 'Offline' {
    BeforeAll {
        Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
    }

    BeforeEach {
        Mock -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest {
            '{"id":"result_123","object":"agent"}'
        }
    }

    It 'accepts typed agent objects through the pipeline' {
        $Agent = [pscustomobject]@{ id = 'agent_123' }
        $Agent.psobject.TypeNames.Insert(0, 'PSOpenAI.Agent')

        $null = $Agent | Get-Agent
        $null = $Agent | Remove-Agent -Confirm:$false

        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'Get' -and $Uri.AbsolutePath -eq '/v1/agents/agent_123'
        }
        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter {
            $Method -eq 'Delete' -and $Uri.AbsolutePath -eq '/v1/agents/agent_123'
        }
    }

    It 'binds API property names from session objects in the pipeline' {
        $Session = [pscustomobject]@{ session_id = 'session_123' }

        $null = $Session | Get-AgentSessionEvent

        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter {
            $Stream -and $Uri.AbsolutePath -eq '/v1/agents/sessions/session_123/events'
        }
    }

    It 'sends list filters and follows cursor pagination' {
        $script:PageNumber = 0
        Mock -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest {
            $script:PageNumber++
            if ($script:PageNumber -eq 1) {
                '{"object":"list","data":[{"id":"agent_1"}],"has_more":true,"last_id":"agent_1"}'
            }
            else {
                '{"object":"list","data":[{"id":"agent_2"}],"has_more":false}'
            }
        }

        @(Get-Agent -Limit 1 -Order asc -After agent_0 -All).id | Should -Be @('agent_1', 'agent_2')

        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter {
            $Uri.Query -match 'limit=1' -and $Uri.Query -match 'order=asc' -and $Uri.Query -match 'after=agent_0'
        }
        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter {
            $Uri.Query -match 'after=agent_1'
        }
    }

    It 'selects session, subagent, and turn item paths by parameter set' {
        $null = Get-AgentSessionItem session_123
        $null = Get-AgentSessionItem session_123 -SubagentId subagent_123
        $null = Get-AgentSessionItem session_123 -SubagentId subagent_123 -TurnId turn_123

        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -ParameterFilter {
            $Uri.AbsolutePath -eq '/v1/agents/sessions/session_123/items'
        }
        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -ParameterFilter {
            $Uri.AbsolutePath -eq '/v1/agents/sessions/session_123/subagents/subagent_123/items'
        }
        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -ParameterFilter {
            $Uri.AbsolutePath -eq '/v1/agents/sessions/session_123/subagents/subagent_123/turns/turn_123/items'
        }
    }

    It 'selects root and subagent turn paths by parameter set' {
        $null = Get-AgentSessionTurn session_123
        $null = Get-AgentSessionTurn session_123 -TurnId turn_123
        $null = Get-AgentSessionTurn session_123 -SubagentId subagent_123
        $null = Get-AgentSessionTurn session_123 -SubagentId subagent_123 -TurnId turn_123

        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -ParameterFilter {
            $Uri.AbsolutePath -eq '/v1/agents/sessions/session_123/turns'
        }
        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -ParameterFilter {
            $Uri.AbsolutePath -eq '/v1/agents/sessions/session_123/turns/turn_123'
        }
        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -ParameterFilter {
            $Uri.AbsolutePath -eq '/v1/agents/sessions/session_123/subagents/subagent_123/turns'
        }
        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -ParameterFilter {
            $Uri.AbsolutePath -eq '/v1/agents/sessions/session_123/subagents/subagent_123/turns/turn_123'
        }
    }

    It 'returns artifact content as a single byte array' {
        Mock -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest {
            [byte[]](1, 2, 3)
        }

        $Artifact = [pscustomobject]@{
            session_id = 'session_123'
            id         = 'artifact_123'
        }
        $Content = $Artifact | Get-AgentSessionArtifactContent

        $Content.GetType() | Should -Be ([byte[]])
        $Content | Should -HaveCount 3
        $Content[2] | Should -Be 3
    }

    It 'honors WhatIf for removal commands' {
        $null = Remove-Agent agent_123 -WhatIf
        $null = Remove-AgentSession session_123 -WhatIf
        $null = Remove-AgentSessionArtifact session_123 artifact_123 -WhatIf
        $null = Remove-AgentEnvironmentTemplate template_123 -WhatIf
        $null = Remove-AgentVault vault_123 -WhatIf
        $null = Remove-AgentVaultCredential vault_123 credential_123 -WhatIf

        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -Times 0 -Exactly
    }
}
