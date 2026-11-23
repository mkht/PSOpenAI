---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Request-Decision.md
schema: 2.0.0
---

# Request-Decision

## SYNOPSIS
Evaluate text, images, JSON, and conversation history with the Decisions API.

## SYNTAX

### Message (Default)

```
Request-Decision
  [[-Message] <String[]>]
  [-Images <String[]>]
  [-InputJson <Object>]
  [-ImageDetail <String>]
  [-Model <String>]
  [-PredicateQuestionName <String[]>]
  [-PredicateQuestionInstructions <Object[]>]
  [-ChoiceQuestionName <String[]>]
  [-ChoiceQuestionInstructions <Object[]>]
  [-ChoiceQuestionChoices <Object[]>]
  [-ScoreQuestionName <String[]>]
  [-ScoreQuestionInstructions <Object[]>]
  [-ScoreQuestionLevels <Object[]>]
  [-PromptCacheKey <String>]
  [-PromptCacheMode <String>]
  [-PromptCacheTtl <String>]
  [-SafetyIdentifier <String>]
  [-TimeoutSec <Int32>]
  [-MaxRetryCount <Int32>]
  [-ApiBase <Uri>]
  [-ApiKey <SecureString>]
  [-Organization <String>]
  [<CommonParameters>]
```

### InputItem

```
Request-Decision
  -InputItem <Object[]>
  [-ImageDetail <String>]
  [-Model <String>]
  [-PredicateQuestionName <String[]>]
  [-PredicateQuestionInstructions <Object[]>]
  [-ChoiceQuestionName <String[]>]
  [-ChoiceQuestionInstructions <Object[]>]
  [-ChoiceQuestionChoices <Object[]>]
  [-ScoreQuestionName <String[]>]
  [-ScoreQuestionInstructions <Object[]>]
  [-ScoreQuestionLevels <Object[]>]
  [-PromptCacheKey <String>]
  [-PromptCacheMode <String>]
  [-PromptCacheTtl <String>]
  [-SafetyIdentifier <String>]
  [-TimeoutSec <Int32>]
  [-MaxRetryCount <Int32>]
  [-ApiBase <Uri>]
  [-ApiKey <SecureString>]
  [-Organization <String>]
  [<CommonParameters>]
```

## DESCRIPTION
Send shared evidence and questions to the generally available POST /v1/decisions endpoint.
Specify questions with PredicateQuestionInstructions, ChoiceQuestionInstructions, or ScoreQuestionInstructions. At least one question is required. The GA API supports up to 400 questions per request, increased from 200 in public beta. The command sends all supplied questions without enforcing an upper limit, leaving limit validation and any error response to the API so future API limit increases can be used without a module update.

Each instruction array defines the questions of that type. Optional names and required choice/level entries are matched by index. Omitted, null, and empty names are left out of the request. Each choice question requires at least two choices; a question with fewer choices produces an error and is skipped. Each score question requires at least one level.

Questions are sent in Predicate, Choice, Score order, preserving array order within each type. Each answer corresponds to the question at the same index in the resulting questions array.

Score level order defines the numeric indices. Use an ordered dictionary (`[ordered]@{ ... }`) or an array for ScoreQuestionLevels when the order matters. A regular hashtable (`@{ ... }`) does not guarantee the order in which its keys are enumerated. Supplying one emits a warning, and the question is still sent using its enumerated key order.

Specify Message, Images, InputJson, or any combination of them. A Message array supplies ordered text parts as shared evidence in one request. Pipeline strings are processed separately, with one request per string. Images accepts local image paths, inline base64 data URLs, and publicly accessible HTTP(S) image URLs. Shared content is sent in text, image, JSON order. InputJson accepts an object or an array of objects without converting it to a JSON string first.

Alternatively, use InputItem for an ordered array of API input items: user, developer, system, and assistant messages, function calls and outputs, and custom tool calls and outputs. Tool outputs must match their calls by call_id. InputItem cannot be combined with Message, Images, or InputJson. The Input alias continues to mean Message.

