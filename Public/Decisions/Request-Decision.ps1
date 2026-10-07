function Request-Decision {
    [CmdletBinding(DefaultParameterSetName = 'Message')]
    [OutputType([pscustomobject])]
    param (
        [Parameter(ParameterSetName = 'Message', Position = 0, ValueFromPipeline)]
        [ValidateNotNullOrEmpty()]
        [Alias('Input', 'Text')]
        [string]$Message,

        [Parameter(Mandatory, ParameterSetName = 'InputMessages')]
        [ValidateNotNullOrEmpty()]
        [object[]]$InputMessages,

        [Parameter(ParameterSetName = 'Message')]
        [ValidateCount(1, 128)]
        [ValidateNotNullOrEmpty()]
        [string[]]$Images,

        [Parameter(ParameterSetName = 'Message')]
        [ValidateSet('auto', 'low', 'high', 'original')]
        [string][LowerCaseTransformation()]$ImageDetail = 'auto',

        [Parameter(Mandatory, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [Alias('Question')]
        [object[]]$Questions,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [Completions('gpt-6-luna')]
        [string]$Model = 'gpt-6-luna',

        [Parameter()]
        [AllowEmptyString()]
        [ValidateLength(0, 128)]
        [Alias('safety_identifier')]
        [string]$SafetyIdentifier,

        [Parameter()]
        [int]$TimeoutSec = 0,

        [Parameter()]
        [ValidateRange(0, 100)]
        [int]$MaxRetryCount = 0,

        [Parameter()]
        [System.Uri]$ApiBase,

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
        $OpenAIParameter = Get-OpenAIAPIParameter -EndpointName 'Decisions' -Parameters $PSBoundParameters -ErrorAction Stop
    }

    process {
        $PostBody = [System.Collections.Specialized.OrderedDictionary]::new()
        $PostBody.model = $Model
        $PostBody.questions = @($Questions)

        if ($PSCmdlet.ParameterSetName -eq 'InputMessages') {
            # Preserve API message/part ordering and caller-supplied fields.
            $PostBody.input = @($InputMessages)
        }
        elseif ($Images.Count -gt 0) {
            $Parts = @()
            if ($PSBoundParameters.ContainsKey('Message')) {
                $Parts += @{ type = 'input_text'; text = $Message }
            }
            foreach ($Image in $Images) {
                if ($Image -match '^data:image/[^;,]+;base64,') {
                    $ImageUrl = $Image
                }
                else {
                    # Decisions accepts inline images only. Missing files and URLs
                    # must fail here rather than being sent as external image URLs.
                    $ImageUrl = Convert-ImageToDataURL -File $Image -ErrorAction Stop
                }
                $Parts += @{ type = 'input_image'; image_url = $ImageUrl; detail = $ImageDetail }
            }
            $PostBody.input = @(@{ role = 'user'; content = $Parts })
        }
        elseif ($PSBoundParameters.ContainsKey('Message')) {
            $PostBody.input = $Message
        }
        else {
            Write-Error -Exception ([System.ArgumentException]::new('Message, Images, or InputMessages is required.'))
            return
        }

        if ($PSBoundParameters.ContainsKey('SafetyIdentifier')) {
            $PostBody.safety_identifier = $SafetyIdentifier
        }

        $params = @{
            Method            = $OpenAIParameter.Method
            Uri               = $OpenAIParameter.Uri
            ContentType       = $OpenAIParameter.ContentType
            TimeoutSec        = $OpenAIParameter.TimeoutSec
            MaxRetryCount     = $OpenAIParameter.MaxRetryCount
            ApiKey            = $OpenAIParameter.ApiKey
            Organization      = $OpenAIParameter.Organization
            Body              = $PostBody
            AdditionalQuery   = $AdditionalQuery
            AdditionalHeaders = $AdditionalHeaders
            AdditionalBody    = $AdditionalBody
        }
        $Response = Invoke-OpenAIHttpRequest @params
        if ($null -eq $Response) {
            return
        }

        try {
            $Response = $Response | ConvertFrom-Json -ErrorAction Stop
        }
        catch {
            Write-Error -Exception $_.Exception
            return
        }

        if ($null -ne $Response) {
            $Response.PSObject.TypeNames.Insert(0, 'PSOpenAI.Decision')
            Write-Output $Response
        }
    }
}
