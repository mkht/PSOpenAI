---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/ConvertFrom-Token.md
schema: 2.0.0
---

# ConvertFrom-Token

## SYNOPSIS
Decode tokens to original text.

## SYNTAX

### encoding (Default)
```
ConvertFrom-Token
    [-Token] <Int32[]>
    [[-Encoding] <String>]
    [-AsArray]
    [<CommonParameters>]
```

### model
```
ConvertFrom-Token
    [-Token] <Int32[]>
    [-Model] <String>
    [-AsArray]
    [<CommonParameters>]
```

## DESCRIPTION
Decode tokens to original text.

## EXAMPLES

### Example 1
```powershell
$Tokens = (9906, 11, 1917, 0)
ConvertFrom-Token -Token $Tokens -Model 'gpt-4'
# Output: Hello, world!
```

### Example 2
```powershell
(102415, 230, 102415, 240, 102415, 239) | ConvertFrom-Token -Encoding 'o200k_base'
# Output: 🍈🍒🍑
```

## PARAMETERS
### -Token
Specifies the token array to be decoded.

```yaml
Type: Int32[]
Parameter Sets: (All)
Required: True
Position: 0
Accept pipeline input: True (ByValue)
```

### -Encoding
Specifies the encoding name. Currently `cl100k_base` and `o200k_base` are supported.  
It cannot be specified with the model name.

```yaml
Type: String
Parameter Sets: encoding
Accepted values: cl100k_base, o200k_base
Required: False
Position: 1
Default value: cl100k_base
```

### -Model
Specifies the model name. such like `gpt-4` or `text-embedding-3-small`.  
It cannot be specified with the encoding name.

```yaml
Type: String
Parameter Sets: model
Required: True
Position: 1
Default value: None
```

### -AsArray
If set, output as an array of strings decoded token by token.

```yaml
Type: SwitchParameter
Required: False
Position: Named
Default value: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.Int32[]

## OUTPUTS

### System.String

## NOTES

## RELATED LINKS
[https://github.com/openai/tiktoken](https://github.com/openai/tiktoken)
