function Wait-Batch {
    [CmdletBinding(DefaultParameterSetName = 'StatusForWait')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [ValidateScript({ [bool](Get-BatchIdFromInputObject $_) })]
        [Alias('Id')]
        [Object]$InputObject,

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

        [Parameter(ParameterSetName = 'StatusForWait')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet(
            'validating',
            'failed',
            'in_progress',
            'finalizing',
            'completed',
            'expired',
            'cancelling',
            'cancelled'
        )]
        [string[]]$StatusForWait = @('validating', 'in_progress', 'finalizing'),

        [Parameter(ParameterSetName = 'StatusForExit')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet(
            'validating',
            'failed',
            'in_progress',
            'finalizing',
            'completed',
            'expired',
            'cancelling',
            'cancelled'
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
                    'validating',
                    'failed',
                    'in_progress',
                    'finalizing',
                    'completed',
                    'expired',
                    'cancelling',
                    'cancelled'
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
        $batchId = Get-BatchIdFromInputObject $InputObject

        # Create cancellation token for timeout
        $Cancellation = [System.Threading.CancellationTokenSource]::new()
        if ($TimeoutSec -gt 0) {
            $Cancellation.CancelAfter([timespan]::FromSeconds($TimeoutSec))
        }

        try {
            $PollCounter = 0
            $ProgressTitle = 'Waiting for completes...'
            do {
                #Wait
                $innerBatchObject = $null
                Start-CancelableWait -Milliseconds ([System.Math]::Min((200 * ($PollCounter++)), 1000)) -CancellationToken $Cancellation.Token -ea Stop
                $innerBatchObject = PSOpenAI\Get-Batch -BatchId $batchId @CommonParams
                Write-Progress -Activity $ProgressTitle -Status ('The status of batch with id "{0}" is "{1}"' -f $innerBatchObject.id, $innerBatchObject.status) -PercentComplete -1
            } while ($innerBatchObject.status -and $innerBatchObject.status -in $innerStatusForWait)
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

        if (-not $innerBatchObject.status) {
            Write-Error 'Could not retrieve the status of batch.'
        }

        #Finished
        Write-Verbose ('The status of batch with id "{0}" is "{1}"' -f $innerBatchObject.id, $innerBatchObject.status)
        $innerBatchObject
        return
    }

    end {

    }
}
