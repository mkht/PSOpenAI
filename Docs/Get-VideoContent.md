---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Get-VideoContent.md
schema: 2.0.0
---

# Get-VideoContent

## SYNOPSIS
Downloads generated video content.

## SYNTAX

```
Get-VideoContent
    [-VideoId] <String>
    [-OutFile <String>]
    [-Variant <String>]
    [-WaitForCompletion]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [-Organization <String>]
    [<CommonParameters>]
```

## DESCRIPTION
Retrieves the binary content for a generated video. You can save the response to a file or work with the bytes in memory. Use the `-WaitForCompletion` switch to wait for the associated job to succeed before downloading its assets.

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-VideoContent -VideoId 'video_abc123' -OutFile C:\videos\demo.mp4
```

Saves the video content for the specified job to `C:\videos\demo.mp4`.

### Example 2
```powershell
PS C:\> $Bytes = Get-VideoContent -VideoId 'video_abc123'
```

Returns the video bytes for further processing.

### Example 3
```powershell
PS C:\> Get-VideoContent -VideoId 'video_abc123' -Variant thumbnail -WaitForCompletion -OutFile C:\videos\demo.webp
```

Waits for the job to finish and then downloads the thumbnail asset.

## PARAMETERS

### -VideoId
The identifier of the video whose media to download.

```yaml
Type: String
Aliases: video_id, Id
Required: True
Position: 0
Accept pipeline input: True (ByPropertyName, ByValue)
```

### -OutFile
Path to the file where the content should be saved. If omitted, the cmdlet returns the byte array instead of writing to disk.

```yaml
Type: String
Required: False
Position: Named
```

### -Variant
Which downloadable asset to return. Supported values are `video`, `thumbnail`, and `spritesheet`. The default value is `video`.

```yaml
Type: String
Required: False
Position: Named
Default value: video
```

### -WaitForCompletion
When specified, waits for the job to reach a completed state before downloading the content.

```yaml
Type: SwitchParameter
Required: False
Position: Named
```

### -TimeoutSec
Specifies how long the request can be pending before it times out.
The default value is `0` (infinite).

```yaml
Type: Int32
Required: False
Position: Named
Default value: 0
```

### -MaxRetryCount
Number between `0` and `100`.
Specifies the maximum number of retries if the request fails.
The default value is `0` (No retry).
Note : Retries will only be performed if the request fails with a `429 (Rate limit reached)` or `5xx (Server side errors)` error. Other errors (e.g., authentication failure) will not be performed.

```yaml
Type: Int32
Required: False
Position: Named
Default value: 0
```

### -ApiBase
Specifies an API endpoint URL such like: `https://your-api-endpoint.test/v1`
If not specified, it will use `https://api.openai.com/v1`

```yaml
Type: System.Uri
Required: False
Position: Named
Default value: https://api.openai.com/v1
```

### -ApiKey
Specifies API key for authentication.
The type of data should `[string]` or `[securestring]`.
If not specified, it will try to use `$global:OPENAI_API_KEY` or `$env:OPENAI_API_KEY`

```yaml
Type: Object
Required: False
Position: Named
```

### -Organization
Specifies Organization ID which used for an API request.
If not specified, it will try to use `$global:OPENAI_ORGANIZATION` or `$env:OPENAI_ORGANIZATION`

```yaml
Type: string
Aliases: OrgId
Required: False
Position: Named
```

## INPUTS

## OUTPUTS

### System.Byte[]

## NOTES

## RELATED LINKS

[https://platform.openai.com/docs/api-reference/videos/content](https://platform.openai.com/docs/api-reference/videos/content)
