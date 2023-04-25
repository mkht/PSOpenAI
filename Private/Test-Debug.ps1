using namespace System.Management.Automation

function Test-Debug {
    [CmdletBinding()]
    [OutputType([bool])]
    param ()

    return [bool](
        $DebugPreference -in (
            [ActionPreference]::Continue,
            [ActionPreference]::Inquire,
            [ActionPreference]::Break,
            [ActionPreference]::Stop
        )
    )
}
