function Wait-VectorStoreFileBatch {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(ParameterSetName = 'VectorStore', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('InputObject')]  # for backward compatibility
        [PSTypeName('PSOpenAI.VectorStore')]$VectorStore,

        [Parameter(ParameterSetName = 'VectorStoreId', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('vector_store_id')]
        [string][UrlEncodeTransformation()]$VectorStoreId,

        [Parameter(ParameterSetName = 'VectorStore', Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'VectorStoreId', Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('batch_id')]
        [string][UrlEncodeTransformation()]$BatchId,

        [Parameter(ParameterSetName = 'VectorStoreFileBatch', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [PSTypeName('PSOpenAI.VectorStore.FileBatch')]$Batch,

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
            'in_progress',
            'completed',
            'failed',
            'cancelling',
            'cancelled'
        )]
        [string[]]$StatusForWait = @('in_progress'),

        [Parameter()]
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
        $innerStatusForWait = [System.Collections.Generic.HashSet[string]]::new($StatusForWait)
        if ($PSBoundParameters.ContainsKey('StatusForExit')) {
            $innerStatusForWait.ExceptWith([System.Collections.Generic.List[string]]$StatusForExit)
        }

        # Parse Common params
        $CommonParams = ParseCommonParams $PSBoundParameters
    }

    process {
        # Get ids
        if ($PSCmdlet.ParameterSetName -ceq 'VectorStore') {
            $VectorStoreId = $VectorStore.id
        }
        elseif ($PSCmdlet.ParameterSetName -ceq 'VectorStoreFileBatch') {
            $VectorStoreId = $Batch.vector_store_id
            $BatchId = $Batch.id
        }

        if (-not $VectorStoreId) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve vector store id.'))
            return
        }
        if (-not $BatchId) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve batch id.'))
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
                $innerBatchObject = $null
                $WaitMilliSec = [System.Math]::Min(($InitialPollIntervalMilliSec * ($PollCounter++)), $PollIntervalMilliSec)
                Start-CancelableWait -Milliseconds $WaitMilliSec -CancellationToken $Cancellation.Token -ea Stop
                $innerBatchObject = PSOpenAI\Get-VectorStoreFileBatch -VectorStoreId $VectorStoreId -BatchId $BatchId @CommonParams
                Write-Progress -Activity $ProgressTitle -Status ('The status of batch with id "{0}" is "{1}"' -f $innerBatchObject.id, $innerBatchObject.status) -PercentComplete -1
            } while ($innerBatchObject.status -and $innerBatchObject.status -in $innerStatusForWait)
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
