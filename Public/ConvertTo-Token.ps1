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
    }

    process {
        if ($null -eq $Tokenizer) {
            $e = [System.InvalidOperationException]::new('Tokenizer object does not initilized.')
            Write-Error -Exception $e
            return
        }

        , $Tokenizer.Encode($Text, [System.Collections.Generic.List[string]]::new()).ToArray()
    }

    end {

    }
}
