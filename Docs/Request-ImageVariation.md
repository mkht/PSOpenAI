---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Request-ImageVariation.md
schema: 2.0.0
---

# Request-ImageVariation

## SYNOPSIS
Creates a variation of a given image.

## SYNTAX

```
Request-ImageVariation
    [-Image] <String>
    [-NumberOfImages <UInt16>]
    [-Size <String>]
    [-Format <String>]
    [-User <String>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <Object>]
    [-Organization <String>]
    [<CommonParameters>]
```

```
Request-ImageVariation
    [-Image] <String>
    [-NumberOfImages <UInt16>]
    [-Size <String>]
    -OutFile <String>
    [-User <String>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <Object>]
    [-Organization <String>]
    [<CommonParameters>]
```

## DESCRIPTION
Creates a variation of a given image.  
https://platform.openai.com/docs/guides/images/image-generation

## EXAMPLES

### Example 1: Creates a variation of a given image, then save to file.
```PowerShell
Request-ImageVariation -Image C:\cupcake.png -OutFile C:\cupcake2.png -Size 256x256
```

| Source (cupcake.png)                | Generated (cupcake2.png)             |
| ----------------------------------- | ------------------------------------ |
| ![source](/Docs/images/cupcake.png) | ![output](/Docs/images/cupcake2.png) |



### Example 2: Creates a variation of a given image, then output as base64 string.
```PowerShell
Request-ImageVariation -Image C:\cupcake.png -Format "base64"
```
```
iVBORw0KGgoAAAANSUhEUgAABAAAAAQACAIAAADwf7zUAAAAaGV......
```

## PARAMETERS

### -Image
(Required)
The image to use as the basis for the variation(s).  
Must be a valid PNG file, less than 4MB, and square.

```yaml
Type: String
Parameter Sets: (All)
Aliases: File
Required: True
Position: 1
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -NumberOfImages
The number of images to generate.  
Must be between `1` and `10`.
The default value is `1`.

```yaml
Type: UInt16
Aliases: n
Required: False
Position: Named
Default value: 1
```

### -Size
The size of the generated images.  
Must be one of `256x256`, `512x512`, or `1024x1024`.
The default value is `1024x1024`.

```yaml
Type: String
Required: False
Position: Named
Default value: 1024x1024
```

### -Format
The format in which the generated images are returned.  
Must be one of `url`, `base64` or `byte`.

```yaml
Type: String
Parameter Sets: Format
Aliases: response_format
Required: False
Position: Named
Default value: url
```

### -OutFile
Specify the file path where the generated images will be saved.  
This cannot be specified with the `Format` parameter.
Also, `NumberOfImages` must be `1`.

```yaml
Type: String
Parameter Sets: OutFile
Required: True
Position: Named
```

### -User
A unique identifier representing your end-user, which can help OpenAI to monitor and detect abuse.

```yaml
Type: String
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
Note 1: Retries will only be performed if the request fails with a `429 (Rate limit reached)` or `5xx (Server side errors)` error. Other errors (e.g., authentication failure) will not be performed.  
Note 2: Retry intervals increase exponentially with jitters, such as `1s > 2s > 4s > 8s > 16s`

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
Aliases: Token
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

### Format = url    : string or array of string
### Format = base64 : Generated image data represented in base64 string.
### Format = byte   : Byte array of generated image.
### OutFile         : Nothing.
## NOTES

## RELATED LINKS

[https://platform.openai.com/docs/guides/images/image-generation](https://platform.openai.com/docs/guides/images/image-generation)

[https://platform.openai.com/docs/api-reference/images/create-variation](https://platform.openai.com/docs/api-reference/images/create-variation)

