using namespace System.IO
using namespace System.Text
using namespace System.Collections
using namespace System.Collections.Generic

function New-MultipartFormContent {
    [CmdletBinding()]
    [OutputType([byte[]])]
    param (
        [Parameter(Mandatory)]
        [IDictionary]$FormData,

        [Parameter()]
        [string]$Boundary
    )

    $Utf8Enc = [UTF8Encoding]::new($false)  #UTF8NoBOM
    [List[byte]]$script:FormContent = [List[byte]]::new()

    # Set boundary
    if ([string]::IsNullOrWhiteSpace($Boundary)) {
        $Boundary = New-MultipartFormBoundary
    }
    $Boundary = '--' + $Boundary
    $script:InternalBoundary = $Utf8Enc.GetBytes($Boundary)

    #Contents
    foreach ($formEntry in $FormData.GetEnumerator()) {
        AddMultipartContent -fieldName $formEntry.Key -fieldValue $formEntry.Value -enumerate $true
    }

    #End boundary
    $script:FormContent.AddRange($script:InternalBoundary)
    $script:FormContent.AddRange([byte[]](45, 45))  # '--'

    #Output as [byte[]]
    Write-Output (, $script:FormContent.ToArray())
}

function AddMultipartBoundary {
    $script:FormContent.AddRange($script:InternalBoundary)
    $script:FormContent.AddRange([byte[]](13, 10))  # "`r`n"
}

function AddMultipartContent {
    [OutputType([void])]
    param(
        [object]$fieldName,
        [object]$fieldValue,
        [bool]$enumerate
    )

    if ($fieldValue -is [FileInfo]) {
        AddMultipartBoundary
        $script:FormContent.AddRange((GetMultipartFileContent -fieldName $fieldName -file $fieldValue))
    }
    elseif (-not $enumerate -or $fieldValue -is [string] -or $fieldValue -isnot [IEnumerable]) {
        AddMultipartBoundary
        $script:FormContent.AddRange((GetMultipartStringContent -fieldName $fieldName -fieldValue $fieldValue))
        return
    }
    elseif ($fieldValue -is [IDictionary] -and $fieldValue.Type -eq 'bytes') {
        AddMultipartBoundary
        $script:FormContent.AddRange((GetMultipartBytesContent -fieldName $fieldName -content $fieldValue.Content -fileName $fieldValue.FileName))
    }
    elseif ($enumerate -and $fieldValue -is [IEnumerable]) {
        foreach ($item in $fieldValue) {
            AddMultipartContent -fieldName $fieldName -fieldValue $item -enumerate $false
        }
    }
}

function GetMultipartFileContent {
    [OutputType([List[byte]])]
    param(
        [string]$fieldName,
        [FileInfo]$file
    )
    $MimeType = Get-MimeTypeFromFile -FileInfo $file
    GetMultipartBytesContent -fieldName $fieldName -content ([File]::ReadAllBytes($file.FullName)) -fileName $file.Name -ContentType $MimeType
}

function GetMultipartStringContent {
    [OutputType([List[byte]])]
    param(
        [string]$fieldName,
        [string]$fieldValue
    )
    $contentType = 'text/plain'
    $header = @(
        ('Content-Disposition: form-data; name="{0}"' -f $fieldName),
        # NOTE: Some Azure endpoints does not process requests correctly when this header is present,
        #       even though it is allowed in the RFC and is not a problem in OpenAI. :(
        # ('Content-Type: {0}; charset=utf-8' -f $contentType),
        '',
        ''
    ) -join "`r`n"

    $Utf8Enc = [UTF8Encoding]::new($false)
    [List[byte]]$result = [List[byte]]::new()
    $result.AddRange($Utf8Enc.GetBytes($header))
    $result.AddRange($Utf8Enc.GetBytes($fieldValue))
    $result.AddRange([byte[]](13, 10))  # "`r`n"
    return , $result
}

function GetMultipartBytesContent {
    [OutputType([List[byte]])]
    param(
        [string]$fieldName,
        [byte[]]$content,
        [string]$fileName,
        [string]$contentType = 'application/octet-stream'
    )
    $ContentDispositionHeader = 'Content-Disposition: form-data; name="{0}"' -f $fieldName
    if (-not [string]::IsNullOrWhiteSpace($fileName)) {
        $ContentDispositionHeader += "; filename*=utf-8''{0}" -f [Uri]::EscapeDataString($fileName)
    }
    $header = @(
        $ContentDispositionHeader,
        ('Content-Type: {0}' -f $contentType),
        '',
        ''
    ) -join "`r`n"

    $Utf8Enc = [UTF8Encoding]::new($false)
    [List[byte]]$result = [List[byte]]::new()
    $result.AddRange($Utf8Enc.GetBytes($header))
    $result.AddRange($content)
    $result.AddRange([byte[]](13, 10))  # "`r`n"
    return , $result
}
