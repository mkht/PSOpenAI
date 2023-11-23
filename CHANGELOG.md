# Changelog
### 2.2.0
- Add [Request-AudioSpeech](/Docs/Request-AudioSpeech.md) function. It generates audio from the input text.
  ```PowerShell
  PS C:\> Request-AudioSpeech -text 'Do something fun to play.' -OutFile 'C:\Output\text2speech.mp3' -Voice Alloy
  ```

- Add new functions for using the OpenAI Assistants API.
 
  To use Assistants with the new PSOpenAI cmdlets, please refer to this guide.  
  [Guide: How to use Assistants](/Guides/How_to_use_Assistants.md)

  > [!WARNING]  
  > The Assistants API is still in Beta. Specifications, usage, and parameters are subject to change without announcement.

  + Assistants: `Get-Assistant`, `New-Assistant`, `Remove-Assistant`, `Set-Assistant`
  + Threads: `Get-Thread`, `New-Thread`, `Remove-Thread`, `Set-Thread`
  + Messages: `Get-ThreadMessage`, `Add-ThreadMessage`
  + Runs: `Get-ThreadRun`, `Start-ThreadRun`, `Stop-ThreadRun`, `Wait-ThreadRun`, `Receive-ThreadRun`
  + Steps: `Get-ThreadRunStep`
  + Files: `Get-OpenAIFile`, `Register-OpenAIFile`, `Remove-OpenAIFile`, `Get-OpenAIFileContent`

- Change directory name from "Examples" to ["Guides"](/Guides).
- Suppress verbose message about the organization-Id not found.
- Fix minor bugs.

### 2.1.0
Implements some updates that announced in OpenAI Dev Day 2023.  
  (New features such as Threads or Assistants does not implemented yet. We are working in progress.)
- Add / Rename / Remove some parameters to `Request-ChatComplention`.
  + Add : `-Images`, `-ImageDetail`, `-Tools`, `-ToolChoice`, `-Format`, `-Seed`  
  + Remove : `-Functions`, `-FunctionCall`, `-MaxFunctionCallCount`  
  + Rename : `-InvokeFunctionOnCallMode` to `-InvokeTools`  
- Add new models to tab completions of `Request-ChatComplention`.
  + `gpt-3.5-turbo-1106`, `gpt-4-1106-preview`, `gpt-4-vision-preview`
- Add `-Model` parameter to `Request-ImageGeneration`. You can specifiy the model name. (`dall-e-2` or `dall-e-3`)
- Add `-Quality` and `-Style` parameters to `Request-ImageGeneration` (for `dall-e-3`)

