function Start-Batch {
    [CmdletBinding(DefaultParameterSetName = 'BatchObject')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(ParameterSetName = 'File', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [PSTypeName('PSOpenAI.File')]$File,

        [Parameter(ParameterSetName = 'FileId', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('input_file_id')]
        [string]$FileId,

        [Parameter(ParameterSetName = 'BatchObject', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('InputObject')]  # for backword compatibility
        [PSTypeName('PSOpenAI.Batch.Input')]$BatchInput,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Completions(
            '/v1/chat/completions',
            '/v1/embeddings',
            '/v1/completions'
        )]
        [string][LowerCaseTransformation()]$Endpoint = '/v1/chat/completions',

        [Parameter()]
        [Alias('completion_window')]
        [string]$CompletionWindow = '24h', #Currently only 24h is supported.

        [Parameter()]
        [System.Collections.IDictionary]$MetaData,

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
        # Initialize API Key
        [securestring]$SecureToken = Initialize-APIKey -ApiKey $ApiKey -ErrorAction Stop

        # Initialize API Base
        $ApiBase = Initialize-APIBase -ApiBase $ApiBase -ApiType $ApiType -ErrorAction Stop

        # Initialize Organization ID
        $Organization = Initialize-OrganizationID -OrgId $Organization

        # Get API context
        $OpenAIParameter = Get-OpenAIContext -EndpointName 'Batch' -ApiType $ApiType -AuthType $AuthType -ApiBase $ApiBase -ApiVersion $ApiVersion -ErrorAction Stop

        # Parse Common params
        $CommonParams = ParseCommonParams $PSBoundParameters

        $StartTime = [datetime]::Now.ToUniversalTime()
        $BatchBag = [System.Collections.Generic.List[string]]::new()
    }

    process {
        if ($PSCmdlet.ParameterSetName -ceq 'BatchObject') {
            # Set endpoint url
            if ((-not $PSBoundParameters.ContainsKey('Endpoint')) -and $BatchInput[0].url) {
                $Endpoint = $BatchInput[0].url
            }

            foreach ($item in $BatchInput) {
                # Validate input object
                if ($null -eq $item) {
                    continue
                }
                elseif (-not ($item.custom_id -and $item.method -and $item.url)) {
                    Write-Error -Exception ([System.ArgumentException])::new('Invalid batch input.')
                    continue
                }
                try {
                    $jsonl = ConvertTo-Json $item -Compress -Depth 100 -ErrorAction Stop
                }
                catch {
                    Write-Error -Exception ([System.ArgumentException])::new('Could not convert batch input object to JSONL string.')
                    continue
                }

                # Add an object to queue
                $BatchBag.Add($jsonl)
            }
        }
    }

    end {
        if ($PSCmdlet.ParameterSetName -ceq 'BatchObject') {
            if ($BatchBag.Count -eq 0) {
                return
            }
            # Should upload data first
            $bytedata = [System.Text.Encoding]::UTF8.GetBytes($BatchBag -join "`n")
            $filename = ('batch-psopenai_{0}_{1:x4}.jsonl' -f $StartTime.ToString('s'), (Get-Random -Maximum 65535))
            Write-Verbose -Message ('Uploading a batch data to OpenAI. (File name: "{0}")' -f $filename)
            $fileobject = PSOpenAI\Add-OpenAIFile -Content $bytedata -Name $filename -Purpose 'batch' @CommonParams
            Write-Verbose -Message ('Batch data is successfully uploaded. (File ID: "{0}")' -f $fileobject.id)
            $FileId = $fileobject.id
        }
        elseif ($PSCmdlet.ParameterSetName -ceq 'File') {
            if ($File.Count -gt 1) {
                Write-Error -Exception ([System.ArgumentException]::new('Multiple file objects cannot be input.'))
                return
            }
            $FileId = $File.id
        }

        if (-not $FileId) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve input file id.'))
            return
        }

        #region Construct parameters for API request
        $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()
        $PostBody.input_file_id = $FileId
        $PostBody.endpoint = $Endpoint
        $PostBody.completion_window = $CompletionWindow
        if ($PSBoundParameters.ContainsKey('Metadata')) {
            $PostBody.metadata = $Metadata
        }
        #endregion

        #region Send API Request
        $splat = @{
            Method            = $OpenAIParameter.Method
            Uri               = $OpenAIParameter.Uri
            ContentType       = $OpenAIParameter.ContentType
            TimeoutSec        = $TimeoutSec
            MaxRetryCount     = $MaxRetryCount
            ApiKey            = $SecureToken
            AuthType          = $OpenAIParameter.AuthType
            Organization      = $Organization
            Body              = $PostBody
            AdditionalQuery   = $AdditionalQuery
            AdditionalHeaders = $AdditionalHeaders
            AdditionalBody    = $AdditionalBody
        }
        $Response = Invoke-OpenAIAPIRequest @splat

        # error check
        if ($null -eq $Response) {
            return
        }
        #endregion

        #region Parse response object
        try {
            $Response = $Response | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            Write-Error -Exception $_.Exception
        }
        #endregion

        #region Output
        Write-Verbose ('Start batch with id "{0}". The current status is "{1}"' -f $Response.id, $Response.status)
        ParseBatchObject $Response
        #endregion
    }
}
