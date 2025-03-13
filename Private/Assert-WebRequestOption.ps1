function Assert-WebRequestOption {
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [System.Collections.IDictionary]$WebOptions,

        [Parameter()]
        [switch]$Stream
    )

    # Disallow overwriting or specifying the following parameters
    $SkipParameters = [System.Collections.Generic.HashSet[string]]::new(
        [string[]]@(
            'Uri',
            'Headers',
            'Body',
            'Form',
            'Method',
            'CustomMethod',
            'ContentType',
            'UserAgent',
            'TimeoutSec',
            'UseBasicParsing',
            'Authentication',
            'Credential',
            'Token',
            'UseDefaultCredentials',
            'InFile',
            'OutFile',
            'Resume',
            'PassThru',
            'SessionVariable'
        )
    )

    $SkipParameters.UnionWith([System.Management.Automation.PSCmdlet]::CommonParameters)
    $SkipParameters.UnionWith([System.Management.Automation.PSCmdlet]::OptionalCommonParameters)

    $OutputWebOptions = @{}

    if (-not $Stream) {
        $WebCmd = Get-Command -Name 'Invoke-WebRequest' -Module 'Microsoft.PowerShell.Utility'
        if (-not $WebCmd) {
            Write-Error "The cmdlet 'Invoke-WebRequest' is not available."
            return
        }

        $WebOptions.Keys | ForEach-Object {
            if ((-not $WebCmd.Parameters.ContainsKey($_)) -or $SkipParameters.Contains($_)) {
                Write-Warning "The parameter '$_' is not supported by the cmdlet."
                continue
            }
            $OutputWebOptions.Add($_, $WebOptions[$_])
        }
    }



    return $OutputWebOptions
}