### 2.0.0
**This is a major release that includes breaking changes.**
- Add `-ApiBase` parameter to specify the base URL of the API endpoint.  
  This is useful for using the OpenAI compatible API such like [FastChat](https://github.com/lm-sys/FastChat) or [LM Studio](https://lmstudio.ai/) in a private environment.  
  ```PowerShell
  PS C:\> Request-ChatCompletion -Message 'Hello' -ApiBase 'https://localhost:8000/v1'
  ```
- `Get/New/Remove-AzureOpenAIDeployments` functions are removed.  
- Remove `-Token` parameter from all functions. Use `-ApiKey` instead.
- `OPENAI_TOKEN` environment variable is deprecated. Use `OPENAI_API_KEY` instead.
- The default model for `Request-TextCompletion` is changed to `gpt-3.5-turbo-instruct` from `text-davinci-003`.
- Add `-Format` parameter to `Request-Embeddings` function. This parameter can be used to specify the format of the returned embeddings.  

### 1.15.2
- Fix various issues about Function calling.

### 1.15.0
- Add new whisper functions for Azure OpenAI Service
    + [Request-AzureAudioTranscription](/Docs/Request-AzureAudioTranscription.md)
    + [Request-AzureAudioTranslation](/Docs/Request-AzureAudioTranslation.md)
- Remove the upper limit on the `-MaxTokens` parameter. (The maximum number of tokens depends on the model used)
- Add support for Function calling method on Azure OpenAI Service.
- Change default api version of Azure OpenAI Service to `2023-09-01-preview`

### 1.14.3
- Add a new `gpt-3.5-turbo-instruct` model to tab completions of `Request-TextCompletion`.

### 1.14.2
- Update tab completions for models of `Request-TextCompletion`.
  + To avoid breaking change, the default model used remains legacy `text-davinci-003`. We plan to change it on the future release.
- Update warning messages about the deprecation models that has been announced by OpenAI.
  + https://platform.openai.com/docs/deprecations
- Remove warning messages about the expiration dates of these models. Because OpenAI has announced that the discontinued dates for these models will be postponed for the time being.
  + `gpt-3.5-turbo-0301`
  + `gpt-4-0314`
  + `gpt-4-32k-0314`

### 1.14.0
- Add initial support for Function calling method of the OpenAI ChatCompletion API. See the [guide](/Examples/How_to_call_functions_with_ChatGPT.ipynb).
- Change the name of `-RolePrompt` to `-SystemMessage` (`-RolePrompt` can also continue to be used as an alias )
- Add new ChatGPT models. 
  + `gpt-3.5-turbo-16k`
  + `gpt-3.5-turbo-0613`
  + `gpt-3.5-turbo-16k-0613`
  + `gpt-4-0613`
  + `gpt-4-32k-0613`
- Ready for old models discontinuation on 2023-09-13.
  + `gpt-3.5-turbo-0301`
  + `gpt-4-0314`
  + `gpt-4-32k-0314`

### 1.13.0
- Add [Request-AzureImageGeneration](/Docs/Request-AzureImageGeneration.md) for Azure DALL-E

### 1.12.6
- Update Azure API version to `2023-05-15` of latest stable.
- Update docs and examples.

### 1.12.5
- Fix an issue that the User-Agent was not set in stream requests.
- Minor fixes/improvements.

### 1.12.4
- Use HTTP/2 for API requests if the platform is supported.
- Adjust retry intervals for API requests.

### 1.12.3
- Improve error handling.
- The `code-davinci-edit-001` model is restored.  
  It appears that the previous unavailability was a temporary problem rather than a permanent retirement.

### 1.12.2
- `ConvertTo-Token` and `ConvertFrom-Token` performance has been significantly improved. (Up to 100 times faster)

### 1.12.1
- Improve error handling.

### 1.12.0
- Messages can now be entered directly from the pipeline. (`Request-ChatGPT`)  
   ```PowerShell
   PS C:\> "Can you recommend some music?" | Request-ChatGPT | Select-Object -ExpandProperty Answer
   I can suggest some popular and diverse genres and artists that listeners enjoy...
   ```
- `Request-Moderation` now outputs a warning message when content policies are violated. To suppress this, specify `-WarningAction Ignore`.  
   ```PowerShell
   PS C:\> Request-Moderation -Text "This is a harmful message" -WarningAction Ignore
   ```
- Fix incorrect links in the command help.

### 1.11.0
- Add new commands for Azure OpenAI Service.  
  + [Get-AzureOpenAIModels](/Docs/Get-AzureOpenAIModels.md)
  + [Get-AzureOpenAIDeployments](/Docs/Get-AzureOpenAIDeployments.md)
  + [New-AzureOpenAIDeployments](/Docs/New-AzureOpenAIDeployments.md)
  + [Remove-AzureOpenAIDeployments](/Docs/Remove-AzureOpenAIDeployments.md)
- Fix an issue that unmasked API key would unintentionally be exposed in debug messages when using `-Stream`.
- Fix issue with organization ID not being used correctly when using `-Stream`.
- Minor fixes.

### 1.10.0
 - Add `-Organization` parameter to specify the Organization ID used for API requests.
 - Improve output of verbose and debug messages.
 - Enable tab completion for model names.
 - Misc improvements.

### 1.9.2
 - Add new commands [Get-CosineSimilarity](/Docs/Get-CosineSimilarity.md) for calculates cosine similarity between two vectors.  
   Note: Added for convenience, not good implementation for performance or accuracy. For production use, it is recommended to use an external library such as [Math.NET Numerics](https://numerics.mathdotnet.com/).

### 1.9.1
 - Improve behavior of `ConvertTo-Token` and `ConvertFrom-Token` when a jagged array is input via pipeline.

### 1.9.0
 - Now PSOpenAI has experimental supports for Azure OpenAI Service. These new commands added.  
   + [Request-AzureChatGPT](/Docs/Request-AzureChatCompletion.md)
   + [Request-AzureEmbeddings](/Docs/Request-AzureEmbeddings.md)
   + [Request-AzureTextCompletion](/Docs/Request-AzureTextCompletion.md)

### 1.8.0
 - Add `-Name` option for `Request-ChatGPT`.  
   This parameter can be used to specify the name of the messenger.  
   e.g.)  
   ```PowerShell
   PS C:\> (Request-ChatGPT -Message 'Do you know my name?' -Name 'Samuel' -Model 'gpt-4-0314' -Temperature 0).Answer
   Yes, your name is Samuel.
   ```
 - Change the `-Message` parameter of `Request-ChatGPT` to optional and accepts input from pipeline by property name.  
 - Multiple strings can be specified for `-RolePrompt`.
 - Add `-AsArray` option for `ConvertFrom-Token`.  
 - Some minor changes.

### 1.7.0
 - Add new commands [ConvertTo-Token](/Docs/ConvertTo-Token.md) and [ConvertFrom-Token](/Docs/ConvertFrom-Token.md) for converting text and token IDs to each other.  
   (Using [microsoft/Tokenizer](https://github.com/microsoft/Tokenizer) library.)  
 - Add `-LogitBias` option for `Request-ChatGPT` and `Request-TextCompletion`.  

### 1.6.0
 - Add a new command [Request-Embeddings](/Docs/Request-Embeddings.md). 
 - **[IMPORTANT CHANGE]**  
   Change the environment variable name of the API auth key from `OPENAI_TOKEN` to `OPENAI_API_KEY`. And also change the parameter name from `-Token` to `-ApiKey`.  
   This is because the word "Token" is often confused with a term used in the field of machine learning, and the official OpenAI reference uses this name.  
   For backward compatibility, `OPENAI_TOKEN` and `-Token` will continue to work, but may be deprecated entirely in the future.

### 1.5.0
 - Add `-MaxRetryCount` option for all functions.  
   Retries up to the maximum number of times specified if an API request fails with a `429 (Rate limit reached)` or `5xx (Server side errors)` error. The retry interval increases exponentially up to 128 seconds.
 - These obsolated functions are completely removed.
   + `Request-CodeCompletion`
   + `Request-CodeEdit`
 - Minor fixes.

### 1.4.0
 - Add a new command [Enter-ChatGPT](/Docs/Enter-ChatGPT.md). You can communicate with ChatGTP interactively on the console. 

### 1.3.0
 - Add `-Stream` option for `Request-ChatGPT` and `Request-TextCompletion`.
 - The AI model `code-davinci-edit-001` has been outdated.
 - Fix wrong messages about expires date of AI models.

### 1.2.1
 - OpenAI has announced that the Codex API will be discontinued on 2023-03-23, the following functions may no longer work in the future. In the future release, these functions will be completely removed from the module.
   + `Request-CodeCompletion`
   + `Request-CodeEdit`
 - When a request specifying an AI model that has been or will be discontinued by OpenAI is executed, Warning messages will be output. (the request continues to be executed).  
   AI models that will output warning messages at this time:  
   + `code-davinci-001`
   + `code-davinci-002`
   + `code-cushman-001`
   + `code-cushman-002`

### 1.2.0
 - Add `StopSequence` parameter for `Request-ChatGPT`, `Request-TextCompletion`, `Request-CodeCompletion`.  
   When specific words are output from the API, subsequent output is stopped.  
   e.g.)
    ```PowerShell
    # This code generates only top 4 list.
    Request-TextCompletion -Prompt 'List of top 10 most populous countries' -StopSequence '5.'
    ```

### 1.1.2
 - Fix an issue that the language code may not be set correctly in `Request-AudioTranscription` on macOS and Linux environment.
 - Fix minor issues on Windows PowerShell 5.1
 - Fix Flaky Tests.

### 1.1.0
 - Improve error handling.
 - Change the default value of the `MaxTokens` parameter of `Request-TextCompletion` to `2048`. The previous default value of `16` was not useful for most use cases.
 - Add the `Request-CodeCompletion` function. This performs the same process as `Request-TextCompletion`, but is more suitable for generating program code since the AI model used by default is `code-davinci-002`.
 - Add Pester tests for all public functions.

### 1.0.0
 - Initial public release.
