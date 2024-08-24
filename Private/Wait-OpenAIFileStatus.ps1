function Wait-OpenAIFileStatus {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(ParameterSetName = 'Id', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('file_id')]
        [string][UrlEncodeTransformation()]$FileId,

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
            'uploaded',
            'pending',
            'running',
            'processed',
            'error',
            'deleting',
            'deleted'
        )]
        [string[]]$StatusForWait = @('pending', 'running', 'deleting'),

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [ValidateSet(
            'uploaded',
            'pending',
            'running',
            'processed',
            'error',
            'deleting',
            'deleted'
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
        if (-not $FileId) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve file id.'))
            return
        }

        # Create cancellation token for timeout
        $Cancellation = [System.Threading.CancellationTokenSource]::new()
        if ($TimeoutSec -gt 0) {
            $Cancellation.CancelAfter([timespan]::FromSeconds($TimeoutSec))
        }

        try {
            [uint32]$PollCounter = 0
            [uint32]$PollIntervalMilliSec = $PollIntervalSec * 1000
            [uint32]$InitialPollIntervalMilliSec = $PollIntervalMilliSec / 3
            $ProgressTitle = 'Waiting for completion...'
            do {
                #Wait
                $innerFileObject = $null
                $WaitMilliSec = [System.Math]::Min(($InitialPollIntervalMilliSec * ($PollCounter++)), $PollIntervalMilliSec)
                Start-CancelableWait -Milliseconds $WaitMilliSec -CancellationToken $Cancellation.Token -ea Stop
                $innerFileObject = PSOpenAI\Get-OpenAIFile -FileId $FileId @CommonParams
                Write-Progress -Activity $ProgressTitle -Status ('The status of file with id "{0}" is "{1}"' -f $innerFileObject.id, $innerFileObject.status) -PercentComplete -1
            } while ($innerFileObject.status -and $innerFileObject.status -in $innerStatusForWait)
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

        if (-not $innerFileObject.status) {
            Write-Error 'Could not retrieve the status of file.'
        }

        #Finished
        Write-Verbose ('The status of file with id "{0}" is "{1}"' -f $innerFileObject.id, $innerFileObject.status)
        $innerFileObject
        return
    }

    end {

    }
}
