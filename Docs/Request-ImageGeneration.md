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
    [-NumberOfImages <UInt16>]
    [-Size <String>]
    [-Format <String>]
    [-User <String>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-Token <Object>]
    [<CommonParameters>]
```

```
Request-ImageGeneration
    [-Prompt] <String>
    [-NumberOfImages <UInt16>]
    [-Size <String>]
    -OutFile <String>
    [-User <String>]
    [-TimeoutSec <Int32>]
    [-Token <Object>]
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
Request-ImageGeneration -Prompt 'Delicious ramen with gyoza' -Format "url" -NumberOfImages 3
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
The maximum length is 1000 characters.

```yaml
Type: String
Required: True
Position: 1
Accept pipeline input: True (ByValue)
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

### -Token
Specifies API key for authentication.  
The type of data should `[string]` or `[securestring]`.  
If not specified, it will try to use `$global:OPENAI_TOKEN` or `$env:OPENAI_TOKEN`

```yaml
Type: Object
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

[https://platform.openai.com/docs/api-reference/images/create](https://platform.openai.com/docs/api-reference/images/create)

