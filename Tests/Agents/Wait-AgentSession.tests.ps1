#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    Import-Module (Join-Path $script:ModuleRoot 'PSOpenAI.psd1') -Force
}

Describe 'Wait-AgentSession' -Tag 'Offline' {
    It 'polls until the session becomes idle' {
        $script:PollCount = 0
        Mock -ModuleName $script:ModuleName Get-AgentSession {
            $script:PollCount++
            if ($script:PollCount -eq 1) {
                [pscustomobject]@{id = 'session_123'; status = 'in_progress' }
            }
            else {
                [pscustomobject]@{id = 'session_123'; status = 'idle' }
            }
        }

        $Result = Wait-AgentSession -SessionId 'session_123' -PollIntervalSec 0

        $Result.status | Should -BeExactly 'idle'
        Should -Invoke Get-AgentSession -ModuleName $script:ModuleName -Times 2 -Exactly
    }

    It 'accepts an agent session object from the pipeline' {
        Mock -ModuleName $script:ModuleName Get-AgentSession {
            [pscustomobject]@{id = 'session_456'; status = 'requires_action' }
        }
        $Session = [pscustomobject]@{id = 'session_456'; status = 'in_progress' }
        $Session.PSObject.TypeNames.Insert(0, 'PSOpenAI.Agent.Session')

        $Result = $Session | Wait-AgentSession -PollIntervalSec 0

        $Result.id | Should -BeExactly 'session_456'
        $Result.status | Should -BeExactly 'requires_action'
    }

    It 'reports an unexpected status instead of returning it as a completed session' {
        Mock -ModuleName $script:ModuleName Get-AgentSession {
            [pscustomobject]@{id = 'session_123'; status = 'paused' }
        }

        $Errors = @()
        $Result = Wait-AgentSession `
            -SessionId 'session_123' `
            -PollIntervalSec 0 `
            -ErrorAction SilentlyContinue `
            -ErrorVariable Errors

        $Result | Should -BeNullOrEmpty
        $Errors.Exception.Message | Should -Match 'unexpected status'
    }
}
