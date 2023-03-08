function New-MultipartFormBoundary {
    [guid]::NewGuid().ToString()
}
