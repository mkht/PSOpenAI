# Migrate from Request-ChatCompletion to Request-Response

This guide explains how to migrate your code from the traditional `Request-ChatCompletion` to the new `Request-Response` interface in PSOpenAI module.

## Functional Differences

There are several important functional differences.  
`Request-Response` is not a superset of `Request-ChatCompletion`. There are things that can only be done with `Request-ChatCompletion`.

| Feature                    | ChatCompletion |   Response    | Notes                                           |
| -------------------------- | :------------: | :-----------: | ----------------------------------------------- |
| Basic text chat            |       ✅        |       ✅       | Both support core chat functionality            |
| Audio I/O                  |       ✅        |       ❌       | Audio features only available in ChatCompletion |
| Newer models (o1-pro etc.) |       ❌        |       ✅       | Response required for latest models             |
| Built-in tools             |       ❌        |       ✅       | File search, Computer-Use, etc.                 |
| History management         |     Manual     | Auto / Manual | Response maintains state automatically          |

## Usage Differences

The basic usage of `Request-ChatCompletion` and `Request-Response` is quite similar.

#### Request-ChatCompletion

```powershell
$Output = Request-ChatCompletion -Message 'Hello' -Model 'gpt-4o-mini'
$Output | Format-List
```
```
id                 : chatcmpl-abc123
object             : chat.completion
model              : gpt-4o-mini-2024-07-18
choices            : {@{index=0; message=; logprobs=; finish_reason=stop}}
usage              : @{prompt_tokens=8; completion_tokens=10; total_tokens=18}
service_tier       : default
system_fingerprint : fp_abc123
created            : 2025/04/11 10:15:43
Message            : Hello
Answer             : {Hello! How can I assist you today?}
History            : {System.Collections.Specialized.OrderedDictionary}
```

#### Request-Response

```powershell
$Output = Request-Response -Message 'Hello' -Model 'gpt-4o-mini'
$Output | Format-List
```
```
id                   : resp_abc123
object               : response
status               : completed
model                : gpt-4o-mini-2024-07-18
output               : {@{id=msg_abc123; type=message; status=completed; content=System.Object[]; role=assistant}}
previous_response_id : 
store                : True
truncation           : disabled
usage                : @{input_tokens=8; input_tokens_details=; output_tokens=10; output_tokens_details=; total_tokens=18}
created_at           : 2025/04/11 10:15:43
LastUserMessage      : Hello
output_text          : Hello! How can I assist you today?
History              : {@{role=user; content=System.Object[]}, @{role=assistant; content=System.Object[]}}
```

Here are several changes to consider when replacing:

### Output Properties Have Changed

The property containing the last user message has changed to `LastUserMessage`, and the model output is now in the `output_text` property.

> You might question why it's not `OutputText`, but this aligns with OpenAI's API reference documentation.

`output_text` is always a single string. (The `Answer` property in `Request-ChatCompletion` is always an array of strings.)

```powershell
# Responses
$Output = Request-Response -Message 'Hello' -Model 'gpt-4o-mini'
echo "You say : $($Output.LastUserMessage)"
echo " AI say : $($Output.output_text)"

## (Chat Completions equivalent)
$Output = Request-ChatCompletion -Message 'Hello' -Model 'gpt-4o-mini'
echo "You say : $($Output.Message)"
echo " AI say : $($Output.Answer[0])"
```

### Default Model Changed to `gpt-4o-mini`

When the `-Model` parameter is not specified in `Request-ChatCompletion`, `gpt-3.5-turbo` is used.  
When the `-Model` parameter is not specified in `Request-Response`, `gpt-4o-mini` is used.

> It's recommended to always specify the `-Model` parameter

### Cannot Pass User Messages Through Pipeline

```powershell
## You can do this
"Hello." | Request-ChatCompletion -Model 'gpt-4o'

## Cannot do this
"Hello." | Request-Response -Model 'gpt-4o'
```

Conversation history can be passed through the pipeline.

```powershell
## Conversation state
$First = Request-Response -Message "Hello."
$Second = $First | Request-Response -Message "Can you assist me?"
```

### History Property Type Has Changed

The `History` property added to maintain conversation history is an array of `[OrderedDictionary]` in `Request-ChatCompletion`, but is now an array of `[PSCustomObject]` in `Request-Response`.

### `-Store` Is Now Boolean with True Default

The `-Store` parameter in `Request-ChatCompletion` is a switch parameter, defaulting to off (`$false`).  
In `Request-Response`, `-Store` is a boolean and defaults to `$true` if not explicitly specified.

```powershell
Request-Response -Message "Don't save this." -Store $false
```

### Stream Not Output to Information Stream

When using Stream output in `Request-ChatCompletion`, it is output to both standard output and the Information stream.  
In `Request-Response`, it only outputs to standard output. If you want to capture Stream to both the console host and a variable, you can achieve this using PowerShell's built-in `Tee-Object` function.

```PowerShell
Request-Response -Message 'Hello' -Model 'gpt-4o' -Stream | Tee-Object -Variable StreamOut | Write-Host -NoNewLine
Write-Output $StreamOut
```
