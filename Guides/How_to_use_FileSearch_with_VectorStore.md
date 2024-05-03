# How to use File search with Assistants and Vector Store

> [!WARNING]  
> The Assistants API is still in Beta. Specifications, usage, and parameters are subject to change without announcement.

File Search augments the Assistant with knowledge from outside its model, such as proprietary product information or documents provided by your users.

OpenAI's official document is here.  
https://platform.openai.com/docs/assistants/tools/file-search

This guide describes how to use File search with Assistants and Vector Store API step-by-step.

## Step 1: Upload files and add them to a Vector Store

To access your files, upload your files to OpenAI and create a Vector Store to contain them.

Use the `Register-OpenAIFile` and `New-VectorStore` cmdlet.

```PowerShell
# Import PSOpenAI module and Set API key.
Import-Module ..\PSOpenAI.psd1 -Force
$env:OPENAI_API_KEY = '<Put your API key here>'

# Upload some files for file search
## You need to set the purpose as "assistants"
$UploadedFiles = Get-ChildItem "C:\UploadFiles\*" -File | Register-OpenAIFile -Purpose "assistants"

# Create new vector store and attach uploaded items to that.
$VectorStore = New-VectorStore -Name 'VectorStore-1' -FileId $UploadedFiles.Id

# Or, you can add items to existing VectorStore.
$VectorStore | Add-VectorStoreFile -FileId "file-abc123"
```

## Step 2: Create a new Assistant with File Search Enabled

```powershell
# Create a new Assistant with File Search Enabled
$Assistant = New-Assistant `
    -Name "My Assistant" `
    -Model "gpt-3.5-turbo" `
    -UseFileSearch `
    -VectorStoresForFileSearch $VectorStore `
    -Instructions "You are a helpful assistant. You have access to the files you need to answer questions. Always answer based on the contents of the file."
```

## Step 3: Create a Thread and Run, and check the output

```PowerShell
# Create a new Thread with message and run it immediately
$ThreadRun = Start-ThreadRun `
    -Assistant $Assistant `
    -Message 'What is the extension number and name of the person in charge of Contoso help desk for employees?'

# Get a result message by assistant
$Result = $ThreadRun | Receive-ThreadRun -Wait

# Display message
$Result.Messages.SimpleContent

Role      Type Content
----      ---- -------
user      text What is the extension number and name of the person in charge of Contoso help desk for employees?
assistant text The person in charge of the Contoso help desk for employees is Alex Johnson, and the extension number is 1001【4:0†source】.
```

## Step 4: Clean up (optional)

Delete Vector Store and uploaded files when no longer needed.

```PowerShell
# Remove a Vector Store
$VectorStore | Remove-VectorStore

# Remove uploaded files
$UploadedFiles | Remove-OpenAIFiles
```
