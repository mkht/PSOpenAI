---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Add-ConversationItem.md
schema: 2.0.0
---

# Add-ConversationItem

## SYNOPSIS
Adds a message to a Conversation.

## SYNTAX

```
Add-ConversationItem
    -ConversationId <String>
    [-Message <String>]
    [-Role <String>]
    [-SystemMessage <String[]>]
    [-DeveloperMessage <String[]>]
    [-Images <String[]>]
    [-ImageDetail <String>]
    [-Files <String[]>]
    [-Include <String[]>]
    [-PassThru]
    [-TimeoutSec <Int32>]
    [-MaxRetryCount <Int32>]
    [-ApiBase <Uri>] 
    [-ApiKey <SecureString>]
    [<CommonParameters>]
```

## DESCRIPTION
Adds a message, file, image, or other content to a Conversation.  
Typically used to add user messages to a conversation.

## EXAMPLES

### Example 1
```powershell
PS C:\> Add-ConversationItem -ConversationId "conv_abc1234" -Message "Hello, what's the weather today?"
```
Adds a message to the specified Conversation. No output by default.

### Example 2
```powershell
PS C:\> Add-ConversationItem -ConversationId "conv_abc1234" -Message "Please analyze this image" -Images "C:\images\sample.png"
```
Adds a message with an attached image file.

### Example 3
```powershell
PS C:\> Add-ConversationItem -ConversationId "conv_abc1234" -Message "Please check the file" -Files "C:\docs\sample.pdf" -PassThru
```
Adds a message with an attached file and returns the Conversation object when PassThru is specified.

## PARAMETERS

### -ConversationId
The ID of the conversation to add the item to.

```yaml
Type: String
Aliases: Conversation, conversation_id
Required: True
Position: Named
Accept pipeline input: True (ByPropertyName, ByValue)
```

### -Message
The content of the user message to add.

```yaml
Type: String
Required: False
Position: 0
```

### -Role
Specifies the role of the message. One of `user`, `system`, `developer`, or `assistant`.

```yaml
Type: String
Required: False
Position: Named
Default value: user
```

### -SystemMessage
Specifies one or more system messages.

```yaml
Type: String[]
Aliases: system
Required: False
Position: Named
```

### -DeveloperMessage
Specifies one or more developer messages.

```yaml
Type: String[]
Required: False
Position: Named
```

### -Images
Specifies the path, URL, or file ID of image files to attach.

```yaml
Type: String[]
Required: False
Position: Named
```

### -ImageDetail
Specifies the detail level of the image. One of `auto`, `low`, or `high`.

```yaml
Type: String
Required: False
Position: Named
Default value: auto
```

### -Files
Specifies the path, URL, or file ID of files to attach.

```yaml
Type: String[]
Required: False
Position: Named
```

### -Include
Additional fields to include in the response.

```yaml
Type: String[]
Required: False
Position: Named
```

### -TimeoutSec
Specifies the request timeout in seconds. 0 means unlimited.

```yaml
Type: Int32
Required: False
Position: Named
Default value: 0
```

### -MaxRetryCount
Number between 0 and 100. Specifies the maximum number of retries for 429/5xx errors.

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
Specifies the organization ID.

```yaml
Type: String
Aliases: OrgId
Required: False
Position: Named
```

### -PassThru
When specified, returns the Conversation object after adding the message.

```yaml
Type: SwitchParameter
Required: False
Position: Named
```

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[https://platform.openai.com/docs/api-reference/conversations/create-items](https://platform.openai.com/docs/api-reference/conversations/create-items)
