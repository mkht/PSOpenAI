# How to chat with AI models

OpenAI provides multiple advanced models for chat with.

PSOpenAI PowerShell module provides `Request-ChatCompletion` command for using the OpenAI API throw PowerShell friendly style.

`Request-ChatCompletion` take a series of messages as input, and return an AI-written message as output.

This guide describes how to use `Request-ChatCompletion` with various parameters.

## 1. Import the PSOpenAI module and set API key

If you set the API key to the environment variable named `OPENAI_API_KEY`. PSOpenAI commands will use it implicitly.

```powershell
# imports
Import-Module ..\PSOpenAI.psd1

# Set OpenAI API Key
$env:OPENAI_API_KEY = '<Put your API key here>'
```

## 2. Ask one question, and get an answer (Single turn chat)

`Request-ChatCompletion` has some basic parameters:

+ `-Message`: The messages to the model.
+ `-Model`: The name of the model you want to use (e.g.: `gpt-4o`, `o1-mini`).

```powershell
$Response = Request-ChatCompletion -Message "Hi, please tell me your name." -Model "gpt-4o"

Write-Output $Response
# Response
id                 : chatcmpl-AP3cLoS9chWc2Zh7Gz8XFD91jPXTu
object             : chat.completion
model              : gpt-4o-2024-08-06
choices            : {@{index=0; message=; logprobs=; finish_reason=stop}}
usage              : @{prompt_tokens=15; completion_tokens=13; total_tokens=28; prompt_tokens_details=}
system_fingerprint : fp_0bc6d133f2
created            : 2024/11/02 16:13:45
Message            : Hi, please tell me your name.
Answer             : {I am called ChatGPT! How can I assist you today?}
History            : {System.Collections.Specialized.OrderedDictionary, System.Collections.Specialized.OrderedDictionary}
```

If you want to extract just the output.

```powershell
$Response.Answer
#> I am called ChatGPT! How can I assist you today?
```

## 3. Conversation and context (Multi-turn chat)

`Request-ChatCompletion` accepts past dialogs from pipeline. Additional questions can be asked while keeping context.

```powershell
# First turn
$Response1 = Request-ChatCompletion `
  -Model "gpt-4o-mini" `
  -Message "What is the population of the United States? Please answer briefly."
"[Q1]: " + $Response1.Message
"[A1]: " + $Response1.Answer

# Second turn
$Response2 = $Response1 | Request-ChatCompletion `
  -Model "gpt-4o-mini" `
  -Message "Translate the previous answer into Japanese."
"[Q2]: " + $Response2.Message
"[A2]: " + $Response2.Answer
```

This script displays as:
```
[Q1]: What is the population of the United States? Please answer briefly.                                               
[A1]: As of October 2023, the estimated population of the United States is approximately 333 million people.

[Q2]: Translate the previous answer into Japanese.                                                                      
[A2]: 2023年10月現在、アメリカ合衆国の推定人口は約3億3300万人です。
```

## 4. System messages

The system message can be used to prime the assistant with different personalities or behaviors.

Use `-SystemMessage` parameter for specifiyng system message.

Be aware that the how much pay attention to the system message is depending on the model.

```powershell
$Response = Request-ChatCompletion `
  -Model "gpt-4o-mini" `
  -Message "What is the population of the United States? Please answer briefly." `
  -SystemMessage "Please answer in Russian."

$Response.Answer
# > На октябрь 2023 года население США составляет примерно 333 миллиона человек.
```
Due to the effect of the system messages, questions in English, but answers in Russian.

## 5. Stream Outputs

By default, when you request a completion from the OpenAI, the entire completion is generated before being sent back in a single response.

If you're generating long completions, waiting for the response can take many seconds.

To get responses sooner, you can 'stream' the completion as it's being generated. This allows you to start printing or processing the beginning of the completion before the full completion is finished.

To stream completions, enables `-Stream` switch.

```powershell
Request-ChatCompletion "Describe ChatGPT in 100 charactors." -Model "gpt-4o" -Stream | Write-Host -NoNewline
#> ChatGPT is an advanced AI language model by OpenAI, designed for conversation and content generation.
```

### About output type of stream

Stream output is sequentially output to the PowerShell pipeline (standard output stream). Therefore, when the stream output is saved to a variable or displayed on the console, it is not a single string, but an array of small string chunks.

```powershell
$Response = Request-ChatCompletion "Describe ChatGPT in 100 charactors." -Model "gpt-4o" -Stream

"Size of an array: " + $Response.Count
for($i=0; $i -lt 5; $i++){
    "[$i] " + $Response[$i]
}

# Convert array of string to single string
-join $Response
```

```
Size of an array: 21

[0]
[1] Chat
[2] GPT
[3]  is
[4]  an

ChatGPT is an AI language model by OpenAI that generates human-like text based on input prompts.
```

### How to display output to the console and save it to a variable as well

Stream output is simultaneously output to the information stream in addition to the standard output stream. This can be used to save to variables and display on the console at the same time.

```powershell
Request-ChatCompletion "Describe ChatGPT in 100 charactors." -Model "gpt-4o" -Stream -InformationVariable Response | Write-Host -NoNewline
""
-join $Response

