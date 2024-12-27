
$PrivateDirectory = Join-Path $PSScriptRoot 'Private'
$PublicDirectory = Join-Path $PSScriptRoot 'Public'

$PrivateFunctions = Get-ChildItem -LiteralPath $PrivateDirectory -Recurse -Filter '*.ps1' -File
$PublicFunctions = Get-ChildItem -LiteralPath $PublicDirectory -Recurse -Filter '*.ps1' -File

# Exclude on specific platfotm.
$Exclude = @()
if (-not $IsWindows -or $PSVersionTable.PSVersion -lt 7.4) {
    $Exclude = @(
        'Start-RealtimeSessionAudioOutput.ps1'
        'Stop-RealtimeSessionAudioOutput.ps1'
        'Start-RealtimeSessionAudioInput.ps1'
        'Stop-RealtimeSessionAudioInput.ps1'
    )
}

# Include Private functions
$PrivateFunctions | Where-Object { $_.Name -notin $Exclude } | ForEach-Object {
    . $_.FullName
}

# Include Public functions
$PublicFunctions | Where-Object { $_.Name -notin $Exclude }  | ForEach-Object {
    . $_.FullName
}

# Export public functions
$ExportFunctions = [string[]]@()
$PublicFunctions | ForEach-Object {
    if (Test-Path -LiteralPath "Function:/$($_.BaseName)") {
        $ExportFunctions += $_.BaseName
    }
}
if ($ExportFunctions.Count -ge 1) {
    Export-ModuleMember -Function $ExportFunctions -Alias *
}

# Initialize context dictionary
Clear-OpenAIContext

# Export classes
$ExportableTypes = @(
    [APIRequestException]
    [BadRequestException]
    [ContentFilteredException]
    [UnauthorizedException]
    [NotFoundException]
    [RateLimitExceededException]
    [QuotaLimitExceededException]
)

# Get the internal TypeAccelerators class to use its static methods.
$TypeAcceleratorsClass = [psobject].Assembly.GetType('System.Management.Automation.TypeAccelerators')

# Add type accelerators for every exportable type.
foreach ($Type in $ExportableTypes) {
    if ($Type.FullName -notin $ExistingTypeAccelerators.Keys) {
        $null = $TypeAcceleratorsClass::Add($Type.FullName, $Type)
    }
}
# Remove type accelerators when the module is removed.
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
    foreach ($Type in $ExportableTypes) {
        $null = $TypeAcceleratorsClass::Remove($Type.FullName)
    }
}.GetNewClosure()
