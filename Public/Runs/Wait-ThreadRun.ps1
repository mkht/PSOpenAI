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
        [string[]]$StatusForExit
    )

    begin {
        # Parameter contruction
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
        $GetThreadRunparams = $CommonParams
        $GetThreadRunparams.RunId = $InputObject.id
        $GetThreadRunparams.InputObject = $InputObject.thread_id
        $GetThreadRunparams.Primitive = $true

        # Create cancellation token for timeout
        $Cancellation = [System.Threading.CancellationTokenSource]::new()
        if ($TimeoutSec -gt 0) {
            $Cancellation.CancelAfter([timespan]::FromSeconds($TimeoutSec))
        }

        try {
            $PollCounter = 1
            $ProgressTitle = 'Waiting for completes...'
            while ($InputObject.status -and $InputObject.status -in $innerStatusForWait) {
                #Wait
                Write-Progress -Activity $ProgressTitle -Status ('The status of run with id "{0}" is "{1}"' -f $InputObject.id, $InputObject.status) -PercentComplete -1
                $InputObject = $null
                Start-CancelableWait -Milliseconds ([System.Math]::Min((200 * ($PollCounter++)), 1000)) -CancellationToken $Cancellation.Token -ea Stop
                $InputObject = PSOpenAI\Get-ThreadRun @GetThreadRunparams
            }
            Write-Progress -Activity $ProgressTitle -Completed
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
            if ($null -ne $Cancellation) {
                $Cancellation.Dispose()
            }
        }

        if (-not $InputObject.status) {
            Write-Error 'Could not retrieve the status of run.'
        }

        #Finished
        Write-Verbose ('The status of run with id "{0}" is "{1}"' -f $InputObject.id, $InputObject.status)
        $GetThreadRunparams.Primitive = $false
        PSOpenAI\Get-ThreadRun @GetThreadRunparams
        return
    }

    end {

    }
}