Each question instruction can be a string or a nonempty array of input_text, input_image, and input_json parts. Wrap a content-part array with a unary comma to supply it as one question. These parts are forwarded as supplied; image_url must be a data URL or public HTTP(S) URL. Only Images converts local image paths.

Prompt caching is automatic for an identical shared input prefix of at least 1,024 tokens. Questions are outside the reusable prefix. Use PromptCacheKey to partition reuse, and PromptCacheMode and PromptCacheTtl to configure caching. To mark an explicit boundary, supply prompt_cache_breakpoint = @{ mode = 'explicit' } on a text or image part through InputItem. Breakpoints cannot be used in question instructions. Explicit mode with no marked boundary does not use caching.

The returned PSOpenAI.Decision object contains model, answers, and usage. Answer fields, boolean or string choice values, fractional scores, and refusal answers are preserved.

## EXAMPLES

### Example 1: Check a condition
```powershell
$params = @{
    Message = 'Please refund my purchase.'
    PredicateQuestionName = 'needs_refund'
    PredicateQuestionInstructions = 'Is the customer requesting a refund?'
}
$result = Request-Decision @params
$result.answers[0].probability
```
Returns the estimated probability that the condition is true. A question can instead receive an answer with type refusal.

### Example 2: Classify and score shared evidence
```powershell
$choices = [ordered]@{
    support = 'Problems using the product.'
    billing = 'Invoices and payments.'
}
$levels = [ordered]@{
    Low = 'The product remains usable.'
    High = 'The product cannot be used.'
}
$params = @{
    Message = 'The application cannot open any documents.'
    ChoiceQuestionName = 'route'
    ChoiceQuestionInstructions = 'Which team should handle this issue?'
    ChoiceQuestionChoices = $choices
    ScoreQuestionName = 'severity'
    ScoreQuestionInstructions = 'How much does the issue prevent use of the product?'
    ScoreQuestionLevels = $levels
}
Request-Decision @params
```
The dictionary keys become choice values or score labels, and their values become optional descriptions. The choice answer precedes the score answer. Score levels are ordered from index 0, and score is a probability-weighted average that can fall between indices.

### Example 3: Evaluate a local image
```powershell
$params = @{
    Images = './photo.png'
    ImageDetail = 'original'
    PredicateQuestionName = 'text_visible'
    PredicateQuestionInstructions = 'Does the image contain readable text?'
}
Request-Decision @params
```
Converts the local image to an inline data URL. Images can be combined with Message and can also contain data URLs or publicly accessible HTTP(S) image URLs. HTTP(S) URLs are forwarded without downloading the image locally. File IDs are not supported.

### Example 4: Evaluate a publicly hosted image

```powershell
Request-Decision -Message 'Inspect this publicly hosted image.' `
    -Images 'https://upload.wikimedia.org/wikipedia/commons/a/a9/Example.jpg' `
    -PredicateQuestionInstructions 'Does the image contain visible text?'
```

Passes the public HTTPS image URL to the API as `image_url`. The API must be able to retrieve the image.

### Example 5: Ask multiple choice questions about shared text
```powershell
$usableChoices = @($true, $false)
$resolutionChoices = @('refund', 'repair')
$params = @{
    Message = @('The display is cracked and the device will not turn on.', 'I want a refund.')
    ChoiceQuestionName = @('usable', 'resolution')
    ChoiceQuestionInstructions = @('Is the device usable?', 'Which resolution does the customer request?')
    ChoiceQuestionChoices = @($usableChoices, $resolutionChoices)
    SafetyIdentifier = 'user-opaque-id'
}
Request-Decision @params
```
Sends both text strings as shared evidence in one request. Each outer Choices array entry belongs to the instruction at the same index. The first choice uses JSON booleans; string and boolean values remain distinct.

### Example 6: Supply descriptions in ordered choice and score arrays

