function Request-RealtimeSessionResponse {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$EventId,

        [Parameter()]
        [AllowEmptyString()]
        [string]$Instructions,

        [Parameter()]
        [ValidateSet('text', 'audio')]
        [string[]]$Modalities = @('text'),

        [Parameter()]
        [Completions(
            'alloy',
            'ash',
            'ballad',
            'coral',
            'echo',
            'sage',
            'shimmer',
            'verse'
        )]
        [string][LowerCaseTransformation()]$Voice,

        [Parameter()]
        [Completions(
            'pcm16',
            'g711_ulaw',
            'g711_alaw'
        )]
        [string][LowerCaseTransformation()]$OutputAudioFormat,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [System.Collections.IDictionary[]]$Tools,

        [Parameter()]
        [Completions('none', 'auto', 'required')]
        [string]$ToolChoice,

        [Parameter()]
        [ValidateRange(0.6, 1.2)]
        [float]$Temperature,

        [Parameter()]
        [ValidateRange(-1, 4096)]
        [int]$MaxOutputTokens = -1,

        [Parameter()]
        [Completions('auto', 'none')]
        [String]$Conversation,

        [Parameter()]
        [System.Collections.IDictionary]$MetaData,

        <#
          In OpenAI's API, this corresponds to the "Input" parameter name.
          But avoid using the variable name $Input for variable name,
          because it is used as an automatic variable in PowerShell.
        #>
        [Parameter()]
        [AllowEmptyCollection()]
        [Alias('Input')]
        [object[]]$InputObject
    )

    begin {
        $MessageObject = @{type = 'response.create'; response = @{} }
    }

    process {
        if (-not [string]::IsNullOrEmpty($EventId)) {
            $MessageObject.event_id = $EventId
        }
        if ($PSBoundParameters.ContainsKey('Instructions')) {
            $MessageObject.response.instructions = $Instructions
        }
        if ($PSBoundParameters.ContainsKey('Modalities')) {
            $MessageObject.response.modalities = $Modalities
        }
        if ($PSBoundParameters.ContainsKey('Voice')) {
            $MessageObject.response.voice = $Voice
        }
        if ($PSBoundParameters.ContainsKey('OutputAudioFormat')) {
            $MessageObject.response.output_audio_format = $OutputAudioFormat
        }
        if ($PSBoundParameters.ContainsKey('Tools')) {
            $MessageObject.response.tools = $Tools
        }
        if ($PSBoundParameters.ContainsKey('ToolChoice')) {
            $MessageObject.response.tool_choice = $ToolChoice
        }
        if ($PSBoundParameters.ContainsKey('Temperature')) {
            $MessageObject.response.temperature = $Temperature
        }
        if ($PSBoundParameters.ContainsKey('MaxOutputTokens')) {
            if ($MaxOutputTokens -lt 0) {
                $MessageObject.response.max_output_tokens = 'inf'
            }
            else {
                $MessageObject.response.max_output_tokens = $MaxOutputTokens
            }
        }
        if ($PSBoundParameters.ContainsKey('Conversation')) {
            $MessageObject.response.conversation = $Conversation
        }
        if ($PSBoundParameters.ContainsKey('MetaData')) {
            $MessageObject.response.metadata = $MetaData
        }
        if ($PSBoundParameters.ContainsKey('InputObject')) {
            $MessageObject.response.input = $InputObject
        }

        PSOpenAI\Send-RealtimeSessionEvent -Message ($MessageObject | ConvertTo-Json -Depth 10)
    }

    end {
    }
}