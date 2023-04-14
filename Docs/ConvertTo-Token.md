---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/ConvertTo-Token.md
schema: 2.0.0
---

# ConvertTo-Token

## SYNOPSIS
BPE tokeniser for use with OpenAI's models.

## SYNTAX

### encoding (Default)
```
ConvertTo-Token
    [-Text] <String>
    [[-Encoding] <String>]
    [<CommonParameters>]
```

### model
```
ConvertTo-Token
    [-Text] <String>
    [-Model] <String>
    [<CommonParameters>]
```

## DESCRIPTION
Encode text to tokens for use with OpenAI's models. (tokenize)  
The output values are compatible with OpenAI tiktoken.


## EXAMPLES

### Example 1
```powershell
$Text = Hello, world!
ConvertTo-Token -Text $Text -Model 'gpt-4'
# Output: (9906, 11, 1917, 0)
```

### Example 2
```powershell
'🍈🍒🍑' | ConvertTo-Token -Encoding 'p50k_base'
# Output: (8582, 235, 230, 8582, 235, 240, 8582, 235, 239)
```

## PARAMETERS

### -Text
Specifies texts to be encoded.

```yaml
Type: String
Parameter Sets: (All)
Required: True
Position: 0
Accept pipeline input: True (ByValue)
```

### -Encoding
Specifies the encoding name. Accepted values are `cl100k_base`, `p50k_base`, `p50k_edit`, `r50k_base`, `gpt2`.  
It cannot be specified with the model name.

```yaml
Type: String
Parameter Sets: encoding
Accepted values: cl100k_base, p50k_base, p50k_edit, r50k_base, gpt2
Required: False
Position: 1
Default value: cl100k_base
```

### -Model
Specifies the model name. such like `gpt-4` or `text-davinci-003`.  
It cannot be specified with the encoding name.

```yaml
Type: String
Parameter Sets: model
Required: True
Position: 1
Default value: None
```


### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### System.String

## OUTPUTS

### System.Int32[]

## NOTES

## RELATED LINKS
[https://github.com/openai/tiktoken](https://github.com/openai/tiktoken)
