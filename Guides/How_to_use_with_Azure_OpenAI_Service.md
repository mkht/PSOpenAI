# Migrating Azure OpenAI to the OpenAI-compatible v1 API

Starting with PSOpenAI 5.0, the explicit Azure API mode is removed. Azure OpenAI v1 can be used as an OpenAI-compatible API server. PSOpenAI does not translate legacy Azure requests or guarantee Azure feature/model availability.

## Update connection settings

1. Remove `ApiType`, `ApiVersion`, and `AuthType` from commands, splatted dictionaries, `$PSDefaultParameterValues`, and saved context data. This also applies to `-ApiType OpenAI`. Explicit use of a removed parameter fails during parameter binding; old properties piped into `Set-OpenAIContext` do not restore an Azure mode.
2. Replace the resource root URL with the complete v1 base: `https://<resource>.openai.azure.com/openai/v1/` (or the corresponding `services.ai.azure.com` endpoint). Do not include `/deployments/<name>`.
3. Pass the Azure API key or an already acquired Entra ID access token to `ApiKey`. Both use `Authorization: Bearer ...`.
4. Pass the model deployment name to `Model`. The module cannot infer it from the endpoint or the underlying model name.

```powershell
Clear-OpenAIContext
Set-OpenAIContext `
    -ApiBase 'https://<resource>.openai.azure.com/openai/v1/' `
    -ApiKey $AzureApiKey

Request-ChatCompletion -Model '<deployment-name>' -Message 'Hello'
Request-Response -Model '<deployment-name>' -Message 'Hello'
```

Alternatively, set `OPENAI_API_KEY` and `OPENAI_API_BASE` environment variables. PSOpenAI uses **OPENAI_API_BASE**, not the official SDK's `OPENAI_BASE_URL`. Explicit parameters override context; API keys and API bases then fall back to global variables before environment variables. Clear or replace old context settings when changing servers.

## Entra ID access tokens

Acquire a token outside PSOpenAI using your existing Azure identity tooling and permissions. Pass the token itself, including a SecureString token returned by Az.Accounts, directly to `ApiKey`:

```powershell
# After acquiring a token using your Azure identity tooling:
Set-OpenAIContext -ApiBase 'https://<resource>.openai.azure.com/openai/v1/' -ApiKey $MyToken.Token
Request-ChatCompletion -Model '<deployment-name>' -Message 'Hello'
```

PSOpenAI does not acquire or refresh tokens. Obtain a new token and update the context before it expires. See Microsoft's current [authentication and v1 migration guidance](https://learn.microsoft.com/en-us/azure/foundry/openai/api-version-lifecycle) for token scopes and role requirements.

## Compatibility boundaries

- GA v1 requests do not need a dated `api-version`. Some preview operations still require a query parameter or feature header. Use `-AdditionalQuery @{ 'api-version' = 'preview' }` or `AdditionalHeaders` on HTTP commands as required by the service. These options are not available on the Realtime connection commands.
- Images use the OpenAI request format; image edits upload files and masks as multipart data. Legacy Azure JSON/Data URL image-edit conversion has been removed. Image and audio operation availability and content types must be checked against the service's current [media API reference](https://learn.microsoft.com/en-us/azure/foundry/openai/reference-preview-latest).
- Batch request URLs use `/v1/chat/completions`, `/v1/responses`, etc., independently of the API base. The service determines which endpoints it accepts. Regenerate legacy Azure batch input with `-AsBatch`, or update both its JSONL URLs and the job endpoint according to the [Batch guide](https://learn.microsoft.com/en-us/azure/foundry/openai/how-to/batch).
- Realtime uses `/openai/v1/realtime?model=<deployment-name>` for conversation sessions. Authentication and transcription-session availability should be verified for the target service; see the [WebSocket guide](https://learn.microsoft.com/en-us/azure/foundry/openai/how-to/realtime-audio-websockets).
- Video commands use the OpenAI `/videos` request and output format. Azure Sora 2 documents this format, but legacy Azure video job IDs and `generations` objects are not converted. Finish/download legacy jobs with PSOpenAI 4.x before migrating. See the [Sora 2 guide](https://learn.microsoft.com/en-us/azure/foundry/openai/concepts/video-generation).
- Arbitrary deployment names are accepted, but they do not identify a tokenizer. For `LogitBias`, use integer token IDs generated for the actual model, for example `-LogitBias @{ 1234 = -100 }`. The old fixed Azure tokenizer assumption has been removed.
- Model-name-specific defaults and deprecation warnings are shared with other compatible servers; a deployment name is not resolved to its underlying model. Supply model-specific options explicitly when needed.
- Unsupported operations are reported by the target server. PSOpenAI does not detect Azure hosts, auto-rewrite their URLs, or fall back to legacy endpoints.

The migration is based on official specifications. Offline tests verify request construction and shared transport behavior; they do not establish live Azure availability. No live Azure verification was performed for this migration.
