function Get-BatchOutput {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(ParameterSetName = 'Batch', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('InputObject')]  # for backword compatibility
        [PSTypeName('PSOpenAI.Batch')]$Batch,

        [Parameter(ParameterSetName = 'Id', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('batch_id')]
        [Alias('Id')]   # for backword compatibility
        [string][UrlEncodeTransformation()]$BatchId,

        [Parameter()]
        [switch]$Wait,

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
        # Parse Common params
        $CommonParams = ParseCommonParams $PSBoundParameters
    }

    process {
        # Get batch id
        if ($PSCmdlet.ParameterSetName -ceq 'Batch') {
            $BatchId = $Batch.id
        }
        if (-not $BatchId) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve batch id.'))
            return
        }

        $OutputFileId = $null
        if ($Batch.output_file_id) {
            $OutputFileId = $Batch.output_file_id
        }
        elseif ($Wait -and $Batch.status -ne 'completed') {
            $innerBatchObject = $BatchId | PSOpenAI\Wait-Batch @CommonParams
            $OutputFileId = $innerBatchObject.output_file_id
        }
        else {
            $innerBatchObject = PSOpenAI\Get-Batch -BatchId $BatchId @CommonParams
            $OutputFileId = $innerBatchObject.output_file_id
        }

        if (-not $OutputFileId) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve batch output file id.'))
            return
        }

        #Download batch output content
        $ByteContent = PSOpenAI\Get-OpenAIFileContent -FileId $OutputFileId @CommonParams
        if (-not $ByteContent) {
            return
        }

        # Parse and output
        [System.Text.Encoding]::UTF8.GetString($ByteContent) -split "`n" | Where-Object { $_ } | ForEach-Object {
            $ret = ConvertFrom-Json -InputObject $_
            $ret.PSObject.TypeNames.Insert(0, 'PSOpenAI.Batch.Output')
            if ($ret.response.body.object -eq 'chat.completion') {
                $ret.response.body = ParseChatCompletionObject $ret.response.body
            }
            $ret
        }
    }

    end {}
}
