#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

BeforeAll {
    $script:ModuleRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
    $script:ModuleName = 'PSOpenAI'
    Import-Module (Join-Path $script:ModuleRoot 'PSOpenAI.psd1') -Force
}

Describe 'Agents environment and vault commands' -Tag 'Offline' {
    BeforeAll {
        Mock -ModuleName $script:ModuleName Initialize-APIKey { [securestring]::new() }
    }

    BeforeEach {
        Mock -ModuleName $script:ModuleName Invoke-OpenAIHttpRequest {
            '{"id":"resource_123","object":"agent.resource"}'
        }
    }

    It 'creates an environment template from named parameters' {
        $Parameters = @{
            Name                = 'Development'
            CapabilityDirectory = '/workspace/capabilities'
            Env                 = @{ STAGE = 'test' }
            File                = @(@{ type = 'file_id'; file_id = 'file_123'; path = '/workspace/input.txt' })
            Network             = @{ access = 'enabled'; allowed_domains = @('api.example.com') }
            Packages            = @{ python = @('requests') }
            Plugin              = @(@{ type = 'inline'; name = 'helper'; description = 'Test helper'; source = 'UEsDBAoAAAAA' })
            Skill               = @(@{ type = 'skill_reference'; skill_id = 'skill_123' })
            Setup               = @(@{ command = 'echo ready'; cwd = '/workspace' })
        }

        $null = New-AgentEnvironmentTemplate @Parameters

        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter {
            $Uri.AbsolutePath -eq '/v1/agents/environments/templates' -and
            $Body -is [System.Collections.Specialized.OrderedDictionary] -and
            $Body.name -eq 'Development' -and
            $Body.capability_directories[0] -eq '/workspace/capabilities' -and
            $Body.env.STAGE -eq 'test' -and
            $Body.files[0].file_id -eq 'file_123' -and
            $Body.network.access -eq 'enabled' -and
            $Body.packages.python[0] -eq 'requests' -and
            $Body.plugins[0].name -eq 'helper' -and
            $Body.skills[0].skill_id -eq 'skill_123' -and
            $Body.setup_commands[0].command -eq 'echo ready'
        }
    }

    It 'updates only the explicitly supplied environment template properties' {
        $null = Set-AgentEnvironmentTemplate envtpl_123 -Name 'Updated' -Env @{} -Confirm:$false

        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter {
            $Uri.AbsolutePath -eq '/v1/agents/environments/templates/envtpl_123' -and
            $Body.name -eq 'Updated' -and
            $Body.Contains('env') -and
            -not $Body.Contains('network')
        }
    }

    It 'adds an uploaded OpenAI file to an environment using named parameters' {
        $null = Add-AgentEnvironmentFile env_123 -FileId file_123 -Path '/workspace/input.txt'

        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter {
            $Uri.AbsolutePath -eq '/v1/agents/environments/env_123/files' -and
            $Body.type -eq 'file_id' -and
            $Body.file_id -eq 'file_123' -and
            $Body.path -eq '/workspace/input.txt'
        }
    }

    It 'rejects environment file destinations outside the workspace' {
        { Add-AgentEnvironmentFile env_123 -FileId file_123 -Path '/tmp/input.txt' -ErrorAction Stop } | Should -Throw
        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -Times 0 -Exactly
    }

    It 'creates a vault from named parameters' {
        $null = New-AgentVault -Name 'Application secrets' -Metadata @{ team = 'platform' }

        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter {
            $Uri.AbsolutePath -eq '/v1/vaults' -and
            $Body -is [System.Collections.Specialized.OrderedDictionary] -and
            $Body.name -eq 'Application secrets' -and
            $Body.metadata.team -eq 'platform'
        }
    }

    It 'creates a static bearer credential from a SecureString' {
        $Token = ConvertTo-SecureString 'fake-static-token' -AsPlainText -Force
        $null = New-AgentVaultCredential vault_123 -Name 'MCP token' -Token $Token -McpServerUrl 'https://mcp.example.com'

        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter {
            $Uri.AbsolutePath -eq '/v1/vaults/vault_123/credentials' -and
            $Body.name -eq 'MCP token' -and
            $Body.auth.type -eq 'static_bearer' -and
            $Body.auth.token -eq 'fake-static-token' -and
            $Body.auth.mcp_server_url -eq 'https://mcp.example.com/'
        }
    }

    It 'creates a limited environment-variable credential from a SecureString' {
        $SecretValue = ConvertTo-SecureString 'fake-environment-secret' -AsPlainText -Force
        $null = New-AgentVaultCredential vault_123 -Name 'Service key' -SecretName 'SERVICE_API_KEY' -SecretValue $SecretValue -AllowedHost 'api.example.com', 'backup.example.com'

        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter {
            $Body.auth.type -eq 'environment_variable' -and
            $Body.auth.secret_name -eq 'SERVICE_API_KEY' -and
            $Body.auth.secret_value -eq 'fake-environment-secret' -and
            $Body.auth.networking.type -eq 'limited' -and
            $Body.auth.networking.allowed_hosts.Count -eq 2
        }
    }

    It 'defaults an environment-variable credential to unrestricted substitution' {
        $SecretValue = ConvertTo-SecureString 'fake-environment-secret' -AsPlainText -Force
        $null = New-AgentVaultCredential vault_123 -Name 'Service key' -SecretName 'SERVICE_API_KEY' -SecretValue $SecretValue

        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter {
            $Body.auth.networking.type -eq 'unrestricted' -and
            -not $Body.auth.networking.Contains('allowed_hosts')
        }
    }

    It 'rotates static bearer and environment-variable credentials without destination fields' {
        $Token = ConvertTo-SecureString 'fake-rotated-token' -AsPlainText -Force
        $SecretValue = ConvertTo-SecureString 'fake-rotated-secret' -AsPlainText -Force

        $null = Set-AgentVaultCredential vault_123 credential_123 -Token $Token -Confirm:$false
        $null = Set-AgentVaultCredential vault_123 credential_456 -SecretValue $SecretValue -Confirm:$false

        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter {
            $Uri.AbsolutePath -eq '/v1/vaults/vault_123/credentials/credential_123' -and
            $Body.auth.type -eq 'static_bearer' -and
            $Body.auth.token -eq 'fake-rotated-token' -and
            -not $Body.auth.Contains('mcp_server_url')
        }
        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -Times 1 -Exactly -ParameterFilter {
            $Uri.AbsolutePath -eq '/v1/vaults/vault_123/credentials/credential_456' -and
            $Body.auth.type -eq 'environment_variable' -and
            $Body.auth.secret_value -eq 'fake-rotated-secret' -and
            -not $Body.auth.Contains('secret_name')
        }
    }

    It 'retains raw Body and Auth parameter sets for advanced API shapes' {
        $null = New-AgentEnvironmentTemplate -Body @{ name = 'Raw template' }
        $null = Add-AgentEnvironmentFile env_123 -Body @{ type = 'inline'; data = 'dGVzdA=='; path = '/workspace/test.txt' }
        $null = New-AgentVault -Body @{ name = 'Raw vault' }
        $null = New-AgentVaultCredential vault_123 -Name 'OAuth token' -Auth @{ type = 'mcp_oauth'; access_token = 'fake-oauth-token'; mcp_server_url = 'https://mcp.example.com' }
        $null = Set-AgentVaultCredential vault_123 credential_123 -Body @{ auth = @{ type = 'mcp_oauth'; access_token = 'fake-rotated-oauth-token' } } -Confirm:$false

        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -Times 5 -Exactly
    }

    It 'does not rotate a credential when WhatIf is used' {
        $Token = ConvertTo-SecureString 'fake-token' -AsPlainText -Force
        $null = Set-AgentVaultCredential vault_123 credential_123 -Token $Token -WhatIf

        Should -Invoke Invoke-OpenAIHttpRequest -ModuleName $script:ModuleName -Times 0 -Exactly
    }
}
