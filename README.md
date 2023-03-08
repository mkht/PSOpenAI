# PSOpenAI

PowerSell module for OpenAI API.
You can use OpenAI functions such as ChatGPT, Speech-to-Text, Text-to-Image from PowerShell.

**This is a community-based project and is not an official offering of OpenAI.**

日本語版のREADMEは[こちら](/README.ja.md)

----
## Requirements

+ Windows PowerShell 5.1
+ PowerShell 7 or higher

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

+ [Get-OpenAIModels](/Docs/Get-OpenAIModels.md)
+ [Request-AudioTranscription](/Docs/Request-AudioTranscription.md)
+ [Request-AudioTranslation](/Docs/Request-AudioTranslation.md)
+ [Request-ChatCompletion](/Docs/Request-ChatCompletion.md)
+ [Request-ChatGPT](/Docs/Request-ChatCompletion.md)
+ [Request-CodeEdit](/Docs/Request-CodeEdit.md)
+ [Request-ImageEdit](/Docs/Request-ImageEdit.md)
+ [Request-ImageGeneration](/Docs/Request-ImageGeneration.md)
+ [Request-ImageVariation](/Docs/Request-ImageVariation.md)
+ [Request-Moderation](/Docs/Request-Moderation.md)
+ [Request-TextCompletion](/Docs/Request-TextCompletion.md)
+ [Request-TextEdit](/Docs/Request-TextEdit.md)

----
## Usages

### ChatGPT

You can ask questions to ChatGPT.

```PowerShell
$global:OPENAI_TOKEN = '<Put your API key here.>'
$Result = Request-ChatGPT -Message "Who are you?"
Write-Output $Result.Answer
```

This code ouputs answer from ChatGPT

```
I am an AI language model created by OpenAI, designed to assist with ...
```

### Audio transcription (Speech-to-Text)

Transcribes audio into the input language.

```PowerShell
$global:OPENAI_TOKEN = '<Put your API key here.>'
Request-AudioTranscription -File 'C:\SampleData\audio.mp3' -Format text
```

This code transcribes voice in `C:\SampleData\audio.mp3`. Like this.

```
Perhaps he made up to the party afterwards and took her and ...
```

### Image generation (Text-to-Image)

Creating images from scratch based on a text prompt.

```PowerShell
$global:OPENAI_TOKEN = '<Put your API key here.>'
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

### Code generation

Generates program code from instructions.

```PowerShell
Request-CodeEdit -Instruction 'Write a function in python that calculates fibonacci' | select -ExpandProperty Answer
```

```python
def fibonacci(num):
    a = 0
    b = 1
    if num ==1:
       print(a)
    else:
        print(a)
        print(b)
        #the sequence starts with 0,1
        for i in range(2,num):
            c = a+b
            a = b
            b = c
            print(c)

fibonacci(10)
```

### Restore masked images

```PowerShell
Request-ImageEdit -Image 'C:\sunflower_masked.png' -Prompt 'sunflower' -OutFile 'C:\sunflower_restored.png' -Size 256x256
```

Masked image is restored to full images by AI models.

|Source|Generated|
|----|----|
| ![masked](/Docs/images/sunflower_masked.png)  | ![restored](/Docs/images/sunflower_restored.png)   |


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

### Method 1: Supply as named parameter.
Specify the API key explicitly in the `Token` parameter. It must be specified each time the function is called.  
This is best used when the function is called only once or with few calls, such as when executing manually from the console.

```PowerShell
PS C:> Request-ChatGPT -Message "Who are you?" -Token '<Put your API key here.>'
```

### Method 2: Set a global variable named `OPENAI_TOKEN`.
Set the API key to the `$global:OPENAI_TOKEN` variable. The variable is implicitly used whenever a function is called within the session.  

```PowerShell
PS C:> $global:OPENAI_TOKEN = '<Put your API key here.>'
PS C:> Request-ChatGPT -Message "Who are you?"
```

### Method 3: Set an environment variable named `OPENAI_TOKEN`.
Set the API key to the environment variable named `OPENAI_TOKEN`.  
This method is best suited when running on a trusted host or CI/CD pipeline.

```PowerShell
PS C:> $env:OPENAI_TOKEN = '<Put your API key here.>'
PS C:> Request-ChatGPT -Message "Who are you?"
```


----
## Changelog
### 1.0.0
 - Initial public release.


----
## Plans and TODOs.

If you have a feature request or bug report, please tell us in Issue.

+ Write Pester test codes.
+ Automated testing including non-Windows environments.
+ Performance improvements.
+ Add GPT-3 fine-tuning support.
+ Add some missing parameters, such like `stop` or `logit_bias`.
+ Add an option for change output types / formats.
+ Logs, verbose messages.

----
## Licenses
[MIT License](/LICENSE)
