function Add-RealtimeSessionItem {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$EventId,

        [Parameter()]
        [string]$PreviousItemId,

        [Parameter()]
        [string]$ItemId,

        [Parameter()]
        [ValidateSet(
            'message',
            'function_call',
            'function_call_output'
        )]
        [string]$ItemType = 'message',

        [Parameter()]
        [ValidateSet(
            'completed',
            'in_progress',
            'incomplete'
        )]
        [string]$Status,

        [Parameter()]
        [ValidateSet(
            'user',
            'assistant',
            'system'
        )]
        [string]$Role = 'user',

        [Parameter(Mandatory, Position = 0)]
        [Alias('Text')]
        [Alias('Message')]
        [ValidateNotNullOrEmpty()]
        [string]$Content,

        [Parameter()]
        [ValidateSet(
            'input_text',
            'input_audio',
            'item_reference',
            'text'
        )]
        [ValidateNotNullOrEmpty()]
        [string]$ContentType = 'input_text',

        [Parameter()]
        [string]$ContentTranscript,

        [Parameter()]
        [string]$FunctionCallId,

        [Parameter()]
        [string]$FunctionCallName,

        [Parameter()]
        [string]$FunctionCallArguments,

        [Parameter()]
        [string]$FunctionCallOutput,

        [Parameter()]
        [switch]$TriggerResponse
    )

    begin {
        $MessageObject = @{type = 'conversation.item.create'; item = @{} }
    }

    process {
        if (-not [string]::IsNullOrEmpty($EventId)) {
            $MessageObject.event_id = $EventId
        }
        if ($PSBoundParameters.ContainsKey('PreviousItemId')) {
            $MessageObject.previous_item_id = $PreviousItemId
        }

        $MessageObject.item.type = $ItemType
        if ($PSBoundParameters.ContainsKey('ItemId')) {
            $MessageObject.item.id = $ItemId
        }
        if ($PSBoundParameters.ContainsKey('Status')) {
            $MessageObject.item.status = $Status
        }
        if (-not [string]::IsNullOrEmpty($ContentType)) {
            $MessageObject.item.role = $Role
        }

        $MessageObject.item.content = @(@{type = $ContentType })
        if ($ContentType -in ('input_text', 'text')) {
            $MessageObject.item.content[0].text = $Content
        }
        elseif ($ContentType -eq 'input_audio') {
            $MessageObject.item.content[0].audio = $Content
        }
        elseif ($ContentType -eq 'item_reference') {
            $MessageObject.item.content[0].id = $Content
        }
        if ($PSBoundParameters.ContainsKey('ContentTranscript')) {
            $MessageObject.item.content[0].transcript = $ContentTranscript
        }

        if ($ItemType -eq 'function_call') {
            if ($PSBoundParameters.ContainsKey('FunctionCallId')) {
                $MessageObject.item.call_id = $FunctionCallId
            }
            if ($PSBoundParameters.ContainsKey('FunctionCallName')) {
                $MessageObject.item.name = $FunctionCallName
            }
            if ($PSBoundParameters.ContainsKey('FunctionCallArguments')) {
                $MessageObject.item.arguments = $FunctionCallArguments
            }
        }

        if ($ItemType -eq 'function_call_output') {
            if ($PSBoundParameters.ContainsKey('FunctionCallOutput')) {
                $MessageObject.item.output = $FunctionCallOutput
            }
        }

        PSOpenAI\Send-RealtimeSessionEvent -Message ($MessageObject | ConvertTo-Json -Depth 10)

        if ($TriggerResponse) {
            PSOpenAI\Request-RealtimeSessionResponse
        }
    }

    end {
    }
}