function Invoke-ChatCompletionFunction {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter()]
        [object]$Arguments,

        [Parameter()]
        [ValidateSet('None', 'Auto', 'Confirm')]
        [string]$InvokeFunctionOnCallMode = 'Confirm'
    )

    if ($InvokeFunctionOnCallMode -eq 'None') {
        return
    }

    $fCommandResult = $null
    $fCommandInfo = Get-Command -Name $Name
    $fArguments = ConvertFrom-Json $Arguments | ObjectToHashTable
    $argmsg = foreach ($item in $fArguments.GetEnumerator()) {
        ('{0} = {1}' -f $item.Key, $item.Value)
    }
    $CommandQueryMessage = "Function: $Name / Arguments: @{$(($argmsg -join '; '))}"
    if ($fCommandInfo.CommandType -in ('Cmdlet', 'Function', 'Alias')) {
        $canInvoke =
        if ($InvokeFunctionOnCallMode -eq 'Confirm') {
            $PSCmdlet.ShouldContinue($CommandQueryMessage, 'This command will be executed. Do you want to grant it?')
        }
        else {
            $InvokeFunctionOnCallMode -eq 'Auto'
        }

        if (-not $canInvoke) {
            return
        }
        else {
            Write-Verbose "Execute command: $CommandQueryMessage"
            $fCommandResult = & $fCommandInfo.Name @fArguments
        }
    }
    else {
        $ex = [System.NotSupportedException]::new(('The type of {0} command is {1}. Can not execute it.' -f $fCall.name, $fCommandInfo.CommandType))
        $er = [System.Management.Automation.ErrorRecord]::new($ex, 'UnsupportedCommandType', [System.Management.Automation.ErrorCategory]::InvalidOperation, $null)
        $PSCmdlet.ThrowTerminatingError($er)
        return
    }

    if ($null -eq $fCommandResult -or $fCommandResult.Count -eq 0) {
        $fCommandResult = if ($?) { '[SUCCEEDED]' }else { '[FAILED]' }
    }

    ObjectToContent -InputObject $fCommandResult
}
