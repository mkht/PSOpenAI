function ParseThreadRunStepObject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [PSCustomObject]$InputObject,

        [Parameter()]
        [System.Collections.IDictionary]$CommonParams = @{},

        [Parameter()]
        [switch]$Primitive
    )

    $simplecontent = `
        if ($InputObject.type -eq 'message_creation') {
        if ($msgid = $InputObject.step_details.message_creation.message_id) {
            $GetThreadMessageParams = $CommonParams
            $GetThreadMessageParams.InputObject = $InputObject
            $GetThreadMessageParams.MessageId = $msgid
            $msg = PSOpenAI\Get-ThreadMessage @GetThreadMessageParams
            [PSCustomObject]@{
                Role    = $msg.role
                Type    = $msg.content.type
                Content = $msg.content.text.value
            }
        }
    }
    elseif ($InputObject.type -eq 'tool_calls') {
        foreach ($call in $InputObject.step_details.tool_calls) {
            if ($call.type -eq 'code_interpreter') {
                [PSCustomObject]@{
                    Role    = $InputObject.type
                    Type    = $call.type + '.input'
                    Content = $call.code_interpreter.input
                }
                foreach ($out in $call.code_interpreter.outputs) {
                    if ($out.type -eq 'logs') {
                        [PSCustomObject]@{
                            Role    = $InputObject.type
                            Type    = $call.type + '.output.logs'
                            Content = $out.logs
                        }
                    }
                    elseif ($out.type -eq 'image') {
                        [PSCustomObject]@{
                            Role    = $InputObject.type
                            Type    = $call.type + '.output.image'
                            Content = $out.image.file_id
                        }
                    }
                }
            }
            elseif ($call.type -eq 'retrieval') {
                [PSCustomObject]@{
                    Role    = $InputObject.type
                    Type    = $call.type
                    Content = $null
                }
            }
            elseif ($call.type -eq 'function') {
                [PSCustomObject]@{
                    Role    = $InputObject.type
                    Type    = $call.type
                    Content = $call.function.output
                }
            }
        }
    }

    # Add custom type name and properties to output object.
    $InputObject.PSObject.TypeNames.Insert(0, 'PSOpenAI.Thread.Run.Step')
      ('created_at', 'expired_at', 'cancelled_at', 'failed_at', 'completed_at') | ForEach-Object {
        if ($null -ne $InputObject.$_ -and ($unixtime = $InputObject.$_ -as [long])) {
            # convert unixtime to [DateTime] for read suitable
            $InputObject | Add-Member -MemberType NoteProperty -Name $_ -Value ([System.DateTimeOffset]::FromUnixTimeSeconds($unixtime).LocalDateTime) -Force
        }
    }

    $InputObject | Add-Member -MemberType NoteProperty -Name 'SimpleContent' -Value $simplecontent -Force
    Write-Output $InputObject
}
