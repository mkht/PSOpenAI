---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Request-ImageGeneration.md
schema: 2.0.0
---

# Request-ImageGeneration

## SYNOPSIS
Creates an image given a prompt.

## SYNTAX

```
Request-ImageGeneration
    [-Prompt] <String>
    [-Model <String>]
    [-NumberOfImages <UInt16>]
    [-Size <String>]
    [-Quality <String>]
    [-Style <String>]
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
Request-ImageGeneration
    [-Prompt] <String>
    [-Model <String>]
    [-NumberOfImages <UInt16>]
    [-Size <String>]
    [-Quality <String>]
    [-Style <String>]
    -OutFile <String>
    [-User <String>]
    [-TimeoutSec <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <Object>]
    [<CommonParameters>]
```

## DESCRIPTION
Creates an image given a prompt.  
https://platform.openai.com/docs/guides/images/image-generation

## EXAMPLES

### Example 1: Creates and save an image from prompt. 
```PowerShell
Request-ImageGeneration -Prompt 'A cute baby lion' -Size 256x256 -OutFile C:\babylion.png
```

![lion](/Docs/images/babylion.png)


### Example 2: Creates multiple images at once, and retrieve results by URL.
```PowerShell
Request-ImageGeneration -Prompt 'Delicious ramen with gyoza' -Model dall-e-2 -Format "url" -NumberOfImages 3
```
```
https://oaidalleapiprodscus.blob.core.windows.net/private/org-BXLtGIt0xglP9if8FVhkD...
https://oaidalleapiprodscus.blob.core.windows.net/private/org-BXLtGIt0xglP9if8FVhkD...
https://oaidalleapiprodscus.blob.core.windows.net/private/org-BXLtGIt0xglP9if8FVhkD...
```

## PARAMETERS

### -Prompt
(Required)
A text description of the desired image(s).  

```yaml
Type: String
Required: True
Position: 1
Accept pipeline input: True (ByValue)
```

### -Model
The model to use for image generation. The default is `dall-e-2`

```yaml
Type: String
Required: False
Position: Named
Default value: dall-e-2
```

### -NumberOfImages
The number of images to generate. Must be between 1 and 10. For `dall-e-3`, only `1` is supported.

```yaml
Type: UInt16
Aliases: n
Required: False
Position: Named
Default value: 1
```

### -Size
The size of the generated images. Must be one of `256x256`, `512x512`, or `1024x1024` for `dall-e-2`. Must be one of `1024x1024`, `1792x1024`, or `1024x1792` for `dall-e-3` models.  
The default value is `1024x1024`.

```yaml
Type: String
Required: False
Position: Named
Default value: 1024x1024
```

### -Quality
The quality of the image that will be generated. `hd` creates images with finer details and greater consistency across the image. This param is only supported for `dall-e-3`.

```yaml
Type: String
Required: False
Position: Named
Default value: standard
```

### -Style
The style of the generated images. Must be one of `vivid` or `natural`. Vivid causes the model to lean towards generating hyper-real and dramatic images. Natural causes the model to produce more natural, less hyper-real looking images. This param is only supported for `dall-e-3`.

```yaml
Type: String
Required: False
Position: Named
Default value: vivid
```

### -Format
The format in which the generated images are returned.  
Must be one of `url`, `base64`, `byte` or `raw_response`.

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

### Format = url             : string or array of string
### Format = base64          : Generated image data represented in base64 string.
### Format = byte            : Byte array of generated image.
### Format = raw_response    : string
### OutFile                  : Nothing.

## NOTES

## RELATED LINKS

[https://platform.openai.com/docs/guides/images/image-generation](https://platform.openai.com/docs/guides/images/image-generation)

[https://platform.openai.com/docs/api-reference/images/create](https://platform.openai.com/docs/api-reference/images/create)

