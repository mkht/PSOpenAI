function Assert-UnsupportedModels {
    [CmdletBinding()]
    [OutputType([void])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string]$Model
    )

    Begin {
        #Should this list be separated as a JSON or PSD1 static file?
        $ListOfUnsupportedModels = @(
            @{
                Id      = 'code-davinci-001'
                Expires = '2023-03-23'
            },
            @{
                Id      = 'code-davinci-002'
                Expires = '2023-03-23'
            },
            @{
                Id      = 'code-cushman-001'
                Expires = '2023-03-23'
            },
            @{
                Id      = 'code-cushman-002'
                Expires = '2023-03-23'
            }
        )
    }

    Process {
        $now = [datetime]::Now
        $m = $ListOfUnsupportedModels | Where-Object { $_.Id -eq $Model } | Select-Object -First 1
        if ($expires = $m.Expires -as [datetime]) {
            if ($now -ge $expires) {
                $msg = ('The {0} model has been discontinued on {1}. Please consider using a different model.' -f $m.Id, $m.Expires)
            }
            elseif (($now - $expires) -ge [timespan]::FromDays(-30)) {
                $msg = ('The {0} model will be discontinued on {1}. Please consider using a different model.' -f $m.Id, $m.Expires)
            }

            if ($msg) {
                Write-Warning -Message $msg
            }
        }
    }

    End {

    }
}
