---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Request-ContentProvenanceCheck.md
schema: 2.0.0
---

# Request-ContentProvenanceCheck

## SYNOPSIS
Check an image or audio file for supported OpenAI provenance signals.

## SYNTAX

```
Request-ContentProvenanceCheck
    [-File] <String>
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [<CommonParameters>]
```

## DESCRIPTION
Check an image or audio file for supported OpenAI provenance signals.

## EXAMPLES

### Example 1
```powershell
PS C:\> Request-ContentProvenanceCheck -File 'C:\Images\sample.png'
```
Returns the provenance check and its results.

## PARAMETERS

### -File
Path to the image or audio file to check. Relative paths and pipeline input are supported.

```yaml
Type: String
Required: True
Position: 0
Accept pipeline input: True (ByValue)
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

```yaml
Type: Int32
Required: False
Position: Named
Default value: 0
```

### -ApiBase
Specifies an API endpoint URL such as: `https://your-api-endpoint.test/v1`  
If not specified, it will use `https://api.openai.com/v1`.

```yaml
Type: System.Uri
Required: False
Position: Named
Default value: https://api.openai.com/v1
```

### -ApiKey
Specifies API key for authentication.  
The type of data should be `[string]` or `[securestring]`.  
If not specified, it will try to use `$global:OPENAI_API_KEY` or `$env:OPENAI_API_KEY`.

```yaml
Type: SecureString
Required: False
Position: Named
```


## INPUTS

### System.String

## OUTPUTS

### PSCustomObject

A PSOpenAI.ContentProvenanceCheck object containing created_at (local DateTime), object, and results. Nested result fields are preserved from the API.

## NOTES

Uploads the file as multipart/form-data to POST /v1/content_provenance_checks. Image results include C2PA and SynthID; audio results include SynthID.

A not_detected outcome does not establish that the content is human-created. Signals may be missing or degraded, and other companies' models are not detected.

This endpoint is provided by OpenAI; Azure OpenAI is not supported.

## RELATED LINKS

[https://developers.openai.com/api/reference/resources/content_provenance_checks/methods/create/](https://developers.openai.com/api/reference/resources/content_provenance_checks/methods/create/)
