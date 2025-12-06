---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Request-ResponseCompaction.md
schema: 2.0.0
---

# Request-ResponseCompaction

## SYNOPSIS
Runs a compaction pass over a conversation. Compaction returns encrypted, opaque items and the underlying logic may evolve over time.

## SYNTAX

```
Request-ResponseCompaction
    [[-Message] <String>]
    [-Role <String>]
    [-Model <String>]
    [-SystemMessage <String[]>]
    [-DeveloperMessage <String[]>]
    [-Instructions <String>]
    [-Images <String[]>]
    [-ImageDetail <String>]
    [-Files <String[]>]
    [-PreviousResponseId <String>]
    [-OutputRawResponse]
    [-Organization <String>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [-History <Object[]>]
    [<CommonParameters>]
```

## DESCRIPTION
Runs a compaction pass over a conversation. Compaction returns encrypted, opaque items and the underlying logic may evolve over time.

## EXAMPLES

### Example
```powershell
PS C:\> $Response = Request-Response 'Tell me about traditional Japanese cuisine.' -Model 'gpt-5.1'
PS C:\> $CompactedRespomse = $Response | Request-ResponseCompaction -Model 'gpt-5.1'
```

## PARAMETERS

### -Message
A text input to the model.

```yaml
Type: String
Aliases: UserMessage, input
Required: False
Position: 0
```

### -Role
The role of the message input. One of `user`, `system`, or `developer`. The default is `user`.

```yaml
Type: String
Required: False
Position: Named
```

### -Model
The name of model to use. The default value is `gpt-4o-mini`.

```yaml
Type: String
Required: False
Position: Named
Accept pipeline input: True (ByPropertyName)
Default value: gpt-4o-mini
```

### -SystemMessage
(Instead of this parameter, the use of the `-Instructions` parameter is recommended.)  
Instructions that the model should follow.

```yaml
Type: String[]
Required: False
Position: Named
```

### -DeveloperMessage
(Instead of this parameter, the use of the `-Instructions` parameter is recommended.)  
Instructions that the model should follow.

```yaml
Type: String[]
Required: False
Position: Named
```

### -Instructions
A system (or developer) message inserted into the model's context.

```yaml
Type: String
Required: False
Position: Named
```

### -PreviousResponseId
The unique ID of the previous response to the model. Use this to create multi-turn conversations.

```yaml
Type: String
Aliases: previous_response_id
Required: False
Position: Named
Accept pipeline input: True (ByPropertyName)
```

### -Images
A list of images to passing the model. You can specify local image file or remote url.  

```yaml
Type: String[]
Required: False
Position: Named
```

### -ImageDetail
Controls how the model processes the image and generates its textual understanding. You can select from `Low` or `High`.  

```yaml
Type: String
Accepted values: auto, low, high
Required: False
Position: Named
Default value: auto
```

### -Files
A file input to the model.  
You can speciy a list of the local file path, the URL of the file or the ID of the file to be uploaded.

```yaml
Type: String[]
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

### -History
An object for keeping the conversation history.

```yaml
Type: Object[]
Required: False
Position: Named
Accept pipeline input: True (ByPropertyName)
```

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

## RELATED LINKS

https://platform.openai.com/docs/api-reference/responses/compact
