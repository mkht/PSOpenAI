function ConvertFrom-Token {
    [CmdletBinding(DefaultParameterSetName = 'encoding')]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [AllowEmptyCollection()]
        [int[]]$Token,

        [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'model')]
        [string][LowerCaseTransformation()]$Model,

        [Parameter(Mandatory = $false, Position = 1, ParameterSetName = 'encoding')]
        [ValidateSet('cl100k_base', 'p50k_base', 'p50k_edit', 'r50k_base', 'gpt2')]
        [string]$Encoding = 'cl100k_base',

        [Parameter()]
        [switch]$AsArray
    )

    begin {
        $Tokenizer = $null
        try {
            if ($PSCmdlet.ParameterSetName -eq 'Model') {
                if ([string]::IsNullOrWhiteSpace($Model)) {
                    throw [System.ArgumentException]::new('The model name not specifed properly.')
                }
                else {
                    $Tokenizer = [Microsoft.DeepDev.TokenizerBuilder]::CreateByModelName($Model)
                }
            }
            else {
                $Tokenizer = [Microsoft.DeepDev.TokenizerBuilder]::CreateByEncoderName($Encoding)
            }
        }
        catch {
            Write-Error -Exception $_.Exception
        }

        $TokenList = [System.Collections.Generic.List[int]]::new()
    }

    process {
        try {
            if ($AsArray) {
                foreach ($t in $Token) {
                    [int[]]$t_array = , $t
                    $Tokenizer.Decode($t_array)
                }
            }
            elseif ($Token.Length -eq 0) {
                [string]::Empty
            }
            elseif ($Token.Length -eq 1) {
                $TokenList.Add($Token[0])
            }
            else {
                $TokenList.Clear()
                $PartialTokenList = [System.Collections.Generic.List[int]]::new()
                foreach ($t in $Token) {
                    $PartialTokenList.Add($t)
                }
                $Tokenizer.Decode($PartialTokenList.ToArray())
            }
        }
        catch {
            Write-Error -Exception $_.Exception
        }
    }

    end {
        if ($TokenList.Count -ne 0) {
            try {
                $Tokenizer.Decode($TokenList.ToArray())
            }
            catch {
                Write-Error -Exception $_.Exception
            }
        }
    }
}
