# Changelog
### 1.12.0
- Messages can now be entered directly from the pipeline. (`Request-ChatGPT`)  
   ```PowerShell
   PS C:/> "Can you recommend some music?" | Request-ChatGPT | Select-Object -ExpandProperty Answer
   I can suggest some popular and diverse genres and artists that listeners enjoy...
   ```
- `Request-Moderation` now outputs a warning message when content policies are violated. To suppress this, specify `-WarningAction Ignore`.  
   ```PowerShell
   PS C:/> Request-Moderation -Text "This is a harmful message" -WarningAction Ignore
   ```
- Fix incorrect links in the comannd help.

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
   PS C:/> (Request-ChatGPT -Message 'Do you know my name?' -Name 'Samuel' -Model 'gpt-4-0314' -Temperature 0).Answer
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
