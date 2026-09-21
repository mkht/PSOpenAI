---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/v5/Docs/Get-AgentSessionArtifactContent.md
schema: 2.0.0
---

# Get-AgentSessionArtifactContent

## SYNOPSIS
Downloads the binary content of a session artifact.

## SYNTAX

```
Get-AgentSessionArtifactContent [-SessionId] <String> [-ArtifactId] <String> [[-OutFile] <String>]
 [[-TimeoutSec] <Int32>] [[-MaxRetryCount] <Int32>] [[-ApiType] <OpenAIApiType>] [[-ApiBase] <Uri>]
 [[-AuthType] <String>] [[-ApiKey] <SecureString>] [[-Organization] <String>]
 [[-AdditionalQuery] <IDictionary>] [[-AdditionalHeaders] <IDictionary>] [-ProgressAction <ActionPreference>]
 [<CommonParameters>]
```

## DESCRIPTION
Downloads the binary content of a session artifact. This command uses the OpenAI Agents API public beta and sends the required `OpenAI-Beta: agents=v1` header. Nested, evolving request schemas are accepted through `-Body` where applicable.

## EXAMPLES

### Example 1
```powershell
Get-AgentSessionArtifactContent -SessionId 'session_123' -ArtifactId 'artifact_123' -OutFile './artifact.bin'
```

Downloads an immutable session artifact.

## PARAMETERS

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

### -ArtifactId
The session artifact ID.

```yaml
Type: String
Parameter Sets: (All)
Aliases: artifact_id

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
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

### -OutFile
The local path where downloaded artifact content is saved.

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
