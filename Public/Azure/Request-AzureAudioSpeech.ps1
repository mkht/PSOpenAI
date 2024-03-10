function Request-AzureAudioSpeech {
    [CmdletBinding(DefaultParameterSetName = 'Default')]
    [OutputType([void])]
    param (
        [Parameter(ParameterSetName = 'Default', Mandatory = $true, Position = 0)]
        [Alias('Input')]
        [ValidateNotNullOrEmpty()]
        [string]$Text,

        # For pipeline input from chat completion
        [Parameter(ParameterSetName = 'Pipeline', DontShow = $true, Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNull()]
        [Object]$InputObject,

        [Parameter(Mandatory = $true)]
        [Alias('Model')]
        [string]$Deployment,

        [Parameter()]
        [Completions(
            'alloy',
            'echo',
            'fable',
            'onyx',
            'nova',
            'shimmer'
        )]
        [string][LowerCaseTransformation()]$Voice = 'alloy',

        [Parameter()]
        [Alias('response_format')]
        [Completions(
            'mp3',
            'opus',
            'aac',
            'flac',
            'wav',
            'pcm'
        )]
        [string][LowerCaseTransformation()]$Format,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$OutFile,

        [Parameter()]
        [ValidateRange(0.25, 4.0)]
        [double]$Speed = 1.0,

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
            Request-AudioSpeech @Parameters
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