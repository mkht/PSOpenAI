function _TreatJsonSchemaObjectProprs {
    param(
        [Object]$SchemaObj,
        [bool]$RemoveUnsupportedKeyWords = $true
    )
    # Probably, there is more polished methods. (ISchemaProcessor?)

    # https://platform.openai.com/docs/guides/structured-outputs/some-type-specific-keywords-are-not-yet-supported
    $UnsupportedKeyWords = @(
        'minLength', 'maxLength', 'pattern', 'format',
        'minimum', 'maximum', 'multipleOf',
        'patternProperties', 'unevaluatedProperties', 'propertyNames', 'minProperties', 'maxProperties',
        'unevaluatedItems', 'contains', 'minContains', 'maxContains', 'minItems', 'maxItems', 'uniqueItems', 'maxContains', 'maxContains', 'maxContains'
    )

    try {
        $SchemaObj.PSObject.Properties.Remove('$schema')
        $SchemaObj.PSObject.Properties.Remove('title')
    }
    catch {}

    if ($SchemaObj.properties) {
        $props = [string[]]($SchemaObj.properties | Get-Member -MemberType NoteProperty).Name
        $SchemaObj | Add-Member -MemberType NoteProperty -Name 'required' -Value $props -Force

        if ($RemoveUnsupportedKeyWords) {
            foreach ($p in $props) {
                $UnsupportedKeyWords.ForEach({
                        $SchemaObj.properties.$p.PSObject.Properties.Remove($_)
                    })
            }
        }
    }

    if ($SchemaObj.Definitions) {
        foreach ($def in ($SchemaObj.Definitions | Get-Member -MemberType NoteProperty).Name) {
            _TreatJsonSchemaObjectProprs -SchemaObj $SchemaObj.Definitions.$def
        }
    }
}

function ConvertTo-JsonSchema {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [type]$Type
    )

    begin {
        if (-not ('NJsonSchema.JsonSchema' -as [type])) {
            $LibsPath = Join-Path $PSScriptRoot '..\Libs\NJsonSchema\netstandard2.0'
            if (-not ('Newtonsoft.Json.Schema.JsonSchema' -as [type])) {
                Add-Type -Path (Join-Path $LibsPath 'Newtonsoft.Json.dll')
            }
            Add-Type -Path (Join-Path $LibsPath 'Namotion.Reflection.dll')
            Add-Type -Path (Join-Path $LibsPath 'NJsonSchema.dll')
        }

        $setting = [NJsonSchema.Generation.JsonSchemaGeneratorSettings]::new()
        $setting.DefaultEnumHandling = [NJsonSchema.Generation.EnumHandling]::String
        $generator = [NJsonSchema.Generation.JsonSchemaGenerator]::new($setting)
    }

    process {
        $typeSchemaRef = $generator.Generate($Type)
        $typeSchemaObj = $typeSchemaRef.ToJson() | ConvertFrom-Json
        _TreatJsonSchemaObjectProprs -SchemaObj $typeSchemaObj -RemoveUnsupportedKeyWords $true
        $typeSchemaObj
    }

    end {
    }
}
