function Disconnect-OpenAIRealtimeSession {
    [CmdletBinding()]
    param ()

    begin {}
    process {}
    end {
        if ($null -eq $script:WebSocketClient) {
            Write-Warning 'Could not find session.'
        }
        elseif ($script:WebSocketClient.State -ne [System.Net.WebSockets.WebSocketState]::Open) {
            Write-Warning 'Session already closed.'
        }
        else {
            Write-Verbose 'Closing session.'
            try {
                # Close with timeout
                $_cts = [System.Threading.CancellationTokenSource]::new()
                $_cts.CancelAfter([timespan]::FromSeconds(5))
                $closeTask = $script:WebSocketClient.CloseAsync([System.Net.WebSockets.WebSocketCloseStatus]::NormalClosure, '', $_cts.Token)

                # Wait for close
                do {
                    Start-Sleep -Milliseconds 100
                } while (-not $closetask.IsCompleted)
                Write-Verbose 'Session closed.'
                Write-Host 'Session closed.' -ForegroundColor Green
            }
            finally {
                if ($null -ne $_cts) {
                    $_cts.Dispose()
                }
                if ($null -ne $script:WebSocketClient) {
                    $script:WebSocketClient.Dispose()
                    $script:WebSocketClient = $null
                }
            }
        }

        if ($null -ne $script:ReceiveMessageJob) {
            try {
                $script:ReceiveMessageJob.Stop()
                $script:ReceiveMessageJob.Dispose()
                $script:ReceiveMessageJob = $null
            }
            catch {
                Write-Error -Exception $_.Exception
            }
        }
        $global:PSOpenAIRealtimeSessionLock = $false
    }
}
