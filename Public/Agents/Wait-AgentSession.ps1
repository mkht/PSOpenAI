function Wait-AgentSession {
    [CmdletBinding(DefaultParameterSetName = 'SessionId')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(
            ParameterSetName = 'Session',
            Mandatory,
            Position = 0,
            ValueFromPipeline
        )]
        [PSTypeName('PSOpenAI.Agent.Session')]
        [pscustomobject]$Session,

        [Parameter(
            ParameterSetName = 'SessionId',
            Mandatory,
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName
        )]
        [ValidateNotNullOrEmpty()]
        [Alias('session_id', 'Id')]
        [string][UrlEncodeTransformation()]$SessionId,

        [Parameter()]
        [ValidateRange(0, 1000)]
        [float]$PollIntervalSec = 1.0,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('idle', 'in_progress', 'requires_action', 'failed')]
        [string[]]$StatusForWait = @('in_progress'),

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet('idle', 'in_progress', 'requires_action', 'failed')]
        [string[]]$StatusForExit = @('idle', 'requires_action', 'failed'),

        [Parameter()]
        [int]$TimeoutSec = 0,

        [Parameter()]
        [ValidateRange(0, 100)]
        [int]$MaxRetryCount = 0,

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
        [System.Collections.IDictionary]$AdditionalQuery,

        [Parameter()]
        [System.Collections.IDictionary]$AdditionalHeaders,

        [Parameter()]
        [object]$AdditionalBody
    )

    begin {
        $InnerStatusForWait = [System.Collections.Generic.HashSet[string]]::new($StatusForWait)
        $InnerStatusForWait.ExceptWith([System.Collections.Generic.List[string]]$StatusForExit)

        $CommonParams = ParseCommonParams $PSBoundParameters
    }

    process {
        if ($PSCmdlet.ParameterSetName -eq 'Session') {
            $SessionId = $Session.id
        }
        if ([string]::IsNullOrWhiteSpace($SessionId)) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve the agent session id.'))
            return
        }

        $Cancellation = [System.Threading.CancellationTokenSource]::new()
        if ($TimeoutSec -gt 0) {
            $Cancellation.CancelAfter([timespan]::FromSeconds($TimeoutSec))
        }

        try {
            [uint32]$PollCounter = 0
            [uint32]$PollIntervalMilliSec = $PollIntervalSec * 1000
            [uint32]$InitialPollIntervalMilliSec = $PollIntervalMilliSec / 3
            $ProgressTitle = 'Waiting for agent session...'

            do {
                $WaitMilliSec = [System.Math]::Min(
                    ($InitialPollIntervalMilliSec * ($PollCounter++)),
                    $PollIntervalMilliSec
                )
                Start-CancelableWait `
                    -Milliseconds $WaitMilliSec `
                    -CancellationToken $Cancellation.Token `
                    -ErrorAction Stop

                $CurrentSession = PSOpenAI\Get-AgentSession `
                    -SessionId $SessionId `
                    @CommonParams

                Write-Progress `
                    -Activity $ProgressTitle `
                    -Status ('Session "{0}" is "{1}".' -f $CurrentSession.id, $CurrentSession.status) `
                    -PercentComplete -1
            } while ($CurrentSession.status -and $CurrentSession.status -in $InnerStatusForWait)
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

        if (-not $CurrentSession.status) {
            Write-Error 'Could not retrieve the status of the agent session.'
            return
        }
        if ($CurrentSession.status -notin $StatusForExit) {
            Write-Error ('Agent session "{0}" reached unexpected status "{1}".' -f `
                    $CurrentSession.id, $CurrentSession.status)
            return
        }

        Write-Verbose ('Agent session "{0}" reached status "{1}".' -f $CurrentSession.id, $CurrentSession.status)
        Write-Output $CurrentSession
    }

    end {

    }
}
