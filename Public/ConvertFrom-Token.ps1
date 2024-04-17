function ConvertFrom-Token {
    [CmdletBinding(DefaultParameterSetName = 'encoding')]
    [OutputType([string])]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [AllowEmptyCollection()]
        [int[]]$Token,

        [Parameter(Mandatory, Position = 1, ParameterSetName = 'model')]
        [string][LowerCaseTransformation()]$Model,

        [Parameter(Mandatory = $false, Position = 1, ParameterSetName = 'encoding')]
        [ValidateSet('cl100k_base')]
        [string]$Encoding = 'cl100k_base',

        [Parameter()]
        [switch]$AsArray
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

        $Decoder = [PSOpenAI.TokenizerLib.Cl100kBaseTokenizer]::Decode
        $TokenList = [System.Collections.Generic.List[int]]::new()
    }

    process {
        try {
            if ($AsArray) {
                foreach ($t in $Token) {
                    [int[]]$t_array = , $t
                    $Decoder.Invoke($t_array)
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
                $Decoder.Invoke($PartialTokenList.ToArray())
            }
        }
        catch {
            Write-Error -Exception $_.Exception
        }
    }

    end {
        if ($TokenList.Count -ne 0) {
            try {
                $Decoder.Invoke($TokenList.ToArray())
            }
            catch {
                Write-Error -Exception $_.Exception
            }
        }
    }
}
