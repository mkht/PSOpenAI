# How to handle API keys and context parameters

To request to the OpenAI (and Azure OpenAI Service), we need to specify API key for authentication. And some scenarios also additional parameters such as organization IDs and Azure resource names must be provided.

This guide illustrates how the PSOpenAI handle these user-specific parameters.

## API key

### 1. Set an environment variable `OPENAI_API_KEY`

Set the API key to the environment variable named `OPENAI_API_KEY`. PSOpenAI will use the key implicitly.

This method is best suited when running on a trusted host or CI/CD pipeline.

```powershell
$env:OPENAI_API_KEY = '<Put your API key here>'
Request-ChatCompletion -Message "Who are you?" -Verbose >$null
```

```
VERBOSE: API Key found in environment variable "OPENAI_API_KEY".
VERBOSE: API key to be used is sk-I0I*******************************************B5
VERBOSE: Organization-ID to be used is 
VERBOSE: Request to OpenAI API
VERBOSE: HTTP/1.1 POST with 79-byte payload
VERBOSE: received 330-byte response of content type application/json
VERBOSE: OpenAI API response: 
StatusCode    : 200
processing_ms : 1109
request_id    : 54be116c347d2b42e5db89133c074442
```

### 2. Set a global variable `OPENAI_API_KEY`

Set the API key to the `$global:OPENAI_API_KEY` variable. PSOpenAI will use the key implicitly.

### 3. Specify to the named parameter.

Specify the API key explicitly in the `-ApiKey` parameter. It must be specified each time the function is called.

This is best used when the function is called only once or with few calls, such as when executing manually from the console.

```powershell
Request-ChatCompletion -Message "Who are you?" -ApiKey '<Put your API key here>'
```

## Organization ID

For users who belong to multiple organizations, you can pass an organization id for an API request. Usage from these API requests will count against the specified organization's subscription quota.

The method of specifying the organization ID is the same as for API keys. It can be specified as an environment variable, a global variable, or a named parameter. The variable name is `OPENAI_ORGANIZATION` and the parameter name is `-Orgnization`.

```powershell
# 1. Environment variable
$env:OPENAI_ORGANIZATION = '<Put your organization ID here>'

# 2. Global variable
$global:OPENAI_ORGANIZATION = '<Put your organization ID here>'

# 3. Named parameter
Request-ChatCompletion -Message 'Hello OpenAI' -Organization '<Put your organization ID here>'
```

## API Base (Azure OpenAI Service)

For Azure OpenAI Service, the API base is required to be specified. This is usually a URL of the form `https://<your-resource-name>.openai.azure.com/`.

The method of specifying the API base is the same as for API keys. It can be specified as an environment variable, a global variable, or a named parameter. The variable name is `OPENAI_API_BASE` and the parameter name is `-ApiBase`.

```powershell
# Set required params for the Azure OpenAI Service
$env:OPENAI_API_KEY = '<Put your API key for Azure here>'
$Deployment = 'gpt-4o'

# 1. Environment variable
$env:OPENAI_API_BASE = 'https://your-resource-name.openai.azure.com/'

# 2. Global variable
$global:OPENAI_API_BASE = 'https://your-resource-name.openai.azure.com/'

# 3. Named parameter
Request-ChatCompletion -Message 'Hello Azure' -Deployment $Deployment -ApiBase 'https://your-resource-name.openai.azure.com/' -ApiType 'Azure'
```

### Other compatible servers

You can also use an OpenAI API compatible server such as [LM Studio](https://lmstudio.ai/) or [Ollama](https://ollama.com/blog/openai-compatibility).

```powershell
$env:OPENAI_API_KEY = 'dummy'
$env:OPENAI_API_BASE = 'http://localhost:1234/v1'

Request-ChatCompletion -Message 'Hello Local LLM' -Model 'llama2'
```

## Context

Set-OpenAIContext is used to store common parameters such as API key, API base, and authentication method in Context and implicitly use them in all function calls.

> [!NOTE]
> Context is only effective within the configured PowerShell session and is not persistent. It will be cleared by restarting the session or reloading the module.

```powershell
# Set context to use Azure
Set-OpenAIContext `
    -ApiType Azure `
    -AuthType Azure `
    -ApiKey 'Put your api key here' `
    -ApiBase 'https://your-resource-name.openai.azure.com/' `

# This command calls to Azure implicitly.
Request-ChatCompletion -Message 'Hello Azure' -Model 'gpt-4o'

# Re-set context to use local LLM
Set-OpenAIContext `
    -ApiType OpenAI `
    -AuthType OpenAI `
    -ApiKey 'dummy' `
    -ApiBase 'http://localhost:1234/v1' `

# This command calls to local server implicitly.
Request-ChatCompletion -Message 'Hello Local LLM' -Model 'gpt-4o'

# Clear context (reset to default)
Clear-OpenAIContext
```
