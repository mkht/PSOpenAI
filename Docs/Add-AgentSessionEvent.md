---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/v5/Docs/Add-AgentSessionEvent.md
schema: 2.0.0
---

# Add-AgentSessionEvent

## SYNOPSIS
Adds one or more input events to an agent session.

## SYNTAX

```
Add-AgentSessionEvent [-SessionId] <String> [-Event] <Object[]> [[-IdempotencyKey] <String>]
 [[-TimeoutSec] <Int32>] [[-MaxRetryCount] <Int32>] [[-ApiType] <OpenAIApiType>] [[-ApiBase] <Uri>]
 [[-AuthType] <String>] [[-ApiKey] <SecureString>] [[-Organization] <String>]
 [[-AdditionalQuery] <IDictionary>] [[-AdditionalHeaders] <IDictionary>] [[-AdditionalBody] <Object>]
 [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Adds one or more input events to an agent session. This command uses the OpenAI Agents API public beta and sends the required `OpenAI-Beta: agents=v1` header. Nested, evolving request schemas are accepted through `-Body` where applicable.

## EXAMPLES

### Example 1
```powershell
Add-AgentSessionEvent -SessionId 'session_123' -Event @{ type = 'message'; role = 'user'; content = @(@{ type = 'input_text'; text = 'Continue.' }) }
```

Submits a user input event to an existing session.

## PARAMETERS

### -AdditionalBody
Additional JSON properties to merge into the request body.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AdditionalHeaders
Additional HTTP headers to include in the request.

```yaml
Type: IDictionary
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AdditionalQuery
Additional query parameters to include in the request.

```yaml
Type: IDictionary
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ApiBase
The base URI for the OpenAI API.

```yaml
Type: Uri
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ApiKey
The OpenAI API key as a secure string.

```yaml
Type: SecureString
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ApiType
The API provider. Agents API commands support OpenAI only.

```yaml
Type: OpenAIApiType
Parameter Sets: (All)
Aliases:
Accepted values: OpenAI, Azure

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AuthType
The authentication type. Use openai for the Agents API.

```yaml
Type: String
Parameter Sets: (All)
Aliases:
Accepted values: openai, azure, azure_ad

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Event
One or more input event objects to submit to the session.

```yaml
Type: Object[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IdempotencyKey
An idempotency key sent in the Idempotency-Key request header.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -MaxRetryCount
The maximum number of retries for transient API failures.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Organization
The OpenAI organization ID.

```yaml
Type: String
Parameter Sets: (All)
Aliases: OrgId

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SessionId
The managed agent session ID.

```yaml
Type: String
Parameter Sets: (All)
Aliases: session_id

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TimeoutSec
The request timeout in seconds. Zero uses the module default.

```yaml
Type: Int32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -ProgressAction
Controls how PowerShell responds to progress updates.

```yaml
Type: ActionPreference
Parameter Sets: (All)
Aliases: proga

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS

[OpenAI Agents API](https://developers.openai.com/api/reference/typescript/resources/beta/subresources/agents)
