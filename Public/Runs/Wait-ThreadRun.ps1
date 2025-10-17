function Wait-ThreadRun {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(ParameterSetName = 'Run', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('InputObject')]  # for backward compatibility
        [PSTypeName('PSOpenAI.Thread.Run')]$Run,

        [Parameter(ParameterSetName = 'Id', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('run_id')]
        [string][UrlEncodeTransformation()]$RunId,

        [Parameter(ParameterSetName = 'Id', Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('thread_id')]
        [string][UrlEncodeTransformation()]$ThreadId,

        [Parameter()]
        [int]$TimeoutSec = 0,

        [Parameter()]
        [ValidateRange(0, 100)]
        [int]$MaxRetryCount = 0,

        [Parameter()]
        [ValidateRange(0, 1000)]
        [float]$PollIntervalSec = 1.0,

        [Parameter()]
        [OpenAIApiType]$ApiType = [OpenAIApiType]::OpenAI,

        [Parameter()]
        [System.Uri]$ApiBase,

        [Parameter(DontShow)]
        [string]$ApiVersion,

        [Parameter()]
        [ValidateSet('openai', 'azure', 'azure_ad')]
        [string]$AuthType = 'openai',

        [Parameter()]
        [securestring][SecureStringTransformation()]$ApiKey,

        [Parameter()]
        [Alias('OrgId')]
        [string]$Organization,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet(
            'queued',
            'in_progress',
            'completed',
            'requires_action',
            'expired',
            'cancelling',
            'cancelled',
            'failed',
            'incomplete'
        )]
        [string[]]$StatusForWait = @('queued', 'in_progress'),

        [Parameter()]
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
        # Parameter construction
        $innerStatusForWait = [System.Collections.Generic.HashSet[string]]::new($StatusForWait)
        if ($PSBoundParameters.ContainsKey('StatusForExit')) {
            $innerStatusForWait.ExceptWith([System.Collections.Generic.List[string]]$StatusForExit)
        }

        # Parse Common params
        $CommonParams = ParseCommonParams $PSBoundParameters
    }

    process {
        # Get ids
        if ($PSCmdlet.ParameterSetName -ceq 'Run') {
            $ThreadId = $Run.thread_id
            $RunId = $Run.id
        }
        if (-not $ThreadId) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve Thread ID.'))
            return
        }
        if (-not $RunId) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve Run ID.'))
            return
        }

        $GetThreadRunparams = $CommonParams
        $GetThreadRunparams.RunId = $RunId
        $GetThreadRunparams.ThreadId = $ThreadId
        $GetThreadRunparams.Primitive = $true

        # Create cancellation token for timeout
        $Cancellation = [System.Threading.CancellationTokenSource]::new()
        if ($TimeoutSec -gt 0) {
            $Cancellation.CancelAfter([timespan]::FromSeconds($TimeoutSec))
        }

        try {
            [uint32]$PollCounter = 0
            [uint32]$PollIntervalMilliSec = $PollIntervalSec * 1000
            [uint32]$InitialPollIntervalMilliSec = $PollIntervalMilliSec / 3
            $ProgressTitle = 'Waiting for completes...'
            do {
                #Wait
                $innerRunObject = $null
                $WaitMilliSec = [System.Math]::Min(($InitialPollIntervalMilliSec * ($PollCounter++)), $PollIntervalMilliSec)
                Start-CancelableWait -Milliseconds $WaitMilliSec -CancellationToken $Cancellation.Token -ea Stop
                $innerRunObject = PSOpenAI\Get-ThreadRun @GetThreadRunparams
                Write-Progress -Activity $ProgressTitle -Status ('The status of run with id "{0}" is "{1}"' -f $innerRunObject.id, $innerRunObject.status) -PercentComplete -1
            } while ($innerRunObject.status -and $innerRunObject.status -in $innerStatusForWait)
        }
        catch [OperationCanceledException] {
            Write-TimeoutError
            return
        }
        catch {
            Write-Error -Exception $_.Exception
            return
        }
        finally {
            Write-Progress -Activity $ProgressTitle -Completed
            if ($null -ne $Cancellation) {
                $Cancellation.Dispose()
            }
        }

        if (-not $innerRunObject.status) {
            Write-Error 'Could not retrieve the status of run.'
        }

        #Finished
        Write-Verbose ('The status of run with id "{0}" is "{1}"' -f $innerRunObject.id, $innerRunObject.status)
        $GetThreadRunparams.Primitive = $false
        PSOpenAI\Get-ThreadRun @GetThreadRunparams
        return
    }

    end {

    }
}