```powershell
$choices = @(
    [pscustomobject]@{ value = 'refund'; description = 'Return the payment.' }
    [pscustomobject]@{ value = 'repair'; description = 'Fix the item.' }
)
$levels = @(
    [pscustomobject]@{ label = 'Low'; description = 'The item remains usable.' }
    [pscustomobject]@{ label = 'High'; description = 'The item cannot be used.' }
)
Request-Decision -Message 'The item is broken.' `
    -ChoiceQuestionInstructions 'Which resolution is requested?' -ChoiceQuestionChoices (,$choices) `
    -ScoreQuestionInstructions 'How severe is the damage?' -ScoreQuestionLevels (,$levels)
```

The array order is preserved. A choice array needs at least two entries; each score level receives an index according to its position.

### Example 7: Evaluate structured data directly

```powershell
$order = @{
    total     = 125.50
    delivered = $false
    items     = @(@{ sku = 'A-1'; quantity = 2 })
}
Request-Decision -InputJson $order `
    -PredicateQuestionInstructions 'Is this an undelivered order over 100 dollars?'
```

Sends the object in an input_json content part, preserving numbers, booleans, and arrays. InputJson can be combined with Message and Images. The API accepts an object or an array of objects, with at most 32 container levels, 10,000 values, and 256 KiB of compact UTF-8 JSON per part.

### Example 8: Compare question images against a shared reference

```powershell
$candidate = @(
    @{ type = 'input_text'; text = 'Does this candidate match reference A?' }
    @{ type = 'input_image'; image_url = 'https://example.com/candidate.jpg' }
)
Request-Decision -Images 'https://example.com/reference.jpg' `
    -PredicateQuestionName 'matches' -PredicateQuestionInstructions (,$candidate)
```

Replace the example URLs with accessible images. The unary comma keeps the two content parts together as one question. For multiple questions, use an outer array containing one string or content-part array per question. Choice and score instructions accept the same content parts.

### Example 9: Evaluate a conversation with explicit prompt caching

```powershell
$items = @(
    @{
        role = 'developer'
        content = @(@{
            type                    = 'input_text'
            text                    = $policyText
            prompt_cache_breakpoint = @{ mode = 'explicit' }
        })
    }
    @{ role = 'user'; content = 'What is the status of order 42?' }
    @{ type = 'function_call'; name = 'lookup_order'; arguments = '{"id":42}'; call_id = 'call_1' }
    @{ type = 'function_call_output'; call_id = 'call_1'; output = 'The order has shipped.' }
)
Request-Decision -InputItem $items -PromptCacheKey 'order-policy-v1' `
    -PromptCacheMode explicit -PromptCacheTtl '30m' `
    -PredicateQuestionInstructions 'Has the requested order shipped?'
```

Set policyText to the policy your application uses. A reusable prefix needs at least 1,024 tokens to benefit from caching. InputItem preserves API item order and nested fields; the API validates roles, content types, tool call matching, and cache boundaries. User messages can include text, images, and JSON; developer/system messages accept input text, assistant messages accept output_text/refusal parts, and function/custom tool outputs accept text and images. System messages are treated as developer messages.

## PARAMETERS

### -Message
Shared text evidence. Alias: Input. Supply Message, Images, InputJson, or a combination of them. A single text string is sent as a string; multiple strings become ordered input_text parts. Pipeline strings each produce a separate request. Cannot be combined with InputItem.

```yaml
Type: String[]
Parameter Sets: Message
Aliases: Input
Required: False
Position: 0
Accept pipeline input: True (ByValue)
```

### -Images
One to 128 local image paths, inline base64 image data URLs, or publicly accessible HTTP(S) image URLs, shared by all questions. Local paths are converted to data URLs before sending; HTTP(S) URLs are passed through unchanged. Missing files, directories, and unsupported URI schemes produce an error before the API request. The API must be able to retrieve any supplied URL. Cannot be combined with InputItem. Question images and shared images count toward the same API image limits.

```yaml
Type: String[]
Parameter Sets: Message
Required: False
Position: Named
```

### -ImageDetail
Image detail for Images. Completion candidates are auto, low, high, and original. Other values can also be supplied and are validated by the server. Values are converted to lowercase before sending.

```yaml
Type: String
Required: False
Position: Named
Default value: auto
```

