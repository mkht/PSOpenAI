function Get-ThreadMessage {
    [CmdletBinding(DefaultParameterSetName = 'List')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('thread_id')]
        [Alias('Thread')]
        [ValidateScript({
            ($_ -is [string]) -or `
                ($_.id -is [string]) -or `
                ($_.thread_id -is [string] -and $_.thread_id.StartsWith('thread_'))
            })]
        [Object]$InputObject,

        [Parameter(ParameterSetName = 'Get', Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('message_id')]
        [ValidateNotNullOrEmpty()]
        [string][UrlEncodeTransformation()]$MessageId,

        [Parameter(ParameterSetName = 'List')]
        [ValidateRange(1, 100)]
        [int]$Limit = 20,

        [Parameter(ParameterSetName = 'ListAll')]
        [switch]$All,

        [Parameter(ParameterSetName = 'ListAll', DontShow = $true)]
        [string]$After,

        [Parameter(ParameterSetName = 'ListAll', DontShow = $true)]
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

        [Parameter(DontShow = $true)]
        [OpenAIApiType]$ApiType = [OpenAIApiType]::OpenAI,

        [Parameter()]
        [System.Uri]$ApiBase,

        [Parameter(DontShow = $true)]
        [string]$ApiVersion,

        [Parameter(DontShow = $true)]
        [string]$AuthType = 'openai',

        [Parameter()]
        [securestring][SecureStringTransformation()]$ApiKey,

        [Parameter()]
        [Alias('OrgId')]
        [string]$Organization
    )

    begin {
        # Initialize API Key
        [securestring]$SecureToken = Initialize-APIKey -ApiKey $ApiKey

        # Initialize API Base
        $ApiBase = Initialize-APIBase -ApiBase $ApiBase -ApiType $ApiType

        # Initialize Organization ID
        $Organization = Initialize-OrganizationID -OrgId $Organization

        # Get API endpoint
        if ($ApiType -eq [OpenAIApiType]::Azure) {
            $OpenAIParameter = Get-AzureOpenAIAPIEndpoint -EndpointName 'Threads' -Engine $Model -ApiBase $ApiBase -ApiVersion $ApiVersion
        }
        else {
            $OpenAIParameter = Get-OpenAIAPIEndpoint -EndpointName 'Threads' -ApiBase $ApiBase
        }
        # Parse Common params
        # $CommonParams = ParseCommonParams $PSBoundParameters
    }

    process {
        # Get thread_id
        [string][UrlEncodeTransformation()]$ThreadID = ''
        if ($InputObject -is [string]) {
            $ThreadID = $InputObject
        }
        elseif ($InputObject.id -is [string] -and $InputObject.id.StartsWith('thread_')) {
            $ThreadID = $InputObject.id
        }
        elseif ($InputObject.thread_id -is [string] -and $InputObject.thread_id.StartsWith('thread_')) {
            $ThreadID = $InputObject.thread_id
        }
        if (-not $ThreadID) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve Thread ID.'))
            return
        }

        # Query run step messages (option)
        if (-not $MessageId -and $InputObject.object -eq 'thread.run.step' -and $InputObject.type -eq 'message_creation') {
            Write-Verbose 'Input is a run step object. Query associated message.'
            $MessageId = $InputObject.step_details.message_creation.message_id
        }

        if ($MessageId) {
            $QueryUri = $OpenAIParameter.Uri.ToString() + "/$ThreadID/messages/$MessageId"
        }
        elseif ($PSCmdlet.ParameterSetName -eq 'List') {
            $QueryUri = $OpenAIParameter.Uri.ToString() + "/$ThreadID/messages?limit=$Limit&order=$Order"
        }
        else {
            $QueryUri = $OpenAIParameter.Uri.ToString() + "/$ThreadID/messages"
            $QueryParam = [System.Web.HttpUtility]::ParseQueryString([string]::Empty)
            $QueryParam.Add('limit', '100');
            $QueryParam.Add('order', $Order);
            if ($After) {
                $QueryParam.Add('after', $After);
            }
            if ($Before) {
                $QueryParam.Add('before', $Before);
            }
            $QueryUri = $QueryUri + '?' + $QueryParam.ToString()
        }

        #region Send API Request
        $Response = Invoke-OpenAIAPIRequest `
            -Method 'Get' `
            -Uri $QueryUri `
            -ContentType $OpenAIParameter.ContentType `
            -TimeoutSec $TimeoutSec `
            -MaxRetryCount $MaxRetryCount `
            -ApiKey $SecureToken `
            -AuthType $AuthType `
            -Organization $Organization `
            -Headers (@{'OpenAI-Beta' = 'assistants=v1' })

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
            $res.PSObject.TypeNames.Insert(0, 'PSOpenAI.Thread.Message')
            if ($null -ne $res.created_at -and ($unixtime = $res.created_at -as [long])) {
                # convert unixtime to [DateTime] for read suitable
                $res | Add-Member -MemberType NoteProperty -Name 'created_at' -Value ([System.DateTimeOffset]::FromUnixTimeSeconds($unixtime).LocalDateTime) -Force
            }
            $res | Add-Member -MemberType ScriptProperty -Name 'SimpleContent' -Value {
                foreach ($c in $this.content) {
                    [PSCustomObject]@{
                        Role    = $this.role
                        Type    = $c.type
                        Content = $(if ($c.type -eq 'text') { $c.text.value }elseif ($c.type -eq 'image_file') { $c.image_file.file_id })
                    }
                }
            } -Force

            Write-Output $res
        }
        #endregion

        #region Pagenation
        if ($Response.has_more) {
            if ($PSCmdlet.ParameterSetName -eq 'ListAll') {
                # pagenate
                $PagenationParam = $PSBoundParameters
                $PagenationParam.After = $Response.last_id
                $null = $PagenationParam.Remove('Id')
                $null = $PagenationParam.Remove('MessageId')
                $null = $PagenationParam.Remove('Limit')
                PSOpenAI\Get-ThreadMessage @PagenationParam
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
