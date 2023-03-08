function Request-CodeEdit {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias('Message')]
        [string]$Instruction,

        [Parameter()]
        [AllowEmptyString()]
        [Alias('Input')]
        [string]$Text = '',

        [Parameter()]
        [string]$Model = 'code-davinci-edit-001',

        [Parameter()]
        [ValidateRange(0.0, 2.0)]
        [double]$Temperature,

        [Parameter()]
        [ValidateRange(0.0, 1.0)]
        [Alias('top_p')]
        [double]$TopP,

        [Parameter()]
        [Alias('n')]
        [uint16]$NumberOfAnswers,

        [Parameter()]
        [int]$TimeoutSec = 0,

        [Parameter()]
        [object]$Token
    )

    # Just call the Request-TextEdit with 'code-davinci-edit-001' model.
    $CodeEditParam = $PSBoundParameters
    if (-not $PSBoundParameters.ContainsKey('Model')) {
        $CodeEditParam.Model = $Model
    }
    Request-TextEdit @CodeEditParam
}
