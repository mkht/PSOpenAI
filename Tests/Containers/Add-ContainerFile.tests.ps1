#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

Describe 'Add-ContainerFile' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        BeforeAll {
            Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
            Mock -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest { $PesterBoundParameters }
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest {
                @"
{
  "id": "$($Body.file_id)",
  "object": "container.file",
  "created_at": 1747848842,
  "bytes": 880,
  "container_id": "cntr_123",
  "path": "/mnt/data/88e1-tsconfig.json",
  "source": "user"
}
"@ } -ParameterFilter { $ContentType -eq 'application/json' }

            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest {
                @'
{
  "id": "cf-abc123",
  "object": "container.file",
  "created_at": 1747848842,
  "bytes": 880,
  "container_id": "cntr_123",
  "path": "/mnt/data/88e1-tsconfig.json",
  "source": "user"
}
'@ } -ParameterFilter { $ContentType -eq 'multipart/form-data' }
        }

        BeforeEach {
            $script:Result = ''
        }

        It 'Add file to container (container: object / file: id)' {
            $contr = [pscustomobject]@{
                id     = 'cntr_123'
                object = 'container'
                name   = 'TestContainer'
            }
            $contr.PSObject.TypeNames.Insert(0, 'PSOpenAI.Container')
            { $script:Result = Add-ContainerFile -Container $contr -FileId 'file-abc123' -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -ParameterFilter { $ContentType -eq 'application/json' } -Times 1 -Exactly
            $Result | Should -BeOfType [pscustomobject]
            $Result.id | Should -Be 'file-abc123'
            $Result.container_id | Should -Be 'cntr_123'
            $Result.psobject.TypeNames | Should -Contain 'PSOpenAI.Container.File'
        }

        It 'Add file to container (container: id / file: id)' {
            { $script:Result = Add-ContainerFile -ContainerId 'cntr_123' -FileId 'file-abc345' -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -ParameterFilter { $ContentType -eq 'application/json' } -Times 1 -Exactly
            $Result | Should -BeOfType [pscustomobject]
            $Result.id | Should -Be 'file-abc345'
            $Result.psobject.TypeNames | Should -Contain 'PSOpenAI.Container.File'
        }

        It 'Add file to container (container: id / file: object)' {
            $file = [pscustomobject]@{
                id     = 'file-xxx123'
                object = 'file'
            }
            $file.PSObject.TypeNames.Insert(0, 'PSOpenAI.File')
            { $script:Result = Add-ContainerFile -ContainerId 'cntr_123' -File $file -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -ParameterFilter { $ContentType -eq 'application/json' } -Times 1 -Exactly
            $Result | Should -BeOfType [pscustomobject]
            $Result.id | Should -Be 'file-xxx123'
            $Result.psobject.TypeNames | Should -Contain 'PSOpenAI.Container.File'
        }

        It 'Add file to container (container: id / file: path)' {
            $filePath = Join-Path $script:TestData 'sweets_donut.png'
            { $script:Result = Add-ContainerFile -ContainerId 'cntr_123' -File $filePath -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -ParameterFilter { $ContentType -eq 'multipart/form-data' } -Times 1 -Exactly
            $Result | Should -BeOfType [pscustomobject]
            $Result.id | Should -Be 'cf-abc123'
            $Result.psobject.TypeNames | Should -Contain 'PSOpenAI.Container.File'
        }

        It 'Add file to container (container: id / file: FileInfo)' {
            $fileInfo = Get-Item (Join-Path $script:TestData 'sweets_donut.png')
            { $script:Result = Add-ContainerFile -ContainerId 'cntr_123' -File $fileInfo -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -ParameterFilter { $ContentType -eq 'multipart/form-data' } -Times 1 -Exactly
            $Result | Should -BeOfType [pscustomobject]
            $Result.id | Should -Be 'cf-abc123'
            $Result.psobject.TypeNames | Should -Contain 'PSOpenAI.Container.File'
        }

        It 'Add multiple files to container (container: id / file: id)' {
            { $script:Result = Add-ContainerFile -ContainerId 'cntr_123' -File ('file-id1', 'file-id2') -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -ParameterFilter { $ContentType -eq 'application/json' } -Times 2 -Exactly
            $Result | Should -HaveCount 2
            $Result[0].id | Should -Be 'file-id1'
            $Result[1].id | Should -Be 'file-id2'
        }

        It 'Add multiple files to container (container: id / file: path)' {
            $filePath1 = Join-Path $script:TestData 'sweets_donut.png'
            $filePath2 = Join-Path $script:TestData 'google.png'
            { $script:Result = Add-ContainerFile -ContainerId 'cntr_123' -File ($filePath1, $filePath2) -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -ParameterFilter { $ContentType -eq 'multipart/form-data' } -Times 2 -Exactly
            $Result | Should -HaveCount 2
            $Result[0].id | Should -Be 'cf-abc123'
            $Result[1].id | Should -Be 'cf-abc123'
        }

        It 'ContainerId and FileId can be input as positional parameters' {
            { $script:Result = Add-ContainerFile 'cntr_123' 'file-abc1234' -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -ParameterFilter { $ContentType -eq 'application/json' } -Times 1 -Exactly
            $Result.id | Should -Be 'file-abc1234'
        }

        It 'Container Id can be input by pipeline' {
            { $script:Result = 'cntr_123' | Add-ContainerFile -FileId 'file-abc1234' -ea Stop } | Should -Not -Throw
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -ParameterFilter { $ContentType -eq 'application/json' } -Times 1 -Exactly
            $Result.id | Should -Be 'file-abc1234'
        }

        It 'Timeout' {
            Mock -Verifiable -ModuleName $script:ModuleName Invoke-OpenAIAPIRequest {
                Start-Sleep -Seconds 2
                return @'
{
  "id": "cf-abc123",
  "object": "container.file",
  "created_at": 1747848842,
  "bytes": 880,
  "container_id": "cntr_123",
  "path": "/mnt/data/88e1-tsconfig.json",
  "source": "user"
}
'@ } -ParameterFilter { $TimeoutSec -gt 0 }
            { $script:Result = Add-ContainerFile -ContainerId 'cntr_123' -FileId 'file-abc345' -TimeoutSec 1 -ea Stop } | Should -Throw -ExceptionType ([System.TimeoutException])
            Should -Invoke -CommandName Invoke-OpenAIAPIRequest -ModuleName $script:ModuleName -ParameterFilter { $TimeoutSec -gt 0 } -Scope It -Times 1 -Exactly
        }
    }
}
