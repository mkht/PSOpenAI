function Invoke-AgentApiRequest {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)] [string]$EndpointName,
        [Parameter()] [string]$Path,
        [Parameter(Mandatory)] [ValidateSet('Get', 'Post', 'Delete')] [string]$Method,
        [Parameter(Mandatory)] [hashtable]$Parameters,
        [Parameter()] [object]$Body,
        [Parameter()] [System.Collections.IDictionary]$Query,
        [Parameter()] [switch]$All,
        [Parameter()] [switch]$Stream,
        [Parameter()] [switch]$Binary,
        [Parameter()] [string]$OutFile,
        [Parameter()] [string]$TypeName
    )

    if ($Parameters.ContainsKey('ApiType') -and $Parameters.ApiType -eq [OpenAIApiType]::Azure) {
        throw [System.NotSupportedException]::new('The Agents API is currently available only from OpenAI.')
    }

    $OpenAIParameter = Get-OpenAIAPIParameter -EndpointName $EndpointName -Parameters $Parameters -ErrorAction Stop
    $After = if ($null -ne $Query) { $Query.after } else { $null }

    do {
        $UriBuilder = [System.UriBuilder]::new($OpenAIParameter.Uri)
        if (-not [string]::IsNullOrWhiteSpace($Path)) {
            $UriBuilder.Path += '/' + $Path.TrimStart('/')
        }
        $QueryParams = [System.Web.HttpUtility]::ParseQueryString($UriBuilder.Query)
        if ($null -ne $Query) {
            foreach ($Entry in $Query.GetEnumerator()) {
                $Value = if ($Entry.Key -eq 'after') { $After } else { $Entry.Value }
                if ($null -eq $Value -or [string]::IsNullOrWhiteSpace([string]$Value)) { continue }
                foreach ($Item in @($Value)) {
                    $QueryParams.Add([string]$Entry.Key, [string]$Item)
                }
            }
        }
        $UriBuilder.Query = $QueryParams.ToString()

        $Request = @{
            Method            = $Method
            Uri               = $UriBuilder.Uri
            ContentType       = $OpenAIParameter.ContentType
            TimeoutSec        = $OpenAIParameter.TimeoutSec
            MaxRetryCount     = $OpenAIParameter.MaxRetryCount
            ApiKey            = $OpenAIParameter.ApiKey
            AuthType          = $OpenAIParameter.AuthType
            Organization      = $OpenAIParameter.Organization
            Headers           = @{'OpenAI-Beta' = 'agents=v1' }
            AdditionalQuery   = $Parameters.AdditionalQuery
            AdditionalHeaders = $Parameters.AdditionalHeaders
            AdditionalBody    = $Parameters.AdditionalBody
        }
        if ($PSBoundParameters.ContainsKey('Body')) { $Request.Body = $Body }
        if ($OutFile) { $Request.OutFile = $OutFile }

        if ($Stream) {
            Invoke-OpenAIHttpRequest -Stream @Request | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | ForEach-Object {
                try { $_ | ConvertFrom-Json -ErrorAction Stop } catch { Write-Error -Exception $_.Exception }
            }
            return
        }

        $Response = Invoke-OpenAIHttpRequest @Request
        if ($null -eq $Response -or $OutFile) { return }
        if ($Binary) {
            Write-Output -NoEnumerate ([byte[]]$Response)
            return
        }
        if ([string]::IsNullOrWhiteSpace([string]$Response)) { return }
        try { $ResponseObject = $Response | ConvertFrom-Json -ErrorAction Stop } catch { Write-Error -Exception $_.Exception; return }

        $Objects = if ($ResponseObject.object -eq 'list' -and $null -ne $ResponseObject.data) { @($ResponseObject.data) } else { @($ResponseObject) }
        foreach ($Object in $Objects) {
            if ($TypeName) { $Object.psobject.TypeNames.Insert(0, $TypeName) }
            Write-Output $Object
        }

        $HasMore = $All -and [bool]$ResponseObject.has_more -and -not [string]::IsNullOrWhiteSpace([string]$ResponseObject.last_id)
        if ($HasMore) { $After = $ResponseObject.last_id }
    } while ($HasMore)
}
