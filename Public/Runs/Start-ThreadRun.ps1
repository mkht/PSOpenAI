function Start-ThreadRun {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('thread_id')]
        [Alias('Thread')]
        [ValidateScript({
            ($_ -is [string] -and $_.StartsWith('thread_')) -or `
                ($_.id -is [string] -and $_.id.StartsWith('thread_')) -or `
                ($_.thread_id -is [string] -and $_.thread_id.StartsWith('thread_'))
            })]
        [Object]$InputObject,

        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [Alias('assistant_id')]
        [ValidateScript({
            ($_ -is [string] -and $_.StartsWith('asst_')) -or `
                ($_.id -is [string] -and $_.id.StartsWith('asst_')) -or `
                ($_.assistant_id -is [string] -and $_.assistant_id.StartsWith('asst_'))
            })]
        [Object]$Assistant,

        [Parameter()]
        [Completions(
            'gpt-3.5-turbo',
            'gpt-4',
            'gpt-3.5-turbo-16k',
            'gpt-3.5-turbo-0613',
            'gpt-3.5-turbo-16k-0613',
            'gpt-3.5-turbo-1106',
            'gpt-4-0613',
            'gpt-4-32k',
            'gpt-4-32k-0613',
            'gpt-4-1106-preview',
            'gpt-4-vision-preview'
        )]
        [string][LowerCaseTransformation()]$Model = 'gpt-3.5-turbo',

        [Parameter()]
        [ValidateLength(0, 32768)]
        [string]$Instructions,

        [Parameter()]
        [AllowEmptyCollection()]
        [System.Collections.IDictionary[]]$Tools,

        [Parameter()]
        [bool]$UseCodeInterpreter = $false,

        [Parameter()]
        [bool]$UseRetrieval = $false,

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
            $OpenAIParameter = Get-AzureOpenAIAPIEndpoint -EndpointName 'Runs' -Engine $Model -ApiBase $ApiBase -ApiVersion $ApiVersion
        }
        else {
            $OpenAIParameter = Get-OpenAIAPIEndpoint -EndpointName 'Runs' -ApiBase $ApiBase
        }

        # Parse Common params
        $CommonParams = ParseCommonParams $PSBoundParameters
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
        $QueryUri = ($OpenAIParameter.Uri.ToString() -f $ThreadID)

        #region Construct parameters for API request
        $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()

        # Get assistant_id
        $AssistantId = ''
        if ($Assistant -is [string]) {
            $AssistantId = $Assistant
        }
        elseif ($Assistant.id -is [string] -and $Assistant.id.StartsWith('asst_')) {
            $AssistantId = $Assistant.id
        }
        elseif ($Assistant.assistant_id -is [string] -and $Assistant.assistant_id.StartsWith('asst_')) {
            $AssistantId = $Assistant.assistant_id
        }

        if (-not $AssistantId) {
            Write-Error -Exception ([System.ArgumentException]::new('Could not retrieve Assistant ID.'))
            return
        }

        if ($UseCodeInterpreter) {
            $Tools += @{'type' = 'code_interpreter' }
        }
        if ($UseRetrieval) {
            $Tools += @{'type' = 'retrieval' }
        }

        $PostBody.assistant_id = $AssistantId
        if ($PSBoundParameters.ContainsKey('Model')) {
            $PostBody.model = $Model
        }
        if ($PSBoundParameters.ContainsKey('Instructions')) {
            $PostBody.instructions = $Instructions
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
            -Body $PostBody

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
        Write-Verbose ('Start thread run with id "{0}". The current status is "{1}"' -f $Response.id, $Response.status)
        ParseThreadRunObject $Response -CommonParams $CommonParams -Primitive
        #endregion
    }

    end {

    }
}
