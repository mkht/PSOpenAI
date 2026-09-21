#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    Import-Module (Join-Path $script:ModuleRoot 'PSOpenAI.psd1') -Force
}

Describe 'Agents API object handling' -Tag 'Offline' {
    BeforeAll {
        Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
    }

    It 'adds a PSOpenAI type and converts timestamps' {
        Mock -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest {
            '{"id":"agent_123","object":"agent","created_at":0,"updated_at":1}'
        }

        $Result = Get-Agent -AgentId 'agent_123'

        $Result.PSObject.TypeNames | Should -Contain 'PSOpenAI.Agent'
        $Result.created_at | Should -BeOfType ([datetime])
        $Result.updated_at | Should -BeOfType ([datetime])
    }

    It 'types streamed session events and converts event timestamps' {
        Mock -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest -ParameterFilter { $Stream } {
            '{"type":"agent.session.idle","created_at":1,"session":{"id":"session_123"}}'
        }

        $Result = Get-AgentSessionEvent -SessionId 'session_123'

        $Result.PSObject.TypeNames | Should -Contain 'PSOpenAI.Agent.Session.Event'
        $Result.created_at | Should -BeOfType ([datetime])
    }
}
