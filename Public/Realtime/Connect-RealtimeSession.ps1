function Connect-RealtimeSession {
    [CmdletBinding()]
    param (
        [Parameter()]
        [Completions(
            'gpt-realtime'
        )]
        [string]$Model = 'gpt-realtime',

        [Parameter()]
        [OpenAIApiType]$ApiType = [OpenAIApiType]::OpenAI,

        [Parameter()]
        [System.Uri]$ApiBase,

        [Parameter(DontShow)]
        [string]$ApiVersion,

        [Parameter()]
        [ValidateSet('openai', 'azure', 'azure_ad')]
        [string]$AuthType = 'openai',

        [Parameter()]
        [securestring][SecureStringTransformation()]$ApiKey

    )

    begin {
        # Global lock
        # Limit to only 1 session at a time
        if ($global:PSRealtimeSessionLock) {
            Write-Error 'Creating a new session is locked, run Disconnect-RealtimeSession to terminate existing session.'
            return
        }

        # Get API context
        $OpenAIParameter = Get-OpenAIAPIParameter -EndpointName 'Realtime' -Parameters $PSBoundParameters -Engine $Model -ErrorAction Stop

        #region Set variables
        $IsDebug = Test-Debug
        $ServiceName = switch -Wildcard ($OpenAIParameter.AuthType) {
            'openai*' { 'OpenAI' }
            'azure*' { 'Azure OpenAI' }
        }
        #endregion

        #region Construct Query URI
        $UriBuilder = [System.UriBuilder]::new($OpenAIParameter.Uri)
        $QueryParam = [System.Web.HttpUtility]::ParseQueryString($UriBuilder.Query)
        if ($OpenAIParameter.ApiType -eq [OpenAIApiType]::Azure) {
            $QueryParam.Add('deployment', $Model)
        }
        else {
            $QueryParam.Add('model', $Model)
        }
        $UriBuilder.Query = $QueryParam.ToString()
        $SessionUri = $UriBuilder.Uri
        $private:PlainToken = DecryptSecureString $OpenAIParameter.ApiKey
        #endregion

        #region Connect to websocket session
        try {
            # Init websocket client
            $script:WebSocketClient = [System.Net.WebSockets.ClientWebSocket]::new()

            # Set Authorization header
            if ($OpenAIParameter.AuthType -eq 'azure') {
                $WebSocketClient.Options.SetRequestHeader('api-key', $private:PlainToken)
            }
            else {
                $WebSocketClient.Options.SetRequestHeader('Authorization', "Bearer $private:PlainToken")
            }

            # Set debug header
            if ($IsDebug) {
                $WebSocketClient.Options.SetRequestHeaders['OpenAI-Debug'] = 'true'
            }

            # Verbose / Debug / Information output
            $ConnectingMessage = "Connecting to $ServiceName realtime API endpoint : $SessionUri"
            Write-Host $ConnectingMessage -ForegroundColor Green
            Write-Verbose $ConnectingMessage

            # Connect
            $_ct = [System.Threading.CancellationToken]::new($false)
            $null = $WebSocketClient.ConnectAsync($SessionUri, $_ct).GetAwaiter().GetResult()
            if ($WebSocketClient.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
                Write-Host 'Connected.' -ForegroundColor Green
                Write-Verbose 'Connected.'
                $global:PSRealtimeSessionLock = $true
            }
            else {
                Write-Error 'Connection failed.'
                return
            }
        }
        catch {
            try { $WebSocketClient.Dispose() }catch {}
            Write-Error -Exception $_.Exception
        }
        finally {
            $private:PlainToken = $null
        }
        #endregion

        #region Init message receive thread
        $ReceiveMessageJobScript = {
            param($ws, $consolehost)

            $_buffer = [System.Net.WebSockets.WebSocket]::CreateClientBuffer(1024 * 18, 1024)
            $_ct = [System.Threading.CancellationToken]::new($false)
            $receiveResult = $null

            # Start message receive loop
            while ($ws.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
                $jsonResult = ''
                do {
                    $receiveResult = $ws.ReceiveAsync($_buffer, $_ct).GetAwaiter().GetResult()

                    if ($receiveResult.MessageType -eq [System.Net.WebSockets.WebSocketMessageType]::Close) {
                        Write-Verbose 'Received session close request from server.'
                        Write-Verbose ('Status : {0} | Description : {1}' -f $receiveResult.CloseStatus, $receiveResult.CloseStatusDescription)
                        $ws.CloseOutputAsync($receiveResult.CloseStatus, '', $_ct).GetAwaiter().GetResult()
                        # Exit receive loop
                        return
                    }
                    elseif ($receiveResult.MessageType -ne [System.Net.WebSockets.WebSocketMessageType]::Text) {
                        $ex = [System.NotImplementedException]::new('Currently supports only text messages.')
                        Write-Error -Exception $ex
                    }
                    else {
                        $jsonResult += [System.Text.Encoding]::UTF8.GetString($_buffer, 0, $receiveResult.Count)
                    }
                } while (
                    $ws.State -eq [System.Net.WebSockets.WebSocketState]::Open -and (-not $receiveResult.EndOfMessage)
                )

                if (-not [string]::IsNullOrEmpty($jsonResult)) {
                    # Parse object
                    try {
                        $Response = $jsonResult | ConvertFrom-Json -ErrorAction Stop
                    }
                    catch {
                        Write-Error -Exception $_.Exception
                        continue
                    }

                    # Fire custom event
                    $null = $consolehost.RunSpace.Events.GenerateEvent(
                        'PSOpenAI.Realtime.ReceiveMessage',
                        'PSOpenAI',
                        @($Response),
                        $null
                    )
                }
            }
        }

        # Start receive thread
        $script:ReceiveMessageJob = [PowerShell]::Create()
        $script:ReceiveMessageJob.RunSpace.Name = 'PSOpenAI.MessageReceiveThread'
        $null = $ReceiveMessageJob.AddScript($ReceiveMessageJobScript).
        AddParameter('ws', $WebSocketClient).
        AddParameter('consolehost', $Host).BeginInvoke()
        #endregion
    }

    process {}

    end {}
}