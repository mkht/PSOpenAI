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
    }
}