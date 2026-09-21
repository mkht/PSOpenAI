# How to use the Agents API

The Agents API is a public beta API for reusable agent configurations and managed sessions. PSOpenAI exposes common operations as named PowerShell parameters while retaining `-Body` and `-AdditionalBody` for advanced or newly introduced API fields.

The API currently works with OpenAI endpoints only. It is not available through Azure OpenAI endpoints.

Official reference: [OpenAI Agents API](https://developers.openai.com/api/reference/python/resources/beta/subresources/agents)

## Create an agent and run a session

Create a reusable agent with ordinary PowerShell parameters:

```powershell
$Agent = New-Agent `
    -Model 'gpt-5.6-luna' `
    -Name 'PowerShell reviewer' `
    -Instructions 'Review PowerShell code and return concise, actionable findings.' `
    -Reasoning @{ effort = 'medium'; summary = 'concise' } `
    -Text @{ verbosity = 'medium'; format = @{ type = 'text' } }
```

Start a session. If `-Environment` and `-EnvironmentTemplateId` are omitted, PSOpenAI selects `{ type = 'none' }`:

```powershell
$Session = $Agent | New-AgentSession `
    -Input 'Explain the most important issue in this script.'

$Session = $Session | Wait-AgentSession -TimeoutSec 120
$Session.status
```

`Wait-AgentSession` returns when the session becomes `idle`, `requires_action`, or `failed`. A `requires_action` result means the caller must handle the entries in `required_actions` before the session can continue.

## Continue a session

Submit another user message without constructing the event schema manually:

```powershell
$Session | Add-AgentSessionEvent `
    -Message 'Show a corrected implementation.' `
    -IdempotencyKey ([guid]::NewGuid().ToString())

$Session = $Session | Wait-AgentSession -TimeoutSec 120
```

For cancellation, function results, or other event variants, use `-Event`:

```powershell
$Session | Add-AgentSessionEvent -Event @{
    type = 'agent.session.input.cancel'
}
```

## Stream session events

Use `-Stream` when creating a session or `Get-AgentSessionEvent` for an existing session:

```powershell
$Agent | New-AgentSession `
    -Input 'Summarize this request.' `
    -Stream |
    ForEach-Object {
        "{0}: {1}" -f $_.type, $_.session_id
    }
```

Streamed objects have the `PSOpenAI.Agent.Session.Event` type name. Their top-level Unix timestamp properties are converted to local `DateTime` values.

## Use a hosted environment

An environment template can define files, packages, network policy, skills, plugins, and confidential setup commands:

```powershell
$Template = New-AgentEnvironmentTemplate `
    -Name 'PowerShell test environment' `
    -Packages @{ system = @('powershell'); python = @('pytest') } `
    -Network @{ access = 'disabled' } `
    -Setup @(
        @{ command = 'pwsh --version'; cwd = '/workspace' }
    )

$Session = $Agent | New-AgentSession `
    -EnvironmentTemplateId $Template.id `
    -Input 'Inspect the files in /workspace.'
```

To attach an existing Files API object to a running hosted environment:

```powershell
$Environment = Get-AgentEnvironment -EnvironmentId $Session.environment.id
$Environment | Add-AgentEnvironmentFile `
    -FileId $OpenAIFile.id `
    -Path '/workspace/input.txt'
```

Use `-Environment` directly for inline hosted or self-hosted environment configurations not covered by the convenience parameters.

## Use Vault credentials

Vault secret values are accepted as `SecureString`. PSOpenAI converts them to plain text only while constructing and sending the request, then clears the temporary unmanaged buffer.

```powershell
$Vault = New-AgentVault -Name 'MCP credentials'
$Token = Read-Host 'MCP bearer token' -AsSecureString

$Credential = $Vault | New-AgentVaultCredential `
    -Name 'internal-mcp' `
    -Token $Token `
    -McpServerUrl 'https://mcp.example.com'
```

Attach the vault when creating a session:

```powershell
$Session = $Agent | New-AgentSession `
    -VaultId $Vault.id `
    -Input 'Use the configured MCP service.'
```

`New-AgentVaultCredential` also supports environment-variable credentials. OAuth and future authentication shapes can be supplied through `-Auth` or raw `-Body`.

## Inspect turns, items, subagents, and artifacts

```powershell
$Turns = Get-AgentSessionTurn -SessionId $Session.id -All
$Items = Get-AgentSessionItem -SessionId $Session.id -All
$Subagents = Get-AgentSessionSubagent -SessionId $Session.id -All
$Artifacts = Get-AgentSessionArtifact -SessionId $Session.id -All

if ($Artifacts) {
    Get-AgentSessionArtifactContent `
        -SessionId $Session.id `
        -ArtifactId $Artifacts[0].id `
        -OutFile './agent-output.bin'
}
```

Objects returned by Agents API commands include `PSOpenAI.Agent.*` type names and can be passed through the pipeline to compatible commands.

## Advanced request bodies

Named parameters cover stable, commonly used fields. Use raw `-Body` when the beta API introduces a schema that PSOpenAI does not expose yet:

```powershell
$Agent = New-Agent -Body @{
    model        = 'gpt-5.6-luna'
    instructions = 'Use an experimental agent configuration.'
    tools        = @(
        @{ type = 'web_search'; mode = 'cached' }
    )
}
```

`-AdditionalBody` remains available for adding or overriding top-level request fields. It is a shallow merge, so supply a complete nested object when overriding nested configuration.

## Cleanup

Deletion commands support `-WhatIf` and confirmation:

```powershell
$Session | Remove-AgentSession
$Agent | Remove-Agent
$Template | Remove-AgentEnvironmentTemplate
$Vault | Remove-AgentVault
```

Because Agents API is beta, review the official schema before relying on advanced event, environment, or credential shapes in long-lived automation.
