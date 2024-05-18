function Get-ThreadMessage {
    [CmdletBinding(DefaultParameterSetName = 'List')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(ParameterSetName = 'Get_Thread', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'List_Thread', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Alias('InputObject')]  # for backword compatibility
        [PSTypeName('PSOpenAI.Thread')]$Thread,

        [Parameter(ParameterSetName = 'Get_ThreadId', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'List_ThreadId', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('thread_id')]
        [string][UrlEncodeTransformation()]$ThreadId,

        [Parameter(ParameterSetName = 'Get_Thread', Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [Parameter(ParameterSetName = 'Get_ThreadId', Mandatory, Position = 1, ValueFromPipelineByPropertyName)]
        [Alias('message_id')]
        [ValidateNotNullOrEmpty()]
        [string][UrlEncodeTransformation()]$MessageId,

        [Parameter(ParameterSetName = 'List_Thread')]
        [Parameter(ParameterSetName = 'List_ThreadId')]
        [Alias('run_id')]
        [string]$RunId,

        [Parameter(ParameterSetName = 'List_Run', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [PSTypeName('PSOpenAI.Thread.Run')]$Run,

        [Parameter(ParameterSetName = 'Get_RunStep', Mandatory, Position = 0, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [PSTypeName('PSOpenAI.Thread.Run.Step')]$Step,

        [Parameter(ParameterSetName = 'List_Thread')]
        [Parameter(ParameterSetName = 'List_ThreadId')]
        [Parameter(ParameterSetName = 'List_Run')]
        [ValidateRange(1, 100)]
        [int]$Limit = 20,

        [Parameter(ParameterSetName = 'List_Thread')]
        [Parameter(ParameterSetName = 'List_ThreadId')]
        [Parameter(ParameterSetName = 'List_Run')]
        [switch]$All,

        [Parameter(ParameterSetName = 'List_Thread', DontShow)]
        [Parameter(ParameterSetName = 'List_ThreadId', DontShow)]
        [Parameter(ParameterSetName = 'List_Run', DontShow)]
        [string]$After,

        [Parameter(ParameterSetName = 'List_Thread', DontShow)]
        [Parameter(ParameterSetName = 'List_ThreadId', DontShow)]
        [Parameter(ParameterSetName = 'List_Run', DontShow)]
        [string]$Before,

        [Parameter(ParameterSetName = 'List_Thread')]
        [Parameter(ParameterSetName = 'List_ThreadId')]
        [Parameter(ParameterSetName = 'List_Run')]
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
        # Get API context
        $OpenAIParameter = Get-OpenAIAPIParameter -EndpointName 'Threads' -Parameters $PSBoundParameters -ErrorAction Stop
    }

    process {
        # Get ids
        if ($PSCmdlet.ParameterSetName -like '*_Thread') {
            $ThreadId = $Thread.id
        }
        elseif ($PSCmdlet.ParameterSetName -like '*_Run') {
            $ThreadId = $Run.thread_id
            $RunId = $Run.id
        }
        elseif ($PSCmdlet.ParameterSetName -like '*_RunStep') {
            $ThreadId = $Step.thread_id
            $RunId = $Step.run_id
            $MessageId = $Step.step_details.message_creation.message_id
        }

        if (-not $ThreadId) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve thread id.'))
            return
        }

        $UriBuilder = [System.UriBuilder]::new($OpenAIParameter.Uri)
        $UriBuilder.Path += "/$ThreadID/messages"
        if ($MessageId) {
            $UriBuilder.Path += "/$MessageId"
            $QueryUri = $UriBuilder.Uri
        }
        else {
            $QueryParam = [System.Web.HttpUtility]::ParseQueryString($UriBuilder.Query)
            if ($All) {
                $Limit = 100
            }
            $QueryParam.Add('limit', $Limit);
            $QueryParam.Add('order', $Order);
            if ($RunId) {
                $QueryParam.Add('run_id', $RunId);
            }
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
            TimeoutSec        = $OpenAIParameter.TimeoutSec
            MaxRetryCount     = $OpenAIParameter.MaxRetryCount
            ApiKey            = $OpenAIParameter.ApiKey
            AuthType          = $OpenAIParameter.AuthType
            Organization      = $OpenAIParameter.Organization
            Headers           = @{'OpenAI-Beta' = 'assistants=v2' }
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
                        Content = $(if ($c.type -eq 'text') { $c.text.value }elseif ($c.type -eq 'image_file') { $c.image_file.file_id }elseif ($c.type -eq 'image_url') { $c.image_url.url })
                    }
                }
            } -Force

            Write-Output $res
        }
        #endregion

        #region Pagenation
        if ($Response.has_more) {
            if ($All) {
                # pagenate
                $PagenationParam = $PSBoundParameters
                $PagenationParam.After = $Response.last_id
                $null = $PagenationParam.Remove('MessageId')
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
