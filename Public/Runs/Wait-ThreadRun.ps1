function Wait-ThreadRun {
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

        [Parameter(DontShow = $true)]
        [OpenAIApiType]$ApiType = [OpenAIApiType]::OpenAI,

        [Parameter()]
        [System.Uri]$ApiBase,

        [Parameter(DontShow = $true)]
        [string]$ApiVersion,

        [Parameter(DontShow = $true)]
        [string]$AuthType = 'openai',

        [Parameter()]
        [securestring][SecureStringTransformation()]$ApiKey,

        [Parameter()]
        [Alias('OrgId')]
        [string]$Organization,

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
        # Parameter construction
        if ($PSCmdlet.ParameterSetName -eq 'StatusForExit') {
            $innerStatusForWait = [System.Collections.Generic.HashSet[string]]::new([string[]](
                    'queued',
                    'in_progress',
                    'completed',
                    'requires_action',
                    'expired',
                    'cancelling',
                    'cancelled',
                    'failed'
                ))
            $innerStatusForWait.ExceptWith([System.Collections.Generic.List[string]]$StatusForExit)
        }
        else {
            $innerStatusForWait = [System.Collections.Generic.HashSet[string]]::new($StatusForWait)
        }

        # Parse Common params
        $CommonParams = ParseCommonParams $PSBoundParameters
    }

    process {
        $innerRunObject = $InputObject

        $GetThreadRunparams = $CommonParams
        $GetThreadRunparams.RunId = $innerRunObject.id
        $GetThreadRunparams.InputObject = $innerRunObject.thread_id
        $GetThreadRunparams.Primitive = $true

        # Create cancellation token for timeout
        $Cancellation = [System.Threading.CancellationTokenSource]::new()
        if ($TimeoutSec -gt 0) {
            $Cancellation.CancelAfter([timespan]::FromSeconds($TimeoutSec))
        }

        try {
            $PollCounter = 1
            $ProgressTitle = 'Waiting for completes...'
            while ($innerRunObject.status -and $innerRunObject.status -in $innerStatusForWait) {
                #Wait
                Write-Progress -Activity $ProgressTitle -Status ('The status of run with id "{0}" is "{1}"' -f $innerRunObject.id, $innerRunObject.status) -PercentComplete -1
                $innerRunObject = $null
                Start-CancelableWait -Milliseconds ([System.Math]::Min((200 * ($PollCounter++)), 1000)) -CancellationToken $Cancellation.Token -ea Stop
                $innerRunObject = PSOpenAI\Get-ThreadRun @GetThreadRunparams
            }
        }
        catch [OperationCanceledException] {
            Write-Error -ErrorRecord $_
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
