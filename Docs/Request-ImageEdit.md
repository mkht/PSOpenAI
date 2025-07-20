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
    -Image <String[]>
    -Prompt <String>
    [-Model <String>]
    [-Mask <String>]
    [-NumberOfImages <UInt16>]
    [-Size <String>]
    [-Quality <String>]
    [-ResponseFormat <String>]
    [-OutputRawResponse]
    [-User <String>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <Object>]
    [-Organization <String>]
    [<CommonParameters>]
```

```
Request-ImageEdit
    -Image <String[]>
    -Prompt <String>
    -OutFile <String>
    [-Model <String>]
    [-Mask <String>]
    [-NumberOfImages <UInt16>]
    [-Size <String>]
    [-Quality <String>]
    [-User <String>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <Object>]
    [<CommonParameters>]
```

## DESCRIPTION
Creates an edited or extended image given an original image and a prompt.  
https://platform.openai.com/docs/guides/image-generation

## EXAMPLES

### Example 1: Edit an image with a prompt.
```PowerShell
Request-ImageEdit -Model 'gpt-image-1' -Prompt 'A bird on the desert' -Image 'C:\sand_with_fether.png' -OutFile 'C:\bird_on_desert.png' -Size 1024x1024
```

| Original                                        | Generated                                  |
| ----------------------------------------------- | ------------------------------------------ |
| ![original](/Docs/images/sand_with_feather.png) | ![edited](/Docs/images/bird_on_desert.png) |


### Example 2: Create variation image from source and mask.
```PowerShell
Request-ImageEdit -Model 'gpt-image-1' -Image C:\sand_with_feather.png -Mask C:\fether_mask.png -Prompt "A bird on the desert" -OutFile C:\edit2.png
```

| Source (sand_with_feather.png)                | Mask (fether_mask.png)                | Generated (edit2.png)               |
| --------------------------------------------- | ------------------------------------- | ----------------------------------- |
| ![masked](/Docs/images/sand_with_feather.png) | ![mask](/Docs/images/fether_mask.png) | ![restored](/Docs/images/edit2.png) |



## PARAMETERS

### -Image
(Required)
The image(s) to edit. Must be a supported image file or an array of images. For gpt-image-1, each image should be a png, webp, or jpg file less than 25MB. For dall-e-2, you can only provide one image, and it should be a square png file less than 4MB.

```yaml
Type: String[]
Aliases: File
Required: True
Position: Named
```

### -Prompt
(Required)
A text description of the desired image(s). The maximum length is 1000 characters for dall-e-2, and 32000 characters for gpt-image-1.

```yaml
Type: String
Required: True
Position: Named
```

### -Mask
An additional image whose fully transparent areas (e.g. where alpha is zero) indicate where image should be edited. If there are multiple images provided, the mask will be applied on the first image. Must be a valid PNG file, less than 4MB, and have the same dimensions as image.

```yaml
Type: String
Required: False
Position: Named
```

### -Model
The model to use for image generation. Only dall-e-2 and gpt-image-1 are supported. Defaults to dall-e-2 unless a parameter specific to gpt-image-1 is used.

```yaml
Type: String
Required: False
Position: Named
```

### -NumberOfImages
The number of images to generate. Must be between 1 and 10.

```yaml
Type: UInt16
Aliases: n
Required: False
Position: Named
Default value: 1
```

### -Quality
The quality of the image that will be generated. high, medium and low are only supported for gpt-image-1. dall-e-2 only supports standard quality. Defaults to auto.

```yaml
Type: String
Required: False
Position: Named
Default value: auto
```

### -Size
The size of the generated images. Must be one of `1024x1024`, `1536x1024` (landscape), `1024x1536` (portrait), or `auto` (default value) for gpt-image-1, and one of `256x256`, `512x512`, or `1024x1024` for dall-e-2.

```yaml
Type: String
Required: False
Position: Named
Default value: auto
```

### -ResponseFormat
The format in which the generated images are returned. Must be one of `url`, `base64` or `byte`. gpt-image-1 only supports `base64`.

```yaml
Type: String
Parameter Sets: Format
Aliases: response_format
Required: False
Position: Named
Default value: base64
```

### -OutputRawResponse
If specifies this switch, an output of this function to be a raw response value from the API. (Normally JSON formatted string.)

```yaml
Type: SwitchParameter
Parameter Sets: Format
Required: False
Position: Named
```

### -OutFile
Specify the file path where the generated images will be saved. This cannot be specified with the `ResponseFormat` parameter.

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

## NOTES

## RELATED LINKS

[https://platform.openai.com/docs/guides/image-generation](https://platform.openai.com/docs/guides/image-generation)

[https://platform.openai.com/docs/api-reference/images/createEdit](https://platform.openai.com/docs/api-reference/images/createEdit)
