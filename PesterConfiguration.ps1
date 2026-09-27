#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '6.0.0' }

$configuration = New-PesterConfiguration
$configuration.TestRegistry.Enabled = $false
$configuration