### -Model
Model to use. The GA API currently supports gpt-6-luna. Completion candidates do not restrict model or deployment names on compatible servers.

```yaml
Type: String
Parameter Sets: (All)
Required: False
Position: Named
Default value: gpt-6-luna
```

### -PredicateQuestionName
Optional predicate question names, matched by index to PredicateQuestionInstructions. Omitted, null, or empty entries do not send a `name` property.

```yaml
Type: String[]
Required: False
Position: Named
```

### -PredicateQuestionInstructions
Instructions for predicate questions that estimate whether a condition is true. Each entry creates one question and can be a string or a nonempty array of input_text, input_image, and input_json parts. Wrap a content-part array with a unary comma to keep it as one question; names may be omitted. Content parts are forwarded without local image conversion or cache breakpoints.

```yaml
Type: Object[]
Required: False
Position: Named
```

### -ChoiceQuestionName
Optional choice question names, matched by index to ChoiceQuestionInstructions. Omitted, null, or empty entries do not send a `name` property.

```yaml
Type: String[]
Required: False
Position: Named
```

### -ChoiceQuestionInstructions
Instructions for choice questions. Each entry can be a string or a nonempty content-part array, as described for PredicateQuestionInstructions, and requires a corresponding choices entry in ChoiceQuestionChoices.

```yaml
Type: Object[]
Required: False
Position: Named
```

### -ChoiceQuestionChoices
One entry per ChoiceQuestionInstructions entry. An entry can be a dictionary mapping string or boolean choice values to optional descriptions, or an enumerable of string/boolean values and objects with a `value` property and optional `description` property. The enumerable may contain dictionaries or other property-based objects. A property-based object passed alone produces only one choice, so it does not meet the two-choice minimum. Questions with fewer than two choices produce an error and are skipped; detailed option validation is performed by the API.

For one question, pass the dictionary directly or use `, $choices` to wrap an array of values. For multiple questions, use `@($firstChoices, $secondChoices)` with one entry per question.

```yaml
Type: Object[]
Required: False
Position: Named
```

### -ScoreQuestionName
Optional score question names, matched by index to ScoreQuestionInstructions. Omitted, null, or empty entries do not send a `name` property.

```yaml
Type: String[]
Required: False
Position: Named
```

### -ScoreQuestionInstructions
Instructions for score questions. Each entry can be a string or a nonempty content-part array, as described for PredicateQuestionInstructions, and requires a corresponding levels entry in ScoreQuestionLevels.

```yaml
Type: Object[]
Required: False
Position: Named
```

### -ScoreQuestionLevels
One entry per ScoreQuestionInstructions entry. An entry can be a dictionary mapping labels to optional descriptions, an enumerable of labels and objects with a `label` property and optional `description` property, or a property-based object that produces one level. The enumerable may contain dictionaries or other property-based objects. Each entry must contain at least one level; detailed level validation is performed by the API. Level order defines indices starting at 0. To preserve the intended order, use `[ordered]@{ ... }` or an array. An ordinary `@{ ... }` emits a warning because its key order is not guaranteed; processing continues.

For one question, pass the dictionary directly or use `, $levels` to wrap an array of labels. For multiple questions, use `@($firstLevels, $secondLevels)` with one entry per question.

```yaml
Type: Object[]
Required: False
Position: Named
```

### -InputJson
Shared structured evidence sent as an input_json part after any text and image parts. Supply an object or an array of objects, such as a hashtable or PSCustomObject, without converting it to a JSON string. Nested JSON values are preserved. The API validates JSON size and depth limits. Cannot be combined with InputItem.

```yaml
Type: Object
Parameter Sets: Message
Required: False
Position: Named
```

### -InputItem
An ordered array of API input items, including messages, function calls and outputs, and custom tool calls and outputs. Items are forwarded unchanged, allowing supported role-specific content and explicit prompt_cache_breakpoint fields on shared text/image parts. Supply API-ready image URLs; local paths are not converted. Cannot be combined with Message (including its Input alias), Images, or InputJson. A single item is still sent as an array.

