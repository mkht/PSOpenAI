function Request-ResponseCompaction {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [Alias('input')]
        [Alias('UserMessage')]
        [string]$Message,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Completions('user', 'system', 'developer', 'assistant')]
        [string][LowerCaseTransformation()]$Role = 'user',

        [Parameter(ValueFromPipelineByPropertyName)]
        [Completions(
            'gpt-3.5-turbo',
            'gpt-4',
            'gpt-4o',
            'gpt-4o-mini',
            'gpt-3.5-turbo-16k',
            'gpt-4-turbo',
            'gpt-4.1',
            'gpt-4.1-mini',
            'gpt-4.1-nano',
            'gpt-5',
            'gpt-5-mini',
            'gpt-5-nano',
            'gpt-5-pro',
            'gpt-5-chat-latest',
            'gpt-5-codex',
            'gpt-5.1',
            'gpt-5.1-chat-latest',
            'gpt-5.1-codex',
            'gpt-5.1-codex-mini',
            'gpt-5.1-codex-max',
            'o1',
            'o1-pro',
            'o3',
            'o3-pro',
            'o3-mini',
            'o4-mini',
            'o3-deep-research',
            'o4-mini-deep-research',
            'codex-mini-latest',
            'computer-use-preview'
        )]
        [string]$Model = 'gpt-4o-mini',

        #region System messages
        [Parameter()]
        [AllowEmptyString()]
        [Alias('system')]
        [string[]]$SystemMessage,

        [Parameter()]
        [AllowEmptyString()]
        [string[]]$DeveloperMessage,

        [Parameter()]
        [string]$Instructions,
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
        [Alias('previous_response_id')]
        [string]$PreviousResponseId,

        [Parameter()]
        [switch]$OutputRawResponse,

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

        [Parameter(ValueFromPipelineByPropertyName)]
        [object[]]$History,

        [Parameter()]
        [System.Collections.IDictionary]$AdditionalQuery,

        [Parameter()]
        [System.Collections.IDictionary]$AdditionalHeaders,

        [Parameter()]
        [object]$AdditionalBody
    )

    begin {
        # Get API context
        $OpenAIParameter = Get-OpenAIAPIParameter -EndpointName 'Responses.Compact' -Parameters $PSBoundParameters -Engine $Model -ErrorAction Stop

        ## Set up masking patterns
        $MaskPatterns = [System.Collections.Generic.List[Tuple[regex, string]]]::new()
    }

    process {
        #region Construct parameters for API request
        $Response = $null
        $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()

        # Specify model
        $PostBody.model = $Model

        if ($PreviousResponseId) {
            $PostBody.previous_response_id = $PreviousResponseId
        }

        if ($PSBoundParameters.ContainsKey('Instructions')) {
            $PostBody.instructions = $Instructions
        }

        #region Construct messages
        $Messages = [System.Collections.Generic.List[object]]::new()
        # Append past conversations
        foreach ($pastmsg in $History) {
            $Messages.Add($pastmsg)
        }

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
        #endregion

        # Error if message is empty.
        if ($Messages.Count -eq 0) {
            Write-Error 'No message is specified. You must specify one or more messages.'
            return
        }

        $PostBody.input = $Messages.ToArray()
        #endregion

        $splat = @{
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
            MaskPatterns      = $MaskPatterns
        }

        #region Send API Request (No Stream)
        $Response = Invoke-OpenAIAPIRequest @splat

        # error check
        if ($null -eq $Response) {
            return
        }
        # Parse response object
        if ($OutputRawResponse) {
            Write-Output $Response
            return
        }
        try {
            $Response = $Response | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            Write-Error -Exception $_.Exception
            return
        }
        #endregion

        #region For history, set model responses to messages list.
        if ($Response.output.Count -ge 1) {
            $Messages.Clear()
            $Messages.AddRange(@($Response.output))
        }
        #endregion

        #region Output
        ParseResponseCompactionObject $Response -Messages $Messages
        #endregion
    }

    end {

    }
}