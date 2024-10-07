function Send-OpenAIRealtimeSessionMessage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [ValidateNotNull()]
        [string]$Message  # JSON string
    )

    begin {}

    process {
        if ($null -eq $script:WebSocketClient) {
            Write-Error 'No valid session found, please run Connect-OpenAIRealtimeSession to initiate connection.'
            return
        }
        elseif ($script:WebSocketClient.State -ne [System.Net.WebSockets.WebSocketState]::Open) {
            Write-Error 'Session already closed.'
            return
        }

        # Send message
        $_ct = [Threading.CancellationToken]::new($false)
        [ArraySegment[byte]]$messageBytes = [System.Text.Encoding]::UTF8.GetBytes($Message)
        $null = $script:WebSocketClient.SendAsync(
            $messageBytes,
            [System.Net.WebSockets.WebSocketMessageType]::Text,
            $true,
            $_ct
        ).GetAwaiter().GetResult()

        # Fire custom event
        $null = $Host.RunSpace.Events.GenerateEvent(
            'PSOpenAI.Realtime.SendMessage',
            'PSOpenAI',
            @($Message),
            $null
        )
    }

    end {
    }
}