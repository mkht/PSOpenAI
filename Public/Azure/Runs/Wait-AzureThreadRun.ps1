function Wait-AzureThreadRun {
    [CmdletBinding(DefaultParameterSetName = 'StatusForWait')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [ValidateScript({ ([string]$_.id).StartsWith('run_', [StringComparison]::Ordinal) -and ([string]$_.thread_id).StartsWith('thread_', [StringComparison]::Ordinal) })]
        [Alias('Run')]
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

        [Parameter(ParameterSetName = 'StatusForWait')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet(
            'queued',
            'in_progress',
            'completed',
            'requires_action',
            'expired',
            'cancelling',
            'cancelled',
            'failed'
        )]
        [string[]]$StatusForWait = @('queued', 'in_progress'),

        [Parameter(ParameterSetName = 'StatusForExit')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet(
            'queued',
            'in_progress',
            'completed',
            'requires_action',
            'expired',
            'cancelling',
            'cancelled',
            'failed'
        )]
        [string[]]$StatusForExit,

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
            PSOpenAI\Wait-ThreadRun @paramseters
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
