# Changelog
### 4.32.0
- Add `-PromptCacheKey` and `-SafetyIdentifier` parameters to `Request-ChatCompletion` and `Request-Response`.

### 4.31.0
- Add support for streaming image generation.
- Reduce size of sample images.
- Fix an issue that API requests does not follow the specified timeout value.

### 4.30.0
- Add `o3-deep-research` and `o4-mini-deep-research`.
- Improve handling of file inputs in `Request-Response`. You can now specify a URL of a file.
- Update model deprecation list.
- Don't send Content-Type header on GET requests.  
- Fix documentation for `Request-Response` function. [#43](https://github.com/mkht/PSOpenAI/issues/43)
- Fix User-Agent header handling.

### 4.29.1
- Fix file upload failures due to incorrectly set content headers. [#42](https://github.com/mkht/PSOpenAI/issues/42)

### 4.29.0
- Add `o3-pro` model.
- Add new parameters to `Request-Response` for reusable prompts.
- Fix potential issues.

### 4.28.0
- Add Speed and Tracing parameters to `Set-RealtimeSessionConfiguration`.
- Fix issue that the `-TurnDetectionSilenceDuration` parameter of `Set-RealtimeSessionConfiguration` does not work properly.

### 4.27.0
- Add new parameters to `Get-Response` and `Request-Response` for streaming and background processing.
- Improve handling of array-type query parameters.

### 4.26.0
- Add new built-in tools for Responses API, such as Remote MCP, Code Interpreter, and Image Generation.
- Optimize list view of Response object.
- Add new functions for Containers.
    + [New-Container](/Docs/New-Container.md)
    + [Get-Container](/Docs/Get-Container.md)
    + [Remove-Container](/Docs/Remove-Container.md)
    + [Add-ContainerFile](/Docs/Add-ContainerFile.md)
    + [Get-ContainerFile](/Docs/Get-ContainerFile.md)
    + [Get-ContainerFileContent](/Docs/Get-ContainerFileContent.md)
    + [Remove-ContainerFile](/Docs/Remove-ContainerFile.md)

### 4.25.0
- Add `codex-mini-latest` model.
- Update deprecation models list.

### 4.24.0
- Add `Connect-RealtimeTranscriptionSession` and `Set-RealtimeTranscriptionSessionConfiguration`.
- Add `gpt-image-1` model support for `Request-ImageGeneration` and `Request-ImageEdit`.
- Add Azure support for `Request-ImageEdit`. (Not fully tested.)
- Update default Azure OpenAI API version to `2025-04-01-preview`.
- Fix some minor issues.

### 4.23.0
- Add `o3` and `o4-mini` models.
- API update.

### 4.22.0
- Updates to supported voice list.
- Add `gpt-4.1`, `gpt-4.1-mini` and `gpt-4.1-nano` models.
- Remove `gpt-4.5-preview` that will be shutdown on 2025-07-14.

### 4.21.0
- Add new function `Request-Response` for OpenAI's new API interface for generating model responses.  
  [Guide: Migrate ChatCompletion to Response](/Guides/Migrate_ChatCompletion_to_Response.md)  
- Update default Azure OpenAI API version to `2025-03-01-preview`.

### 4.20.0
- Add new model and parameter for `Request-AudioSpeech`.  
    + Models: `gpt-4o-mini-tts`
    + Parameters: `-Instructions`
- Add new models and parameters for `Request-AudioTranscription`.  
    + Models: `gpt-4o-transcribe`, `gpt-4o-mini-transcribe`
    + Parameters: `-Include`, `-Stream`, `-StreamOutputType`

```PowerShell
# Example for transcription with streaming output
Request-AudioTranscription -Model 'gpt-4o-transcribe' -File 'C:\audio.wav' -Stream | Write-Host -NoNewline
```

### 4.19.0
- Add new models for `Request-ChatCompletion`.
  + `gpt-4o-search-preview`
  + `gpt-4o-mini-search-preview`
- Add new parameters for Web search to `Request-ChatCompletion`
- Update default Azure OpenAI API version to `2025-02-01-preview`.

```PowerShell
# Example for Web search
Request-ChatCompletion -Model gpt-4o-search-preview -WebSearchContextSize high `
  -Message ' What was a happy news in the world today?'
```

### 4.18.0
- Add `gpt-4.5-preview` model.
- Add model encoding mappings for `gpt-4.5-preview`, `o1` and `o3` models.
- Add `-InterruptResponse` parameter to `Set-RealtimeSessionConfiguration`
- Fix an issue where requests to `*.azure.com` could not be executed when the `ApiType` is `OpenAI`. [#38](https://github.com/mkht/PSOpenAI/issues/38)  
  This allows the use of GitHub Models and Azure ML.
```PowerShell
# Example for GitHub Models
$env:OPENAI_API_KEY  = '<Your-GitHub-Token>'
$env:OPENAI_API_BASE = 'https://models.inference.ai.azure.com/'
Request-ChatCompletion -Message 'Hello.' -Model 'DeepSeek-R1' -ApiType OpenAI
```

### 4.17.0
- Add new functions for storing chat completions.  
  + [Get-ChatCompletion](/Docs/Get-ChatCompletion.md)
  + [Set-ChatCompletion](/Docs/Set-ChatCompletion.md)
  + [Remove-ChatCompletion](/Docs/Remove-ChatCompletion.md)
- Improved handling of refusal messages in `Request-ChatCompletion`.
- Improved stability of `Get-*` commands.
- Minor improvements / fixes.

### 4.16.0
- Add `-ReasoningEffort` parameter to assistant functions.
- Add `o1` and `o3-mini` models to assistant functions.

### 4.15.0
- Add support for `item_reference` content type in `Add-RealtimeSessionItem`.
- Allow `-MaxTokens` and `-MaxCompletionTokens` parameters to accept negative values.  
  This is for compatibility APIs; the official OpenAI API returns an error for values less than `1`.
- Implement new api exception types.
  + `PermissionDeniedException`
  + `ConflictException`
  + `UnprocessableEntityException`
- Minor improvements.

### 4.14.0
- Add `o3-mini` for `Request-ChatCompletion`.
- Add new parameters for `Set-RealtimeSessionConfiguration`.
  + `-InputAudioTranscriptionLanguage`
  + `-InputAudioTranscriptionPrompt`
- Update default Azure OpenAI API version to `2025-01-01-preview`.

### 4.13.1
- Fixed an issue where a request would not execute if only the Images parameter was specified without the Message parameter in `Request-ChatCompletion`. (Issue [#36](https://github.com/mkht/PSOpenAI/issues/36))

### 4.13.0
- Add new voices for `Request-AudioSpeech`.  
  + `ash`, `coral`, `sage`

### 4.12.2
- Fixed an issue where the proper API was not being called when adding items in a Realtime session

### 4.12.0
- Add `-DeveloperMessage` & `-ReasoningEffort` params for `Request-ChatCompletion`.  
- Add `o1` and `gpt-4o-mini-audio-preview` models to tab completions.
- Add `-CreateResponseOnTurnEnd` param for `Set-RealtimeSessionConfiguration`.
- Fixed an issue where model names incompatible with Assistants were included in tab completions.

### 4.11.0
- The model name parameters are now case sensitive.  
  Previously, model names were converted to lowercase internally. This is optimal for the OpenAI, but some compatible API servers require uppercase model names.
- Add `-All`, `-Limit` & `-Order` params for `Get-OpenAIFile`.  

### 4.10.0
- Add `-Prediction` param for `Request-ChatCompletion`.  
  ref: [Use Predicted Outputs](https://platform.openai.com/docs/guides/latency-optimization#use-predicted-outputs)  

### 4.9.1
- Add a support for audio input / output in `Request-ChatCompletion`.

  ```PowerShell
  Request-ChatCompletion -Model gpt-4o-audio-preview `
    -Modalities text, audio `
    -Voice 'shimmer' `
    -InputAudio 'C:\hello.mp3' `
    -AudioOutFile 'C:\response.mp3'
  ```

- Fix an issue with incorrect discontinuance date for the gpt4-32k model.

### 4.8.0
- Add an experimental support for Realtime API.  
  This enables real-time conversations with the AI assitstant. Please refer to this guide.  
  [Guide: How to use Realtime API](/Guides/How_to_use_Realtime_API.md)
- Update default api version of Azure OpenAI Service to `2024-10-01-preview`
- Outputs Run and RunStep error messages as warnings.
- Fix an issue where some request URIs contains duplicate slashes.

### 4.7.0
- Add `-Store` & `-MetaData` params for `Request-ChatCompletion`.  
  For support Stored Completions that was annouced at OpenAI DevDay 2024.

### 4.6.0
- Add `-Images` parameter for `Request-Moderation`.

### 4.5.0
- Add `omni-moderation-latest` model to tab completions.

### 4.4.1
- Refactor file upload handling for non-ASCII filenames.

### 4.4.0
- Add `o1-preview` and `o1-mini` models to tab completions.
- Add `-MaxCompletionTokens` parameter for `Request-ChatCompletion`.  
   The `-MaxTokens` parameter is now deprecated.
- `gpt-3.5-turbo-0613` and `gpt-3.5-turbo-16k-0613` is deprecated on 2024-09-13.  
   You can still call these models, but it is removed from model name completion.

### 4.3.0
- Add `-Include` param for `Get-ThreadRunStep`.
- Add `-RankerForFileSearch` and `-ScoreThresholdForFileSearch` params for `New-Assistant`.
- Add `-PollIntervalSec` param for `Wait-*` functions.
- Update default api version of Azure OpenAI Service to `2024-07-01-preview`
- Fix misc bugs related to Azure OpenAI Service.

### 4.2.0
- Add support for new `chatgpt-4o-latest` model.

### 4.1.1
- Fixed issue that occurred when using `json_schema` in Windows PowerShell 5.1 (#30)

### 4.1.0
- Add a support for Structured Outpus.  
  Please refer to this guide.  
  [Guide: How to use Structured Outputs](/Guides/How_to_use_StructuredOutputs.md)

### 4.0.0
**This is a major release that includes breaking changes.**
- **REMOVE** All Azure specific function is removed.  
  You can use Azure OpenAI Service by `-ApiType` parameter.
- Add `gpt-4o-mini` model to tab completions.

### 3.16.0
- Add `-ServiceTier` parameter to `Request-ChatCompletion`.

### 3.15.1
- Fix issues about Get/Add/Remove-OpenAIFile with Azure OpenAI Service.
- Fix issue that the `New-VectorStore` with `-FileId` parameter.

### 3.15.0
- Add `-ParallelToolCalls` parameter.
- Add `-ChunkingStrategy` parameter.
- Add `-MaxNumberOfFileSearchResults` parameter.

### 3.14.0
- Fix issue on Windows PowerShell 5.1 with Azure OpenAI Service.
- Add `-WaitForRunComplete` param to `Add-ThreadMessage`.  (#15) (Thanks @potatoqualitee!)

### 3.13.0
- Add new utility functions for set commmon params (context)
  + [Get-OpenAIContext](/Docs/Get-OpenAIContext.md)
  + [Set-OpenAIContext](/Docs/Set-OpenAIContext.md)
  + [Clear-OpenAIContext](/Docs/Clear-OpenAIContext.md)
- Improve performance of cl100k_base tokenizer

### 3.12.0
- Support for `o200k_base` tokenizer that is used in `gpt-4o`.
- Add `-AsBatch` for embeddings and text completions.
- Add `incomplete` status of Run.

### 3.11.0
- Add `gpt-4o` model to tab completions.

### 3.10.0
- Add `-Images` parameter to `Add-ThreadMessage`.  
  This makes that the image input can be used in Assistants.
- Fix issues about relative file path input.
- Rename `Register-OpenAIFile` to `Add-OpenAIFile`.  
  (Note: You can still use `Register-OpenAIFile` as an alias. However, in the future release, the alias will be removed.)

### 3.9.1
- Fix issue that the `Start-ThreadRun` would throw an authentication error in some situations. (#11) (Thanks @potatoqualitee!)
- Fix issue that the `Start-ThreadRun` with `-Stream` doesn't work on Windows PowerShell 5.1
- Improve documents.

### 3.9.0
- Add new [Remove-ThreadMessage](/Docs/Remove-ThreadMessage.md) function.
- Add "required" as an option for `-ToolChoice`
- Improve documents.

### 3.8.0
- Commands for Assistants now uses v2 version of API. (Still in beta)
- Add new commands for Vector Store.
- Fix minor issues
  
[Guide: How to use File search with Assistants and Vector Store](/Guides/How_to_use_FileSearch_with_VectorStore.md)

### 3.7.0
- Add new functions for Batch API.  
  
  To use Batch with the new PSOpenAI cmdlets, please refer to this guide.  
  [Guide: How to use Batch](/Guides/How_to_use_Batch.md)

  + `Start-Batch`
  + `Get-Batch`
  + `Wait-Batch`
  + `Stop-Batch`
  + `Get-BatchOutput`

- `Register-OpenAIFile` is used to make byte arrays uploadable without saving them to a file.
  ```PowerShell
  $ByteArray = [System.Text.Encoding]::UTF8.GetBytes('some text data')
  Register-OpenAIFile -Content $ByteArray -Name 'filename.txt' -Purpose assistants
  ```

- All Azure versions of the function is deprecated.  
  Instead, the `-ApiType` parameter added to the normal functions.  
  You can call the Azure OpenAI Service by specifying `-ApiType` as `Azure`.

  ```PowerShell
  $env:OPENAI_API_KEY = '<Put your api key here>'
  $env:OPENAI_API_BASE  = 'https://<your-resource-name>.openai.azure.com/'
  Request-ChatCompletion `
    -Message 'Hello.' `
    -Deployment 'gpt-4' `
    -ApiType Azure
  ```

### 3.6.1
- Fix a bug that caused `New-Assistant` to fail without explicitly passing the model name.
- Fix an issue that `Stop-ThreadRun` does not working.
- Improved code readability using splatting (#6) (Thanks @potatoqualitee!)

### 3.6.0
- Add new params to `Start-ThreadRun`
  + `-MaxPromptTokens`
  + `-MaxCompletionTokens`
  + `-TruncationStrategyType`
  + `-TruncationStrategyLastMessages`
  + `-ToolChoice`
  + `-ToolChoiceFunctionName`
- Updates the list of model names for tab completions.

### 3.5.0
- Add `-AdditionalMessages` parameter to `Start-ThreadRun`
- Add `-RunId` parameter to `Get-ThreadMessage`

### 3.4.0
- Add `-Temperature` parameter to `Start-ThreadRun`

### 3.3.1
- Remove unintended files in the previous release.

### 3.3.0
- Change the parameter type to `[switch]` for `-UseCodeInterpreter` & `-UseRetrieval`
- Add `-Stream` parameter to `Start-ThreadRun`
- Add `-Format` parameter to `Start-ThreadRun`

### 3.2.0
- `Start-ThreadRun` now can be use without preparing threads in advance.

  example :
  ```PowerShell
  $Assistant = New-Assistant -Model "gpt-3.5-turbo"
  $Run = Start-ThreadRun -Assistant $Assistant -Message "Hello, what can you do for me?"
  $Result = $Run | Receive-ThreadRun -Wait
  ```

### 3.1.0
- Change max value of the `-TopLogProbs` parameter to `20`.
- Change default api version of Azure OpenAI Service to `2024-03-01-preview`
- Add new common parameters to almost all functions.
  + `-AdditionalQuery`
  + `-AdditionalHeaders`
  + `-AdditionalBody`
- Fix minor issues.

### 3.0.0
**This is a major release that includes breaking changes.**
- **REMOVE** parameter alias `Engine` from all functions.
- **REMOVE** old encoding support from `ConvertTo-Token` and `ConvertFrom-Token`. Now these commands only support `cl100k_base` encoding. It because all models currently supported by OpenAI use this encoding.  
- Remove `Request-AzureExtensionsChatCompletion`. It was undocumented.
- Fix a bug that a file to be saved in an unexpected location when only a file name is specified in the `-OutFile` parameter.
- Add new functions for using the Assistants API on the Azure OpenAI Service.
- Add `wav` and `pcm` to response format of `Request-AudioSpeech`.

### 2.10.0
- Add new embedding model's support to `ConvertTo-Token`.
- Remove `-InstanceId` parameter to `Request-ChatCompletion`, it because the param does not GA.

### 2.9.0
- Add `-InstanceId` parameter to `Request-ChatCompletion`.

### 2.8.0
- Add `-TimestampGranularities` parameter to `Request-AudioTranscription`.
- Add new [Request-AzureAudioSpeech](/Docs/Request-AzureAudioSpeech.md) function.
- Change default api version of Azure OpenAI Service to `2024-02-15-preview`

### 2.7.0
- The retry logic supports with `retry-after-ms` and `retry-after` response headers.
- Add new model names to tab completions.
- Add `-Dimensions` param for `Request-Embeddings`.
- The exceptions thrown from API requests now have unique type information that differs depending on the error.  
  Also, the exception contains the complete response header and contents, not just the message. This allows for more detailed information about the error.  
  Currently, PSOpenAI has these type of exceptions.
    + `APIRequestException`
    + `BadRequestException`
    + `ContentFilteredException`
    + `UnauthorizedException`
    + `NotFoundException`
    + `RateLimitExceededException`
    + `QuotaLimitExceededException`

### 2.6.2
- Improved performance when executing a large number of requests in a short period of time.

### 2.6.1
- Fixed an issue where a double request was incorrectly executed when a `-Stream` was specified.

### 2.6.0
- Remove `Request-TextEdit` function due to the API endpoint being shut down by OpenAI.
- The retry decision respects the value of the `x-should-retry` response header.
- Updates the list of deprecation models.
- Rebuild libraries using .NET 8

### 2.5.0
- Add `-AdditionalInstructions` parameter to `Start-ThreadRun`.

### 2.4.0
- Add `-LogProbs` and `-TopLogProbs` parameter to `Request-ChatCompletion`.
- Add `-Images` and `-ImageDetail` parameter to `Request-AzureChatCompletion`.  
  These parameters are currently acceptable only on the `gpt-4-vision-preview` model.

### 2.3.0
- `Request-AzureImageGeneration` now supports DALL-E 3 model.
- Change default api version of Azure OpenAI Service to `2023-12-01-preview`
- Fix minor issues.

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
