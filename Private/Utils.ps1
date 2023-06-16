function ObjectToHashTable {
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [object]$InputObject
    )
    $hashtable = @{}
    foreach ( $property in $InputObject.psobject.properties.name ) {
        $hashtable[$property] = $InputObject.$property
    }
    $hashtable
}

function ObjectToContent {
    param(
        [Parameter(Mandatory, Position = 0)]
        [AllowNull()]
        [object]$InputObject
    )

    if ($InputObject -is [array]) {
        foreach ($o in $InputObject) {
            ObjectToContent -InputObject $o
        }
        return
    }

    if (
        $null -eq $InputObject -or `
            $InputObject -eq [System.Management.Automation.Internal.AutomationNull]::Value -or `
            $InputObject -eq [System.DBNull]::Value -or `
            $InputObject -eq [NullString]::Value

    ) {
        $null
    }
    elseif (
        $InputObject -is [string] -or `
            $InputObject -is [System.Collections.IDictionary] -or `
            $InputObject -is [char] -or `
            $InputObject -is [bool] -or `
            $InputObject -is [datetime] -or `
            $InputObject -is [System.DateTimeOffset] -or `
            $InputObject -is [uri] -or `
            $InputObject -is [double] -or `
            $InputObject -is [float] -or `
            $InputObject -is [decimal] -or `
            $InputObject -is [double]
    ) {
        $InputObject
    }
    elseif (
        $InputObject -is [timespan] -or `
            $InputObject -is [guid] -or `
            $InputObject -is [regex] -or `
            $InputObject -is [ipaddress] -or `
            $InputObject -is [mailaddress]
    ) {
        $InputObject.ToString()
    }
    else {
        $t = $InputObject.GetType()
        if ($t.IsPrimitive) {
            $InputObject
        }
        elseif ($t.Name -eq 'PSCustomObject') {
            $InputObject
        }
        elseif ($t.IsEnum) {
            [string]$InputObject
        }
        else {
            ($InputObject | Format-List | Out-String) -replace "`r", ''
        }
    }
}
