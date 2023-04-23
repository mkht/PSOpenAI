class VectorUtils {
    static [double] Dot ([double[]]$Vector1, [double[]]$Vector2) {
        if ($Vector1.Length -ne $Vector2.Length) {
            throw [System.ArgumentException]::new('All vectors must have the same dimensionality.')
        }

        [double]$dot = .0d
        for ($i = 0; $i -lt $Vector1.Count; $i++) {
            $dot += $Vector1[$i] * $Vector2[$i]
        }
        return $dot
    }

    static [double] Norm ([double[]]$Vector1) {
        return [System.Math]::Sqrt([VectorUtils]::Dot($Vector1, $Vector1))
    }

    static [double] CosineSimilarity ([double[]]$Vector1, [double[]]$Vector2) {
        return [VectorUtils]::Dot($Vector1, $Vector2) / [VectorUtils]::Norm($Vector1) * [VectorUtils]::Norm($Vector2)
    }

    static [double] CosineDistance ([double[]]$Vector1, [double[]]$Vector2) {
        return 1.0 - [VectorUtils]::CosineSimilarity($Vector1, $Vector2)
    }
}

function Get-CosineSimilarity {
    [CmdletBinding()]
    [OutputType([double])]
    param (
        [Parameter(Mandatory, Position = 0)]
        [double[]]$Vector1,

        [Parameter(Mandatory, Position = 1)]
        [double[]]$Vector2
    )
    try {
        [VectorUtils]::CosineSimilarity($Vector1, $Vector2)
    }
    catch {
        Write-Error -Exception $_.Exception
    }
}
