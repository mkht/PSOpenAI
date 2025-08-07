---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Get-Response.md
schema: 2.0.0
---

# Get-Response

## SYNOPSIS
Retrieves a model response with the given ID.

## SYNTAX

```
Get-Response
    [-ResponseId] <String>
    [-Include] <String[]>
    [-IncludeObfuscation <Boolean>]
    [-Stream]
    [-StreamOutputType <String>]
    [-StartingAfter <Int32>]
    [-OutputRawResponse]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [-Organization <String>]
    [<CommonParameters>]
```

## DESCRIPTION
Retrieves a model response with the given ID.

## EXAMPLES

### Example 1
```powershell
PS C:\> Get-Response -ResponseId "resp_abcd123"
```

Get a response with the specified ID.


## PARAMETERS

### -ResponseId
The ID of the response to retrieve.

```yaml
Type: String
Aliases: response_id, Id
Required: True
Position: 0
Accept pipeline input: True (ByPropertyName, ByValue)
```

### -Include
Specify additional output data to include in the model response.

```yaml
Type: String[]
Required: False
Position: Named
```

### -IncludeObfuscation
When true, stream obfuscation will be enabled. Stream obfuscation adds random characters to an obfuscation field on streaming delta events to normalize payload sizes as a mitigation to certain side-channel attacks.

```yaml
Type: Boolean
Aliases: include_obfuscation
Required: False
Position: Named
```

### -Stream
If set, the model response data will be streamed to the client.

```yaml
Type: SwitchParameter
Required: False
Position: Named
```

### -StreamOutputType
Specifying the format that the function output. This parameter is only valid for the stream output. This parameter is only valid for the stream output.
  - `text`   : Output only text deltas that the model generated. (Default)  
  - `object` : Output all events that the API respond.  

```yaml
Type: String
Accepted values: text, object
Required: False
Position: Named
Default value: text
```

### -StartingAfter
The sequence number of the event after which to start streaming. This parameter is only valid for the stream output.

```yaml
Type: Int32
Required: False
Position: Named
```

### -OutputRawResponse
If specifies this switch, an output of this function to be a raw response value from the API. (Normally JSON formatted string.)

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

### PSCustomObject

## NOTES

## RELATED LINKS

[https://platform.openai.com/docs/api-reference/responses/get](https://platform.openai.com/docs/api-reference/responses/get)
