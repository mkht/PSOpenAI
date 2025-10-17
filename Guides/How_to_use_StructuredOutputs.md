# How to use Structured Outputs

Structured Outputs is a feature that ensures the model will always generate responses that adhere to your supplied JSON Schema, so you don't need to worry about the model omitting a required key, or hallucinating an invalid enum value.

OpenAI's official guide is here.  
https://platform.openai.com/docs/guides/structured-outputs/

PSOpenAI module integrates a parasing helpers with PowerShell Class and .NET types.

This guide describes some use cases for Structured Outputs.

> [!NOTE]  
> Structured Outputs is only supported with the `gpt-4o-mini`, `gpt-4o-mini-2024-07-18`, and `gpt-4o-2024-08-06` model and later.

## Examples

### Chain of thought

You can ask the model to output an answer in a structured, step-by-step way, to guide the user through the solution.

```powershell
# Defines PowerShell classes
class Step {
    [string]$Explanation
    [string]$Output
}

class MathReasoning {
    [Step[]]$Steps
    [string]$FinalAnswer
}

# Ask the AI model the steps to solve a math question.
$Result = Request-ChatCompletion `
            -Model "gpt-4o-2024-08-06" `
            -SystemMessage "You are a helpful math tutor. Guide the user through the solution step by step." `
            -Message "How can I solve 8x + 7 = 31" `
            -ResponseFormat ([MathReasoning])
```

The point is that the `-ResponseFormat` parameter specifies the defined PowerShell class type `[MathReasoning]`.  
This instructs the AI model to return an object of this type using Structured Ouputs mode.

PSOpenAI deserialize the response and sets the `Answer` property to an object of the specified type.

```powershell
$Result.Answer[0].FinalAnswer
#> x = 3

$Result.Answer[0].Steps
#> Explanation                                                                                       Output
#> -----------                                                                                       ------
#> The given equation is 8x + 7 = 31. We want to isolate the variable x on one side of the equation. 8x + 7 = 31
#> To isolate x, first subtract 7 from both sides to eliminate the constant term on the left side.   8x + 7 - 7 = 31 - 7
#> Simplifying both sides, we have 8x = 24.                                                          8x = 24
#> Next, divide both sides of the equation by 8 to solve for x.                                      8x / 8 = 24 / 8
#> Simplifying both sides after division gives x = 3.                                                x = 3

# The parsed object is also stored in $Result.choices[0].message.parsed
$Result.choices[0].message.parsed

# The original unparsed response is stored in $Result.choices[0].message.content as a JSON format string.
$Result.choices[0].message.content
#> {
#>   "Steps":[
#>     {
#>       "Explanation":"The given equation is 8x + 7 = 31. We want to isolate the variable x on one side of the equation.",
#>       "Output":"8x + 7 = 31"
#>     },
#>     {
#>       "Explanation":"To isolate x, first subtract 7 from both sides to eliminate the constant term on the left side.",
#>       "Output":"8x + 7 - 7 = 31 - 7"
#>     },
#>     {
#>       "Explanation":"Simplifying both sides, we have 8x = 24.",
#>       "Output":"8x = 24"
#>     },
#>     {
#>       "Explanation":"Next, divide both sides of the equation by 8 to solve for x.",
#>       "Output":"8x / 8 = 24 / 8"
#>     },
#>     {
#>       "Explanation":"Simplifying both sides after division gives x = 3.",
#>       "Output":"x = 3"
#>     }
#>   ],
#>   "FinalAnswer":"x = 3"
#> }
```

----

### Structured data extraction

Here is an example of extracting information about a meeting from the text of a message received from a colleague as a fully structured object.

```powershell
# Defines enums & classes
enum MeetingType {
    GoogleMeet
    MicrosoftTeams
    Webex
    Zoom
    FaceToFace
}

enum AttendeeType {
    Executive
    Employee
    Client
    Guest
}

class Attendee {
    [string]$Name
    [AttendeeType]$Type
}

class MeetingEvent {
    [string[]]$Topics
    [Attendee[]]$Attendees
    [MeetingType]$Type
    [datetime]$DateAndTime
}
```

```powershell
# Extracting data from a text message using Structured Outputs
$TextMessage = @'
Hi Alex,

I apologize for the short notice, but we have a web meeting with our client 
tomorrow (August 10, 2024) at 10:00 a.m. to go over the details of the contract, 
and I'd like you to join us.

The meeting will include me (Ira Willis), you, our client Mr. Kojima, and our 
Executive Director, Ms. Montana.

Mr. Kojima said that he would like to make some changes to the contract we 
discussed and in exchange, he would like to lower the price of the contract. Oh well.

We usually use the Google Meet for our meetings, but this time, at the request of 
the client, we will be using the Zoom, so please be careful not to make a mistake.

If you cannot attend due to unavoidable circumstances, please let me know immediately.

Thanks in advance.

Ira Willis
'@

$Result = Request-ChatCompletion `
            -Model "gpt-4o-2024-08-06" `
            -SystemMessage "You are an assistant who reads the meeting information from messages." `
            -Message $TextMessage `
            -ResponseFormat ([MeetingEvent])

$Result.Answer[0]
#> Topics      : {Details of the contract, Potential changes and price adjustments}
#> Attendees   : {Ira Willis, Alex, Mr. Kojima, Ms. Montana}
#> Type        : Zoom
#> DateAndTime : 2024/08/10 10:00:00

$Result.Answer[0].Attendees
#> Name             Type
#> ----             ----
#> Ira Willis   Employee
#> Alex         Employee
#> Mr. Kojima     Client
#> Ms. Montana Executive
```
----

## Use Structured Outputs with own JSON schema

If using the built-in parser is not suitable, you can specify your own JSON schema directly.  
Specify `"json_schema"` to `-ResponseFormat` and a JSON schema string to `-JsonSchema`.

Please refer to the official OpenAI guide to creating your own JSON schema.  
https://platform.openai.com/docs/guides/structured-outputs/supported-schemas

```powershell
$ownJsonSchema = @'
{
  "name": "reasoning_schema",
  "strict": true,
  "schema": {
    "type": "object",
    "properties": {
      "reasoning_steps": {
        "type": "array",
        "items": {
          "type": "string"
        },
        "description": "The reasoning steps leading to the final conclusion."
      },
      "answer": {
        "type": "string",
        "description": "The final answer, taking into account the reasoning steps."
      }
    },
    "required": [
      "reasoning_steps",
      "answer"
    ],
    "additionalProperties": false
  }
}
'@

# Request to chat completion
$Result = Request-ChatCompletion `
            -Model "gpt-4o-mini" `
            -Message "9.11 and 9.9 -- which is bigger?" `
            -ResponseFormat "json_schema" `
            -JsonSchema $ownJsonSchema
```

In this method, the Answer is set to a JSON string. How you parse this is up to you.

```powershell
$Result.Answer[0]
#> {
#>   "reasoning_steps":[
#>     "We need to compare two decimal numbers: 9.11 and 9.9.",
#>     "First, we can write the two numbers with the same number of decimal places for easier comparison: 9.11 and 9.90.",
#>     "Now we compare the numbers digit by digit from left to right:",
#>     "The whole number part of both is 9, so we look at the first decimal place after the point: 1 in 9.11 and 9 in 9.90.",
#>     "Since 1 is less than 9, we can conclude that 9.11 is less than 9.90."
#>   ],
#>  "answer":"9.9 is bigger than 9.11."
#> }
```
