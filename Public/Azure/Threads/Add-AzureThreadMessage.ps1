function Add-AzureThreadMessage {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('thread_id')]
        [Alias('Thread')]
        [ValidateScript({
            ($_ -is [string] -and $_.StartsWith('thread_')) -or `
                ($_.id -is [string] -and $_.id.StartsWith('thread_')) -or `
                ($_.thread_id -is [string] -and $_.thread_id.StartsWith('thread_'))
            })]
        [Object]$InputObject,

        [Parameter(Mandatory = $true, Position = 0)]
        [Alias('Text')]
        [Alias('Content')]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter()]
        [string][LowerCaseTransformation()]$Role = 'user',

        [Parameter()]
        [Alias('file_ids')]
        [ValidateRange(0, 10)]
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
        [switch]$PassThru
    )

    begin {
        # Construct parameters
        $Parameters = $PSBoundParameters
        $Parameters.ApiType = [OpenAIApiType]::Azure
        $Parameters.AuthType = $AuthType

        # Invoke
        $steppablePipeline = {
            PSOpenAI\Add-ThreadMessage @Parameters
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