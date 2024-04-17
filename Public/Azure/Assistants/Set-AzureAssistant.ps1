function Set-AzureAssistant {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('assistant_id')]
        [Alias('Assistant')]
        [ValidateScript({ [bool](Get-AssistantIdFromInputObject $_) })]
        [Object]$InputObject,

        [Parameter()]
        [ValidateLength(0, 256)]
        [string]$Name,

        [Parameter()]
        [Alias('Model')]
        [string]$Deployment,

        [Parameter()]
        [ValidateLength(0, 512)]
        [string]$Description,

        [Parameter()]
        [ValidateLength(0, 32768)]
        [string]$Instructions,

        [Parameter()]
        [AllowEmptyCollection()]
        [System.Collections.IDictionary[]]$Tools,

        [Parameter()]
        [switch]$UseCodeInterpreter,

        [Parameter()]
        [switch]$UseRetrieval,

        [Parameter()]
        [Alias('file_ids')]
        [ValidateRange(0, 20)]
        [string[]]$FileId,

        [Parameter()]
        [System.Collections.IDictionary]$MetaData,

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
        [ValidateSet('azure', 'azure_ad')]
        [string]$AuthType = 'azure',

        [Parameter()]
        [securestring][SecureStringTransformation()]$ApiKey,

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
        if ($PSBoundParameters.ContainsKey('Deployment')) {
            $Parameters.Model = $Deployment
            $null = $Parameters.Remove('Deployment')
        }

        # Invoke
        $steppablePipeline = {
            PSOpenAI\Set-Assistant @paramseters
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
