function ParseThreadRunObject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [PSCustomObject]$InputObject,

        [Parameter()]
        [System.Collections.IDictionary]$CommonParams = @{},

        [Parameter()]
        [switch]$Primitive
    )

    # Add custom type name and properties to output object.
    $InputObject.PSObject.TypeNames.Insert(0, 'PSOpenAI.Thread.Run')
  ('created_at', 'expires_at', 'started_at', 'cancelled_at', 'failed_at', 'completed_at') | ForEach-Object {
        if ($null -ne $InputObject.$_ -and ($unixtime = $InputObject.$_ -as [long])) {
            # convert unixtime to [DateTime] for read suitable
            $InputObject | Add-Member -MemberType NoteProperty -Name $_ -Value ([System.DateTimeOffset]::FromUnixTimeSeconds($unixtime).LocalDateTime) -Force
        }
    }
    Write-Output $InputObject
}
