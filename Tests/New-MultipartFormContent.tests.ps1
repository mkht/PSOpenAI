#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeDiscovery {
    Import-Module (Join-Path (Split-Path $PSScriptRoot -Parent) 'PSOpenAI.psd1') -Force
}

BeforeAll {
    $script:ModuleRoot = Split-Path $PSScriptRoot -Parent
    Import-Module (Join-Path $script:ModuleRoot 'PSOpenAI.psd1') -Force
}

Describe 'New-MultipartFormContent' -Tag 'Offline' {
    InModuleScope PSOpenAI {
        It 'Includes a regular filename so servers recognize a file part' {
            $path = Join-Path $TestDrive 'sample.png'
            [System.IO.File]::WriteAllBytes($path, [byte[]](0, 1, 2, 255))
            $file = Get-Item $path
            $body = New-MultipartFormContent -FormData @{ file = $file } -Boundary 'test-boundary'
            $text = [System.Text.Encoding]::UTF8.GetString($body)
            $text | Should -Match 'name="file"; filename="sample.png"; filename\*=utf-8''''sample.png'
            $text | Should -Match 'Content-Type: image/png'
            $body | Should -BeOfType [byte]
            $body.Length | Should -BeGreaterThan $file.Length
        }

        It 'Escapes unsafe filename characters and preserves an extended UTF-8 filename' {
            $body = New-MultipartFormContent -FormData @{
                file = @{
                    Type     = 'bytes'
                    FileName = "画像`"`r`n.png"
                    Content  = [byte[]](1, 2, 3)
                }
            } -Boundary 'test-boundary'
            $text = [System.Text.Encoding]::UTF8.GetString($body)
            $encoded = [Uri]::EscapeDataString("画像`"`r`n.png")
            $text | Should -Match ([regex]::Escape(('filename="{0}"; filename*=utf-8''''{0}' -f $encoded)))
            ($text -split "`r`n" | Where-Object { $_ -like 'Content-Disposition:*' }) | Should -HaveCount 1
        }
    }
}
