---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/v5/Docs/Remove-AgentVaultCredential.md
schema: 2.0.0
---

# Remove-AgentVaultCredential

## SYNOPSIS
Deletes a credential from an agent vault.

## SYNTAX

```
Remove-AgentVaultCredential [-VaultId] <String> [-CredentialId] <String> [[-TimeoutSec] <Int32>]
 [[-MaxRetryCount] <Int32>] [[-ApiType] <OpenAIApiType>] [[-ApiBase] <Uri>] [[-AuthType] <String>]
 [[-ApiKey] <SecureString>] [[-Organization] <String>] [[-AdditionalQuery] <IDictionary>]
 [[-AdditionalHeaders] <IDictionary>] [[-AdditionalBody] <Object>] [-ProgressAction <ActionPreference>]
 [-WhatIf] [-Confirm] [<CommonParameters>]
```

## DESCRIPTION
Deletes a credential from an agent vault. This command uses the OpenAI Agents API public beta and sends the required `OpenAI-Beta: agents=v1` header. Nested, evolving request schemas are accepted through `-Body` where applicable.

## EXAMPLES

### Example 1
```powershell
Remove-AgentVaultCredential -VaultId 'vault_123' -CredentialId 'credential_123' -WhatIf
```

Shows what would happen when deleting the vault credential.

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

### -Confirm
Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CredentialId
The vault credential ID.

```yaml
Type: String
Parameter Sets: (All)
Aliases: credential_id

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
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

### -VaultId
The agent vault ID.

```yaml
Type: String
Parameter Sets: (All)
Aliases: vault_id

Required: True
Position: 0
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -WhatIf
Shows what would happen if the cmdlet runs. The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

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
