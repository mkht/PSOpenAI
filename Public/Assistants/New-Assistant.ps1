function New-Assistant {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        # Hidden param, for Set-Assistants cmdlet
        [Parameter(DontShow = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Object]$InputObject,

        [Parameter()]
        [ValidateLength(0, 256)]
        [string]$Name,

        [Parameter()]
        [Completions(
            'gpt-3.5-turbo',
            'gpt-4',
            'gpt-3.5-turbo-16k',
            'gpt-3.5-turbo-0613',
            'gpt-3.5-turbo-16k-0613',
            'gpt-3.5-turbo-1106',
            'gpt-3.5-turbo-0125',
            'gpt-4-0613',
            'gpt-4-32k',
            'gpt-4-32k-0613',
            'gpt-4-turbo',
            'gpt-4-turbo-2024-04-09'
        )]
        [string][LowerCaseTransformation()]$Model = 'gpt-3.5-turbo',

        [Parameter()]
        [ValidateLength(0, 512)]
        [string]$Description,

        [Parameter()]
        [ValidateLength(0, 32768)]
        [string]$Instructions,

        [Parameter()]
        [AllowEmptyCollection()]
        [System.Collections.IDictionary[]]$Tools,

        [Parameter()]
        [switch]$UseCodeInterpreter,

        [Parameter()]
        [switch]$UseRetrieval,

        # [Parameter()]
        # [bool]$UseFunction = $false,

        [Parameter()]
        [Alias('file_ids')]
        [ValidateRange(0, 20)]
        [string[]]$FileId,

        [Parameter()]
        [System.Collections.IDictionary]$MetaData,

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

        # Get API endpoint
        if ($ApiType -eq [OpenAIApiType]::Azure) {
            $OpenAIParameter = Get-AzureOpenAIAPIEndpoint -EndpointName 'Assistants' -ApiBase $ApiBase -ApiVersion $ApiVersion
        }
        else {
            $OpenAIParameter = Get-OpenAIAPIEndpoint -EndpointName 'Assistants' -ApiBase $ApiBase
        }
    }

    process {
        #region Get assistant_id
        if ($null -ne $InputObject) {
            $AssistantId = Get-AssistantIdFromInputObject $InputObject
        }
        #endregion

        #region Construct Query URI
        if (-not [string]::IsNullOrEmpty($AssistantId)) {
            $UriBuilder = [System.UriBuilder]::new($OpenAIParameter.Uri)
            $UriBuilder.Path += "/$AssistantId"
            $QueryUri = $UriBuilder.Uri
        }
        else {
            $QueryUri = $OpenAIParameter.Uri
        }
        #endregion

        #region Construct tools object
        if ($UseCodeInterpreter) {
            $Tools += @{'type' = 'code_interpreter' }
        }
        if ($UseRetrieval) {
            $Tools += @{'type' = 'retrieval' }
        }
        #endregion

        #region Construct parameters for API request
        $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()
        if ($PSBoundParameters.ContainsKey('Model')) {
            $PostBody.model = $Model
        }
        if ($PSBoundParameters.ContainsKey('Name')) {
            $PostBody.name = $Name
        }
        if ($PSBoundParameters.ContainsKey('Description')) {
            $PostBody.description = $Description
        }
        if ($PSBoundParameters.ContainsKey('Instructions')) {
            $PostBody.instructions = $Instructions
        }
        if ($PSBoundParameters.ContainsKey('FileId')) {
            $PostBody.file_ids = $FileId
        }
        if ($PSBoundParameters.ContainsKey('Metadata')) {
            $PostBody.metadata = $Metadata
        }
        if (($Tools.Count -gt 0) -or $PSBoundParameters.ContainsKey('Tools')) {
            $PostBody.tools = $Tools
        }
        #endregion

        #region Send API Request
        $Response = Invoke-OpenAIAPIRequest `
            -Method $OpenAIParameter.Method `
            -Uri $QueryUri `
            -ContentType $OpenAIParameter.ContentType `
            -TimeoutSec $TimeoutSec `
            -MaxRetryCount $MaxRetryCount `
            -ApiKey $SecureToken `
            -AuthType $AuthType `
            -Organization $Organization `
            -Headers (@{'OpenAI-Beta' = 'assistants=v1' }) `
            -Body $PostBody `
            -AdditionalQuery $AdditionalQuery -AdditionalHeaders $AdditionalHeaders -AdditionalBody $AdditionalBody

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
        # Add custom type name and properties to output object.
        $Response.PSObject.TypeNames.Insert(0, 'PSOpenAI.Assistant')
        if ($null -ne $Response.created_at -and ($unixtime = $Response.created_at -as [long])) {
            # convert unixtime to [DateTime] for read suitable
            $Response | Add-Member -MemberType NoteProperty -Name 'created_at' -Value ([System.DateTimeOffset]::FromUnixTimeSeconds($unixtime).LocalDateTime) -Force
        }
        Write-Verbose ('The assistant with id "{0}" has been created.' -f $Response.id)
        Write-Output $Response
        #endregion
    }

    end {

    }
}
