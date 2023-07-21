function Convert-ModelToEncoding {
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Model
    )

    switch -Wildcard ($Model) {
        # chat
        'gpt-3.5-turbo-*' { 'cl100k_base'; continue } # e.g, gpt-3.5-turbo-16k, -0401, etc.
        'gpt-4-*' { 'cl100k_base'; continue }  # e.g., gpt-4-0613, gpt-4-32k, etc.
        'gpt-3.5-turbo' { 'cl100k_base'; continue }
        'gpt-4' { 'cl100k_base'; continue }
        # text
        'text-davinci-003' { 'p50k_base'; continue }
        'text-davinci-002' { 'p50k_base'; continue }
        'text-davinci-001' { 'r50k_base'; continue }
        'text-curie-001' { 'r50k_base' ; continue }
        'text-babbage-001' { 'r50k_base' ; continue }
        'text-ada-001' { 'r50k_base'; continue }
        'davinci' { 'r50k_base'; continue }
        'curie' { 'r50k_base'; continue }
        'babbage' { 'r50k_base' ; continue }
        'ada' { 'r50k_base' ; continue }
        # codex
        'code-davinci-002' { 'p50k_base' ; continue }
        'code-davinci-001' { 'p50k_base' ; continue }
        'code-cushman-002' { 'p50k_base' ; continue }
        'code-cushman-001' { 'p50k_base' ; continue }
        'davinci-codex' { 'p50k_base' ; continue }
        'cushman-codex' { 'p50k_base' ; continue }
        # edit
        'text-davinci-edit-001' { 'p50k_edit' ; continue }
        'code-davinci-edit-001' { 'p50k_edit' ; continue }
        # embeddings
        'text-embedding-ada-002' { 'cl100k_base' ; continue }
        'text-similarity-davinci-001' { 'r50k_base' ; continue }
        'text-similarity-curie-001' { 'r50k_base' ; continue }
        'text-similarity-babbage-001' { 'r50k_base' ; continue }
        'text-similarity-ada-001' { 'r50k_base' ; continue }
        'text-search-davinci-doc-001' { 'r50k_base' ; continue }
        'text-search-curie-doc-001' { 'r50k_base' ; continue }
        'text-search-babbage-doc-001' { 'r50k_base' ; continue }
        'text-search-ada-doc-001' { 'r50k_base' ; continue }
        'code-search-babbage-code-001' { 'r50k_base' ; continue }
        'code-search-ada-code-001' { 'r50k_base' ; continue }
        # open source
        'gpt2' { 'gpt2' ; continue }
    }
}
