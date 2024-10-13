function Remove-RealtimeSessionConversationItem {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$EventId,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ItemId
    )

    begin {
        $MessageObject = @{type = 'conversation.item.delete' }
    }

    process {
        $MessageObject.item_id = $ItemId

        if (-not [string]::IsNullOrEmpty($EventId)) {
            $MessageObject.event_id = $EventId
        }

        PSOpenAI\Send-RealtimeSessionEvent -Message ($MessageObject | ConvertTo-Json -Depth 10)
    }

    end {
    }
}