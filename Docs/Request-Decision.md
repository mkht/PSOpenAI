---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Request-Decision.md
schema: 2.0.0
---

# Request-Decision

## SYNOPSIS
Evaluate text and images with the beta Decisions API.

## SYNTAX

### Message (Default)
```
Request-Decision [[-Message] <String>] [-Images <String[]>] [-ImageDetail <String>]
 [-Questions] <Object[]> [-Model <String>] [-SafetyIdentifier <String>] [-TimeoutSec <Int32>]
 [-MaxRetryCount <Int32>] [-ApiBase <Uri>] [-ApiKey <SecureString>] [-Organization <String>]
 [-AdditionalQuery <IDictionary>] [-AdditionalHeaders <IDictionary>] [-AdditionalBody <Object>]
 [<CommonParameters>]
```

### InputMessages
```
Request-Decision -InputMessages <Object[]> [-Questions] <Object[]> [-Model <String>]
 [-SafetyIdentifier <String>] [-TimeoutSec <Int32>] [-MaxRetryCount <Int32>] [-ApiBase <Uri>]
 [-ApiKey <SecureString>] [-Organization <String>] [-AdditionalQuery <IDictionary>]
 [-AdditionalHeaders <IDictionary>] [-AdditionalBody <Object>] [<CommonParameters>]
```

## DESCRIPTION
Send shared text or image evidence and an ordered list of questions to POST /v1/decisions.
Questions use predicate, choice, or score types. Each answer corresponds to the question at the same array index.

Specify Message, Images, or InputMessages. Message accepts text from the pipeline and sends one request per input string.
Images accepts local image paths and inline base64 data URLs. InputMessages accepts API-format user messages for direct control over content parts and their order.

The returned PSOpenAI.Decision object contains model, answers, and usage. Answer fields, boolean or string choice values, fractional scores, and refusal answers are preserved.

## EXAMPLES

### Example 1: Check a condition
```powershell
$question = @{
    type = 'predicate'
    name = 'needs_refund'
    instructions = 'Is the customer requesting a refund?'
}
$result = Request-Decision -Message 'Please refund my purchase.' -Questions $question
$result.answers[0].probability
```
Returns the estimated probability that the condition is true. A question can instead receive an answer with type refusal.

### Example 2: Classify and score shared evidence
```powershell
$questions = @(
    @{
        type = 'choice'
        name = 'route'
        instructions = 'Which team should handle this issue?'
        choices = @(
            @{ value = 'support'; description = 'Problems using the product.' }
            @{ value = 'billing'; description = 'Invoices and payments.' }
        )
    }
    @{
        type = 'score'
        name = 'severity'
        instructions = 'How much does the issue prevent use of the product?'
        levels = @(
            @{ label = 'Low'; description = 'The product remains usable.' }
            @{ label = 'High'; description = 'The product cannot be used.' }
        )
    }
)
Request-Decision -Message 'The application cannot open any documents.' -Questions $questions
```
Returns answers in question order. Choice values can also be booleans; use $true and $false to retain their JSON boolean type. Score levels are ordered from index 0, and score is a probability-weighted average that can fall between indices.

### Example 3: Evaluate a local image
```powershell
$question = @{
    type = 'predicate'
    name = 'text_visible'
    instructions = 'Does the image contain readable text?'
}
Request-Decision -Images './photo.png' -ImageDetail original -Questions $question
```
Converts the local image to an inline data URL. Images can be combined with Message, and can also contain data URLs. External image URLs and file IDs are not accepted.

### Example 4: Supply API-format user messages
```powershell
$messages = @(
    @{ role = 'user'; content = 'The customer says the display is cracked.' }
    @{ role = 'user'; content = @(@{ type = 'input_text'; text = 'The device will not turn on.' }) }
)
$question = @{ type = 'predicate'; instructions = 'Is the device usable?' }
Request-Decision -InputMessages $messages -Questions $question -SafetyIdentifier 'user-opaque-id'
```
Sends the message array as supplied. Each message must have role user. Content may be a string or an array of input_text and input_image parts. For images, image_url must contain an inline data URL; detail can be auto, low, high, or original.

## PARAMETERS

### -Message
Shared text evidence. Aliases: Input, Text. Either Message or Images is required in the default parameter set.

```yaml
Type: String
Parameter Sets: Message
Aliases: Input, Text
Required: False
Position: 0
Accept pipeline input: True (ByValue)
```

### -InputMessages
An array of API-format user messages containing text and inline images. Message and Images cannot be combined with InputMessages. Message and question schemas supplied directly are validated by the API.

```yaml
Type: Object[]
Parameter Sets: InputMessages
Required: True
Position: Named
```

### -Images
One to 128 local image paths or inline base64 image data URLs, shared by all questions. Local paths are converted to data URLs before sending. Missing files, directories, and external URLs produce an error before the API request.

```yaml
Type: String[]
Parameter Sets: Message
Required: False
Position: Named
```

### -ImageDetail
Image detail for images passed through Images. Accepted values: auto, low, high, original. For InputMessages, specify detail on each input_image part instead.

```yaml
Type: String
Parameter Sets: Message
Required: False
Position: Named
Default value: auto
```

### -Questions
An ordered array of hashtables or objects describing independent questions. A single question is also accepted. Alias: Question.

Every question requires type and instructions, and may have a name. Predicate questions use type predicate. Choice questions use type choice and a choices array, where each entry has a string or boolean value and an optional description. Score questions use type score and an ordered levels array, where each entry has a label and an optional description.

```yaml
Type: Object[]
Parameter Sets: (All)
Aliases: Question
Required: True
Position: 1
```

### -Model
Model to use. The beta API currently supports gpt-6-luna. Completion candidates do not restrict model or deployment names on compatible servers.

```yaml
Type: String
Parameter Sets: (All)
Required: False
Position: Named
Default value: gpt-6-luna
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

### -AdditionalQuery
Additional query parameters for the request.

```yaml
Type: IDictionary
Parameter Sets: (All)
Required: False
Position: Named
```

### -AdditionalHeaders
Additional HTTP request headers.

```yaml
Type: IDictionary
Parameter Sets: (All)
Required: False
Position: Named
```

### -AdditionalBody
Additional body fields as a dictionary, object, or JSON string. Fields are merged shallowly and replace fields with the same name.

```yaml
Type: Object
Parameter Sets: (All)
Required: False
Position: Named
```

## INPUTS

### System.String

## OUTPUTS

### PSCustomObject
A PSOpenAI.Decision object with model, ordered answers, and usage. Predicate answers include probability. Choice and score answers include confidence and probabilities. Refusal answers have type refusal and a question name or null.

## NOTES
The Decisions API is in beta. InputMessages supports only user messages and input_text/input_image parts, with at most 128 images across a request. Non-user roles, audio, files, tools, and item references are unsupported. Streaming and Batch integration are not exposed by this command.

## RELATED LINKS

[Decisions API guide](https://developers.openai.com/api/docs/guides/decisions)

[Create a decision](https://developers.openai.com/api/reference/resources/decisions/methods/create)
