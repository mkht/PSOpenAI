---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Get-CosineSimilarity.md
schema: 2.0.0
---

# Get-CosineSimilarity

## SYNOPSIS
Calculate cosine similarity between two vectors.

## SYNTAX

```
Get-CosineSimilarity
    [-Vector1] <Double[]>
    [-Vector2] <Double[]>
    [<CommonParameters>]
```

## DESCRIPTION
Calculate cosine similarity between two vectors.

## EXAMPLES

### Example 1
```powershell
PS C:\> $v1 = (-0.01302161, -0.01999075, 0.007301898)
PS C:\> $v2 = (0.01506045, -0.04311577, 0.01272033)
PS C:\> Get-CosineSimilarity $v1 $v2
0.00144161334877118
```

## PARAMETERS

### -Vector1
First vector

```yaml
Type: Double[]
Required: True
Position: 0
```

### -Vector2
Second vector. The dimension is must same as first vector.

```yaml
Type: Double[]
Required: True
Position: 1
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

## OUTPUTS

### System.Double

## NOTES

## RELATED LINKS
