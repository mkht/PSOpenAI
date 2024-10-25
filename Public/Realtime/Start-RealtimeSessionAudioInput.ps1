function Start-RealtimeSessionAudioInput {
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

        # No Audio input device
        if ([NAudio.Wave.WaveInEvent]::DeviceCount -le 0) {
            Write-Error 'There is no audio input device on this computer.'
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

        if ($global:PSOpenAISpeakerInput) {
            Write-Warning 'Audio input is already started.'
            return
        }

        # Class definitions
        # This code is copied from https://github.com/Azure-Samples/aoai-realtime-audio-sdk/blob/8105a5c3ab9cc54fe864aa6f8259f72c6829eec7/dotnet/samples/console-from-mic/MicrophoneAudioStream.cs
        Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Threading;
using NAudio.Wave;

#nullable disable

/// <summary>
/// Uses the NAudio library (https://github.com/naudio/NAudio) to provide a rudimentary abstraction of microphone
/// input as a stream.
/// </summary>
public class MicrophoneAudioStream : Stream, IDisposable
{
    private const int SAMPLES_PER_SECOND = 24000;
    private const int BYTES_PER_SAMPLE = 2;
    private const int CHANNELS = 1;

    // For simplicity, this is configured to use a static 10-second ring buffer.
    private readonly byte[] _buffer = new byte[BYTES_PER_SAMPLE * SAMPLES_PER_SECOND * CHANNELS * 10];
    private readonly object _bufferLock = new();
    private int _bufferReadPos = 0;
    private int _bufferWritePos = 0;

    private readonly WaveInEvent _waveInEvent;

    private MicrophoneAudioStream()
    {
        _waveInEvent = new()
        {
            WaveFormat = new WaveFormat(SAMPLES_PER_SECOND, BYTES_PER_SAMPLE * 8, CHANNELS),
        };
        _waveInEvent.DataAvailable += (_, e) =>
        {
            lock (_bufferLock)
            {
                int bytesToCopy = e.BytesRecorded;
                if (_bufferWritePos + bytesToCopy >= _buffer.Length)
                {
                    int bytesToCopyBeforeWrap = _buffer.Length - _bufferWritePos;
                    Array.Copy(e.Buffer, 0, _buffer, _bufferWritePos, bytesToCopyBeforeWrap);
                    bytesToCopy -= bytesToCopyBeforeWrap;
                    _bufferWritePos = 0;
                }
                Array.Copy(e.Buffer, e.BytesRecorded - bytesToCopy, _buffer, _bufferWritePos, bytesToCopy);
                _bufferWritePos += bytesToCopy;
            }
        };
        _waveInEvent.StartRecording();
    }

    public static MicrophoneAudioStream Start() => new();

    public void Stop()
    {
        _waveInEvent.StopRecording();
    }

    public override bool CanRead => true;

    public override bool CanSeek => false;

    public override bool CanWrite => false;

    public override long Length => throw new NotImplementedException();

    public override long Position { get => throw new NotImplementedException(); set => throw new NotImplementedException(); }

    public override void Flush()
    {
        throw new NotImplementedException();
    }

    public override int Read(byte[] buffer, int offset, int count)
    {
        int totalCount = count;

        int GetBytesAvailable() => _bufferWritePos < _bufferReadPos
            ? _bufferWritePos + (_buffer.Length - _bufferReadPos)
            : _bufferWritePos - _bufferReadPos;

        // For simplicity, we'll block until all requested data is available and not perform partial reads.
        while (GetBytesAvailable() < count)
        {
            Thread.Sleep(100);
        }

        lock (_bufferLock)
        {
            if (_bufferReadPos + count >= _buffer.Length)
            {
                int bytesBeforeWrap = _buffer.Length - _bufferReadPos;
                Array.Copy(
                    sourceArray: _buffer,
                    sourceIndex: _bufferReadPos,
                    destinationArray: buffer,
                    destinationIndex: offset,
                    length: bytesBeforeWrap);
                _bufferReadPos = 0;
                count -= bytesBeforeWrap;
                offset += bytesBeforeWrap;
            }

            Array.Copy(_buffer, _bufferReadPos, buffer, offset, count);
            _bufferReadPos += count;
        }

        return totalCount;
    }

    public override long Seek(long offset, SeekOrigin origin)
    {
        throw new NotImplementedException();
    }

    public override void SetLength(long value)
    {
        throw new NotImplementedException();
    }

    public override void Write(byte[] buffer, int offset, int count)
    {
        throw new NotImplementedException();
    }

    protected override void Dispose(bool disposing)
    {
        _waveInEvent?.Dispose();
        base.Dispose(disposing);
    }
}
'@ -ReferencedAssemblies 'System', 'System.Threading', 'System.Threading.Thread', 'NETStandard', 'NAudio', 'NAudio.Core', 'NAudio.WinMM'

        # Start thread
        $script:MicInputStream = [MicrophoneAudioStream]::Start()

        #region Init message receive thread
        $SendAudioJobScript = {
            param($ws, $audio, $consolehost)
            $_audiobuffer = [System.Buffers.ArrayPool[byte]]::Shared.Rent(1024 * 16)
            # Start send audio loop
            while ($ws.State -eq [System.Net.WebSockets.WebSocketState]::Open) {
                $bytesRead = $audio.Read($_audiobuffer, 0, $_audiobuffer.Length)
                if ($bytesRead -eq 0) {
                    break
                }

                $audioData = [Convert]::ToBase64String($_audiobuffer, 0, $bytesRead)
                $jsonMessage = @{
                    type  = 'input_audio_buffer.append'
                    audio = $audioData
                } | ConvertTo-Json
                [ArraySegment[byte]]$messageBytes = [System.Text.Encoding]::UTF8.GetBytes($jsonMessage)

                # Send message
                $_ct = [Threading.CancellationToken]::new($false)
                $null = $ws.SendAsync(
                    $messageBytes,
                    [System.Net.WebSockets.WebSocketMessageType]::Text,
                    $true,
                    $_ct
                ).GetAwaiter().GetResult()

                # Fire custom event
                $null = $consolehost.RunSpace.Events.GenerateEvent(
                    'PSOpenAI.Realtime.SendMessage',
                    'PSOpenAI',
                    @($jsonMessage),
                    $null
                )
            }
        }

        # Start receive thread
        $script:SendAudioJob = [PowerShell]::Create()
        $script:SendAudioJob.RunSpace.Name = 'PSOpenAI.SendAudioThread'
        $null = $SendAudioJob.AddScript($SendAudioJobScript).
        AddParameter('ws', $WebSocketClient).
        AddParameter('audio', $MicInputStream).
        AddParameter('consolehost', $Host).BeginInvoke()
        #endregion
    }

    process {}
    end {}
}