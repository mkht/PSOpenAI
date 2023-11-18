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

function Merge-Dictionary {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [System.Collections.IDictionary]$d1,
        [Parameter(Mandatory, Position = 1)]
        [System.Collections.IDictionary]$d2
    )
    $o = @{}
    foreach ($s in $d1.GetEnumerator()) {
        $o[$s.Key] = $s.Value
    }
    foreach ($s in $d2.GetEnumerator()) {
        $o[$s.Key] = $s.Value
    }
    $o
}

function DecryptSecureString {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory, Position = 0)]
        [securestring]$SecureString
    )
    try {
        $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
        $PlainToken = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($bstr)
        $PlainToken
    }
    catch {
        Write-Error -Exception $_.Exception
    }
    finally {
        $bstr = $PlainToken = $null
    }
}

function ParseCommonParams {
    param (
        [Parameter(Position = 0)]
        [hashtable]$Arguments,

        [Parameter()]
        [string[]]$ParamNames = @(
            'TimeoutSec'
            'MaxRetryCount'
            'ApiBase'
            'ApiVersion'
            'ApiType'
            'AuthType'
            'ApiKey'
            'Organization'
        )
    )
    $OutParam = @{}
    # CommonParams
    $ParamNames.Where({
            $Arguments.ContainsKey($_)
        }).ForEach({
            $OutParam.Add($_, $Arguments."$_")
        })
    $OutParam
}
