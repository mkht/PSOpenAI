function Stop-RealtimeSessionAudioInput {
    [CmdletBinding()]
    param ()

    begin {}
    process {}
    end {
        if ($null -ne $script:MicInputStream) {
            $script:MicInputStream.Stop()
        }

        if ($global:SendAudioJob) {
            try {
                $script:SendAudioJob.Stop()
                $script:SendAudioJob.Dispose()
                $script:SendAudioJob = $null
            }
            catch {
                Write-Error -Exception $_.Exception
            }
        }
    }
    clean {
        if ($null -ne $script:MicInputStream) {
            $script:MicInputStream.Dispose()
            $script:MicInputStream = $null
        }
    }
}