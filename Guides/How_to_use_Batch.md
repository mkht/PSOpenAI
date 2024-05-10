# How to use Batch

The Batch API allows you to create large batches of API requests for asynchronous processing. The Batch API returns completions within 24 hours for a 50% discount.

OpenAI's official reference is here.  
https://platform.openai.com/docs/api-reference/batch

PSOpenAI includes various cmdlets for using the Batch API through PowerShell.

This guide describes how to use Batch step-by-step.

## Step 1: Create batch input items

Batch handles multiple chat completions in a single request. First use `Request-ChatCompletion` to create as many items as needed for batch input.

> [!NOTE]
> Currently, the only request that can be processed using Batch is chat completion.  
> Also, all items included in a single batch request must specify the same model name. Otherwise, an API error will occur.

```PowerShell
# Import PSOpenAI module and Set API key.
Import-Module ..\PSOpenAI.psd1 -Force
$env:OPENAI_API_KEY = '<Put your API key here>'

# Create 3 items for batch request
$BatchItems = @()
# item-1
$BatchItems += Request-ChatCompletion -Message 'Hello.' -Model 'gpt-3.5-turbo' -AsBatch -CustomBatchId 'item-1'
# item-2
$BatchItems += Request-ChatCompletion -Message 'What is a hot dog?' -Model 'gpt-3.5-turbo' -AsBatch -CustomBatchId 'item-2'
# item-3
$BatchItems += Request-ChatCompletion -Message 'How do I say delicious in German?' -Model 'gpt-3.5-turbo' -AsBatch -CustomBatchId 'item-3'
```

The important thing is to add an `-AsBatch` switch to `Request-ChatCompletion`. This creates an object for the batch instead of making an API request immediately.

Specifying `-CustomBatchId` is not required, but it is useful to link batch input and output. If not specified, a random id will be set automatically.

## Step 2: Create and Excecute batch request.

Use `Start-Batch` to start a batch job. Batch jobs take longer than regular requests. (In return, you get a 50% discount.)

You can later run `Get-Batch` several times and wait for the Status to change to "completed", or use `Wait-Batch` to wait until completion.

```PowerShell
# Create and start batch
$Batch = $BatchItems | Start-Batch

# First, the status of batch may "validating" or "in_progress"
$Batch.status

# Run Get-Batch several times and wait for the status to become "complete"
$Batch = Get-Batch -BatchId $Batch.Id
$Batch.status

# Or, you can use Wait-Batch to wait until completion. 
$Batch = $Batch | Wait-Batch
# Status may be "completed"
$Batch.status
```

## Step 3: Get output items of a batch

After the batch has been successfully completed, the results of the batch execution are saved in the storage of your OpenAI account. You can use `Get-BatchOutput` to retrieve this and check the output.

The order of the batch output does not match the input. You must use your Custom ID to see which output corresponds to which input.

```PowerShell
# Retrives batch output
$BatchResult = $Batch | Get-BatchOutput

# Displays batch output object
> $BatchResult
custom_id id              response                                     error
--------- --              --------                                     -----
item-2    batch_req_abcde @{status_code=200; request_id=a37a2; body=}
item-3    batch_req_fghij @{status_code=200; request_id=a4adb; body=}
item-1    batch_req_klmno @{status_code=200; request_id=cd1a9; body=}

# Extract answers
> $BatchResult | select custom_id, @{Name='Answer';Expression={$_.response.body.Answer}}
custom_id Answer
--------- ------
item-2    A hot dog is a type of sausage made of a combination of…
item-3    "Delicious" in German is "lecker" or "köstlich".
item-1    Hello! How can I assist you today?
```

## Step 4: Clean up (Optional)

Batch inputs and outputs are stored as JSONL files in your OpenAI account storage. They are not automatically deleted.

You can use `Remove-OpenAIFile` to delete them if necessary.

```PowerShell
# Remove batch input file from storage
Remove-OpenAIFile -FileId $Batch.input_file_id

# Remove batch output file from storage
Remove-OpenAIFile -FileId $Batch.output_file_id
```
