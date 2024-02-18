function Start-AzureThreadRun {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('thread_id')]
        [Alias('Thread')]
        [ValidateScript({
            ($_ -is [string] -and $_.StartsWith('thread_')) -or `
                ($_.id -is [string] -and $_.id.StartsWith('thread_')) -or `
                ($_.thread_id -is [string] -and $_.thread_id.StartsWith('thread_'))
            })]
        [Object]$InputObject,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('assistant_id')]
        [ValidateScript({
            ($_ -is [string] -and $_.StartsWith('asst_')) -or `
                ($_.id -is [string] -and $_.id.StartsWith('asst_')) -or `
                ($_.assistant_id -is [string] -and $_.assistant_id.StartsWith('asst_'))
            })]
        [Object]$Assistant,

        [Parameter()]
        [Alias('Model')]
        [string]$Deployment,

        [Parameter()]
        [ValidateLength(0, 32768)]
        [string]$Instructions,

        [Parameter()]
        [Alias('additional_instructions')]
        [string]$AdditionalInstructions,

        [Parameter()]
        [AllowEmptyCollection()]
        [System.Collections.IDictionary[]]$Tools,

        [Parameter()]
        [bool]$UseCodeInterpreter = $false,

        [Parameter()]
        [bool]$UseRetrieval = $false,

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
        [securestring][SecureStringTransformation()]$ApiKey
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
            PSOpenAI\Start-ThreadRun @Parameters
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
