function Convert-LogitBiasDictionary {
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.Dictionary[string, float]])]
    param (
        [Parameter(Mandatory, Position = 0)]
        [System.Collections.IDictionary]$InputObject,

        [Parameter()]
        [string]$Model
    )

    $TempHash = [System.Collections.Generic.Dictionary[int, float]]::new()

    foreach ($item in $InputObject.GetEnumerator()) {
        [float]$v = 0
        if (-not ([float]::TryParse($item.Value, [ref]$v))) {
            Write-Error 'The value of LogitBias should be type as [float]'
            continue
        }
        if ($v -gt 100) {
            Write-Warning ('The maximum value of LogitBias is 100. The value {0} is rounded to 100.' -f $v)
            $v = 100
        }
        elseif ($v -lt -100) {
            Write-Warning ('The minimum value of LogitBias is -100. The value {0} is rounded to -100.' -f $v)
            $v = -100
        }

        if ($item.Key -is [int]) {
            $TempHash[$item.Key] = $v
        }
        elseif ($item.Key -as [string]) {
            $wordToken = ConvertTo-Token -Text $item.Key -Model $Model
            if ($null -eq $wordToken -or $wordToken.Count -eq 0) {
                Write-Error ('Could not tokenize the word "{0}"' -f ($item.Key -as [string]))
                continue
            }
            elseif ($wordToken.Count -eq 1) {
                $intToken = [int]$wordToken
                $TempHash[$intToken] = $v
            }
            else {
                Write-Warning ('The word "{0}" has been encoded into multiple tokens, which may cause to behave unintentionally.' -f ($item.Key -as [string]))
                foreach ($token in $wordToken) {
                    $TempHash[$token] = $v
                }
            }
        }
        else {
            Write-Error 'Invalid value has been supplied to LogitBias'
            continue
        }
    }

    # Convert Dictionary<int, float> to Dictionary<string, float>
    # To parse into JSON format, keys must be of type string.
    $ResultHash = [System.Collections.Generic.Dictionary[string, float]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($item in $TempHash.GetEnumerator()) {
        $sk = [string]$item.Key
        $ResultHash[$sk] = $item.Value
    }

    $ResultHash
}