```yaml
Type: Object[]
Parameter Sets: InputItem
Required: True
Position: Named
```

### -PromptCacheKey
Caller-provided key to partition prompt cache reuse. Maximum length is 64 characters. Sent only when explicitly supplied, including an empty string.

```yaml
Type: String
Aliases: prompt_cache_key
Required: False
Position: Named
```

### -PromptCacheMode
Prompt caching mode. Completion candidates are implicit and explicit. The server defaults to implicit, placing a cache breakpoint at the end of shared input. Explicit mode uses only marked boundaries and does not use caching if there are none. Question content is outside the cacheable prefix. Sent only when supplied; server validation applies.

```yaml
Type: String
Aliases: prompt_cache_options.mode
Required: False
Position: Named
```

### -PromptCacheTtl
Minimum lifetime of cache entries. Currently only 30m is supported by Decisions, which is also the server default. Sent only when supplied; server validation applies.

```yaml
Type: String
Aliases: prompt_cache_options.ttl
Required: False
Position: Named
```

### -SafetyIdentifier
Opaque end-user identifier, up to 128 characters, sent as safety_identifier only when explicitly supplied. Alias: safety_identifier.

```yaml
Type: String
Parameter Sets: (All)
Aliases: safety_identifier
Required: False
Position: Named
```

### -TimeoutSec
Timeout in seconds for each request attempt, including response reading. The default 0 means no timeout. Uses the OpenAI context setting when not explicitly supplied.

```yaml
Type: Int32
Parameter Sets: (All)
Required: False
Position: Named
Default value: 0
```

### -MaxRetryCount
Maximum retry count, from 0 to 100. The default 0 disables retries. Uses the OpenAI context setting when not explicitly supplied.

```yaml
Type: Int32
Parameter Sets: (All)
Required: False
Position: Named
Default value: 0
```

### -ApiBase
Base API URL. Uses the OpenAI context setting, or https://api.openai.com/v1 by default. The configured server must implement the Decisions endpoint.

```yaml
Type: System.Uri
Parameter Sets: (All)
Required: False
Position: Named
Default value: https://api.openai.com/v1
```

### -ApiKey
API key as a string or SecureString. If omitted, the context, global OPENAI_API_KEY variable, or OPENAI_API_KEY environment variable is used. Explicit null supplies an empty key.

```yaml
Type: SecureString
Parameter Sets: (All)
Required: False
Position: Named
```

### -Organization
Optional organization ID. Alias: OrgId. Uses the common OpenAI context and environment settings when omitted.

```yaml
Type: String
Parameter Sets: (All)
Aliases: OrgId
Required: False
Position: Named
```

## INPUTS

### System.String

## OUTPUTS

### PSCustomObject
A PSOpenAI.Decision object with model, ordered answers, and usage. Predicate answers include probability. Choice and score answers include confidence and probabilities. Refusal answers have type refusal and a question name or null.

## NOTES
The Decisions API is generally available. This command supports multimodal question instructions, JSON input, conversation history, and prompt caching. It does not enforce an upper limit on the number of questions; requests exceeding the API's limit are sent for server-side validation. Existing text and image calls continue to work. Public HTTP(S) image URLs were already supported by this command during beta.

ImageDetail applies only to Images. Specify detail on individual image parts in InputItem or question instructions. InputItem evaluates supplied tool calls and outputs as evidence; it does not execute tools. Audio, file IDs, item references, streaming, and Batch integration are not exposed by this command.

The API reports cache reads in usage.input_tokens_details.cached_tokens and writes in usage.input_tokens_details.cache_write_tokens. Both are included in input_tokens and must not be added again. The command preserves these counters without recalculating totals.

Organization usage reporting is a management API and is outside PSOpenAI's supported command scope. Private Link and native GPT-Live delegation are service/integration capabilities, rather than additional fields on POST /v1/decisions.

## RELATED LINKS

[Decisions API guide](https://developers.openai.com/api/docs/guides/decisions)

[Create a decision](https://developers.openai.com/api/reference/resources/decisions/methods/create)
