function ParseThreadObject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [PSCustomObject]$InputObject,

        [Parameter()]
        [System.Collections.IDictionary]$CommonParams = @{},

        [Parameter()]
        [switch]$Primitive
    )
    # Add custom type name and properties to output object.
    $InputObject.PSObject.TypeNames.Insert(0, 'PSOpenAI.Thread')
    if ($null -ne $InputObject.created_at -and ($unixtime = $InputObject.created_at -as [long])) {
        # convert unixtime to [DateTime] for read suitable
        $InputObject | Add-Member -MemberType NoteProperty -Name 'created_at' -Value ([System.DateTimeOffset]::FromUnixTimeSeconds($unixtime).LocalDateTime) -Force
    }
    if (-not $Primitive) {
        $InputObject | Add-Member -MemberType NoteProperty -Name 'Messages' -Value @(PSOpenAI\Get-ThreadMessage -InputObject $InputObject.id -All @CommonParams) -Force
    }
    else {
        $InputObject | Add-Member -MemberType NoteProperty -Name 'Messages' -Value ([object[]]::new(0)) -Force
    }
    Write-Output $InputObject
}
