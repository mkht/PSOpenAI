# How to use Realtime API

The Realtime API enables you to communicate with a GPT-4o class model live, in real time experiences.  

OpenAI's official guide is here.  
https://platform.openai.com/docs/guides/realtime

PSOpenAI provides the ability to use the Realtime API in an event-based style through PowerShell.

> [!WARNING]  
> The Realtime API is still in Beta. Specifications, usage, and parameters are subject to change without announcement.

> [!NOTE]  
> PSOpenAI does not yet support voice input/output and use of tools. There are plans to support this in the future.

## Step 1: Subscribe events

PSOpenAI notifies messages received from the server in real time as events.

You can subscribe to the events you are interested in using `Register-EngineEvent` and specify the action to be taken when you receive them.

```powershell
# SourceIdentifier is always "PSOpenAI.Realtime.ReceiveMessage"
Register-EngineEvent -SourceIdentifier "PSOpenAI.Realtime.ReceiveMessage" -Action {
    $eventItem = $Event.SourceArgs[0]
    switch ($eventItem.type) {
        'session.created'
        {
            # Display session info
            Write-Host "`r"
            ('Connected. (SessionID = "{0}")' -f $eventItem.session.id) | Write-Host -ForegroundColor Green
        }
        'response.text.delta'
        {
            # Display text responses from the AI to the console
            $eventItem.delta | Write-Host -NoNewline -ForegroundColor Blue
        }
        'error'
        {
            # Oops, something went wrong.
            Write-Host "`r"
            ('ERROR : "{0}")' -f $eventItem.error.message) | Write-Host -ForegroundColor Red
        }
    }
}
```

There are various types that can be received. All are listed in the [OpenAI reference](https://platform.openai.com/docs/api-reference/realtime-server-events), but here are a few that may be of particular interest to you

- `error`
- `session.created`
- `session.updated`
- `response.done`
- `response.text.delta`
- `response.text.done`


## Step 2: Connect & configure session

You need to connect to a session for conversation.

```powershell
# Import PSOpenAI module and Set API key.
Import-Module ..\PSOpenAI.psd1 -Force
$env:OPENAI_API_KEY = '<Put your API key here>'

# Connect to a session
Connect-OpenAIRealtimeSession
```

Then, configure session settings as needed.
```powershell
# Configure system message, output type, etc.
Set-OpenAIRealtimeSessionConfiguration `
    -Modalities 'text' `
    -Instructions 'You are a assistant for children. Always choose words that are easy for the child to understand.' `
    -Temperature 0.6
```

## Step 3: Send messages

You can add as many messages as you need to the session.  
In turn-based dialogue mode, the AI will not start generating answers once you have added messages.

```powershell
Add-OpenAIRealtimeSessionCoversationItem `
  -Role 'user' `
  -Message 'Hello. Why is the sun so bright?'
```

After adding messages, request the AI to generate an answer.

```powershell
Request-OpenAIRealtimeSessionResponse
```

Since we configured the output AI response events in blue in Step 1, blue text will be displayed on the console.

![session](images/realtime_session.gif)

Repeat this step if you wish to continue the dialogue.

```powershell
Add-OpenAIRealtimeSessionCoversationItem `
  -Role 'user' `
  -Message "Hmmm, I'm not understanding. Explain it more simply."

Request-OpenAIRealtimeSessionResponse
```

## Final Step: Close session

Finally, close the session when the conversation is over.

```powershell
Disconnect-OpenAIRealtimeSession
```

> [!NOTE]  
> Session may end unexpectedly in the middle of a conversation due to timeouts, network errors, etc.  
> Even in such cases, you should always do this.

(Optional) Stop event subscribe if not needed.

```powershell
Unregister-Event -SourceIdentifier "PSOpenAI.Realtime.ReceiveMessage"
```
