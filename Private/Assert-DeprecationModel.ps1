class OpenAIDepricationModels {
    # https://platform.openai.com/docs/deprecations
    static [hashtable] $Expired = @{
        'code-davinci-001'                   = [datetime]::new(2023, 03, 23)
        'code-davinci-002'                   = [datetime]::new(2023, 03, 23)
        'code-cushman-001'                   = [datetime]::new(2023, 03, 23)
        'code-cushman-002'                   = [datetime]::new(2023, 03, 23)
        'text-ada-001'                       = [datetime]::new(2024, 01, 04)
        'text-babbage-001'                   = [datetime]::new(2024, 01, 04)
        'text-curie-001'                     = [datetime]::new(2024, 01, 04)
        'text-davinci-001'                   = [datetime]::new(2024, 01, 04)
        'text-davinci-002'                   = [datetime]::new(2024, 01, 04)
        'text-davinci-003'                   = [datetime]::new(2024, 01, 04)
        'ada'                                = [datetime]::new(2024, 01, 04)
        'babbage'                            = [datetime]::new(2024, 01, 04)
        'curie'                              = [datetime]::new(2024, 01, 04)
        'davinci'                            = [datetime]::new(2024, 01, 04)
        'text-davinci-edit-001'              = [datetime]::new(2024, 01, 04)
        'code-davinci-edit-001'              = [datetime]::new(2024, 01, 04)
        'text-similarity-ada-001'            = [datetime]::new(2024, 01, 04)
        'text-search-ada-doc-001'            = [datetime]::new(2024, 01, 04)
        'text-search-ada-query-001'          = [datetime]::new(2024, 01, 04)
        'code-search-ada-code-001'           = [datetime]::new(2024, 01, 04)
        'code-search-ada-text-001'           = [datetime]::new(2024, 01, 04)
        'text-similarity-babbage-001'        = [datetime]::new(2024, 01, 04)
        'text-search-babbage-doc-001'        = [datetime]::new(2024, 01, 04)
        'text-search-babbage-query-001'      = [datetime]::new(2024, 01, 04)
        'code-search-babbage-code-001'       = [datetime]::new(2024, 01, 04)
        'code-search-babbage-text-001'       = [datetime]::new(2024, 01, 04)
        'text-similarity-curie-001'          = [datetime]::new(2024, 01, 04)
        'text-search-curie-doc-001'          = [datetime]::new(2024, 01, 04)
        'text-search-curie-query-001'        = [datetime]::new(2024, 01, 04)
        'text-similarity-davinci-001'        = [datetime]::new(2024, 01, 04)
        'text-search-davinci-doc-001'        = [datetime]::new(2024, 01, 04)
        'text-search-davinci-query-001'      = [datetime]::new(2024, 01, 04)
        'gpt-3.5-turbo-0613'                 = [datetime]::new(2024, 09, 13)
        'gpt-3.5-turbo-16k-0613'             = [datetime]::new(2024, 09, 13)
        'gpt-4-vision-preview'               = [datetime]::new(2024, 12, 06)
        'gpt-4-1106-vision-preview'          = [datetime]::new(2024, 12, 06)
        'gpt-4-32k'                          = [datetime]::new(2025, 06, 06)
        'gpt-4-32k-0613'                     = [datetime]::new(2025, 06, 06)
        'gpt-4-32k-0314'                     = [datetime]::new(2025, 06, 06)
        'gpt-4.5-preview'                    = [datetime]::new(2025, 07, 14)
        'o1-preview'                         = [datetime]::new(2025, 07, 28)
        'gpt-4o-audio-preview-2024-10-01'    = [datetime]::new(2025, 09, 10)
        'gpt-4o-realtime-preview-2024-10-01' = [datetime]::new(2025, 09, 10)
        'o1-mini'                            = [datetime]::new(2025, 10, 27)
        'text-moderation-007'                = [datetime]::new(2025, 10, 27)
        'text-moderation-stable'             = [datetime]::new(2025, 10, 27)
        'text-moderation-latest'             = [datetime]::new(2025, 10, 27)
    }
}

function Assert-DeprecationModel {
    [CmdletBinding()]
    [OutputType([void])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string]$Model
    )

    Begin {}

    Process {
        if (-not [OpenAIDepricationModels]::Expired.ContainsKey($Model)) {
            return
        }
        $msg = [string]::Empty
        $now = [datetime]::Now
        $expires = [OpenAIDepricationModels]::Expired[$Model]
        if ($expires -isnot [datetime]) {
            return
        }
        elseif ($now -ge $expires) {
            $msg = ('The {0} model has been discontinued on {1}. Please consider using a different model.' -f $Model, $expires.ToString('yyyy-MM-dd'))
        }
        elseif (($now - $expires) -ge [timespan]::FromDays(-30)) {
            $msg = ('The {0} model will be discontinued on {1}. Please consider using a different model.' -f $Model, $expires.ToString('yyyy-MM-dd'))
        }

        if ($msg) {
            Write-Warning -Message $msg
        }
    }

    End {}
}
