function Stop-OpenAIRealtimeSessionResponse {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$EventId
    )

    begin {
        $MessageObject = @{type = 'response.cancel' }
    }

    process {
        PSOpenAI\Send-OpenAIRealtimeSessionMessage -Message ($MessageObject | ConvertTo-Json -Depth 10)
    }

    end {
    }
}