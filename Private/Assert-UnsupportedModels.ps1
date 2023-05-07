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
        $m = $ListOfUnsupportedModels | Where-Object { $_.Id -eq $Model } | Select-Object -First 1
        if ($m) {
            if ([datetime]::Now -ge $m.Expires) {
                $msg = ('The {0} model has been discontinued on {1}. Please consider using a different model.' -f $m.Id, $m.Expires)
            }
            else {
                $msg = ('The {0} model will be discontinued on {1}. Please consider using a different model.' -f $m.Id, $m.Expires)
            }
            Write-Warning -Message $msg
        }
    }

    End {

    }
}
