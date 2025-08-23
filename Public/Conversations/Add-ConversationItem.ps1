function Add-ConversationItem {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory, ValueFromPipeline, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [Alias('Conversation')]
        [Alias('conversation_id')]
        [string][UrlEncodeTransformation()]$ConversationId,

        [Parameter(Position = 0, ValueFromPipelineByPropertyName)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Completions('user', 'system', 'developer', 'assistant')]
        [string][LowerCaseTransformation()]$Role = 'user',

        #region System messages
        [Parameter()]
        [AllowEmptyString()]
        [Alias('system')]
        [string[]]$SystemMessage,

        [Parameter()]
        [AllowEmptyString()]
        [string[]]$DeveloperMessage,
        #endregion System messages

        #region Image input
        [Parameter()]
        [string[]]$Images,

        [Parameter()]
        [ValidateSet('auto', 'low', 'high')]
        [string][LowerCaseTransformation()]$ImageDetail = 'auto',
        #endregion Image input

        #region File input
        [Parameter()]
        [string[]]$Files,
        #endregion File input

        [Parameter()]
        [Completions(
            'code_interpreter_call.outputs',
            'computer_call_output.output.image_url',
            'file_search_call.results',
            'message.input_image.image_url',
            'message.output_text.logprobs',
            'reasoning.encrypted_content'
        )]
        [AllowEmptyCollection()]
        [string[]]$Include,

        [Parameter()]
        [switch]$PassThru,

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
        $OpenAIParameter = Get-OpenAIAPIParameter -EndpointName 'Conversations' -Parameters $PSBoundParameters -ErrorAction Stop

        # Parse Common params
        $CommonParams = ParseCommonParams $PSBoundParameters
    }

    process {
        #region Construct Query URI
        $UriBuilder = [System.UriBuilder]::new($OpenAIParameter.Uri)
        $UriBuilder.Path += "/$ConversationId/items"
        $QueryParam = [System.Web.HttpUtility]::ParseQueryString($UriBuilder.Query)
        if ($PSBoundParameters.ContainsKey('Include')) {
            foreach ($IncludeItem in $Include) {
                $QueryParam.Add('include[]', $IncludeItem)
            }
        }
        $UriBuilder.Query = $QueryParam.ToString()
        $QueryUri = $UriBuilder.Uri
        #endregion


        #region Construct messages
        $Messages = [System.Collections.Generic.List[object]]::new()

        # Specifies system messages (only if specified)
        $sysmsg = [pscustomobject]@{
            type    = 'message'
            role    = 'system'
            content = @()
        }
        foreach ($_msg in $SystemMessage) {
            if (-not [string]::IsNullOrWhiteSpace($_msg)) {
                $sysmsg.content += [pscustomobject]@{type = 'input_text'; text = $_msg }
            }
        }
        if ($sysmsg.content.Count -ge 1) {
            $Messages.Add($sysmsg)
        }

        # Specifies developer messages (only if specified)
        $devmsg = [pscustomobject]@{
            type    = 'message'
            role    = 'developer'
            content = @()
        }
        foreach ($_msg in $DeveloperMessage) {
            if (-not [string]::IsNullOrWhiteSpace($_msg)) {
                $devmsg.content += [pscustomobject]@{type = 'input_text'; text = $_msg }
            }
        }
        if ($devmsg.content.Count -ge 1) {
            $Messages.Add($devmsg)
        }

        #region Add user messages
        $usermsg = [pscustomobject]@{
            type    = 'message'
            role    = 'user'
            content = @()
        }

        # Text message
        if (-not [string]::IsNullOrWhiteSpace($Message)) {
            $usermsg.content += [pscustomobject]@{type = 'input_text'; text = $Message }
        }

        # File input
        if ($PSBoundParameters.ContainsKey('Files')) {
            foreach ($file in $Files) {
                if ([string]::IsNullOrWhiteSpace($file)) { continue }
                $fileContent = $null

                if (Test-Path -LiteralPath $file -PathType Leaf) {
                    # local file
                    $fileItem = Get-Item -LiteralPath $file
                    $fileContent = [pscustomobject]@{
                        type      = 'input_file'
                        filename  = $fileItem.Name
                        file_data = (Convert-FileToDataURL $file)
                    }
                }
                elseif ($file -match '^http[s]?://') {
                    # URL
                    $fileContent = [pscustomobject]@{
                        type     = 'input_file'
                        file_url = $file
                    }
                }
                elseif ($file -match '[\\/]') {
                    # Invalid file path
                    continue
                }
                else {
                    # file id
                    $fileContent = [pscustomobject]@{
                        type    = 'input_file'
                        file_id = $file
                    }
                }
                $usermsg.content += $fileContent
            }
        }

        # Image input
        if ($PSBoundParameters.ContainsKey('Images')) {
            foreach ($image in $Images) {
                if ([string]::IsNullOrWhiteSpace($image)) { continue }
                $imageContent = $null

                if (Test-Path -LiteralPath $image -PathType Leaf) {
                    # local file
                    $imageContent = [pscustomobject]@{
                        type      = 'input_image'
                        image_url = (Convert-ImageToDataURL $image)
                        detail    = $ImageDetail
                    }
                }
                elseif ($image -match 'http[s]?://') {
                    # URL
                    $imageContent = [pscustomobject]@{
                        type      = 'input_image'
                        image_url = $image
                        detail    = $ImageDetail
                    }
                }
                else {
                    # file id
                    $imageContent = [pscustomobject]@{
                        type    = 'input_image'
                        file_id = $file
                        detail  = $ImageDetail
                    }
                }

                $usermsg.content += $imageContent
            }
        }

        if ($usermsg.content.Count -ge 1) {
            $Messages.Add($usermsg)
        }

        # Error if message is empty.
        if ($Messages.Count -eq 0) {
            Write-Error 'No message is specified. You must specify one or more messages.'
            return
        }
        #endregion

        #region Construct parameters for API request
        $PostBody = @{
            items = $Messages.ToArray()
        }
        #endregion

        #region Send API Request
        $params = @{
            Method            = $OpenAIParameter.Method
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

        #region Output
        # Output thread object only when the PassThru switch is specified.
        if ($PassThru) {
            PSOpenAI\Get-Conversation -ConversationId $ConversationId @CommonParams
        }
        #endregion
    }

    end {

    }
}
