function Get-ContainerFileContent {
    [CmdletBinding(DefaultParameterSetName = 'Id')]
    [OutputType([byte[]])]
    param (
        [Parameter(ParameterSetName = 'Container', Mandatory, Position = 0, ValueFromPipeline)]
        [PSTypeName('PSOpenAI.Container')]$Container,

        [Parameter(ParameterSetName = 'Id', Mandatory, Position = 0, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('container_id')]
        [string][UrlEncodeTransformation()]$ContainerId,

        [Parameter(ParameterSetName = 'Container', Mandatory, Position = 1)]
        [Parameter(ParameterSetName = 'Id', Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('file_id')]
        [string][UrlEncodeTransformation()]$FileId,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$OutFile,

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
        $OpenAIParameter = Get-OpenAIAPIParameter -EndpointName 'Container.Files' -Parameters $PSBoundParameters -ErrorAction Stop
    }

    process {
        # Get ids
        if ($PSCmdlet.ParameterSetName -eq 'Container') {
            $ContainerId = $Container.id
        }
        if (-not $ContainerId) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve container id.'))
            return
        }
        if (-not $FileId) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve file id.'))
            return
        }

        #region Construct Query URI
        $QueryUri = $OpenAIParameter.Uri.ToString() -f $ContainerId
        $UriBuilder = [System.UriBuilder]::new($QueryUri)
        $UriBuilder.Path += "/$FileId/content"
        $QueryUri = $UriBuilder.Uri
        #endregion

        #region Send API Request
        $params = @{
            Method            = 'Get'
            Uri               = $QueryUri
            ContentType       = $OpenAIParameter.ContentType
            TimeoutSec        = $OpenAIParameter.TimeoutSec
            MaxRetryCount     = $OpenAIParameter.MaxRetryCount
            ApiKey            = $OpenAIParameter.ApiKey
            AuthType          = $OpenAIParameter.AuthType
            Organization      = $OpenAIParameter.Organization
            AdditionalQuery   = $AdditionalQuery
            AdditionalHeaders = $AdditionalHeaders
            AdditionalBody    = $AdditionalBody
        }
        $Response = Invoke-OpenAIAPIRequest @params

        # error check
        if ($null -eq $Response) {
            return
        }
        #endregion

        #region Output
        if ($OutFile) {
            Write-ByteContent -OutFile $OutFile -Bytes ([byte[]]$Response)
        }
        else {
            Write-Output $Response
        }
        #endregion
    }

    end {

    }
}
