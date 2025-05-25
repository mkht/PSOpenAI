function Add-ContainerFile {
    [CmdletBinding(DefaultParameterSetName = 'ContainerId_FileId')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(ParameterSetName = 'Container_FileId', Mandatory, Position = 0, ValueFromPipeline)]
        [Parameter(ParameterSetName = 'Container_File', Mandatory, Position = 0, ValueFromPipeline)]
        [PSTypeName('PSOpenAI.Container')]$Container,

        [Parameter(ParameterSetName = 'ContainerId_FileId', Mandatory, Position = 0)]
        [Parameter(ParameterSetName = 'ContainerId_File', Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [Alias('container_id')]
        [string][UrlEncodeTransformation()]$ContainerId,

        [Parameter(ParameterSetName = 'Container_FileId', Mandatory, Position = 1)]
        [Parameter(ParameterSetName = 'ContainerId_FileId', Mandatory, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string][UrlEncodeTransformation()]$FileId,

        [Parameter(ParameterSetName = 'Container_File', Mandatory, Position = 1, ValueFromPipeline)]
        [Parameter(ParameterSetName = 'ContainerId_File', Mandatory, Position = 1, ValueFromPipeline)]
        [string]$File,

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
        if ($PSCmdlet.ParameterSetName -like 'Container_*') {
            $ContainerId = $Container.id
        }
        if (-not $ContainerId) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve container id.'))
            return
        }

        #region Construct parameters for API request
        $QueryUri = $OpenAIParameter.Uri.ToString() -f $ContainerId
        $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()

        if ($PSCmdlet.ParameterSetName -like '_FileId') {
            $PostBody.file_id = $FileId
            $OpenAIParameter.ContentType = 'application/json'
        }
        elseif (Test-Path -LiteralPath $File -PathType Leaf) {
            $PostBody.file = Resolve-FileInfo $File
            $OpenAIParameter.ContentType = 'multipart/form-data'
        }
        else {
            $PostBody.file_id = [string]$File
            $OpenAIParameter.ContentType = 'application/json'
        }
        #endregion

        #region Send API Request
        $params = @{
            Method            = 'Post'
            Uri               = $QueryUri
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
        $Response = Invoke-OpenAIAPIRequest @params

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
        ParseContainerFileObject -InputObject $Response
        #endregion
    }

    end {

    }
}
