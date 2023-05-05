function ConvertTo-Token {
    [CmdletBinding(DefaultParameterSetName = 'encoding')]
    [OutputType([int[]])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyString()]
        [string]$Text,

        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'model')]
        [string][LowerCaseTransformation()]$Model,

        [Parameter(Mandatory = $false, Position = 1, ParameterSetName = 'encoding')]
        [ValidateSet('cl100k_base', 'p50k_base', 'p50k_edit', 'r50k_base', 'gpt2')]
        [string]$Encoding = 'cl100k_base'
    )

    begin {
        if ($PSCmdlet.ParameterSetName -eq 'Model') {
            if ([string]::IsNullOrWhiteSpace($Model)) {
                Write-Error -Exception ([System.ArgumentException]::new('The model name not specifed properly.'))
                return
            }
            # Convert model name to encoding name
            $Encoding = Convert-ModelToEncoding -Model $Model
            if (-not $Encoding) {
                Write-Error -Exception ([System.ArgumentException]::new('The model name not specifed properly.'))
                return
            }
        }

        $Encoder = switch ($Encoding) {
            'cl100k_base' { [PSOpenAI.TokenizerLib.Cl100kBaseTokenizer]::Encode }
            'p50k_base' { [PSOpenAI.TokenizerLib.P50kBaseTokenizer]::Encode }
            'p50k_edit' { [PSOpenAI.TokenizerLib.P50kEditTokenizer]::Encode }
            'r50k_base' { [PSOpenAI.TokenizerLib.R50kBaseTokenizer]::Encode }
            'gpt2' { [PSOpenAI.TokenizerLib.Gpt2Tokenizer]::Encode }
        }
    }

    process {
        try {
            , $Encoder.Invoke($Text).ToArray()
        }
        catch {
            Write-Error -Exception $_.Exception
        }
    }

    end {}
}
