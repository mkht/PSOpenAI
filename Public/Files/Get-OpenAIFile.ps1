function Get-OpenAIFile {
    [CmdletBinding(DefaultParameterSetName = 'List')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(ParameterSetName = 'Get_File', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [PSTypeName('PSOpenAI.File')]$File,

        [Parameter(ParameterSetName = 'Get_Id', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('file_id')]
        [Alias('Id')]   # for backword compatibility
        [string][UrlEncodeTransformation()]$FileId,

        [Parameter(ParameterSetName = 'List', Mandatory = $false)]
        [Completions(
            'assistants',
            'assistants_output',
            'batch',
            'batch_output',
            'fine-tune',
            'fine-tune-results',
            'vision'
        )]
        [ValidateNotNullOrEmpty()]
        [string][UrlEncodeTransformation()]$Purpose,

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
        $OpenAIParameter = Get-OpenAIAPIParameter -EndpointName 'Files' -Parameters $PSBoundParameters -ErrorAction Stop
    }

    process {
        # Get id
        if ($PSCmdlet.ParameterSetName -like '*_File') {
            $FileId = $File.id
            if (-not $FileId) {
                Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve file id.'))
                return
            }
        }

        #region Construct Query URI
        $UriBuilder = [System.UriBuilder]::new($OpenAIParameter.Uri)
        if ($PSCmdlet.ParameterSetName -like 'Get_*') {
            $UriBuilder.Path += "/$FileId"
            $QueryUri = $UriBuilder.Uri
        }
        else {
            if ($PSBoundParameters.ContainsKey('Purpose')) {
                $QueryParam = [System.Web.HttpUtility]::ParseQueryString($UriBuilder.Query)
                $QueryParam.Add('purpose', $Purpose);
                $UriBuilder.Query = $QueryParam.ToString()
                $QueryUri = $UriBuilder.Uri
            }
            else {
                $QueryUri = $OpenAIParameter.Uri
            }
        }
        #endregion

        #region Send API Request
        $params = @{
            Method            = 'Get'
            Uri               = $QueryUri
            ContentType       = $OpenAIParameter.ContentType
            TimeoutSec        = $OpenAIParameter.TimeoutSec
            MaxRetryCount     = $OpenAIParameter.MaxRetryCount
            ApiKey            = $OpenAIParameter.ApiKey
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

        #region Parse response object
        try {
            $Response = $Response | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            Write-Error -Exception $_.Exception
        }
        #endregion

        #region Output
        if ($Response.object -eq 'list' -and ($null -ne $Response.data)) {
            # List of object
            $Responses = @($Response.data)
        }
        else {
            # Single object
            $Responses = @($Response)
        }
        # parse objects
        foreach ($res in $Responses) {
            # Add custom type name and properties to output object.
            $res.PSObject.TypeNames.Insert(0, 'PSOpenAI.File')
            if ($null -ne $res.created_at -and ($unixtime = $res.created_at -as [long])) {
                # convert unixtime to [DateTime] for read suitable
                $res | Add-Member -MemberType NoteProperty -Name 'created_at' -Value ([System.DateTimeOffset]::FromUnixTimeSeconds($unixtime).LocalDateTime) -Force
            }
            Write-Output $res
        }
        #endregion
    }

    end {

    }
}
