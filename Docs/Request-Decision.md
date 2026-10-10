---
external help file: PSOpenAI-help.xml
Module Name: PSOpenAI
online version: https://github.com/mkht/PSOpenAI/blob/main/Docs/Request-Decision.md
schema: 2.0.0
---

# Request-Decision

## SYNOPSIS
Evaluate text and images with the Decisions API.

## SYNTAX

```
Request-Decision
  [[-Message] <String[]>]
  [-Images <String[]>]
  [-ImageDetail <String>]
  [-Model <String>]
  [-PredicateQuestionName <String[]>]
  [-PredicateQuestionInstructions <String[]>]
  [-ChoiceQuestionName <String[]>]
  [-ChoiceQuestionInstructions <String[]>]
  [-ChoiceQuestionChoices <Object[]>]
  [-ScoreQuestionName <String[]>]
  [-ScoreQuestionInstructions <String[]>]
  [-ScoreQuestionLevels <Object[]>]
  [-SafetyIdentifier <String>]
  [-TimeoutSec <Int32>]
  [-MaxRetryCount <Int32>]
  [-ApiBase <Uri>]
  [-ApiKey <SecureString>]
  [-Organization <String>]
  [<CommonParameters>]
```

## DESCRIPTION
Send shared text or image evidence and questions to POST /v1/decisions.
Specify questions with PredicateQuestionInstructions, ChoiceQuestionInstructions, or ScoreQuestionInstructions. At least one question is required.

Each instruction array defines the questions of that type. Optional names and required choice/level entries are matched by index. Omitted, null, and empty names are left out of the request. Each choice question requires at least two choices; a question with fewer choices produces an error and is skipped. Each score question requires at least one level.

Questions are sent in Predicate, Choice, Score order, preserving array order within each type. Each answer corresponds to the question at the same index in the resulting questions array.

Score level order defines the numeric indices. Use an ordered dictionary (`[ordered]@{ ... }`) or an array for ScoreQuestionLevels when the order matters. A regular hashtable (`@{ ... }`) does not guarantee the order in which its keys are enumerated. Supplying one emits a warning, and the question is still sent using its enumerated key order.

Specify Message, Images, or both. A Message array supplies ordered text parts as shared evidence in one request. Pipeline strings are processed separately, with one request per string. Images accepts local image paths, inline base64 data URLs, and publicly accessible HTTP(S) image URLs; images follow text parts when both are supplied.

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

## PARAMETERS

### -Message
Shared text evidence. Alias: Input. Either Message or Images is required. A single text string is sent as a string; multiple strings become ordered input_text parts. Pipeline strings each produce a separate request.

```yaml
Type: String[]
Aliases: Input
Required: False
Position: 0
Accept pipeline input: True (ByValue)
```

### -Images
One to 128 local image paths, inline base64 image data URLs, or publicly accessible HTTP(S) image URLs, shared by all questions. Local paths are converted to data URLs before sending; HTTP(S) URLs are passed through unchanged. Missing files, directories, and unsupported URI schemes produce an error before the API request. The API must be able to retrieve any supplied URL.

```yaml
Type: String[]
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
Model to use. The beta API currently supports gpt-6-luna. Completion candidates do not restrict model or deployment names on compatible servers.

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
Instructions for predicate questions that estimate whether a condition is true. Each non-empty entry creates one question; names may be omitted.

```yaml
Type: String[]
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
Instructions for choice questions. Each non-empty entry requires a corresponding choices entry in ChoiceQuestionChoices.

```yaml
Type: String[]
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
Instructions for score questions. Each non-empty entry requires a corresponding levels entry in ScoreQuestionLevels.

```yaml
Type: String[]
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
The Decisions API is in beta. This command constructs user messages with input_text/input_image parts when required, with at most 128 Images entries. It does not expose non-user roles, audio, files, tools, or item references. Streaming and Batch integration are not exposed by this command.

## RELATED LINKS

[Decisions API guide](https://developers.openai.com/api/docs/guides/decisions)

[Create a decision](https://developers.openai.com/api/reference/resources/decisions/methods/create)
