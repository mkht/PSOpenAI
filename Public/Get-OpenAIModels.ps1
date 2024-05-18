function Get-OpenAIModels {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Position = 0, ValueFromPipeline)]
        [Alias('ID')]
        [Alias('Model')]
        [string][LowerCaseTransformation()]$Name,

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
        $OpenAIParameter = Get-OpenAIAPIParameter -EndpointName 'Models' -Parameters $PSBoundParameters -ErrorAction Stop
    }

    process {
        if ($Name) {
            $UriBuilder = [System.UriBuilder]::new($OpenAIParameter.Uri)
            $UriBuilder.Path = $UriBuilder.Path.TrimEnd('/') + "/$Name"
            $OpenAIParameter.Uri = $UriBuilder.Uri
        }

        #region Send API Request
        $splat = @{
            Method            = $OpenAIParameter.Method
            Uri               = $OpenAIParameter.Uri
            ApiKey            = $OpenAIParameter.ApiKey
            AuthType          = $OpenAIParameter.AuthType
            Organization      = $OpenAIParameter.Organization
            TimeoutSec        = $OpenAIParameter.TimeoutSec
            MaxRetryCount     = $OpenAIParameter.MaxRetryCount
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
        $Response = try { ($Response | ConvertFrom-Json -ErrorAction Ignore) }catch { Write-Error -Exception $_.Exception }
        if ($Response.object -eq 'list') {
            $Models = @($Response.data)
        }
        else {
            $Models = @($Response)
        }
        #endregion

        #region Output
        foreach ($m in $Models) {
            if ($null -eq $m) { continue }
            # Add custom type name and properties to output object.
            if ($OpenAIParameter.ApiType -eq [OpenAIApiType]::OpenAI) {
                $m.PSObject.TypeNames.Insert(0, 'PSOpenAI.Model')
            }
            if ($unixtime = $m.created -as [long]) {
                # convert unixtime to [DateTime] for read suitable
                $m | Add-Member -MemberType NoteProperty -Name 'created' -Value ([System.DateTimeOffset]::FromUnixTimeSeconds($unixtime).LocalDateTime) -Force
            }
            if ($unixtime = $m.created_at -as [long]) {
                # convert unixtime to [DateTime] for read suitable
                $m | Add-Member -MemberType NoteProperty -Name 'created_at' -Value ([System.DateTimeOffset]::FromUnixTimeSeconds($unixtime).LocalDateTime) -Force
            }
            if ($unixtime = $m.updated_at -as [long]) {
                # convert unixtime to [DateTime] for read suitable
                $m | Add-Member -MemberType NoteProperty -Name 'updated_at' -Value ([System.DateTimeOffset]::FromUnixTimeSeconds($unixtime).LocalDateTime) -Force
            }
            Write-Output $m
        }
        #endregion
    }

    end {

    }
}
