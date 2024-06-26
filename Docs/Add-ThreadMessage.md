---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Add-ThreadMessage.md
schema: 2.0.0
---

# Add-ThreadMessage

## SYNOPSIS
Add a message to the Thread.

## SYNTAX

```
Add-ThreadMessage
    -ThreadId <String>
    [-Message] <String>
    [-Images <Object[]>]
    [-ImageDetail <String>]
    [-Role <String>]
    [-FileIdsForCodeInterpreter <String[]>]
    [-FileIdsForFileSearch <String[]>]
    [-MetaData <IDictionary>]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>]
    [-ApiKey <SecureString>]
    [-Organization <String>]
    [-PassThru]
    [-WaitForRunComplete]
    [<CommonParameters>]
```

## DESCRIPTION
Add a message to the Thread. The message is usually a question to ask the Assistant.

## EXAMPLES

### Example 1
```powershell
PS C:\> Add-ThreadMessage -ThreadId "thread_abc1234" -Message "How many people lives in the world?"
```

Add a message to the Thread whose ID is `thread_abc1234``. This cmdlet outputs nothing by default.

### Example 2
```powershell
PS C:\> $Thread = New-Thread | Add-ThreadMessage -Message "Think of ideas for my friend's wedding gift." -PassThru
```

Creates a new Thread and adds a message. When the `-PassThru` switch is specified, this cmdlet returns a Thread object with the message added.

## PARAMETERS

### -ThreadId
Specifies an ID of Thread.

```yaml
Type: String
Aliases: thread_id
Required: True
Position: Named
Accept pipeline input: True (ByPropertyName, ByValue)
```

### -Message
The content of the message.  

```yaml
Type: String
Aliases: Content, Text
Required: True
Position: 0
```

### -Images
An array of images for reference to vision-compatible models. You can specify uploaded file id or URL of image.

```yaml
Type: Object[]
Required: False
Position: Named
```

### -ImageDetail
Specifies the detail level of the image if specified by the user. "low" uses fewer tokens, you can opt in to high resolution using "high".

```yaml
Type: String
Required: False
Position: Named
Default value: auto
```

### -Role
The role of the entity that is creating the message. One of `user` or `assistant`

```yaml
Type: String
Required: False
Position: Named
Default value: user
```

### -FileIdsForCodeInterpreter
A list of file IDs made available to the code_interpreter tool. There can be a maximum of 20 files associated with the tool.

```yaml
Type: String[]
Required: False
Position: Named
```

### -FileIdsForFileSearch
A list of file IDs to add to the vector store. There can be a maximum of 10000 files in a vector store.

```yaml
Type: String[]
Required: False
Position: Named
```

### -MetaData
Set of 16 key-value pairs that can be attached to an object. This can be useful for storing additional information about the object in a structured format.

```yaml
Type: IDictionary
Required: False
Position: Named
```

### -PassThru
Returns a Thread object that the message added. By default, this cmdlet doesn't generate any output.

```yaml
Type: SwitchParameter
Required: False
Position: Named
```

### -WaitForRunComplete
This switch parameter, when used, ensures that the cmdlet waits for any active run on the thread to complete before attempting to add a new message. This can help prevent errors that occur when trying to add messages to a thread while a run is still active.
This parameter is optional. If not provided, the cmdlet will attempt to add a message to the thread immediately, regardless of whether a run is active or not.

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

## NOTES

## RELATED LINKS

[https://platform.openai.com/docs/api-reference/messages/createMessage](https://platform.openai.com/docs/api-reference/messages/createMessage)
