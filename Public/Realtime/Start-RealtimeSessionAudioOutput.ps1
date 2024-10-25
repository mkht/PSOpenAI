function Start-RealtimeSessionAudioOutput {
    [CmdletBinding()]
    param (
    )

    begin {
        # Platform check
        if ($PSVersionTable.PSVersion -lt 7.4) {
            Write-Error 'PowerShell version 7.4 or higher is required to run this command.'
            return
        }
        if (-not $IsWindows) {
            Write-Error 'This command can be run only on Windows.'
            return
        }

        # Session check
        if ($null -eq $script:WebSocketClient) {
            Write-Error 'No valid session found, please run Connect-RealtimeSession to initiate connection.'
            return
        }
        elseif ($script:WebSocketClient.State -ne [System.Net.WebSockets.WebSocketState]::Open) {
            Write-Error 'Session already closed.'
            return
        }

        if ($global:PSOpenAISpeakerOutput) {
            Write-Warning 'Audio out is already started.'
            return
        }

        # Class definitions
        [NoRunspaceAffinity()]
        class SpeakerOutput : System.IDisposable {
            hidden [NAudio.Wave.BufferedWaveProvider]$_waveProvider
            hidden [NAudio.Wave.WaveOutEvent]$_waveOutEvent

            SpeakerOutput() {
                $outputAudioFormat = [NAudio.Wave.WaveFormat]::new(24000, 16, 1)
                $this._waveProvider = [NAudio.Wave.BufferedWaveProvider]::new($outputAudioFormat)
                $this._waveProvider.BufferDuration = [timespan]::FromMinutes(2)
                $this._waveOutEvent = [NAudio.Wave.WaveOutEvent]::new()
                $this._waveOutEvent.Init($this._waveProvider)
                $this._waveOutEvent.Play()
            }

            [void] EnqueueForPlayback([byte[]]$audioData) {
                $this._waveProvider.AddSamples($audioData, 0, $audioData.Length)
            }

            [void] ClearPlayback() {
                $this._waveProvider.ClearBuffer()
            }

            [void] Dispose() {
                if ($null -ne $this._waveOutEvent) {
                    $this._waveOutEvent.Dispose()
                }
            }
        }

        # Start thread
        $global:PSOpenAISpeakerOutput = [SpeakerOutput]::new()
        $script:PSOpenAISpeakerOutputEventHandlerJob = `
            Register-EngineEvent -SourceIdentifier 'PSOpenAI.Realtime.ReceiveMessage' -Action {
            $o = $Event.SourceArgs[0]
            if ($o.type -eq 'response.audio.delta') {
                $buffer = [Convert]::FromBase64String($o.delta)
                $global:PSOpenAISpeakerOutput.EnqueueForPlayback($buffer)
            }
        }
    }

    process {}
    end {}
}