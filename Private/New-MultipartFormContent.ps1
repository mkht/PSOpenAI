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

    #Contents
    foreach ($formEntry in $FormData.GetEnumerator()) {
        $script:FormContent.AddRange($Utf8Enc.GetBytes($Boundary))
        $script:FormContent.AddRange($Utf8Enc.GetBytes("`r`n"))
        AddMultipartContent -fieldName $formEntry.Key -fieldValue $formEntry.Value -enumerate $true
    }

    #End boundary
    $script:FormContent.AddRange($Utf8Enc.GetBytes(($Boundary + '--')))

    #Output as [byte[]]
    Write-Output (, $script:FormContent.ToArray())
}

function AddMultipartContent {
    [OutputType([void])]
    Param(
        [object]$fieldName,
        [object]$fieldValue,
        [bool]$enumerate
    )

    if ($fieldValue -is [FileInfo]) {
        $script:FormContent.AddRange((GetMultipartFileContent -fieldName $fieldName -file $fieldValue))
    }
    elseif (-not $enumerate -or $fieldValue -is [string] -or $fieldValue -isnot [IEnumerable]) {
        $script:FormContent.AddRange((GetMultipartStringContent -fieldName $fieldName -fieldValue $fieldValue))
        return
    }
    elseif ($fieldValue -is [IDictionary] -and $fieldValue.Type -eq 'bytes') {
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

    GetMultipartBytesContent -fieldName $fieldName -content ([File]::ReadAllBytes($file.FullName)) -fileName $file.Name
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
        ('Content-Type: {0}; charset=utf-8' -f $contentType),
        '',
        ''
    ) -join "`r`n"

    $Utf8Enc = [UTF8Encoding]::new($false)
    [List[byte]]$result = [List[byte]]::new()
    $result.AddRange($Utf8Enc.GetBytes($header))
    $result.AddRange($Utf8Enc.GetBytes($fieldValue))
    $result.AddRange($Utf8Enc.GetBytes("`r`n"))
    return , $result
}

function GetMultipartBytesContent {
    [OutputType([List[byte]])]
    param(
        [string]$fieldName,
        [byte[]]$content,
        [string]$fileName
    )
    $contentType = 'application/octet-stream'
    $header = @(
        ('Content-Disposition: form-data; name="{0}"; filename="{1}"' -f $fieldName, $fileName),
        ('Content-Type: {0}' -f $contentType),
        '',
        ''
    ) -join "`r`n"

    $Utf8Enc = [UTF8Encoding]::new($false)
    [List[byte]]$result = [List[byte]]::new()
    $result.AddRange($Utf8Enc.GetBytes($header))
    $result.AddRange($content)
    $result.AddRange($Utf8Enc.GetBytes("`r`n"))
    return , $result
}
