function Request-AzureAudioTranscription {
    [CmdletBinding(DefaultParameterSetName = 'Language')]
    [OutputType([string])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [ValidateScript({ Test-Path -LiteralPath $_ -PathType Leaf })]
        [string]$File,

        [Parameter(Mandatory)]
        [Alias('Model')]
        [string]$Deployment,

        [Parameter()]
        [string]$Prompt,

        [Parameter()]
        [Alias('response_format')]
        [ValidateSet('json', 'text', 'srt', 'verbose_json', 'vtt')]
        [string]$Format = 'text',

        [Parameter()]
        [ValidateRange(0.0, 1.0)]
        [double]$Temperature,

        [Parameter(ParameterSetName = 'Language')]
        [string]$Language,

        [Parameter(DontShow, ParameterSetName = 'LiteralLanguage')]
        [string]$LiteralLanguage,

        [Parameter()]
        [int]$TimeoutSec = 0,

        [Parameter()]
        [ValidateRange(0, 100)]
        [int]$MaxRetryCount = 0,

        [Parameter()]
        [System.Uri]$ApiBase,

        [Parameter()]
        [string]$ApiVersion,

        [Parameter()]
        [securestring][SecureStringTransformation()]$ApiKey,

        [Parameter()]
        [ValidateSet('azure', 'azure_ad')]
        [string]$AuthType = 'azure',

        [Parameter()]
        [System.Collections.IDictionary]$AdditionalQuery,

        [Parameter()]
        [System.Collections.IDictionary]$AdditionalHeaders,

        [Parameter()]
        [object]$AdditionalBody
    )

    begin {
        # Construct parameters
        $Parameters = $PSBoundParameters
        $Parameters.ApiType = [OpenAIApiType]::Azure
        $Parameters.AuthType = $AuthType
        $Parameters.Model = $Deployment
        $null = $Parameters.Remove('Deployment')

        # Invoke base function
        $steppablePipeline = {
            Request-AudioTranscription @Parameters
        }.GetSteppablePipeline($myInvocation.CommandOrigin)
        $steppablePipeline.Begin($PSCmdlet)
    }

    process {
        $steppablePipeline.Process($PSItem)
    }

    end {
        $steppablePipeline.End()
    }
}