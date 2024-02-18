function Wait-AzureThreadRun {
    [CmdletBinding(DefaultParameterSetName = 'StatusForWait')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [ValidateScript({ ([string]$_.id).StartsWith('run_') -and ([string]$_.thread_id).StartsWith('thread_') })]
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
        [string[]]$StatusForExit
    )

    begin {
        # Construct parameters
        $Parameters = $PSBoundParameters
        $Parameters.ApiType = [OpenAIApiType]::Azure
        $Parameters.AuthType = $AuthType

        # Invoke
        $steppablePipeline = {
            PSOpenAI\Wait-ThreadRun @Parameters
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
