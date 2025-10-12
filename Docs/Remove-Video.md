---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Remove-Video.md
schema: 2.0.0
---

# Remove-Video

## SYNOPSIS
Deletes a video generation job.

## SYNTAX

```
Remove-Video
    [-VideoId] <String>
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [-Organization <String>]
    [-AdditionalQuery <IDictionary>]
    [-AdditionalHeaders <IDictionary>]
    [-AdditionalBody <Object>]
    [<CommonParameters>]
```

## DESCRIPTION
Deletes a video job that was previously created. Use this to clean up jobs that you no longer need.

## EXAMPLES

### Example 1
```powershell
PS C:\> Remove-Video -VideoId 'video_68ea'
```

Deletes the specified video job.

## PARAMETERS

### -VideoId
The ID of the video job to delete.

```yaml
Type: String
Aliases: video_id, Id
Required: True
Position: 0
Accept pipeline input: True (ByPropertyName, ByValue)
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

### -AdditionalQuery
If you want to explicitly send an extra query params, you can do so.

```yaml
Type: IDictionary
Required: False
Position: Named
```

### -AdditionalHeaders
If you want to explicitly send an extra headers, you can do so.

```yaml
Type: IDictionary
Required: False
Position: Named
```

### -AdditionalBody
If you want to explicitly send an extra body, you can do so.

```yaml
Type: Object
Required: False
Position: Named
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[https://platform.openai.com/docs/api-reference/videos/delete](https://platform.openai.com/docs/api-reference/videos/delete)