# Console output (information stream)
ChatGPT is an AI language model by OpenAI that generates human-like text based on input prompts.

# Stored in the variable (standard output stream)
ChatGPT is an AI language model by OpenAI that generates human-like text based on input prompts.
```

## 6. Use with content moderation

This section describes how to test messages to / from models for violations of OpenAI's content policy. `Request-Moderation` function provides this functionality.

### Simple senario

Before a message is entered to `Request-ChatCompletion`, you can insert `Request-Moderation` into the pipeline. As `Request-Moderation` will output a warning message if the input text violates the content policy, specifying `-WarningAction` as `Stop` will stop processing before the message is passed on to the subsequent pipeline.

```powershell
'I want to kill them.' | Request-Moderation -WarningAction Stop | Request-ChatCompletion -Model "gpt-4o-mini"
```

```
WARNING: This content may violate the content policy. (harassment, harassment/threatening, violence)                    
Write-Warning: Request-Moderation.ps1:143:21
Line |
 143 |  …             Write-Warning "This content may violate the content polic …
     |                ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
     | The running command stopped because the preference variable "WarningPreference" or common parameter is set to Stop: This content may violate the content policy. (harassment, harassment/threatening, violence)
```

### Complex senario

If you want to test not only input but also output messages of the AI, or if you want to perform custom processing when a policy is violated, you will need to be a bit more  complex procedure.

```powershell
$WarningPreference = 'SilentlyContinue'
$InputMessage = 'I want to kill them.'

# Test the input message.
$InputModeration = Request-Moderation -Text $InputMessage
if ($InputModeration.results[0].flagged) {
    # Custom procedure when the input message violates the policy.
    Write-Host 'Input message is harmful.' -ForegroundColor Yellow
}
else {
    Write-Host 'Input message is safe.' -ForegroundColor Green
}

# Get an answer from ChatGPT
$Response = Request-ChatCompletion -Message $InputMessage -Model 'gpt-4o-mini' -MaxTokens 15

# Test the output message.
$OutputModeration = Request-Moderation -Text $Response.Answer[0]
if ($OutputModeration.results[0].flagged) {
    # Custom procedure when the output message violates the policy.
    Write-Host 'Output message is harmful.' -ForegroundColor Yellow
}
else {
    Write-Host 'Output message is safe.' -ForegroundColor Green
}
```

```
Input message is harmful.                                                                                               
Output message is safe.
```

## 7. Miscellaneous options

`Request-ChatCompletion` has many optional parameters such like:

+ `-Temperature`
+ `-StopSequence`
+ `-MaxCompletionTokens`
+ `-Seed`
+ `-PresencePenalty`
+ `-FrequencyPenalty`
+ `-LogitBias`
+ `-TimeoutSec`
+ `-MaxRetryCount`

### Make the response deterministic

If a small value such as `0` or `0.1` is specified for the `-Temperature` parameter, the response will be definitive. On the other hand, if a large value such as `0.8` is specified, the response will be random even if the same message is entered.

```powershell
$Message = 'Please output one person name, as appropriate.'

# Ask same question 5 times with low temprature.
$temp = 0.1
(1..5) | ForEach-Object {
    Request-ChatCompletion -Message $Message -Model "gpt-4o-mini" -Temperature $temp | select -ExpandProperty Answer
}

#> Sure! How about "Alex Morgan"?
#> Sure! How about "Alex Morgan"?
#> Sure! How about "Alex Morgan"?
#> Sure! How about "Alex Morgan"?
#> Sure! How about "Alex Morgan"?

# Ask same questions with high temperature.
$temp = 1.6
(1..5) | ForEach-Object {
    Request-ChatCompletion -Message $Message -Model "gpt-4o-mini" -Temperature $temp | select -ExpandProperty Answer
}

#> Sure! Here's a name: Alex Morgan.
#> Sure! Here’s a name: Alex Taylor.
#> Sure! A name you might find appropriate is "Alex Morgan."
#> Sure! Here’s a name for you: Alice Johnson.
#> Sure, how about "Jane Doe"?
```

### Limit maximum length of output

Specifying the `-MaxCompletionTokens` parameter avoids unintentionally consuming too many tokens by generating excessively long responses.

```powershell
$Response = Request-ChatCompletion -Message "Write a long long poem as you can." -Model "gpt-4o" -MaxCompletionTokens 20
$Response.Answer

#> WARNING: The model seems to have terminated response. Reason: "length"
#> 
#> Sure, here's a lengthy poem for you:
#> Beneath the boundless sky so wide,
#> Where an
```

The AI model tried to write a long poem, but sadly stopped outputting as soon as it started writing.

> [!TIP]  
> When the output is terminated in the middle, a warning message may display on the console. To suppress this, specify "SilentlyContinue" for `-WarningAction`.

