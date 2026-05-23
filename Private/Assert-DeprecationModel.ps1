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
        'codex-mini-latest'                  = [datetime]::new(2026, 01, 16)
        'chatgpt-4o-latest'                  = [datetime]::new(2026, 02, 17)
        'gpt-4-0314'                         = [datetime]::new(2026, 03, 26)
        'gpt-4-1106-preview'                 = [datetime]::new(2026, 03, 26)
        'gpt-4-0125-preview'                 = [datetime]::new(2026, 03, 26)
        'gpt-4o-realtime-preview'            = [datetime]::new(2026, 05, 07)
        'gpt-4o-mini-realtime-preview'       = [datetime]::new(2026, 05, 07)
        'gpt-4o-audio-preview'               = [datetime]::new(2026, 05, 07)
        'gpt-4o-mini-audio-preview'          = [datetime]::new(2026, 05, 07)
        'dall-e-2'                           = [datetime]::new(2026, 05, 12)
        'dall-e-3'                           = [datetime]::new(2026, 05, 12)
        'computer-use-preview'               = [datetime]::new(2026, 07, 23)
        'gpt-5-chat-latest'                  = [datetime]::new(2026, 07, 23)
        'gpt-5-codex'                        = [datetime]::new(2026, 07, 23)
        'gpt-5.1-chat-latest'                = [datetime]::new(2026, 07, 23)
        'gpt-5.1-codex'                      = [datetime]::new(2026, 07, 23)
        'gpt-5.1-codex-max'                  = [datetime]::new(2026, 07, 23)
        'gpt-5.1-codex-mini'                 = [datetime]::new(2026, 07, 23)
        'o3-deep-research'                   = [datetime]::new(2026, 07, 23)
        'o4-mini-deep-research'              = [datetime]::new(2026, 07, 23)
        'gpt-5.2-codex'                      = [datetime]::new(2026, 07, 23)
        'gpt-5.2-chat-latest'                = [datetime]::new(2026, 08, 10)
        'gpt-5.3-chat-latest'                = [datetime]::new(2026, 08, 10)
        'sora-2'                             = [datetime]::new(2026, 09, 24)
        'sora-2-pro'                         = [datetime]::new(2026, 09, 24)
        'gpt-3.5-turbo-instruct'             = [datetime]::new(2026, 09, 28)
        'babbage-002'                        = [datetime]::new(2026, 09, 28)
        'davinci-002'                        = [datetime]::new(2026, 09, 28)
        'gpt-3.5-turbo-1106'                 = [datetime]::new(2026, 09, 28)
        'gpt-3.5-turbo'                      = [datetime]::new(2026, 10, 23)
        'gpt-4'                              = [datetime]::new(2026, 10, 23)
        'gpt-4.1-nano'                       = [datetime]::new(2026, 10, 23)
        'gpt-image-1'                        = [datetime]::new(2026, 10, 23)
        'o1'                                 = [datetime]::new(2026, 10, 23)
        'o1-pro'                             = [datetime]::new(2026, 10, 23)
        'o3-mini'                            = [datetime]::new(2026, 10, 23)
        'o4-mini'                            = [datetime]::new(2026, 10, 23)
    }
}

function Assert-DeprecationModel {
    [CmdletBinding()]
    [OutputType([void])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string]$Model
    )

    begin {}

    process {
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

    end {}
}
