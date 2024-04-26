function Wait-VectorStoreFileBatch {
    [CmdletBinding(DefaultParameterSetName = 'StatusForWait')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [Alias('vector_store_id')]
        [Alias('VectorStore')]
        [ValidateScript({ [bool](Get-VectorStoreIdFromInputObject $_) })]
        [Object]$InputObject,

        [Parameter(Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [Alias('batch_id')]
        [Alias('Id')]
        [string][UrlEncodeTransformation()]$BatchId,

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
            'in_progress',
            'completed',
            'failed',
            'cancelling',
            'cancelled'
        )]
        [string[]]$StatusForWait = @('in_progress'),

        [Parameter(ParameterSetName = 'StatusForExit')]
        [ValidateNotNullOrEmpty()]
        [ValidateSet(
            'in_progress',
            'completed',
            'failed',
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
                    'in_progress',
                    'completed',
                    'failed',
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
        # Create cancellation token for timeout
        $Cancellation = [System.Threading.CancellationTokenSource]::new()
        if ($TimeoutSec -gt 0) {
            $Cancellation.CancelAfter([timespan]::FromSeconds($TimeoutSec))
        }

        try {
            $PollCounter = 0
            $ProgressTitle = 'Waiting for completion...'
            do {
                #Wait
                $innerBatchObject = $null
                Start-CancelableWait -Milliseconds ([System.Math]::Min((200 * ($PollCounter++)), 1000)) -CancellationToken $Cancellation.Token -ea Stop
                $innerBatchObject = PSOpenAI\Get-VectorStoreFileBatch @CommonParams
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
