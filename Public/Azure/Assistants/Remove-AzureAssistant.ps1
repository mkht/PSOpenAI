function Remove-AzureAssistant {
    [CmdletBinding()]
    [OutputType([void])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('assistant_id')]
        [Alias('Assistant')]
        [ValidateScript({
            ($_ -is [string] -and $_.StartsWith('asst_', [StringComparison]::Ordinal)) -or `
                ($_.id -is [string] -and $_.id.StartsWith('asst_', [StringComparison]::Ordinal)) -or `
                ($_.assistant_id -is [string] -and $_.assistant_id.StartsWith('asst_', [StringComparison]::Ordinal))
            })]
        [Object]$InputObject,

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

        # Invoke
        $steppablePipeline = {
            PSOpenAI\Remove-Assistant @Parameters
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
