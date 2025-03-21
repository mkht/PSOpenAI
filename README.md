# PSOpenAI

[![Test](https://github.com/mkht/PSOpenAI/actions/workflows/test.yml/badge.svg)](https://github.com/mkht/PSOpenAI/actions/workflows/test.yml)

PowerShell module for OpenAI and Azure OpenAI Service.  
You can use OpenAI functions such as ChatGPT, Speech-to-Text, Text-to-Image from PowerShell.

**This is a community-based project and is not an official offering of OpenAI.**

+ About OpenAI API  
https://platform.openai.com/docs

+ About Azure OpenAI Service  
https://learn.microsoft.com/en-us/azure/ai-services/openai/overview

日本語版のREADMEは[こちら](/README.ja.md)

----
## Supported Platforms

+ Windows PowerShell 5.1
+ PowerShell 7 or higher
+ Windows, macOS or Linux

You need to sign-up OpenAI account and generates API key for authentication.  
https://platform.openai.com/account/api-keys

----
## Installation

You can install PSOpenAI from [PowerShell Gallery](https://www.powershellgallery.com/packages/PSOpenAI/).
```Powershell
Install-Module -Name PSOpenAI
```

----
## Functions

### Common
+ [ConvertFrom-Token](/Docs/ConvertFrom-Token.md)
+ [ConvertTo-Token](/Docs/ConvertTo-Token.md)
+ [Get-CosineSimilarity](/Docs/Get-CosineSimilarity.md)
+ [Get-OpenAIContext](/Docs/Get-OpenAIContext.md)
+ [Set-OpenAIContext](/Docs/Set-OpenAIContext.md)
+ [Clear-OpenAIContext](/Docs/Clear-OpenAIContext.md)

### OpenAI
#### Chat
[Guide: How to use Chat](/Guides/How_to_use_Chat.md)

+ [Enter-ChatGPT](/Docs/Enter-ChatGPT.md)
+ [Request-ChatCompletion](/Docs/Request-ChatCompletion.md)
+ [Get-ChatCompletion](/Docs/Get-ChatCompletion.md)
+ [Set-ChatCompletion](/Docs/Set-ChatCompletion.md)
+ [Remove-ChatCompletion](/Docs/Remove-ChatCompletion.md)
+ [New-ChatCompletionFunction](/Docs/New-ChatCompletionFunction.md)

#### Assistants
[Guide: How to use Assistants](/Guides/How_to_use_Assistants.md)  
[Guide: How to use File search with Assistants and Vector Store](/Guides/How_to_use_FileSearch_with_VectorStore.md)

+ [Get-Assistant](/Docs/Get-Assistant.md)
+ [New-Assistant](/Docs/New-Assistant.md)
+ [Set-Assistant](/Docs/Set-Assistant.md)
+ [Remove-Assistant](/Docs/Remove-Assistant.md)
+ [Get-Thread](/Docs/Get-Thread.md)
+ [New-Thread](/Docs/New-Thread.md)
+ [Set-Thread](/Docs/Set-Thread.md)
+ [Remove-Thread](/Docs/Remove-Thread.md)
+ [Get-ThreadMessage](/Docs/Get-ThreadMessage.md)
+ [Add-ThreadMessage](/Docs/Add-ThreadMessage.md)
+ [Remove-ThreadMessage](/Docs/Remove-ThreadMessage.md)
+ [Get-ThreadRun](/Docs/Get-ThreadRun.md)
+ [Start-ThreadRun](/Docs/Start-ThreadRun.md)
+ [Stop-ThreadRun](/Docs/Stop-ThreadRun.md)
+ [Wait-ThreadRun](/Docs/Wait-ThreadRun.md)
+ [Receive-ThreadRun](/Docs/Receive-ThreadRun.md)
+ [Get-ThreadRunStep](/Docs/Get-ThreadRunStep.md)
+ [Get-VectorStore](/Docs/Get-VectorStore.md)
+ [New-VectorStore](/Docs/New-VectorStore.md)
+ [Set-VectorStore](/Docs/Set-VectorStore.md)
+ [Remove-VectorStore](/Docs/Remove-VectorStore.md)
+ [Add-VectorStoreFile](/Docs/Add-VectorStoreFile.md)
+ [Get-VectorStoreFile](/Docs/Get-VectorStoreFile.md)
+ [Remove-VectorStoreFile](/Docs/Remove-VectorStoreFile.md)
+ [Start-VectorStoreFileBatch](/Docs/Start-VectorStoreFileBatch.md)
+ [Get-VectorStoreFileBatch](/Docs/Get-VectorStoreFileBatch.md)
+ [Stop-VectorStoreFileBatch](/Docs/Stop-VectorStoreFileBatch.md)
+ [Wait-VectorStoreFileBatch](/Docs/Wait-VectorStoreFileBatch.md)
+ [Get-VectorStoreFileInBatch](/Docs/Get-VectorStoreFileInBatch.md)

#### Realtime
[Guide: How to use Realtime API](/Guides/How_to_use_Realtime_API.md)  

+ [Connect-RealtimeSession](/Docs/Connect-RealtimeSession.md)
+ [Disconnect-RealtimeSession](/Docs/Disconnect-RealtimeSession.md)
+ [Set-RealtimeSessionCofiguration](/Docs/Set-RealtimeSessionCofiguration.md)
+ [Send-RealtimeSessionEvent](/Docs/Send-RealtimeSessionEvent.md)
+ [Add-RealtimeSessionItem](/Docs/Add-RealtimeSessionItem.md)
+ [Remove-RealtimeSessionItem](/Docs/Remove-RealtimeSessionItem.md)
+ [Request-RealtimeSessionResponse](/Docs/Request-RealtimeSessionResponse.md)
+ [Stop-RealtimeSessionResponse](/Docs/Stop-RealtimeSessionResponse.md)
+ [Start-RealtimeSessionAudioInput](/Docs/Start-RealtimeSessionAudioInput.md) *
+ [Stop-RealtimeSessionAudioInput](/Docs/Stop-RealtimeSessionAudioInput.md) *
+ [Start-RealtimeSessionAudioOutput](/Docs/Start-RealtimeSessionAudioInput.md) *
+ [Stop-RealtimeSessionAudioOutput](/Docs/Stop-RealtimeSessionAudioInput.md) *

> [*] Works on Windows with PowerShell 7.4+ only.

#### Images
+ [Request-ImageEdit](/Docs/Request-ImageEdit.md)
+ [Request-ImageGeneration](/Docs/Request-ImageGeneration.md)
+ [Request-ImageVariation](/Docs/Request-ImageVariation.md)

#### Audio
+ [Request-AudioSpeech](/Docs/Request-AudioSpeech.md)
+ [Request-AudioTranscription](/Docs/Request-AudioTranscription.md)
+ [Request-AudioTranslation](/Docs/Request-AudioTranslation.md)

#### Files
+ [Get-OpenAIFile](/Docs/Get-OpenAIFile.md)
+ [Add-OpenAIFile](/Docs/Add-OpenAIFile.md)
+ [Remove-OpenAIFile](/Docs/Remove-OpenAIFile.md)
+ [Get-OpenAIFileContent](/Docs/Get-OpenAIFileContent.md)

#### Batch
[Guide: How to use Batch](/Guides/How_to_use_Batch.md)

+ [Start-Batch](/Docs/Start-Batch.md)
+ [Get-Batch](/Docs/Get-Batch.md)
+ [Wait-Batch](/Docs/Wait-Batch.md)
+ [Stop-Batch](/Docs/Stop-Batch.md)
+ [Get-BatchOutput](/Docs/Get-BatchOutput.md)

#### Others
+ [Get-OpenAIModels](/Docs/Get-OpenAIModels.md)
+ [Request-Embeddings](/Docs/Request-Embeddings.md)
+ [Request-Moderation](/Docs/Request-Moderation.md)
+ [Request-TextCompletion](/Docs/Request-TextCompletion.md)

### Azure OpenAI Service
+ [Guide: How to use with Azure OpenAI Service](Guides/How_to_use_with_Azure_OpenAI_Service.md)

----
## Usages

See [Docs](/Docs) and [Guides](/Guides) for more detailed and complex scenario descriptions.

### ChatGPT (Interactive)

Communicate with ChatGPT interactively on the console.  

```PowerShell
$global:OPENAI_API_KEY = '<Put your API key here.>'
Enter-ChatGPT
```

![Interactive Chat](/Docs/images/InteractiveChat.gif)


### ChatGPT (Scripting)

You can ask questions to ChatGPT.

```PowerShell
$global:OPENAI_API_KEY = '<Put your API key here.>'
$Result = Request-ChatCompletion -Message "Who are you?"
Write-Output $Result.Answer
```

This code outputs answer from ChatGPT

```
I am an AI language model created by OpenAI, designed to assist with ...
```

> [!TIP]  
> The default model used is GPT-3.5-Turbo.  
> If you want to use other models such as GPT-4o, you can specifies model explicitly like this.  
> ```PowerShell
> Request-ChatCompletion -Message "Who are you?" -Model "gpt-4o"
> ```


### Audio Speech (Text-to-Speech)

Generates audio from the input text.

```PowerShell
$global:OPENAI_API_KEY = '<Put your API key here.>'
Request-AudioSpeech -Text 'Do something fun to play.' -OutFile 'C:\Output\text2speech.mp3' -Voice Onyx
```

You can combine with ChatGPT.

```PowerShell
Request-ChatCompletion -Message "Who are you?" | Request-AudioSpeech -OutFile 'C:\Output\ChatAnswer.mp3' -Voice Nova
```


### Audio transcription (Speech-to-Text)

Transcribes audio into the input language.

```PowerShell
$global:OPENAI_API_KEY = '<Put your API key here.>'
Request-AudioTranscription -File 'C:\SampleData\audio.mp3' -Format text
```

This code transcribes voice in `C:\SampleData\audio.mp3`. Like this.

```
Perhaps he made up to the party afterwards and took her and ...
```

### Image generation (Text-to-Image)

Creating images from scratch based on a text prompt.

```PowerShell
$global:OPENAI_API_KEY = '<Put your API key here.>'
Request-ImageGeneration -Prompt 'A cute baby lion' -Model 'dall-e-2' -Size 256x256 -OutFile 'C:\output\babylion.png'
```

This sample code saves image to `C:\output\babylion.png`.
The saved image like this.

![Generated image](/Docs/images/babylion.png)


### Multiple conversations with ChatGPT while keeping context.

`Request-ChatCompletion` accepts past dialogs from pipeline. Additional questions can be asked while maintaining context.

```PowerShell
PS C:\> $FirstQA = Request-ChatCompletion -Message "What is the population of the United States?"
PS C:\> Write-Output $FirstQA.Answer

As of September 2021, the estimated population of the United States is around 331.4 million people.

PS C:\> $SecondQA = $FirstQA | Request-ChatCompletion -Message "Translate the previous answer into French."
PS C:\> Write-Output $SecondQA.Answer

En septembre 2021, la population estimée des États-Unis est d'environ 331,4 millions de personnes.

PS C:\> $ThirdQA = $SecondQA | Request-ChatCompletion -Message 'Please make it shorter.'
PS C:\> Write-Output $ThirdQA.Answer

La population des États-Unis est estimée à environ 331,4 millions de personnes.
```

### Stream completion outputs

By default, results are output all at once after all OpenAI responses are complete, so it may take some time before results are available.

To get responses sooner, you can use the `-Stream` option for `Request-ChatCompletion` and `Request-TextCompletion`. The results will be returned as a "stream". (similar to how ChatGPT WebUI displays)

```PowerShell
Request-ChatCompletion 'Describe ChatGPT in 100 charactors.' -Stream | Write-Host -NoNewline
```

![Stream](/Docs/images/StreamOutput.gif)


### Restore masked images

```PowerShell
Request-ImageEdit -Image 'C:\sunflower_masked.png' -Prompt 'sunflower' -OutFile 'C:\sunflower_restored.png' -Size 256x256
```

Masked image is restored to full images by AI models.

| Source                                       | Generated                                        |
| -------------------------------------------- | ------------------------------------------------ |
| ![masked](/Docs/images/sunflower_masked.png) | ![restored](/Docs/images/sunflower_restored.png) |


### Moderation

Test whether text complies with OpenAI's content policies.

> The moderation endpoint is free to use when monitoring the inputs and outputs of OpenAI APIs.

```PowerShell
PS C:\> $Result = Request-Moderation -Text "I want to kill them."
PS C:\> $Result.results.categories

# True means it violates that category.
sexual           : False
hate             : False
violence         : True
self-harm        : False
sexual/minors    : False
hate/threatening : False
violence/graphic : False
```

----
## About API key

+ [Guide: How to handle API keys and context parameters](Guides/How_to_handle_API-keys_and_Context.md)

Almost all functions require an API key for authentication.  
You need to sign-up OpenAI account and generates API key from here.  
https://platform.openai.com/account/api-keys

There are three ways to give an API key to functions.

### Method 1: Set an environment variable named `OPENAI_API_KEY`. (RECOMMENDED)
Set the API key to the environment variable named `OPENAI_API_KEY`.  
This method is best suited when running on a trusted host or CI/CD pipeline.

```PowerShell
PS C:> $env:OPENAI_API_KEY = '<Put your API key here.>'
PS C:> Request-ChatCompletion -Message "Who are you?"
```

### Method 2: Set a global variable named `OPENAI_API_KEY`.
Set the API key to the `$global:OPENAI_API_KEY` variable. The variable is implicitly used whenever a function is called within the session.  

```PowerShell
PS C:> $global:OPENAI_API_KEY = '<Put your API key here.>'
PS C:> Request-ChatCompletion -Message "Who are you?"
```

### Method 3: Supply as named parameter.
Specify the API key explicitly in the `ApiKey` parameter. It must be specified each time the function is called.  
This is best used when the function is called only once or with few calls, such as when executing manually from the console.

```PowerShell
PS C:> Request-ChatCompletion -Message "Who are you?" -ApiKey '<Put your API key here.>'
```

## Azure OpenAI Service
If you want to use Azure OpenAI Service instead of OpenAI. You should create Azure OpenAI resource to your Azure tenant, and get API key and endpoint url. See guides for more details.

+ [Guide: How to use with Azure OpenAI Service](Guides/How_to_use_with_Azure_OpenAI_Service.md)

### Sample code for Azure
```powershell
$global:OPENAI_API_KEY = '<Put your api key here>'
$global:OPENAI_API_BASE  = 'https://<resource-name>.openai.azure.com/'

Request-ChatCompletion `
  -Message 'Hello Azure OpenAI Service.' `
  -Model 'gpt-4o' `
  -ApiType Azure
```

----
## Changelog

[CHANGELOG.md](/CHANGELOG.md)

----
## Plans and TODOs.

If you have a feature request or bug report, please tell us in Issue.

+ More docs, samples.
+ Performance improvements.
+ Add a support for fine-tuning.

----
## License & Libraries

[MIT License](/LICENSE)

This module uses these OSS libraries.

- [Newtonsoft.Json](https://www.newtonsoft.com/json) by jamesnk (MIT License)
- [NJsonSchema](https://github.com/RicoSuter/NJsonSchema) by rsuter (MIT License)
- [Microsoft.DeepDev.TokenizerLib](https://github.com/microsoft/Tokenizer) by microsoft (MIT License)
- [NAudio](https://github.com/naudio/NAudio) by Mark Heath (MIT License)
