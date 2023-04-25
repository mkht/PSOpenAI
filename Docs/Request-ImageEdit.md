---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Request-ImageEdit.md
schema: 2.0.0
---

# Request-ImageEdit

## SYNOPSIS
Creates an edited or extended image given an original image and a prompt.

## SYNTAX

```
Request-ImageEdit
    -Image <String>
    -Prompt <String>
    [-Mask <String>]
    [-NumberOfImages <UInt16>]
    [-Size <String>]
    [-Format <String>]
    [-User <String>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiKey <Object>]
    [-Organization <String>]
    [<CommonParameters>]
```

```
Request-ImageEdit
    -Image <String>
    -Prompt <String>
    [-Mask <String>]
    [-NumberOfImages <UInt16>]
    [-Size <String>]
    -OutFile <String>
    [-User <String>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiKey <Object>]
    [<CommonParameters>]
```

## DESCRIPTION
Creates an edited or extended image given an original image and a prompt.  
https://platform.openai.com/docs/guides/images/image-generation

## EXAMPLES

### Example 1: Restore masked image.
```PowerShell
Request-ImageEdit -Image C:\sunflower_mask.png -Prompt "sunflower" -OutFile C:\edit.png -Size 256x256
```

|Source (sunflower_mask.png)|Generated (edit.png)|
|----|----|
| ![masked](/Docs/images/sunflower_masked.png)  | ![restored](/Docs/images/sunflower_restored.png)   |


### Example 2: Create variation image from source and mask.
```PowerShell
Request-ImageEdit -Image C:\sand_with_feather.png -Mask C:\fether_mask.png -Prompt "A bird on the desert" -OutFile C:\edit2.png
```

|Source (sand_with_feather.png)|Mask (fether_mask.png)|Generated (edit2.png)|
|----|----|----|
| ![masked](/Docs/images/sand_with_feather.png) | ![mask](/Docs/images/fether_mask.png) | ![restored](/Docs/images/edit2.png)   |



## PARAMETERS

### -Image
(Required)
The image to edit.  
Must be a valid PNG file, less than 4MB, and square.
If mask is not provided, image must have transparency, which will be used as the mask.

```yaml
Type: String
Aliases: File
Required: True
Position: Named
```

### -Prompt
(Required)
A text description of the desired image(s).  
The maximum length is 1000 characters.

```yaml
Type: String
Required: True
Position: Named
```

### -Mask
An additional image whose fully transparent areas (e.g.
where alpha is zero) indicate where image should be edited.  
Must be a valid PNG file, less than 4MB, and have the same dimensions as image.

```yaml
Type: String
Required: False
Position: Named
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

[https://platform.openai.com/docs/api-reference/images/create-edit](https://platform.openai.com/docs/api-reference/images/create-edit)

