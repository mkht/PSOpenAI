function New-ChatCompletionFunction {
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    [CmdletBinding(DefaultParameterSetName = 'Manual')]
    param (
        [Parameter(ParameterSetName = 'Manual' , Mandatory = $true, Position = 0)]
        [ValidatePattern('^[a-zA-Z0-9_-]{1,64}$')]
        [string]$Name,

        [Parameter(ParameterSetName = 'PSCommand' , Mandatory = $true, Position = 0)]
        [ValidateScript({ (Get-Command $_ -ea Ignore) -is [CommandInfo] })]
        [string]$Command,

        [Parameter(ParameterSetName = 'Manual')]
        [Parameter(ParameterSetName = 'PSCommand')]
        [string]$Description,

        [Parameter(ParameterSetName = 'Manual')]
        [System.Collections.IDictionary]$ParametersHashTable,

        [Parameter(ParameterSetName = 'Manual', DontShow = $true)]
        [string]$ParametersType = 'object',

        [Parameter(ParameterSetName = 'PSCommand')]
        [ValidateNotNullOrEmpty()]
        [string[]]$IncludeParameters,

        [Parameter(ParameterSetName = 'PSCommand')]
        [ValidateNotNullOrEmpty()]
        [string[]]$ExcludeParameters,

        [Parameter(ParameterSetName = 'PSCommand')]
        [string]$ParameterSetName
    )

    if ($PSCmdlet.ParameterSetName -eq 'Manual') {
        New-ChatCompletionFunctionFromHashTable @PSBoundParameters
        return
    }
    elseif ($PSCmdlet.ParameterSetName -eq 'PSCommand') {
        New-ChatCompletionFunctionFromPSCommand @PSBoundParameters
        return
    }
}
