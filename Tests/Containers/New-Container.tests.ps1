#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'New-Container' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { @'
{
    "id": "container_abc123",
    "object": "container",
    "created_at": 1747857508,
    "status": "running",
    "expires_after": {
        "anchor": "last_active_at",
        "minutes": 20
    },
    "last_active_at": 1747857508,
    "name": "My Container"
}
'@ }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Create container' {
            { $script:Result = New-Container -Name 'My Container' -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            $Result | Should -BeOfType [pscustomobject]
            $Result.psobject.TypeNames | Should -Contain 'PSOpenAI.Container'
            $Result.id | Should -BeExactly 'container_abc123'
            $Result.created_at | Should -BeOfType [datetime]
            $Result.status | Should -BeExactly 'running'
        }

        It 'Create container (full param)' {
            $Params = @{
                Name                = 'My Container'
                ExpiresAfterMinutes = 120
                ExpiresAfterAnchor  = 'last_active_at'
                FileId              = 'file-abc123', 'file-abc456'
                MemoryLimit         = '4g'
            }
            { $script:Result = New-Container @Params -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
        }

        Context 'Parameter Sets' {
            It 'Name only' {
                { New-Container -Name 'My Container' -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            }

            It 'FileId' {
                # Single
                { New-Container -Name 'My Container' -FileId 'file-abc123' -ea Stop } | Should -Not -Throw
                # Array
                { New-Container -Name 'My Container' -FileId 'file-abc123', 'file-abc456' -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 2 -Exactly
            }

            It 'File object' {
                $InObject1 = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.File'
                    id         = 'file-abc123'
                }
                $InObject2 = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.File'
                    id         = 'file-abc456'
                }
                # Single
                { New-Container -Name 'My Container' -FileId $InObject1 -ea Stop } | Should -Not -Throw
                # Array
                { New-Container -Name 'My Container' -FileId $InObject1, $InObject2 -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 2 -Exactly
            }

            It 'Mix' {
                $InObject1 = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.File'
                    id         = 'file-abc123'
                }
                $InObject2 = [pscustomobject]@{
                    PSTypeName = 'PSOpenAI.File'
                    id         = 'file-abc456'
                }
                { New-Container -Name 'My Container' -FileId 'file-abc123', $InObject1, 'file-abc456', $InObject2 -ea Stop } | Should -Not -Throw
                Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -Times 1 -Exactly
            }
        }
    }
}
