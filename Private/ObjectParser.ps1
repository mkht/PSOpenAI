function ParseBatchObject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [PSCustomObject]$InputObject
    )

    # Add custom type name and properties to output object.
    $InputObject.PSObject.TypeNames.Insert(0, 'PSOpenAI.Batch')
    ('created_at', 'in_progress_at', 'expires_at', 'finalizing_at', 'started_at', 'cancelled_at', 'failed_at', 'expired_at', 'cancelling_at', 'cancelled_at', 'completed_at') | ForEach-Object {
        if ($null -ne $InputObject.$_ -and ($unixtime = $InputObject.$_ -as [long])) {
            # convert unixtime to [DateTime] for read suitable
            $InputObject | Add-Member -MemberType NoteProperty -Name $_ -Value ([System.DateTimeOffset]::FromUnixTimeSeconds($unixtime).LocalDateTime) -Force
        }
    }
    Write-Output $InputObject
}

function ParseAssistantsObject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [PSCustomObject]$InputObject
    )

    # Add custom type name and properties to output object.
    $InputObject.PSObject.TypeNames.Insert(0, 'PSOpenAI.Assistant')
    ('created_at') | ForEach-Object {
        if ($null -ne $InputObject.$_ -and ($unixtime = $InputObject.$_ -as [long])) {
            # convert unixtime to [DateTime] for read suitable
            $InputObject | Add-Member -MemberType NoteProperty -Name $_ -Value ([System.DateTimeOffset]::FromUnixTimeSeconds($unixtime).LocalDateTime) -Force
        }
    }
    Write-Output $InputObject
}

function ParseThreadRunObject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [PSCustomObject]$InputObject
    )

    # Add custom type name and properties to output object.
    $InputObject.PSObject.TypeNames.Insert(0, 'PSOpenAI.Thread.Run')
  ('created_at', 'expires_at', 'started_at', 'cancelled_at', 'failed_at', 'completed_at') | ForEach-Object {
        if ($null -ne $InputObject.$_ -and ($unixtime = $InputObject.$_ -as [long])) {
            # convert unixtime to [DateTime] for read suitable
            $InputObject | Add-Member -MemberType NoteProperty -Name $_ -Value ([System.DateTimeOffset]::FromUnixTimeSeconds($unixtime).LocalDateTime) -Force
        }
    }
    Write-Output $InputObject
}

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

    $simplecontent =
    if ($InputObject.type -eq 'message_creation') {
        if ($msgid = $InputObject.step_details.message_creation.message_id) {
            $GetThreadMessageParams = $CommonParams
            $GetThreadMessageParams.ThreadId = $InputObject.thread_id
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
            elseif ($call.type -eq 'file_search') {
                [PSCustomObject]@{
                    Role    = $InputObject.type
                    Type    = $call.type
                    Content = $null
                }
            }
            elseif ($call.type -eq 'function') {
                [PSCustomObject]@{
                    Role      = $InputObject.type
                    Type      = $call.type
                    Name      = $call.function.name
                    Arguments = $call.function.arguments
                    Content   = $call.function.output
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

function ParseThreadObject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [PSCustomObject]$InputObject,

        [Parameter()]
        [System.Collections.IDictionary]$CommonParams = @{},

        [Parameter()]
        [switch]$Primitive
    )
    # Add custom type name and properties to output object.
    $InputObject.PSObject.TypeNames.Insert(0, 'PSOpenAI.Thread')
    if ($null -ne $InputObject.created_at -and ($unixtime = $InputObject.created_at -as [long])) {
        # convert unixtime to [DateTime] for read suitable
        $InputObject | Add-Member -MemberType NoteProperty -Name 'created_at' -Value ([System.DateTimeOffset]::FromUnixTimeSeconds($unixtime).LocalDateTime) -Force
    }
    if (-not $Primitive) {
        $InputObject | Add-Member -MemberType NoteProperty -Name 'Messages' -Value @(PSOpenAI\Get-ThreadMessage -ThreadId $InputObject.id -All @CommonParams) -Force
    }
    else {
        $InputObject | Add-Member -MemberType NoteProperty -Name 'Messages' -Value ([object[]]::new(0)) -Force
    }
    Write-Output $InputObject
}

function ParseChatCompletionObject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [PSCustomObject]$InputObject,

        [Parameter()]
        [object]$OutputType, # for Structured Outputs

        [Parameter()]
        [System.Collections.IDictionary]$CommonParams = @{},

        [Parameter()]
        [switch]$Primitive
    )
    # Add custom type name and properties to output object.
    $InputObject.PSObject.TypeNames.Insert(0, 'PSOpenAI.Chat.Completion')

    # Date and times
    if ($null -ne $InputObject.created -and ($unixtime = $InputObject.created -as [long])) {
        # convert unixtime to [DateTime] for read suitable
        $InputObject | Add-Member -MemberType NoteProperty -Name 'created' -Value ([System.DateTimeOffset]::FromUnixTimeSeconds($unixtime).LocalDateTime) -Force
    }

    # User messages
    $LastUserMessage = ($Messages.Where({ $_.role -eq 'user' })[-1].content)
    if ($LastUserMessage -isnot [string]) {
        $LastUserMessage = [string]($LastUserMessage | Where-Object { $_.type -eq 'text' } | Select-Object -Last 1).text
    }
    if ($LastUserMessage) { $InputObject | Add-Member -MemberType NoteProperty -Name 'Message' -Value $LastUserMessage }

    # AI messages
    $Answer = @()
    foreach ($choice in $InputObject.choices) {
        # The model refuses to respond
        if ($choice.message.refusal) {
            Write-Warning ('The model refuses to respond. Refusal message: "{0}"' -f $choice.message.refusal)
            $Answer += $choice.message.refusal
            continue
        }

        if ($choice.finish_reason -in ('stop', 'length', 'content_filter')) {
            Write-Warning ('The model seems to have terminated response. Reason: "{0}"' -f $choice.finish_reason)
            $Answer += $choice.message.content
            continue
        }

        if ($OutputType -is [type]) {
            # Structured Outputs
            ## Deserialize JSON output to .NET object
            try {
                $DeserializedObject = [Newtonsoft.Json.JsonConvert]::DeserializeObject($choice.message.content, $OutputType)
                $choice.message | Add-Member -MemberType NoteProperty -Name 'parsed' -Value $DeserializedObject -Force
                $Answer += $DeserializedObject
            }
            catch {
                Write-Error -Exception $_.Exception
            }
            continue
        }

        $Answer += $choice.message.content
    }

    if ($OutputType -isnot [type]) {
        $Answer = [string[]]$Answer
    }
    $InputObject | Add-Member -MemberType NoteProperty -Name 'Answer' -Value $Answer

    # Add History
    if ($Messages) { $InputObject | Add-Member -MemberType NoteProperty -Name 'History' -Value $Messages.ToArray() }

    # Return
    Write-Output $InputObject
}

