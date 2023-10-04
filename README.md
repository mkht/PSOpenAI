# PSOpenAI

[![Test](https://github.com/mkht/PSOpenAI/actions/workflows/test.yml/badge.svg)](https://github.com/mkht/PSOpenAI/actions/workflows/test.yml)

PowerShell module for OpenAI and Azure OpenAI Service.
You can use OpenAI functions such as ChatGPT, Speech-to-Text, Text-to-Image from PowerShell.

**This is a community-based project and is not an official offering of OpenAI.**

+ About OpenAI API  
https://platform.openai.com/docs

+ About Azure OpenAI Service  
https://learn.microsoft.com/en-us/azure/cognitive-services/openai/overview

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

### OpenAI
+ [Enter-ChatGPT](/Docs/Enter-ChatGPT.md)
+ [Get-OpenAIModels](/Docs/Get-OpenAIModels.md)
+ [New-ChatCompletionFunction](/Docs/New-ChatCompletionFunction.md)
+ [Request-AudioTranscription](/Docs/Request-AudioTranscription.md)
+ [Request-AudioTranslation](/Docs/Request-AudioTranslation.md)
+ [Request-ChatCompletion](/Docs/Request-ChatCompletion.md)
+ [Request-ChatGPT](/Docs/Request-ChatCompletion.md)
+ [Request-Embeddings](/Docs/Request-Embeddings.md)
+ [Request-ImageEdit](/Docs/Request-ImageEdit.md)
+ [Request-ImageGeneration](/Docs/Request-ImageGeneration.md)
+ [Request-ImageVariation](/Docs/Request-ImageVariation.md)
+ [Request-Moderation](/Docs/Request-Moderation.md)
+ [Request-TextCompletion](/Docs/Request-TextCompletion.md)
+ [Request-TextEdit](/Docs/Request-TextEdit.md)

### Azure OpenAI Service
+ [Get-AzureOpenAIModels](/Docs/Get-AzureOpenAIModels.md)
+ [Get-AzureOpenAIDeployments](/Docs/Get-AzureOpenAIDeployments.md)
+ [New-AzureOpenAIDeployments](/Docs/New-AzureOpenAIDeployments.md)
+ [Remove-AzureOpenAIDeployments](/Docs/Remove-AzureOpenAIDeployments.md)
+ [Request-AzureAudioTranscription](/Docs/Request-AzureAudioTranscription.md)
+ [Request-AzureAudioTranslation](/Docs/Request-AzureAudioTranslation.md)
+ [Request-AzureChatCompletion](/Docs/Request-AzureChatCompletion.md)
+ [Request-AzureChatGPT](/Docs/Request-AZureChatCompletion.md)
+ [Request-AzureEmbeddings](/Docs/Request-AzureEmbeddings.md)
+ [Request-AzureImageGeneration](/Docs/Request-AzureImageGeneration.md)
+ [Request-AzureTextCompletion](/Docs/Request-AzureTextCompletion.md)

----
## Usages

See [Docs](/Docs) and [Examples](/Examples) for more detailed and complex scenario descriptions.

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
$Result = Request-ChatGPT -Message "Who are you?"
Write-Output $Result.Answer
```

This code ouputs answer from ChatGPT

```
I am an AI language model created by OpenAI, designed to assist with ...
```

> Tips:  
> The default model used is GPT-3.5.  
> If you can and want to use GPT-4, you can specifies model explicitly like this.  
> ```PowerShell
> Request-ChatGPT -Message "Who are you?" -Model "gpt-4"
> ```
> 

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
Request-ImageGeneration -Prompt 'A cute baby lion' -Size 256x256 -OutFile 'C:\output\babylion.png'
```

This sample code saves image to `C:\output\babylion.png`.
The saved image like this.

![Generated image](/Docs/images/babylion.png)


### Multiple conversations with ChatGPT while keeping context.

`Request-ChatGPT` accepts past dialogs from pipeline. Additional questions can be asked while maintaining context.

```PowerShell
PS C:\> $FirstQA = Request-ChatGPT -Message "What is the population of the United States?"
PS C:\> Write-Output $FirstQA.Answer

As of September 2021, the estimated population of the United States is around 331.4 million people.

PS C:\> $SecondQA = $FirstQA | Request-ChatGPT -Message "Translate the previous answer into French."
PS C:\> Write-Output $SecondQA.Answer

En septembre 2021, la population estimée des États-Unis est d'environ 331,4 millions de personnes.

PS C:\> $ThirdQA = $SecondQA | Request-ChatGPT -Message 'Please make it shorter.'
PS C:\> Write-Output $ThirdQA.Answer

La population des États-Unis est estimée à environ 331,4 millions de personnes.
```

### Stream completion outputs

By default, results are output all at once after all OpenAI responses are complete, so it may take some time before results are available.

To get responses sooner, you can use the `-Stream` option for `Request-ChatGPT` and `Request-TextCompletion`. The results will be returned as a "stream". (similar to how ChatGPT WebUI displays)

```PowerShell
Request-ChatGPT 'Describe ChatGPT in 100 charactors.' -Stream | Write-Host -NoNewline
```

![Stream](/Docs/images/StreamOutput.gif)

### Function calling

`Function calling` is an optional capabilities in the Chat Completions API which can be used to provide function specifications. The purpose of this is to enable models to generate function arguments which adhere to the provided specifications.

See detailed usage guide [here](/Examples/How_to_call_functions_with_ChatGPT.ipynb).

```PowerShell
$Message = 'Ping the Google Public DNS address three times and briefly report the results.'
$PingFunction = New-ChatCompletionFunction -Command 'Test-Connection' -IncludeParameters ('TargetName', 'Count')
$Answer = Request-ChatCompletion -Message $Message -Model gpt-3.5-turbo-0613 -Functions $PingFunction -InvokeFunctionOnCallMode Auto
```

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
Almost all functions require an API key for authentication.  
You need to sign-up OpenAI account and generates API key from here.  
https://platform.openai.com/account/api-keys

There are three ways to give an API key to functions.

### Method 1: Set an environment variable named `OPENAI_API_KEY`. (RECOMMENDED)
Set the API key to the environment variable named `OPENAI_API_KEY`.  
This method is best suited when running on a trusted host or CI/CD pipeline.

```PowerShell
PS C:> $env:OPENAI_API_KEY = '<Put your API key here.>'
PS C:> Request-ChatGPT -Message "Who are you?"
```

### Method 2: Set a global variable named `OPENAI_API_KEY`.
Set the API key to the `$global:OPENAI_API_KEY` variable. The variable is implicitly used whenever a function is called within the session.  

```PowerShell
PS C:> $global:OPENAI_API_KEY = '<Put your API key here.>'
PS C:> Request-ChatGPT -Message "Who are you?"
```

### Method 3: Supply as named parameter.
Specify the API key explicitly in the `ApiKey` parameter. It must be specified each time the function is called.  
This is best used when the function is called only once or with few calls, such as when executing manually from the console.

```PowerShell
PS C:> Request-ChatGPT -Message "Who are you?" -ApiKey '<Put your API key here.>'
```

## Azure OpenAI Service
If you want to use Azure OpenAI Service instead of OpenAI. You should create Azure OpenAI resource to your Azure tenant, and get API key and endpoint url. See examples for more details.

+ [How to use with Azure OpenAI Service](Examples/How_to_use_with_Azure_OpenAI_Service.ipynb)

### Sample code for Azure
```powershell
$global:OPENAI_API_KEY = '<Put your api key here>'
$global:OPENAI_API_BASE  = 'https://<resource-name>.openai.azure.com/'

Request-AzureChatCompletion `
  -Message 'Hello Azure OpenAI Service.' `
  -Deployment 'gpt-35-turbo `
```

----
## Changelog

[CHANGELOG.md](/CHANGELOG.md)

----
## Plans and TODOs.

If you have a feature request or bug report, please tell us in Issue.

+ More docs, samples.
+ Performance improvements.
+ Add an option for change output types / formats.

----
## Licenses
[MIT License](/LICENSE)
