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

        Write-Host 'Audio input has been stopped.' -ForegroundColor Green
        Write-Verbose 'Audio input has been stopped.'
    }
    clean {
        if ($null -ne $script:MicInputStream) {
            $script:MicInputStream.Dispose()
            $script:MicInputStream = $null
        }
    }
}