function ParseVectorStoreObject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [PSCustomObject]$InputObject
    )
    # Add custom type name and properties to output object.
    $InputObject.PSObject.TypeNames.Insert(0, 'PSOpenAI.VectorStore')
    ('created_at', 'expires_at', 'last_active_at') | ForEach-Object {
        if ($null -ne $InputObject.$_ -and ($unixtime = $InputObject.$_ -as [long])) {
            # convert unixtime to [DateTime] for read suitable
            $InputObject | Add-Member -MemberType NoteProperty -Name $_ -Value ([System.DateTimeOffset]::FromUnixTimeSeconds($unixtime).LocalDateTime) -Force
        }
    }
    Write-Output $InputObject
}

function ParseVectorStoreFileObject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [PSCustomObject]$InputObject
    )
    # Add custom type name and properties to output object.
    $InputObject.PSObject.TypeNames.Insert(0, 'PSOpenAI.VectorStore.File')
    ('created_at') | ForEach-Object {
        if ($null -ne $InputObject.$_ -and ($unixtime = $InputObject.$_ -as [long])) {
            # convert unixtime to [DateTime] for read suitable
            $InputObject | Add-Member -MemberType NoteProperty -Name $_ -Value ([System.DateTimeOffset]::FromUnixTimeSeconds($unixtime).LocalDateTime) -Force
        }
    }
    Write-Output $InputObject
}

function ParseVectorStoreFileBatchObject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [PSCustomObject]$InputObject
    )
    # Add custom type name and properties to output object.
    $InputObject.PSObject.TypeNames.Insert(0, 'PSOpenAI.VectorStore.FileBatch')
    ('created_at') | ForEach-Object {
        if ($null -ne $InputObject.$_ -and ($unixtime = $InputObject.$_ -as [long])) {
            # convert unixtime to [DateTime] for read suitable
            $InputObject | Add-Member -MemberType NoteProperty -Name $_ -Value ([System.DateTimeOffset]::FromUnixTimeSeconds($unixtime).LocalDateTime) -Force
        }
    }
    Write-Output $InputObject
}