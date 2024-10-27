function Stop-RealtimeSessionResponse {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]$EventId
    )

    begin {
        $MessageObject = @{type = 'response.cancel' }
    }

    process {
        PSOpenAI\Send-RealtimeSessionEvent -Message ($MessageObject | ConvertTo-Json -Depth 10)
    }

    end {
    }
}