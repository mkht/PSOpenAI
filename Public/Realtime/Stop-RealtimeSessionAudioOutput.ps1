function Stop-RealtimeSessionAudioOutput {
    [CmdletBinding()]
    param ()

    begin {}
    process {}
    end {
        if ($script:PSOpenAISpeakerOutputEventHandlerJob) {
            $script:PSOpenAISpeakerOutputEventHandlerJob | Remove-Job -Force
            $script:PSOpenAISpeakerOutputEventHandlerJob = $null
        }

        if ($global:PSOpenAISpeakerOutput) {
            $global:PSOpenAISpeakerOutput.Dispose()
            $global:PSOpenAISpeakerOutput = $null
        }

        Write-Host 'Audio output has been stopped.' -ForegroundColor Green
        Write-Verbose 'Audio output has been stopped.'
    }
}