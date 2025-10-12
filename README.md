# PSOpenAI

[![Test](https://github.com/mkht/PSOpenAI/actions/workflows/test.yml/badge.svg)](https://github.com/mkht/PSOpenAI/actions/workflows/test.yml)

PowerShell module for OpenAI and Azure OpenAI Service.  
You can use OpenAI functions such as ChatGPT, Speech-to-Text, Text-to-Image from PowerShell.

**This is a community-based project and is not an official offering of OpenAI.**

+ About OpenAI API  
https://platform.openai.com/docs

+ About Azure OpenAI Service  
https://learn.microsoft.com/en-us/azure/ai-services/openai/overview

----
## Supported Platforms

+ Windows PowerShell 5.1
+ PowerShell 7 or higher
+ Windows, macOS or Linux

You need to sign-up OpenAI account and generates API key for authentication.  
https://platform.openai.com/api-keys

----
## Installation

You can install PSOpenAI from [PowerShell Gallery](https://www.powershellgallery.com/packages/PSOpenAI/).
```Powershell
Install-Module -Name PSOpenAI
```

----
## Functions

<details>
<summary>The full list of functions</summary>

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

#### Responses
[Guide: Migrate ChatCompletion to Response](/Guides/Migrate_ChatCompletion_to_Response.md)  

+ [Request-Response](/Docs/Request-Response.md)
+ [Get-Response](/Docs/Get-Response.md)
+ [Remove-Response](/Docs/Remove-Response.md)
+ [Get-ResponseInputItem](/Docs/Get-ResponseInputItem.md)

#### Conversations
+ [New-Conversation](/Docs/New-Conversation.md)
+ [Get-Conversation](/Docs/Get-Conversation.md)
+ [Set-Conversation](/Docs/Set-Conversation.md)
+ [Remove-Conversation](/Docs/Remove-Conversation.md)
+ [Add-ConversationItem](/Docs/Add-ConversationItem.md)
+ [Get-ConversationItem](/Docs/Get-ConversationItem.md)
+ [Remove-ConversationItem](/Docs/Remove-ConversationItem.md)

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
+ [Connect-RealtimeTranscriptionSession](/Docs/Connect-RealtimeTranscriptionSession.md)
+ [Disconnect-RealtimeSession](/Docs/Disconnect-RealtimeSession.md)
+ [Set-RealtimeSessionConfiguration](/Docs/Set-RealtimeSessionConfiguration.md)
+ [Set-RealtimeTranscriptionSessionConfiguration](/Docs/Set-RealtimeTranscriptionSessionConfiguration.md)
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

#### Videos
+ [New-Video](/Docs/New-Video.md)
+ [New-VideoRemix](/Docs/New-VideoRemix.md)
+ [Get-Video](/Docs/Get-Video.md)
+ [Get-VideoContent](/Docs/Get-VideoContent.md)
+ [Remove-Video](/Docs/Remove-Video.md)

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

### Containers
+ [New-Container](/Docs/New-Container.md)
+ [Get-Container](/Docs/Get-Container.md)
+ [Remove-Container](/Docs/Remove-Container.md)
+ [Add-ContainerFile](/Docs/Add-ContainerFile.md)
+ [Get-ContainerFile](/Docs/Get-ContainerFile.md)
+ [Remove-ContainerFile](/Docs/Remove-ContainerFile.md)
+ [Get-ContainerFileContent](/Docs/Get-ContainerFileContent.md)

#### Others
+ [Get-OpenAIModels](/Docs/Get-OpenAIModels.md)
+ [Request-Embeddings](/Docs/Request-Embeddings.md)
+ [Request-Moderation](/Docs/Request-Moderation.md)
+ [Request-TextCompletion](/Docs/Request-TextCompletion.md)

### Azure OpenAI Service
+ [Guide: How to use with Azure OpenAI Service](Guides/How_to_use_with_Azure_OpenAI_Service.md)

</details>

----
## Usage

See [Docs](/Docs) and [Guides](/Guides) for more detailed and complex scenario descriptions.

### Responses

The primary method for interacting with OpenAI models. You can generate text from the model with the code below.

```PowerShell
$env:OPENAI_API_KEY = '<Put your API key here.>'
$Response = Request-Response -Model 'gpt-4o' -Message 'Explain quantum physics in simple terms.'
Write-Output $Response.output_text
```

This code outputs answer from model like this.

```
Quantum physics is a branch of science that deals with the behavior of ...
```

### Chat Completions

The previous standard for generating text is the Chat Completions API. You can use that API to generate text from the model with the code below.  

Chat Completions API is compatible with other AI services besides OpenAI, such as GitHub Models and Google Gemini. You can also use self-hosted local AI models with LM Studio or Ollama. That is explained in the Advanced section.

```PowerShell
$env:OPENAI_API_KEY = '<Put your API key here.>'
$Completion = Request-ChatCompletion -Model 'gpt-4o' -Message 'Give me a recipe for chocolate cake.'
Write-Output $Completion.Answer[0]
```

### Audio Speech (Text-to-Speech)

Generates audio from the input text.

```PowerShell
$env:OPENAI_API_KEY = '<Put your API key here.>'
Request-AudioSpeech -Model 'gpt-4o-mini-tts' -Text 'Hello, My name is shimmer.' -OutFile 'C:\Output\text2speech.mp3' -Voice shimmer
```

### Audio transcription (Speech-to-Text)

Transcribes audio into the input language.

```PowerShell
$global:OPENAI_API_KEY = '<Put your API key here.>'
Request-AudioTranscription -Model 'gpt-4o-transcribe' -File 'C:\SampleData\audio.mp3'
```

### Image generation

Creating images from scratch based on a text prompt.

```PowerShell
$global:OPENAI_API_KEY = '<Put your API key here.>'
Request-ImageGeneration -Model 'gpt-image-1' -Prompt 'A cute baby lion' -Size 1024x1024 -OutFile 'C:\output\babylion.png'
```

This sample code saves image to `C:\output\babylion.png`. The saved image like this.

![Generated image](/Docs/images/babylion.png)

### Image edit

```PowerShell
Request-ImageEdit -Model 'gpt-image-1' -Prompt 'A bird on the desert' -Image 'C:\sand_with_fether.png' -OutFile 'C:\bird_on_desert.png' -Size 1024x1024
```

The edited image like this.

| Original                                        | Generated                                  |
| ----------------------------------------------- | ------------------------------------------ |
| ![original](/Docs/images/sand_with_feather.png) | ![edited](/Docs/images/bird_on_desert.png) |

### Video generation
Generate a video from a text prompt.

```PowerShell
$VideoJob = New-Video -Model 'sora-2' -Prompt "A cat playing piano" -Size 1280x720
$VideoJob | Get-VideoContent -OutFile "C:\output\cat_piano.mp4" -WaitForCompletion
```

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

### List available models

Get a list of available models.

```PowerShell
$Models = Get-OpenAIModels
```

### Realtime

The Realtime API enables you to communicate with AI models live, in real time experiences.

Here's a basic text-based example. For more detailed usage, please refer to the guide.
[Guide: How to use Realtime API](/Guides/How_to_use_Realtime_API.md)

```PowerShell
$env:OPENAI_API_KEY = '<Put your API key here>'

# Subscribe to events
Register-EngineEvent -SourceIdentifier 'PSOpenAI.Realtime.ReceiveMessage' -Action {
    $eventItem = $Event.SourceArgs[0]
    switch ($eventItem.type) {
        'response.output_text.delta' {
            $eventItem.delta | Write-Host -NoNewLine -ForegroundColor Blue
        }
    }
}

# Connect to the Realtime session
Connect-RealtimeSession -Model 'gpt-realtime'
Set-RealtimeSessionConfiguration -Modalities 'text' -Instructions 'You are a science tutor.'

# Send messages to the AI model
Add-RealtimeSessionItem -Message 'Why does the sun rise in the east and set in the west?' -TriggerResponse

# Disconnect
Disconnect-RealtimeSession
```

----
## Advanced

### Multiple conversations keeping context.

`Request-Response` and `Request-ChatCompletion` accepts past dialogs from pipeline. Additional questions can be asked while maintaining context.

```PowerShell
PS C:\> $FirstQA = Request-ChatCompletion -Model 'gpt-4.1-nano' -Message 'What is the population of the United States?'
PS C:\> Write-Output $FirstQA.Answer

As of October 2023, the estimated population of the United States is approximately 336 million people.

PS C:\> $SecondQA = $FirstQA | Request-ChatCompletion -Message 'Translate the previous answer into French.'
PS C:\> Write-Output $SecondQA.Answer

En octobre 2023, la population estimée des États-Unis est d'environ 336 millions de personnes.

PS C:\> $ThirdQA = $SecondQA | Request-ChatCompletion -Message 'Just tell me the number.'
PS C:\> Write-Output $ThirdQA.Answer

336 millions
```

### Streaming responses

By default, results are output all at once after all responses are complete, so it may take some time before results are available. To get responses sooner, you can use the `-Stream` option for `Request-ChatCompletion` and `Request-Response`

```PowerShell
Request-ChatCompletion 'Describe ChatGPT in 100 charactors.' -Stream | Write-Host -NoNewline
```

![Stream](/Docs/images/StreamOutput.gif)


### Vision (Image input)

You can input images to the model and get answers.

```PowerShell
# Local file
$Response = Request-Response -Model 'o4-mini' -Images 'C:\SampleData\donut.png' -Message 'How many donuts are there?'

# Remote URL
$Response = Request-Response -Model 'o4-mini' -Images 'https://upload.wikimedia.org/wikipedia/commons/5/5f/Cerro_El_%C3%81vila_desde_El_Bosque_-_Caracas.jpg' -Message 'Where is this?'
```

### Web Search

Allow models to search the web for the latest information before generating a response.

```PowerShell
$Response = Request-Response -Model 'gpt-4.1' -Message 'What was a tech news in Merch 2025?' -UseWebSearch
```

### Azure OpenAI Service

If you want to use Azure OpenAI Service instead of OpenAI. You should create Azure OpenAI resource to your Azure tenant, and get API key and endpoint url. See guides for more details.

+ [Guide: How to use with Azure OpenAI Service](Guides/How_to_use_with_Azure_OpenAI_Service.md)

```powershell
$global:OPENAI_API_KEY = '<Put your api key here>'
$global:OPENAI_API_BASE  = 'https://<resource-name>.openai.azure.com/'

Request-ChatCompletion `
  -Model 'gpt-4o' `
  -Message 'Hello Azure OpenAI Service.' `
  -ApiType Azure
```

### OpenAI Compatible Servers

If you want to use OpenAI compatible services such as GitHub Models, Google Gemini, self-hosted servers like LM Studio or Ollama.

```powershell
# This is an example for GitHub Models.
$global:OPENAI_API_KEY = '<Put your GITHUB_TOKEN>'
$global:OPENAI_API_BASE  = 'https://models.github.ai/inference'

Request-ChatCompletion `
  -Model 'microsoft/Phi-4-reasoning' `
  -Message 'What is the capital of France?' `
  -ApiType OpenAI
```

----
## About API key

+ [Guide: How to handle API keys and context parameters](Guides/How_to_handle_API-keys_and_Context.md)

Almost all functions require an API key for authentication.  
You need to sign-up OpenAI account and generates API key from here.  
https://platform.openai.com/api-keys

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
