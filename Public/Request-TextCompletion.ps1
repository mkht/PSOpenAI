function Request-TextCompletion {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Position = 0, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [Alias('Message')]
        [string[]]$Prompt,

        [Parameter()]
        [string]$Suffix,

        [Parameter()]
        [Completions('gpt-3.5-turbo-instruct', 'babbage-002', 'davinci-002')]
        [string]$Model = 'gpt-3.5-turbo-instruct',

        [Parameter()]
        [ValidateRange(0.0, 2.0)]
        [double]$Temperature,

        [Parameter()]
        [ValidateRange(0.0, 1.0)]
        [Alias('top_p')]
        [double]$TopP,

        [Parameter()]
        [Alias('n')]
        [uint16]$NumberOfAnswers,

        [Parameter()]
        [ValidateCount(1, 4)]
        [Alias('stop')]
        [string[]]$StopSequence,

        [Parameter()]
        [switch]$Stream = $false,

        [Parameter()]
        [Alias('max_tokens')]
        [int]$MaxTokens = 2048,

        [Parameter()]
        [ValidateRange(-2.0, 2.0)]
        [Alias('presence_penalty')]
        [double]$PresencePenalty,

        [Parameter()]
        [ValidateRange(-2.0, 2.0)]
        [Alias('frequency_penalty')]
        [double]$FrequencyPenalty,

        [Parameter()]
        [Alias('logit_bias')]
        [System.Collections.IDictionary]$LogitBias,

        [Parameter()]
        [string]$User,

        [Parameter()]
        [bool]$Echo,

        [Parameter()]
        [Alias('best_of')]
        [uint16]$BestOf,

        [Parameter()]
        [switch]$AsBatch,

        [Parameter()]
        [string]$CustomBatchId,

        [Parameter()]
        [int]$TimeoutSec = 0,

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
        [ValidateRange(0, 100)]
        [int]$MaxRetryCount = 0,

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
        $OpenAIParameter = Get-OpenAIAPIParameter -EndpointName 'Text.Completion' -Parameters $PSBoundParameters -Engine $Model -ErrorAction Stop

        if ($OpenAIParameter.ApiType -eq [OpenAIApiType]::Azure) {
            # Temporal engine name for Azure
            $Engine = 'text-davinci-003'
        }
        else {
            $Engine = $Model
        }
    }

    process {
        # Prompt is required
        if ($null -eq $Prompt -or $Prompt.Count -eq 0) {
            Write-Error -Exception ([System.ArgumentException]::new('"Prompt" property is required.'))
            return
        }

        # When BestOf used with NumberOfAnswers, BestOf must be greater than NumberOfAnswers
        if ($PSBoundParameters.ContainsKey('BestOf') -and $PSBoundParameters.ContainsKey('NumberOfAnswers')) {
            if (-not ($BestOf -gt $NumberOfAnswers)) {
                Write-Error -Exception ([System.ArgumentException]::new('BestOf must be greater than NumberOfAnswers'))
                return
            }
        }

        #region Construct parameters for API request
        $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()
        if ($OpenAIParameter.ApiType -eq [OpenAIApiType]::OpenAI) {
            $PostBody.model = $Model
        }
        if ($PSBoundParameters.ContainsKey('Prompt')) {
            if ($Prompt.Count -eq 1) {
                $PostBody.prompt = [string](@($Prompt)[0])
            }
            else {
                $PostBody.prompt = $Prompt
            }
        }
        if ($PSBoundParameters.ContainsKey('Temperature')) {
            $PostBody.temperature = $Temperature
        }
        if ($PSBoundParameters.ContainsKey('TopP')) {
            $PostBody.top_p = $TopP
        }
        if ($PSBoundParameters.ContainsKey('NumberOfAnswers')) {
            $PostBody.n = $NumberOfAnswers
        }
        if ($PSBoundParameters.ContainsKey('StopSequence')) {
            $PostBody.stop = $StopSequence
        }
        if ($MaxTokens -gt 0) {
            $PostBody.max_tokens = $MaxTokens
        }
        if ($PSBoundParameters.ContainsKey('PresencePenalty')) {
            $PostBody.presence_penalty = $PresencePenalty
        }
        if ($PSBoundParameters.ContainsKey('FrequencyPenalty')) {
            $PostBody.frequency_penalty = $FrequencyPenalty
        }
        if ($PSBoundParameters.ContainsKey('LogitBias')) {
            $PostBody.logit_bias = Convert-LogitBiasDictionary -InputObject $LogitBias -Model $Engine
        }
        if ($PSBoundParameters.ContainsKey('User')) {
            $PostBody.user = $User
        }
        if ($PSBoundParameters.ContainsKey('Echo')) {
            $PostBody.echo = $Echo
        }
        if ($PSBoundParameters.ContainsKey('BestOf')) {
            $PostBody.best_of = $BestOf
        }
        if ($Stream) {
            $PostBody.stream = [bool]$Stream
            # When using the Stream option, limit NumberOfAnswers to 1 to optimize output. (this limit may be relaxed in the future)
            $PostBody.n = 1
        }
        #endregion

        # As Batch
        if ($AsBatch) {
            if ([string]::IsNullOrEmpty($CustomBatchId)) {
                $CustomBatchId = 'request-{0:x4}' -f (Get-Random -Maximum 65535)
            }
            $batchInputObject = [pscustomobject]@{
                'custom_id' = $CustomBatchId
                'method'    = 'POST'
                'url'       = $OpenAIParameter.BatchEndpoint
                'body'      = [pscustomobject]$PostBody
            }
            $batchInputObject.PSObject.TypeNames.Insert(0, 'PSOpenAI.Batch.Input')
            return $batchInputObject
        }

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
        }

        #region Send API Request (Stream)
        if ($Stream) {
            # Stream output
            Invoke-OpenAIAPIRequestSSE @splat |
                Where-Object {
                    -not [string]::IsNullOrEmpty($_)
                } | ForEach-Object {
                    try {
                        $_ | ConvertFrom-Json -ErrorAction Stop
                    }
                    catch {
                        Write-Error -Exception $_.Exception
                    }
                } | Where-Object {
                    $null -ne $_.choices -and $_.choices[0].text -is [string]
                } | ForEach-Object {
                    # Writes content to both the Information stream(6>) and the Standard output stream(1>).
                    $InfoMsg = [System.Management.Automation.HostInformationMessage]::new()
                    $InfoMsg.Message = $_.choices[0].text
                    $InfoMsg.NoNewLine = $true
                    Write-Information $InfoMsg
                    Write-Output $InfoMsg.Message
                }
            return
        }
        #endregion

        #region Send API Request (No Stream)
        else {
            $Response = Invoke-OpenAIAPIRequest @splat

            # error check
            if ($null -eq $Response) {
                return
            }
        }
        #endregion

        #region Parse response object
        try {
            $Response = $Response | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            Write-Error -Exception $_.Exception
        }
        if ($null -ne $Response.choices) {
            $ResponseContent = $Response.choices
        }
        #endregion

        #region Output
        # Add custom type name and properties to output object.
        $Response.PSObject.TypeNames.Insert(0, 'PSOpenAI.Text.Completion')
        if ($unixtime = $Response.created -as [long]) {
            # convert unixtime to [DateTime] for read suitable
            $Response | Add-Member -MemberType NoteProperty -Name 'created' -Value ([System.DateTimeOffset]::FromUnixTimeSeconds($unixtime).LocalDateTime) -Force
        }
        $Response | Add-Member -MemberType NoteProperty -Name 'Prompt' -Value $Prompt
        $Response | Add-Member -MemberType NoteProperty -Name 'Answer' -Value ([string[]]$ResponseContent.text)
        Write-Output $Response
        #endregion
    }

    end {

    }
}
