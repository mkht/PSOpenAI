using namespace System.Management.Automation

function New-ChatCompletionFunctionFromHashTable {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [ValidatePattern('^[a-zA-Z0-9_-]{1,64}$')]
        [string]$Name,

        [Parameter()]
        [string]$Description,

        [Parameter()]
        [System.Collections.IDictionary]$ParametersHashTable,

        [Parameter(DontShow)]
        [string]$ParametersType = 'object'
    )

    $object = [ordered]@{
        name = $Name
    }

    if ($Description) {
        $object.Add('description', $Description)
    }
    if ($ParametersHashTable) {
        $p = [ordered]@{
            type = $TargetParametersType
        }
        $p.Add('properties', $ParametersHashTable)
        $object.Add('parameters', $p)
    }

    $object
}

function New-ChatCompletionFunctionFromPSCommand {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0)]
        [ValidateScript({ (Get-Command $_ -ea Ignore) -is [CommandInfo] })]
        [string]$Command,

        [Parameter()]
        [string]$Description,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]$IncludeParameters,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string[]]$ExcludeParameters,

        [Parameter()]
        [string]$ParameterSetName
    )

    $FunctionDefinition = [ordered]@{}
    $MandatoryParams = [System.Collections.Generic.List[string]]::new()
    $ExcludeParamNames = ([Cmdlet]::CommonParameters + [Cmdlet]::OptionalCommonParameters + $ExcludeParameters)

    $CommandInfo = Get-Command $Command
    if ($null -eq $CommandInfo) {
        return
    }
    if ($CommandInfo -is [AliasInfo]) {
        $CommandInfo = $CommandInfo.ResolvedCommand
    }
    if ($CommandInfo -isnot [CmdletInfo] -and $CommandInfo -isnot [FunctionInfo]) {
        Write-Error "$Command is not a PowerShell command."
        return
    }

    $CommandHelp = Get-Help $CommandInfo -ErrorAction Ignore

    if ($ParameterSetName) {
        $TargetParameterSet = $CommandInfo.ParameterSets | ? { $_.Name -eq $ParameterSetName }
        if (-not $TargetParameterSet) {
            Write-Error "$ParameterSetName does not exist."
            return
        }
    }
    else {
        $TargetParameterSet = $CommandInfo.ParameterSets | ? { $_.IsDefault }
        if (-not $TargetParameterSet) {
            $TargetParameterSet = $CommandInfo.ParameterSets[0]
        }
    }

    $TargetParameters = $TargetParameterSet.Parameters | ? { $_.Name -notin $ExcludeParamNames }
    if ($IncludeParameters.Count -gt 0) {
        $TargetParameters = $TargetParameters | ? { $_.Name -in $IncludeParameters }
    }

    $FunctionDefinition.Add('name', $CommandInfo.Name)
    if ($Description) {
        $FunctionDefinition.Add('description', $Description)
    }
    elseif ($CommandHelp.description) {
        $FunctionDefinition.Add('description', (($CommandHelp.description.text -join "`n") -replace "`r", ''))
    }
    elseif ($CommandHelp.Synopsis) {
        $FunctionDefinition.Add('description', ($CommandHelp.Synopsis -replace "`r", ''))
    }

    $paramHash = [ordered]@{type = 'object' }
    $props = [ordered]@{}
    foreach ($param in $TargetParameters) {
        $isHiddenParam = $false
        $pName = $param.Name
        if ($param.IsMandatory) {
            $MandatoryParams.Add($pName)
        }

        $propHash = ParseParameterType($param.ParameterType)

        $helpmsg = (($CommandHelp.parameters.parameter | ? { $_.name -eq $pName }).description.text -join "`n") -replace "`r", ''
        if ([string]::IsNullOrWhiteSpace($helpmsg)) {
            $helpmsg = [string]$param.HelpMessage
        }
        if (-not [string]::IsNullOrWhiteSpace($helpmsg)) {
            $propHash.Add('description', $helpmsg)
        }

        foreach ($attr in $param.Attributes) {
            if ($attr -is [Parameter] -and $attr.DontShow) {
                $isHiddenParam = $true
            }
            elseif ($attr -is [ValidatePattern]) {
                if ($attr.RegexPattern) { $propHash.pattern = $attr.RegexPattern }
            }
            elseif ($attr -is [ValidateCount]) {
                $propHash.minItems = $attr.MinLength
                $propHash.maxItems = $attr.MaxLength
            }
            elseif ($attr -is [ValidateLength]) {
                $propHash.minLength = $attr.MinLength
                $propHash.maxLength = $attr.MaxLength
            }
            elseif ($attr -is [ValidateRange]) {
                if ($null -ne $attr.MinRange) { $propHash.minimum = $attr.MinRange }
                if ($null -ne $attr.MaxRange) { $propHash.maximum = $attr.MaxRange }
            }
            elseif ($attr -is [ValidateSet]) {
                $propHash.enum = $attr.ValidValues
            }
        }

        if (-not $isHiddenParam) {
            $props.Add($pName, $propHash)
        }
    }
    $paramHash.Add('properties', $props)
    if ($MandatoryParams.Count -gt 0) {
        $paramHash.Add('required', $MandatoryParams.ToArray())
    }
    $FunctionDefinition.Add('parameters', $paramHash)

    $FunctionDefinition
}


function ParseParameterType {
    param (
        [System.Reflection.TypeInfo]$ParameterType
    )

    if ($null -eq $ParameterType) {
        return
    }

    if ($ParameterType.IsArray) {
        $p = @{
            type = 'array'
        }
        $type = ($ParameterType.FullName -replace '\[\]', '') -as [type]
        if ($type) {
            $p.items = ParseParameterType($type)
        }
        $p
    }
    elseif ($ParameterType -in ([bool], [switch])) {
        @{
            type = 'boolean'
        }
    }
    elseif ($ParameterType -in ([int32], [int64], [int16], [bigint])) {
        @{
            type = 'integer'
        }
    }
    elseif ($ParameterType -in ([uint32], [uint64], [uint16])) {
        @{
            type    = 'integer'
            minimum = 0
        }
    }
    elseif ($ParameterType -in ([byte])) {
        @{
            type    = 'integer'
            minimum = 0
            maximum = 255
        }
    }
    elseif ($ParameterType -in ([Single], [double], [decimal])) {
        @{
            type = 'number'
        }
    }
    elseif ($ParameterType -is [string]) {
        @{
            type = 'string'
        }
    }
    elseif ($ParameterType.IsEnum) {
        @{
            type = 'string'
            enum = [string[]][enum]::GetValues($ParameterType)
        }
    }
    elseif ($ParameterType -is [datetime]) {
        @{
            type   = 'string'
            format = 'date-time'
        }
    }
    elseif ($ParameterType -is [regex]) {
        @{
            type   = 'string'
            format = 'regex'
        }
    }
    elseif ($ParameterType -is [uri]) {
        @{
            type   = 'string'
            format = 'uri'
        }
    }
    elseif ($ParameterType -is [guid]) {
        @{
            type   = 'string'
            format = 'uuid'
        }
    }
    elseif ($ParameterType -is [mailaddress]) {
        @{
            type   = 'string'
            format = 'email'
        }
    }
    elseif ($ParameterType.ImplementedInterfaces -contains [System.Collections.IDictionary]) {
        @{
            type = 'object'
        }
    }
    elseif ($ParameterType -is [System.Collections.IDictionary]) {
        @{
            type = 'object'
        }
    }
    else {
        @{
            type = 'string'
        }
    }
}