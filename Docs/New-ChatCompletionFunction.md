---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/New-ChatCompletionFunction.md
schema: 2.0.0
---

# New-ChatCompletionFunction

## SYNOPSIS
Generate function spcifications for ChatGPT Function Call from PowerShell commands

## SYNTAX

```
New-ChatCompletionFunction
    [-Command] <String>
    [-Description <String>]
    [-IncludeParameters <String[]>]
    [-ExcludeParameters <String[]>]
    [-ParameterSetName <String>]
    [<CommonParameters>]
```

## DESCRIPTION
Generate function spcifications for ChatGPT Function Call from PowerShell commands  
The generated function spcification is a hash table that can be converted to a JSON string following JSON Schema.  
https://platform.openai.com/docs/guides/gpt/function-calling

## EXAMPLES

### Example 1
```powershell
PS C:\> New-ChatCompletionFunction -Command "New-Item"
```

Generates a function definition for the `New-Item` command.

### Example 2
```powershell
PS C:\> New-ChatCompletionFunction -Command "Test-Connection" -IncludeParameters ('TargetName', 'Count', 'Delay')
```

Generate a function spcification for the `Test-Connection` command. Only three parameters are included in the function definition: `TargetName`, `Count`, and `Delay`.

### Example 3
```powershell
PS C:\> New-ChatCompletionFunction -Command "Test-NetConnection" -ParameterSetName "RemotePort" -Description "This command tests TCP connectivity of the specified hosts or address and displays the results."
```

Generate a function definition for the `Test-NetConnection` command. Explicitly specifies the parameter set name and command description.

## PARAMETERS

### -Command
Specify the name of the PowerShell command.

```yaml
Type: String
Required: True
Position: 0
```

### -Description
Specifies the descriptive text of the PowerShell command. If not specified, the command help description will be used.

```yaml
Type: String
Required: False
Position: Named
```

### -ExcludeParameters
Names of parameters that should not be included in the function definition.

```yaml
Type: String[]
Required: False
Position: Named
```

### -IncludeParameters
Name of the parameter to be included in the function definition. If this parameter is specified, any unspecified parameters will not be included in the function definition.

```yaml
Type: String[]
Required: False
Position: Named
```

### -ParameterSetName
If a PowerShell command has multiple parameter sets, the default parameter set is selected by default.  
If you want to use a non-default parameter set, specify the set name in this parameter.

```yaml
Type: String
Required: False
Position: Named
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### None

## OUTPUTS

### System.Collections.Specialized.OrderedDictionary

## NOTES

## RELATED LINKS

[https://platform.openai.com/docs/guides/gpt/function-calling](https://platform.openai.com/docs/guides/gpt/function-calling)
