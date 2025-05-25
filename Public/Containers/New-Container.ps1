function New-Container {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter()]
        [uint]$ExpiresAfterMinutes,

        [Parameter()]
        [string][LowerCaseTransformation()]$ExpiresAfterAnchor = 'last_active_at',

        [Parameter()]
        [Alias('file_ids')]
        [object[]]$FileId,

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
        $OpenAIParameter = Get-OpenAIAPIParameter -EndpointName 'Containers' -Parameters $PSBoundParameters -ErrorAction Stop
    }

    process {
        #region Construct parameters for API request
        $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()
        $PostBody.name = $Name

        if ($PSBoundParameters.ContainsKey('ExpiresAfterMinutes')) {
            $PostBody.expires_after = @{
                'anchor'  = $ExpiresAfterAnchor
                'minutes' = $ExpiresAfterMinutes
            }
        }

        if ($FileId.Count -gt 0) {
            $list = [System.Collections.Generic.List[string]]::new($FileId.Count)
            foreach ($item in $FileId) {
                if ($item -is [string]) {
                    $list.Add($item)
                }
                elseif ($item.psobject.TypeNames -contains 'PSOpenAI.File') {
                    $list.Add($item.id)
                }
            }
            if ($list.Count -gt 0) {
                $PostBody.file_ids = $list.ToArray()
            }
        }
        #endregion

        #region Send API Request
        $params = @{
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
        $Response = Invoke-OpenAIAPIRequest @params

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
        ParseContainerObject -InputObject $Response
        #endregion
    }

    end {

    }
}
