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
        'gpt-3.5' { 'cl100k_base'; continue }  # Common shorthand
        'gpt-35-turbo' { 'cl100k_base'; continue }  # Azure deployment name
        'gpt-4' { 'cl100k_base'; continue }
        # base
        'davince-002' { 'cl100k_base'; continue }
        'babbage-002' { 'cl100k_base'; continue }
        # embeddings
        'text-embedding-ada-002' { 'cl100k_base' ; continue }
        'text-embedding-3-small' { 'cl100k_base' ; continue }
        'text-embedding-3-large' { 'cl100k_base' ; continue }
    }
}
