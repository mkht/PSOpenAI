#Requires -Modules @{ ModuleName="Pester"; ModuleVersion="5.3.0" }

$ModuleName = 'PSOpenAI'
$ModuleRoot = Split-Path $PSScriptRoot -Parent
$ModuleName = 'PSOpenAI'
Import-Module (Join-Path $ModuleRoot "$ModuleName.psd1") -Force

BeforeAll {
    $script:ModuleRoot = Split-Path $PSScriptRoot -Parent
    $script:ModuleName = 'PSOpenAI'
    Import-Module (Join-Path $script:ModuleRoot "$script:ModuleName.psd1") -Force

    # backup current value
    $script:BackupGlobalOrgId = $global:OPENAI_ORGANIZATION
    $script:BackupEnvOrgId = $env:OPENAI_ORGANIZATION
}

AfterAll {
    #Restore key
    $global:OPENAI_ORGANIZATION = $script:BackupGlobalOrgId
    $env:OPENAI_ORGANIZATION = $script:BackupEnvOrgId
    $script:BackupGlobalOrgId = $script:BackupEnvOrgId = $null
}

Describe 'Initialize-OrganizationID' {
    Context 'Unit tests (offline)' -Tag 'Offline' {
        InModuleScope $ModuleName {

            BeforeEach {
                $global:OPENAI_ORGANIZATION = $null
                $env:OPENAI_ORGANIZATION = $null
            }

            It 'Organization ID from parameter' {
                $ret = Initialize-OrganizationID -OrgId 'org-ABCDEFGHIabcdefghi'
                $ret | Should -BeOfType [string]
                $ret | Should -BeExactly 'org-ABCDEFGHIabcdefghi'
            }

            It 'Organization ID from global variable (OPENAI_ORGANIZATION)' {
                $global:OPENAI_ORGANIZATION = 'org-GLOBALOrganizationID'
                $ret = Initialize-OrganizationID -OrgId ''
                $ret | Should -BeOfType [string]
                $ret | Should -BeExactly 'org-GLOBALOrganizationID'
            }

            It 'Organization ID from environment variable (OPENAI_ORGANIZATION)' {
                $env:OPENAI_ORGANIZATION = 'org-ENVOrganizationID'
                $ret = Initialize-OrganizationID -OrgId ''
                $ret | Should -BeOfType [string]
                $ret | Should -BeExactly 'org-ENVOrganizationID'
            }

            It '1: OrgId > Global > Env' {
                $OrgId = 'org-ParamOrganizationID'
                $global:OPENAI_ORGANIZATION = 'org-GLOBALOrganizationID'
                $env:OPENAI_ORGANIZATION = 'org-ENVOrganizationID'
                $ret = Initialize-OrganizationID -OrgId $OrgId
                $ret | Should -BeOfType [string]
                $ret | Should -BeExactly $OrgId
            }

            It '2: Organization ID > Global > Env' {
                $OrgId = $null
                $global:OPENAI_ORGANIZATION = 'org-GLOBALOrganizationID'
                $env:OPENAI_ORGANIZATION = 'org-ENVOrganizationID'
                $ret = Initialize-OrganizationID -OrgId $OrgId
                $ret | Should -BeOfType [string]
                $ret | Should -BeExactly $global:OPENAI_ORGANIZATION
            }

            It '3: Organization ID > Global > Env' {
                $OrgId = $null
                $global:OPENAI_ORGANIZATION = $null
                $env:OPENAI_ORGANIZATION = 'org-ENVOrganizationID'
                $ret = Initialize-OrganizationID -OrgId $OrgId
                $ret | Should -BeOfType [string]
                $ret | Should -BeExactly $env:OPENAI_ORGANIZATION
            }
        }
    }
}
