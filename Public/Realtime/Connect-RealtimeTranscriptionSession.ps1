function Connect-RealtimeTranscriptionSession {
    [CmdletBinding()]
    param (
        [Parameter()]
        [System.Uri]$ApiBase,

        [Parameter()]
        [securestring][SecureStringTransformation()]$ApiKey

    )

    begin {
        # Construct parameters
        $Parameters = $PSBoundParameters
        $Parameters.SessionType = 'transcription'

        # Invoke base function
        $steppablePipeline = {
            PSOpenAI\Connect-RealtimeSession @Parameters
        }.GetSteppablePipeline($myInvocation.CommandOrigin)
        $steppablePipeline.Begin($PSCmdlet)
    }

    process {
        $steppablePipeline.Process($PSItem)
    }

    end {
        $steppablePipeline.End()
    }
}