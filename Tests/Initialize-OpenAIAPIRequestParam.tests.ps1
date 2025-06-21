#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

$ModuleRoot = Split-Path $PSScriptRoot -Parent
$ModuleName = 'PSOpenAI'
Import-Module (Join-Path $ModuleRoot "$ModuleName.psd1") -Force

BeforeAll {
    $script:ModuleRoot = Split-Path $PSScriptRoot -Parent
    $script:ModuleName = 'PSOpenAI'
    $script:TestData = Join-Path $script:ModuleRoot 'Tests/TestData'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force
}

AfterAll {
    $script:UserAgent = $null
}

Describe 'Initialize-OpenAIAPIRequestParam' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        InModuleScope $ModuleName {

            It 'Only Uri, should return a hashtable with default values' {
                $ret = Initialize-OpenAIAPIRequestParam -Uri 'https://api.openai.example.com/v1/test'
                # Should return a hashtable
                $ret | Should -BeOfType [hashtable]
                # Should contain Uri
                $ret['Uri'] | Should -BeOfType [System.Uri]
                $ret['Uri'].OriginalString | Should -BeExactly 'https://api.openai.example.com/v1/test'
                # Should set default values
                $ret['Method'] | Should -BeExactly 'Post'
                $ret['ContentType'] | Should -BeExactly 'application/json'
                $ret['ServiceName'] | Should -BeExactly 'OpenAI'
            }

            It 'Set basic parameters' {
                $Parameters = @{
                    Method      = 'Post'
                    Uri         = 'https://api.openai.example.com/v1/test'
                    ContentType = 'application/json'
                    Body        = @{ 'key' = 'value' }
                    Headers     = @{ 'Authorization' = 'Bearer token'; 'X-TEST' = 'true' }
                    AuthType    = 'azure'
                }

                $ret = Initialize-OpenAIAPIRequestParam @Parameters
                $ret | Should -BeOfType [hashtable]
                $ret['Uri'] | Should -BeOfType [System.Uri]
                $ret['Uri'].OriginalString | Should -BeExactly 'https://api.openai.example.com/v1/test'
                $ret['Method'] | Should -BeExactly 'Post'
                $ret['ContentType'] | Should -BeExactly 'application/json'
                $ret['Body'] | Should -BeOfType [hashtable]
                $ret['Body']['key'] | Should -BeExactly 'value'
                $ret['Headers'] | Should -BeOfType [hashtable]
                $ret['Headers']['Authorization'] | Should -BeExactly 'Bearer token'
                $ret['Headers']['X-TEST'] | Should -BeExactly 'true'
                $ret['ServiceName'] | Should -BeExactly 'Azure OpenAI'
            }

            It 'Should assert deprecation model' {
                Mock -Verifiable -ModuleName $script:ModuleName Assert-DeprecationModel { Write-Warning 'Mock called' }
                $Parameters = @{
                    Uri  = 'https://api.openai.example.com/v1/test'
                    Body = @{ model = 'gpt-3.5-turbo-0301'; 'key' = 'value' }
                }
                { $null = Initialize-OpenAIAPIRequestParam @Parameters -WarningAction Stop } | Should -Throw '*Mock called*'
                $ret = Initialize-OpenAIAPIRequestParam @Parameters -WarningAction SilentlyContinue
                Should -Invoke Assert-DeprecationModel -ModuleName $script:ModuleName
                $ret['Uri'].OriginalString | Should -BeExactly 'https://api.openai.example.com/v1/test'
                $ret['Body']['model'] | Should -BeExactly 'gpt-3.5-turbo-0301'
                $ret['Body']['key'] | Should -BeExactly 'value'
            }

            It 'Should set User-Agent - test 1' {
                $script:UserAgent = $null
                Mock -Verifiable -ModuleName $script:ModuleName Get-UserAgent { 'MyCustomUserAgent/1.0' }
                $Parameters = @{
                    Uri = 'https://api.openai.example.com/v1/test'
                }
                $ret1 = Initialize-OpenAIAPIRequestParam @Parameters
                Should -Invoke Get-UserAgent -ModuleName $script:ModuleName -Times 1 -Exactly
                $ret1['UserAgent'] | Should -BeExactly 'MyCustomUserAgent/1.0'

                # User-Agent is cached, should not call Get-UserAgent again
                $ret2 = Initialize-OpenAIAPIRequestParam @Parameters
                Should -Invoke Get-UserAgent -ModuleName $script:ModuleName -Times 1 -Exactly
                $ret2['UserAgent'] | Should -BeExactly 'MyCustomUserAgent/1.0'
            }

            It 'Should set User-Agent - test 2' {
                $script:UserAgent = $null
                Mock -Verifiable -ModuleName $script:ModuleName Get-UserAgent { 'MyCustomUserAgent/1.0' }
                $Parameters = @{
                    Uri               = 'https://api.openai.example.com/v1/test'
                    Headers           = @{'Key' = 'Value' }
                    AdditionalHeaders = @{ 'User-Agent' = 'MyCustomUserAgent2/2.2.2' }
                }
                $ret = Initialize-OpenAIAPIRequestParam @Parameters
                Should -Not -Invoke Get-UserAgent -ModuleName $script:ModuleName
                $ret['UserAgent'] | Should -BeExactly 'MyCustomUserAgent2/2.2.2'
            }

            It 'Should set debug header' {
                Mock -Verifiable -ModuleName $script:ModuleName Test-Debug { $true }
                $Parameters = @{
                    Uri = 'https://api.openai.example.com/v1/test'
                }
                $ret = Initialize-OpenAIAPIRequestParam @Parameters
                Should -Invoke Test-Debug -ModuleName $script:ModuleName
                $ret['Headers']['OpenAI-Debug'] | Should -BeExactly 'true'
            }

            It 'multipart/form-data' {
                Mock -Verifiable -ModuleName $script:ModuleName New-MultipartFormBoundary { 'boundary' }
                $Parameters = @{
                    Uri         = 'https://api.openai.example.com/v1/test'
                    ContentType = 'multipart/form-data'
                    Body        = [ordered]@{'Key1' = 'value1'; 'Key2' = 'value2' }
                }
                $ret = Initialize-OpenAIAPIRequestParam @Parameters
                $ret['ContentType'] | Should -BeExactly 'multipart/form-data; boundary="boundary"'
                $ret['Body'].GetType().Name | Should -Be 'Byte[]'
                $BodyAsString = [System.Text.Encoding]::UTF8.GetString($ret['Body'])
                $BodyAsString | Should -BeExactly (@(
                        '--boundary'
                        'Content-Disposition: form-data; name="Key1"'
                        ''
                        'value1'
                        '--boundary'
                        'Content-Disposition: form-data; name="Key2"'
                        ''
                        'value2'
                        '--boundary--'
                    ) -join "`r`n") # Should use CRLF line endings in multipart/form-data
            }

            It 'AdditionalQuery parameters - test 1' {
                $Parameters = @{
                    Uri             = 'https://api.openai.example.com/v1/test'
                    AdditionalQuery = @{ 'param1' = 'value1'; 'param2' = 'value2' }
                }
                $ret = Initialize-OpenAIAPIRequestParam @Parameters
                $ret['Uri'].ToString() | Should -BeExactly 'https://api.openai.example.com/v1/test?param1=value1&param2=value2'
            }

            It 'AdditionalQuery parameters - test 2' {
                $Parameters = @{
                    Uri             = 'https://api.openai.example.com/v1/test?existing1=param1&existing2=param2'
                    AdditionalQuery = @{ 'param1' = 'value1'; 'param2' = 'value2' }
                }
                $ret = Initialize-OpenAIAPIRequestParam @Parameters
                $ret['Uri'].ToString() | Should -BeExactly 'https://api.openai.example.com/v1/test?existing1=param1&existing2=param2&param1=value1&param2=value2'
            }

            It 'AdditionalHeaders parameters' {
                $Parameters = @{
                    Uri               = 'https://api.openai.example.com/v1/test'
                    Headers           = @{ 'Authorization' = 'Bearer token'; 'X-TEST' = 'true' }
                    AdditionalHeaders = @{ 'X-Custom-Header' = 'CustomValue'; 'X-Another-Header' = 'AnotherValue' }
                }
                $ret = Initialize-OpenAIAPIRequestParam @Parameters
                $ret['Headers']['Authorization'] | Should -BeExactly 'Bearer token'
                $ret['Headers']['X-TEST'] | Should -BeExactly 'true'
                $ret['Headers']['X-Custom-Header'] | Should -BeExactly 'CustomValue'
                $ret['Headers']['X-Another-Header'] | Should -BeExactly 'AnotherValue'
            }

            It 'AdditionalBody parameters - test 1' {
                $Parameters = @{
                    Uri            = 'https://api.openai.example.com/v1/test'
                    ContentType    = 'application/json'
                    Body           = @{ 'key1' = 'value1'; 'key2' = 'value2' }
                    AdditionalBody = @{ 'key3' = 'value3'; 'key4' = 'value4' }
                }
                $ret = Initialize-OpenAIAPIRequestParam @Parameters
                $ret['ContentType'] | Should -BeExactly 'application/json'
                $ret['Body'] | Should -BeOfType [hashtable]
                $ret['Body']['key1'] | Should -BeExactly 'value1'
                $ret['Body']['key2'] | Should -BeExactly 'value2'
                $ret['Body']['key3'] | Should -BeExactly 'value3'
                $ret['Body']['key4'] | Should -BeExactly 'value4'
            }

            It 'AdditionalBody parameters - test 2' {
                $Parameters = @{
                    Uri            = 'https://api.openai.example.com/v1/test'
                    ContentType    = 'application/json'
                    Body           = [pscustomobject]@{ 'key1' = 'value1'; 'key2' = 'value2' }
                    AdditionalBody = [pscustomobject]@{ 'key3' = 'value3'; 'key4' = 'value4' }
                }
                $ret = Initialize-OpenAIAPIRequestParam @Parameters
                $ret['ContentType'] | Should -BeExactly 'application/json'
                $ret['Body'] | Should -BeOfType [hashtable]
                $ret['Body']['key1'] | Should -BeExactly 'value1'
                $ret['Body']['key2'] | Should -BeExactly 'value2'
                $ret['Body']['key3'] | Should -BeExactly 'value3'
                $ret['Body']['key4'] | Should -BeExactly 'value4'
            }

            It 'AdditionalBody parameters - test 3' {
                $Parameters = @{
                    Uri            = 'https://api.openai.example.com/v1/test'
                    ContentType    = 'application/json'
                    Body           = @{ 'key1' = 'value1'; 'key2' = 'value2' }
                    AdditionalBody = (ConvertTo-Json -InputObject (@{ 'key3' = 'value3'; 'key4' = 'value4' }) -Compress)
                }
                $ret = Initialize-OpenAIAPIRequestParam @Parameters
                $ret['ContentType'] | Should -BeExactly 'application/json'
                $ret['Body'] | Should -BeOfType [hashtable]
                $ret['Body']['key1'] | Should -BeExactly 'value1'
                $ret['Body']['key2'] | Should -BeExactly 'value2'
                $ret['Body']['key3'] | Should -BeExactly 'value3'
                $ret['Body']['key4'] | Should -BeExactly 'value4'
            }

            It 'AdditionalBody parameters - test 4' {
                $Parameters = @{
                    Uri            = 'https://api.openai.example.com/v1/test'
                    ContentType    = 'application/json'
                    Body           = @{ 'key1' = $true; 'key2' = 123 }
                    AdditionalBody = @{ 'key3' = @('A', 'B', 'C'); 'key4' = @{ 'subkey1' = 'value1'; 'subkey2' = 'value2' } }
                }
                $ret = Initialize-OpenAIAPIRequestParam @Parameters
                $ret['ContentType'] | Should -BeExactly 'application/json'
                $ret['Body'] | Should -BeOfType [hashtable]
                $ret['Body']['key1'] | Should -BeTrue
                $ret['Body']['key2'] | Should -Be 123
                $ret['Body']['key3'] | Should -HaveCount 3
                $ret['Body']['key3'][0] | Should -BeExactly 'A'
                $ret['Body']['key3'][1] | Should -BeExactly 'B'
                $ret['Body']['key3'][2] | Should -BeExactly 'C'
                $ret['Body']['key4'] | Should -BeOfType [hashtable]
                $ret['Body']['key4']['subkey1'] | Should -BeExactly 'value1'
                $ret['Body']['key4']['subkey2'] | Should -BeExactly 'value2'
            }

            It 'AdditionalBody parameters - test 5' {
                Mock -Verifiable -ModuleName $script:ModuleName New-MultipartFormBoundary { 'boundary' }
                $Parameters = @{
                    Uri            = 'https://api.openai.example.com/v1/test'
                    ContentType    = 'multipart/form-data'
                    Body           = @{ 'Key1' = 'value1' }
                    AdditionalBody = @{ 'Key2' = 'value2' }
                }
                $ret = Initialize-OpenAIAPIRequestParam @Parameters
                $ret['ContentType'] | Should -BeExactly 'multipart/form-data; boundary="boundary"'
                $ret['Body'].GetType().Name | Should -Be 'Byte[]'
                $BodyAsString = [System.Text.Encoding]::UTF8.GetString($ret['Body'])
                $BodyAsString | Should -BeExactly (@(
                        '--boundary'
                        'Content-Disposition: form-data; name="Key1"'
                        ''
                        'value1'
                        '--boundary'
                        'Content-Disposition: form-data; name="Key2"'
                        ''
                        'value2'
                        '--boundary--'
                    ) -join "`r`n") # Should use CRLF line endings in multipart/form-data
            }

            It 'Unknown content type' {
                $Parameters = @{
                    Uri         = 'https://api.openai.example.com/v1/test'
                    ContentType = 'application/uknown'
                    Body        = 'Unknown Content'
                }
                $ret = Initialize-OpenAIAPIRequestParam @Parameters
                $ret['ContentType'] | Should -BeExactly 'application/uknown'
                $ret['Body'] | Should -BeExactly 'Unknown Content'
            }

            It 'Accept undefined arguments' {
                $Parameters = @{
                    Uri          = 'https://api.openai.example.com/v1/test'
                    UnknownParam = 'Unknown Value'
                }
                { $null = Initialize-OpenAIAPIRequestParam @Parameters } | Should -Not -Throw
            }
        }
    }
}
