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

function ParseConversationObject {
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
    $InputObject.PSObject.TypeNames.Insert(0, 'PSOpenAI.Conversation')
    if ($null -ne $InputObject.created_at -and ($unixtime = $InputObject.created_at -as [long])) {
        # convert unixtime to [DateTime] for read suitable
        $InputObject | Add-Member -MemberType NoteProperty -Name 'created_at' -Value ([System.DateTimeOffset]::FromUnixTimeSeconds($unixtime).LocalDateTime) -Force
    }
    if (-not $Primitive) {
        $InputObject | Add-Member -MemberType NoteProperty -Name 'Items' -Value @(PSOpenAI\Get-ConversationItem -ConversationId $InputObject.id -All @CommonParams) -Force
    }
    else {
        $InputObject | Add-Member -MemberType NoteProperty -Name 'Items' -Value ([object[]]::new(0)) -Force
    }
    Write-Output $InputObject
}

function ParseChatCompletionObject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [PSCustomObject]$InputObject,

        [Parameter()]
        [System.Collections.Generic.List[object]]$Messages,

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
    if ($LastUserMessage) {
        $InputObject | Add-Member -MemberType NoteProperty -Name 'Message' -Value $LastUserMessage
    }
    else {
        $InputObject | Add-Member -MemberType NoteProperty -Name 'Message' -Value $null
    }

    # Assistant messages
    $Answer = @()
    foreach ($choice in $InputObject.choices) {
        # The model refuses to respond
        if ($choice.message.refusal) {
            Write-Warning ('The model refuses to respond. Refusal message: "{0}"' -f $choice.message.refusal)
            $Answer += $choice.message.refusal
            continue
        }

        if ($choice.finish_reason -in ('length', 'content_filter')) {
            Write-Warning ('The model seems to have terminated response. Reason: "{0}"' -f $choice.finish_reason)
            $Answer += $choice.message.content
            continue
        }

        # The model respond by audio
        if ($null -eq $choice.message.content -and $choice.message.audio.transcript) {
            $Answer += $choice.message.audio.transcript
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
    if ($Messages.Count -gt 0) {
        $Messages | ForEach-Object { $_.PSObject.TypeNames.Insert(0, 'PSOpenAI.Chat.Completion.Message') }
        $InputObject | Add-Member -MemberType NoteProperty -Name 'History' -Value $Messages.ToArray()
    }
    else {
        $InputObject | Add-Member -MemberType NoteProperty -Name 'History' -Value @()
    }

    # Return
    Write-Output $InputObject
}

function ParseResponseObject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [PSCustomObject]$InputObject,

        [Parameter()]
        [System.Collections.Generic.List[object]]$Messages,

        [Parameter()]
        [object]$OutputType, # for Structured Outputs

        [Parameter()]
        [System.Collections.IDictionary]$CommonParams = @{}
    )

    # Add custom type name and properties to output object.
    $InputObject.PSObject.TypeNames.Insert(0, 'PSOpenAI.Response')

    # Date and times
    @('created_at') | ForEach-Object {
        if ($null -ne $InputObject.$_ -and ($unixtime = $InputObject.$_ -as [long])) {
            # convert unixtime to [DateTime] for read suitable
            $InputObject | Add-Member -MemberType NoteProperty -Name $_ -Value ([System.DateTimeOffset]::FromUnixTimeSeconds($unixtime).LocalDateTime) -Force
        }
    }

    # Warning messages
    foreach ($output in $InputObject.output) {
        ## The model refuses to respond
        if ($output.content.type -eq 'refusal') {
            Write-Warning ('The model refuses to respond. Refusal message: "{0}"' -f $output.content.refusal)
        }
    }

    if ($InputObject.status -eq 'incomplete') {
        Write-Warning ('The status of response is "{0}". Details: "{1}"' -f $InputObject.status, $InputObject.incomplete_details.reason)
    }
    elseif ($InputObject.status -eq 'failed') {
        Write-Warning ('The status of response is "{0}". Error: "{1}" ({2})' -f $InputObject.status, $InputObject.error.message, $InputObject.error.code)
    }

    # Last User message
    $LastUserMessage = ($Messages.Where({ $_.role -eq 'user' })[-1].content)
    if ($LastUserMessage -isnot [string]) {
        $LastUserMessage = [string]($LastUserMessage | Where-Object { $_.type -eq 'input_text' } | Select-Object -Last 1).text
    }
    if ($LastUserMessage) {
        $InputObject | Add-Member -MemberType NoteProperty -Name 'LastUserMessage' -Value $LastUserMessage
    }
    else {
        $InputObject | Add-Member -MemberType NoteProperty -Name 'LastUserMessage' -Value $null
    }

    # Output Text
    ## Note: This logic is same as the one in the openai-python SDK.
    $InputObject | Add-Member -MemberType ScriptProperty -Name 'output_text' -Value `
    {
        $Texts = [System.Collections.Generic.List[string]]::new()
        foreach ($output in $this.output) {
            if ($output.type -eq 'message') {
                foreach ($content in $output.content) {
                    if ($content.type -eq 'output_text') {
                        $Texts.Add($content.text)
                    }
                }
            }
        }
        return (-join $Texts)
    }

    ## Structured Outputs
    $StructuredOutputs = @()
    if ($OutputType -is [type]) {
        foreach ($output in $InputObject.output) {
            if ($output.content.type -eq 'output_text') {
                ## Deserialize JSON output to .NET object
                try {
                    $DeserializedObject = [Newtonsoft.Json.JsonConvert]::DeserializeObject($output.content.text, $OutputType)
                    if ($null -ne $DeserializedObject) {
                        $output.content | Add-Member -MemberType NoteProperty -Name 'parsed' -Value $DeserializedObject -Force
                        $StructuredOutputs += $DeserializedObject
                    }
                }
                catch {
                    Write-Error -Exception $_.Exception
                }
            }
        }
    }
    $InputObject | Add-Member -MemberType NoteProperty -Name 'StructuredOutputs' -Value $StructuredOutputs

    # Add History
    if ($Messages.Count -gt 0) {
        $Messages | ForEach-Object { $_.PSObject.TypeNames.Insert(0, 'PSOpenAI.Response.Message') }
        $InputObject | Add-Member -MemberType NoteProperty -Name 'History' -Value $Messages.ToArray()
    }
    else {
        $InputObject | Add-Member -MemberType NoteProperty -Name 'History' -Value @()
    }

    # Return
    Write-Output $InputObject
}

function ParseResponseCompactionObject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [PSCustomObject]$InputObject,

        [Parameter()]
        [System.Collections.Generic.List[object]]$Messages,

        [Parameter()]
        [System.Collections.IDictionary]$CommonParams = @{}
    )

    # Add custom type name and properties to output object.
    $InputObject.PSObject.TypeNames.Insert(0, 'PSOpenAI.Response.Compaction')

    # Date and times
    @('created_at') | ForEach-Object {
        if ($null -ne $InputObject.$_ -and ($unixtime = $InputObject.$_ -as [long])) {
            # convert unixtime to [DateTime] for read suitable
            $InputObject | Add-Member -MemberType NoteProperty -Name $_ -Value ([System.DateTimeOffset]::FromUnixTimeSeconds($unixtime).LocalDateTime) -Force
        }
    }

    # Add History
    if ($Messages.Count -gt 0) {
        $Messages | ForEach-Object { $_.PSObject.TypeNames.Insert(0, 'PSOpenAI.Response.Message') }
        $InputObject | Add-Member -MemberType NoteProperty -Name 'History' -Value $Messages.ToArray()
    }
    else {
        $InputObject | Add-Member -MemberType NoteProperty -Name 'History' -Value @()
    }

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

function ParseChatCompletionMessageObject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [PSCustomObject]$InputObject
    )

    $OutputObject = [ordered]@{
        id      = $InputObject.id
        role    = $InputObject.role
        content = $InputObject.content
    }

    if ($InputObject.refusal) {
        $OutputObject.Add('refusal', $InputObject.refusal)
    }
    if ($InputObject.name) {
        $OutputObject.Add('name', $InputObject.name)
    }
    if ($InputObject.content_parts) {
        $OutputObject.Add('content_parts', $InputObject.content_parts)
    }
    if ($InputObject.audio) {
        $OutputObject.Add('audio', $InputObject.audio)
    }
    if ($InputObject.tool_calls) {
        $OutputObject.Add('tool_calls', $InputObject.tool_calls)
    }
    if ($InputObject.function_call) {
        $OutputObject.Add('function_call', $InputObject.tool_calls)
    }

    Write-Output $OutputObject
}

function ParseContainerObject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [PSCustomObject]$InputObject
    )
    # Add custom type name and properties to output object.
    $InputObject.PSObject.TypeNames.Insert(0, 'PSOpenAI.Container')
    ('created_at', 'last_active_at') | ForEach-Object {
        if ($null -ne $InputObject.$_ -and ($unixtime = $InputObject.$_ -as [long])) {
            # convert unixtime to [DateTime] for read suitable
            $InputObject | Add-Member -MemberType NoteProperty -Name $_ -Value ([System.DateTimeOffset]::FromUnixTimeSeconds($unixtime).LocalDateTime) -Force
        }
    }
    Write-Output $InputObject
}

function ParseContainerFileObject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [PSCustomObject]$InputObject
    )
    # Add custom type name and properties to output object.
    $InputObject.PSObject.TypeNames.Insert(0, 'PSOpenAI.Container.File')
    ('created_at') | ForEach-Object {
        if ($null -ne $InputObject.$_ -and ($unixtime = $InputObject.$_ -as [long])) {
            # convert unixtime to [DateTime] for read suitable
            $InputObject | Add-Member -MemberType NoteProperty -Name $_ -Value ([System.DateTimeOffset]::FromUnixTimeSeconds($unixtime).LocalDateTime) -Force
        }
    }
    Write-Output $InputObject
}

function ParseImageGenerationObject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [PSCustomObject]$InputObject
    )

    # Add custom type name and properties to output object.
    $InputObject.PSObject.TypeNames.Insert(0, 'PSOpenAI.Image')
    ('created', 'created_at') | ForEach-Object {
        if ($null -ne $InputObject.$_ -and ($unixtime = $InputObject.$_ -as [long])) {
            # convert unixtime to [DateTime] for read suitable
            $InputObject | Add-Member -MemberType NoteProperty -Name $_ -Value ([System.DateTimeOffset]::FromUnixTimeSeconds($unixtime).LocalDateTime) -Force
        }
    }
    Write-Output $InputObject
}

function ParseVideoJobObject {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [PSCustomObject]$InputObject
    )

    # Add custom type name and properties to output object.
    $InputObject.PSObject.TypeNames.Insert(0, 'PSOpenAI.Video.Job')
    ('created_at', 'expires_at', 'started_at', 'cancelled_at', 'failed_at', 'completed_at') | ForEach-Object {
        if ($null -ne $InputObject.$_ -and ($unixtime = $InputObject.$_ -as [long])) {
            # convert unixtime to [DateTime] for read suitable
            $InputObject | Add-Member -MemberType NoteProperty -Name $_ -Value ([System.DateTimeOffset]::FromUnixTimeSeconds($unixtime).LocalDateTime) -Force
        }
    }
    Write-Output $InputObject

    # Output warning message if the status is not success.
    if ($null -ne $InputObject.error -or $InputObject.status -eq 'failed') {
        if ($null -ne $InputObject.failure_reason) {
            $WarnMessage = ('The status of job with id "{0}" is "{1}". Reason: "{2}"' -f `
                    $InputObject.id, $InputObject.status, $InputObject.failure_reason)
        }
        else {
            $WarnMessage = ('The status of job with id "{0}" is "{1}". Error: "{2}" ({3})' -f `
                    $InputObject.id, $InputObject.status, $InputObject.error.message, $InputObject.error.code)
        }
        Write-Warning -Message $WarnMessage
    }
}