function Get-Assistant {
    [CmdletBinding(DefaultParameterSetName = 'List')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(ParameterSetName = 'Get', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('assistant_id')]
        [Alias('Assistant')]
        [ValidateScript({ [bool](Get-AssistantIdFromInputObject $_) })]
        [Object]$InputObject,

        [Parameter(ParameterSetName = 'List')]
        [ValidateRange(1, 100)]
        [int]$Limit = 20,

        [Parameter(ParameterSetName = 'ListAll')]
        [switch]$All,

        [Parameter(ParameterSetName = 'ListAll', DontShow)]
        [string]$After,

        [Parameter(ParameterSetName = 'ListAll', DontShow)]
        [string]$Before,

        [Parameter(ParameterSetName = 'List')]
        [Parameter(ParameterSetName = 'ListAll')]
        [ValidateSet('asc', 'desc')]
        [string][LowerCaseTransformation()]$Order = 'asc',

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
        [securestring]$SecureToken = Initialize-APIKey -ApiKey $ApiKey

        # Initialize API Base
        $ApiBase = Initialize-APIBase -ApiBase $ApiBase -ApiType $ApiType

        # Initialize Organization ID
        $Organization = Initialize-OrganizationID -OrgId $Organization

                # Get API context
        $OpenAIParameter = Get-OpenAIContext -EndpointName 'Assistants' -ApiType $ApiType -AuthType $AuthType -ApiBase $ApiBase -ApiVersion $ApiVersion
    }

    process {
        # Get assistant_id
        if ($null -ne $InputObject) {
            $AssistantId = Get-AssistantIdFromInputObject $InputObject
        }

        $UriBuilder = [System.UriBuilder]::new($OpenAIParameter.Uri)
        if ($AssistantId) {
            $UriBuilder.Path += "/$AssistantId"
            $QueryUri = $UriBuilder.Uri
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'List') {
            $QueryParam = [System.Web.HttpUtility]::ParseQueryString($UriBuilder.Query)
            $QueryParam.Add('limit', $Limit);
            $QueryParam.Add('order', $Order);
            $UriBuilder.Query = $QueryParam.ToString()
            $QueryUri = $UriBuilder.Uri
        }
        else {
            $QueryParam = [System.Web.HttpUtility]::ParseQueryString($UriBuilder.Query)
            $QueryParam.Add('limit', '100');
            $QueryParam.Add('order', $Order);
            if ($After) {
                $QueryParam.Add('after', $After);
            }
            if ($Before) {
                $QueryParam.Add('before', $Before);
            }
            $UriBuilder.Query = $QueryParam.ToString()
            $QueryUri = $UriBuilder.Uri
        }

        #region Send API Request
        $params = @{
            Method            = 'Get'
            Uri               = $QueryUri
            ContentType       = $OpenAIParameter.ContentType
            TimeoutSec        = $TimeoutSec
            MaxRetryCount     = $MaxRetryCount
            ApiKey            = $SecureToken
            AuthType          = $OpenAIParameter.AuthType
            Organization      = $Organization
            Headers           = @{'OpenAI-Beta' = 'assistants=v1' }
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
            $res.PSObject.TypeNames.Insert(0, 'PSOpenAI.Assistant')
            if ($null -ne $res.created_at -and ($unixtime = $res.created_at -as [long])) {
                # convert unixtime to [DateTime] for read suitable
                $res | Add-Member -MemberType NoteProperty -Name 'created_at' -Value ([System.DateTimeOffset]::FromUnixTimeSeconds($unixtime).LocalDateTime) -Force
            }
            Write-Output $res
        }
        #endregion

        #region Pagenation
        if ($Response.has_more) {
            if ($PSCmdlet.ParameterSetName -eq 'ListAll') {
                # pagenate
                $PagenationParam = $PSBoundParameters
                $PagenationParam.After = $Response.last_id
                PSOpenAI\Get-Assistant @PagenationParam
            }
            else {
                Write-Warning 'There is more data that has not been retrieved.'
            }
        }
        #endregion
    }

    end {

    }
}
