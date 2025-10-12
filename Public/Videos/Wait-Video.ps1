function Wait-Video {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('video_id')]
        [Alias('Id')]
        [string][UrlEncodeTransformation()]$VideohId,

        [Parameter()]
        [int]$TimeoutSec = 0,

        [Parameter()]
        [ValidateRange(0, 100)]
        [int]$MaxRetryCount = 0,

        [Parameter()]
        [ValidateRange(0, 1000)]
        [float]$PollIntervalSec = 3.0,

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
        [Completions(
            'queued',
            'in_progress',
            'completed',
            'failed',
            'preprocessing',
            'running',
            'processing',
            'cancelled',
            'succeeded'
        )]
        [string[]]$StatusForWait = @('queued', 'in_progress', 'preprocessing', 'running', 'processing'),

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Completions(
            'queued',
            'in_progress',
            'completed',
            'failed',
            'preprocessing',
            'running',
            'processing',
            'cancelled',
            'succeeded'
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
        # Create cancellation token for timeout
        $Cancellation = [System.Threading.CancellationTokenSource]::new()
        if ($TimeoutSec -gt 0) {
            $Cancellation.CancelAfter([timespan]::FromSeconds($TimeoutSec))
        }

        try {
            [uint32]$PollCounter = 0
            [uint32]$PollIntervalMilliSec = $PollIntervalSec * 1000
            [uint32]$InitialPollIntervalMilliSec = $PollIntervalMilliSec / 3
            do {
                #Wait
                $innerJobObject = $null
                $WaitMilliSec = [System.Math]::Min(($InitialPollIntervalMilliSec * ($PollCounter++)), $PollIntervalMilliSec)
                Start-CancelableWait -Milliseconds $WaitMilliSec -CancellationToken $Cancellation.Token -ea Stop
                $innerJobObject = PSOpenAI\Get-Video -VideoId $VideoId @CommonParams
                $ProgressTitle = ("Waiting for completion... : Job ID '{0}'" -f $innerJobObject.id)
                if ($innerJobObject.progress) {
                    $PercentComplete = $innerJobObject.progress
                    $StatusMessage = ('Progress {0}%' -f $innerJobObject.progress)
                }
                else {
                    $PercentComplete = -1
                    $StatusMessage = ('Status: {0}' -f $innerJobObject.status)
                }
                Write-Progress -Activity $ProgressTitle -CurrentOperation $innerJobObject.status -Status $StatusMessage -PercentComplete $PercentComplete
            } while ($innerJobObject.status -and $innerJobObject.status -in $innerStatusForWait)
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
            Write-Progress -Activity ("The job with id '{0}' has {1}." -f $innerJobObject.id, $innerJobObject.status) -Completed
            if ($null -ne $Cancellation) {
                $Cancellation.Dispose()
            }
        }

        if (-not $innerJobObject.status) {
            Write-Error 'Could not retrieve the status of job.'
        }

        #Finished
        Write-Verbose ('The status of job with id "{0}" is "{1}"' -f $innerJobObject.id, $innerJobObject.status)
        $innerJobObject
        return
    }

    end {

    }
}
