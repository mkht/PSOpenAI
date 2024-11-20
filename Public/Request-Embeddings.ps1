function Request-Embeddings {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        <#
          In OpenAI's API, this corresponds to the "Input" parameter name.
          But avoid using the variable name $Input for variable name,
          because it is used as an automatic variable in PowerShell.
        #>
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [Alias('Input')]
        [string[]]$Text,

        [Parameter()]
        [Completions('text-embedding-ada-002', 'text-embedding-3-small', 'text-embedding-3-large')]
        [string]$Model = 'text-embedding-ada-002',

        [Parameter()]
        [Alias('encoding_format')]
        [ValidateSet('float', 'base64')]
        [string]$Format = 'float',

        [Parameter()]
        [ValidateRange(1, 2147483647)]
        [int]$Dimensions,

        [Parameter()]
        [string]$User,

        [Parameter()]
        [switch]$AsBatch,

        [Parameter()]
        [string]$CustomBatchId,

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
        # Get API context
        $OpenAIParameter = Get-OpenAIAPIParameter -EndpointName 'Embeddings' -Parameters $PSBoundParameters -Engine $Model -ErrorAction Stop
    }

    process {
        # Text is required
        if ($null -eq $Text -or $Text.Count -eq 0) {
            Write-Error -Exception ([System.ArgumentException]::new('"Text" property is required.'))
            return
        }

        #region Construct parameters for API request
        $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()
        if ($OpenAIParameter.ApiType -eq [OpenAIApiType]::OpenAI) {
            $PostBody.model = $Model
        }
        if ($Text.Count -eq 1) {
            $PostBody.input = [string](@($Text)[0])
        }
        else {
            $PostBody.input = $Text
        }
        if ($PSBoundParameters.ContainsKey('User')) {
            $PostBody.user = $User
        }
        if ($PSBoundParameters.ContainsKey('Format')) {
            $PostBody.encoding_format = $Format
        }
        if ($PSBoundParameters.ContainsKey('Dimensions')) {
            $PostBody.dimensions = $Dimensions
        }
        #endregion

        # As Batch
        if ($AsBatch) {
            if ([string]::IsNullOrEmpty($CustomBatchId)) {
                $CustomBatchId = 'request-{0:x4}' -f (Get-Random -Maximum 65535)
            }
            $batchInputObject = [pscustomobject]@{
                'custom_id' = $CustomBatchId
                'method'    = 'POST'
                'url'       = $OpenAIParameter.BatchEndpoint
                'body'      = [pscustomobject]$PostBody
            }
            $batchInputObject.PSObject.TypeNames.Insert(0, 'PSOpenAI.Batch.Input')
            return $batchInputObject
        }

        #region Send API Request
        $splat = @{
            Method            = $OpenAIParameter.Method
            Uri               = $OpenAIParameter.Uri
            ContentType       = $OpenAIParameter.ContentType
            TimeoutSec        = $OpenAIParameter.TimeoutSec
            MaxRetryCount     = $OpenAIParameter.MaxRetryCount
            ApiKey            = $OpenAIParameter.ApiKey
            AuthType          = $OpenAIParameter.AuthType
            Organization      = $OpenAIParameter.Organization
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
        if ($null -ne $Response) {
            for ($i = 0; $i -lt @($Response.data).Count; $i++) {
                if ($Format -eq 'float') {
                    # Convert [Object[]] to [float[]]
                    @($Response.data)[$i].embedding = [float[]]@($Response.data)[$i].embedding
                }
                # Add custom properties to output object.
                @($Response.data)[$i] | Add-Member -MemberType NoteProperty -Name 'Text' -Value @($Text)[$i]
            }
            Write-Output $Response
        }
        #endregion
    }

    end {

    }
}
