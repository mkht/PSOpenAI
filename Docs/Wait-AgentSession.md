---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/v5/Docs/Wait-AgentSession.md
schema: 2.0.0
---

# Wait-AgentSession

## SYNOPSIS
Waits for an agent session to reach a selected status.

## SYNTAX

### SessionId (Default)
```
Wait-AgentSession [-SessionId] <String> [[-PollIntervalSec] <Single>] [[-StatusForWait] <String[]>]
 [[-StatusForExit] <String[]>] [[-TimeoutSec] <Int32>] [[-MaxRetryCount] <Int32>] [[-ApiType] <OpenAIApiType>]
 [[-ApiBase] <Uri>] [[-ApiVersion] <String>] [[-AuthType] <String>] [[-ApiKey] <SecureString>]
 [[-Organization] <String>] [[-AdditionalQuery] <IDictionary>] [[-AdditionalHeaders] <IDictionary>]
 [[-AdditionalBody] <Object>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

### Session
```
Wait-AgentSession [-Session] <PSObject> [[-PollIntervalSec] <Single>] [[-StatusForWait] <String[]>]
 [[-StatusForExit] <String[]>] [[-TimeoutSec] <Int32>] [[-MaxRetryCount] <Int32>] [[-ApiType] <OpenAIApiType>]
 [[-ApiBase] <Uri>] [[-ApiVersion] <String>] [[-AuthType] <String>] [[-ApiKey] <SecureString>]
 [[-Organization] <String>] [[-AdditionalQuery] <IDictionary>] [[-AdditionalHeaders] <IDictionary>]
 [[-AdditionalBody] <Object>] [-ProgressAction <ActionPreference>] [<CommonParameters>]
```

## DESCRIPTION
Polls an agent session while its status matches `-StatusForWait` and returns the latest session object when its status matches `-StatusForExit`. The command throws when the timeout expires or an unexpected status is returned.

## EXAMPLES

### Example 1
```powershell
$Session | Wait-AgentSession -TimeoutSec 120
```

Waits up to 120 seconds for the session to become idle, require an action, or fail.

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
The base URI of the OpenAI API.

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
The API key used to authenticate the request.

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

### -ApiVersion
The API version query value when required by a compatible endpoint.

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

### -AuthType
The authentication scheme used for the API request.

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

### -PollIntervalSec
The number of seconds between status requests.

```yaml
Type: Single
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

### -Session
An agent session object returned by an Agents API command.

```yaml
Type: PSObject
Parameter Sets: Session
Aliases:

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -SessionId
The ID of the agent session.

```yaml
Type: String
Parameter Sets: SessionId
Aliases: session_id, Id

Required: True
Position: 0
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -StatusForExit
Session statuses that cause the command to return the current session.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:
Accepted values: idle, in_progress, requires_action, failed

Required: False
Position: Named
Default value: idle, requires_action, failed
Accept pipeline input: False
Accept wildcard characters: False
```

### -StatusForWait
Session statuses for which the command continues polling.

```yaml
Type: String[]
Parameter Sets: (All)
Aliases:
Accepted values: idle, in_progress, requires_action, failed

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -TimeoutSec
The maximum number of seconds to wait. Specify 0 to wait without a time limit.

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

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Management.Automation.PSObject

### System.String

## OUTPUTS

### System.Management.Automation.PSObject

## NOTES

## RELATED LINKS
