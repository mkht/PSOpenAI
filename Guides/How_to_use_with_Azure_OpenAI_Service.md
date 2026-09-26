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
