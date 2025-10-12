# How to use Video generation functions

Powerful video models such as `sora-2` are available through PSOpenAI. These cmdlets let you request new clips, monitor their progress, download finished assets, remix existing videos, and clean up jobs when you are done.

OpenAI's official documentation for videos is here.
https://platform.openai.com/docs/guides/video_generation

This guide shows end-to-end workflows and reusable snippets for each video-related cmdlet.

> [!NOTE]
> Video generation jobs are asynchronous. The cmdlet that creates or updates a job returns immediately with metadata. Use `Get-Video`, `Wait-Video`, or `Get-VideoContent -WaitForCompletion` to monitor completion before you try to download assets.

## Functions overview

| Scenario | Cmdlet | What it does |
| --- | --- | --- |
| Create a new job | `New-Video` | Submits a prompt, model, duration, and resolution to start rendering.【F:Docs/New-Video.md†L16-L60】 |
| Inspect job metadata | `Get-Video` | Retrieves a single job or lists recent jobs.【F:Docs/Get-Video.md†L16-L64】 |
| Wait for completion | `Wait-Video` | Polls a job until it finishes and shows progress in the console.【F:Public/Videos/Wait-Video.ps1†L1-L118】 |
| Download assets | `Get-VideoContent` | Fetches the rendered video, thumbnail, or spritesheet, optionally waiting for success.【F:Docs/Get-VideoContent.md†L16-L70】 |
| Remix an existing clip | `New-VideoRemix` | Applies a new prompt to a finished video to regenerate only the requested changes.【F:Docs/New-VideoRemix.md†L10-L47】 |
| Delete a job | `Remove-Video` | Removes a job you no longer need.【F:Docs/Remove-Video.md†L16-L55】 |

## Prerequisites

1. Import the module and set your API key.
   ```powershell
   Import-Module ..\PSOpenAI.psd1 -Force
   $env:OPENAI_API_KEY = '<Put your API key here>'
   ```
2. (Optional) Switch to Azure OpenAI by supplying `-ApiType`, `-ApiBase`, and `-ApiVersion` on each cmdlet.
3. Have a writable folder ready for downloaded media.

## Generate and download a video

The script below creates a four-second vertical clip, waits until it finishes, and writes the MP4 to disk.

```powershell
# Submit a new job.
$job = New-Video `
    -Prompt 'A hummingbird drinking nectar in super slow motion, macro lens.' `
    -Model 'sora-2' `
    -Seconds 4 `
    -Size 720x1280

# Wait for completion with a progress bar.
$finishedJob = $job | Wait-Video -PollIntervalSec 5

if ($finishedJob.status -ne 'completed' -and $finishedJob.status -ne 'succeeded') {
    throw "Job $($finishedJob.id) did not finish successfully."
}

# Download the rendered clip.
$videoPath = Join-Path $PWD 'hummingbird.mp4'
$finishedJob | Get-VideoContent -Variant video -OutFile $videoPath
```

Key points:

- `New-Video` accepts optional `-Seconds` and `-Size` switches to tune runtime and resolution.【F:Docs/New-Video.md†L22-L60】
- `Wait-Video` reads the job ID from the pipeline and keeps polling until it leaves the pending statuses.【F:Public/Videos/Wait-Video.ps1†L6-L83】
- `Get-VideoContent` downloads either the main video (`video`), a `thumbnail`, or a `spritesheet` sprite atlas.【F:Docs/Get-VideoContent.md†L28-L56】

## Poll jobs manually

If you prefer to build your own loop, use `Get-Video` to query job state.

```powershell
$job = New-Video -Prompt 'An orange tabby cat playing a grand piano on a stage' -Seconds 8 -Size 1280x720

while ($true) {
    Start-Sleep -Seconds 6
    $current = Get-Video -VideoId $job.id
    "[{0}] status = {1}, progress = {2}%" -f (Get-Date), $current.status, $current.progress

    if ($current.status -notin @('queued', 'in_progress', 'running', 'processing', 'preprocessing')) {
        break
    }
}
```

The job metadata includes `status`, `created_at`, `model`, and a `generations` collection you can inspect or pipe into other cmdlets.【F:Docs/Get-Video.md†L30-L63】

## Download assets when ready

`Get-VideoContent` can wait for completion and return bytes in memory when you do not want to touch disk.

```powershell
$job = New-Video -Prompt 'A drone flythrough of a futuristic city at sunset'

# Wait and download the thumbnail to disk.
Get-VideoContent -VideoId $job.id -Variant thumbnail -WaitForCompletion -OutFile (Join-Path $PWD 'city.webp')

# Fetch the spritesheet into memory for further processing.
$spritesheetBytes = Get-VideoContent -VideoId $job.id -Variant spritesheet -WaitForCompletion
```

When you omit `-OutFile`, the cmdlet returns a `byte[]` you can stream into other commands or write manually.【F:Docs/Get-VideoContent.md†L34-L53】 Using `-WaitForCompletion` ensures the download starts only after the job succeeds.【F:Docs/Get-VideoContent.md†L20-L33】

## Remix an existing video

Once you have a completed job, apply targeted changes with `New-VideoRemix`.

```powershell
$sourceJob = Get-Video -Limit 1 -Order desc | Select-Object -First 1

$remix = New-VideoRemix `
    -VideoId $sourceJob.id `
    -Prompt 'Replace the background with a vibrant cherry blossom garden, keep the subject intact.'

$remix | Wait-Video | Get-VideoContent -OutFile (Join-Path $PWD 'cherry_blossom_remix.mp4')
```

`New-VideoRemix` takes both the prompt and the source `VideoId`, so you can keep the structure of the original clip while updating specific elements.【F:Docs/New-VideoRemix.md†L16-L47】 The resulting job behaves like any other video job—you can wait on it and download content the same way.

## List and clean up jobs

Use the list parameter set on `Get-Video` to review existing jobs and `Remove-Video` to delete ones you no longer need.

```powershell
# Show the 5 most recent jobs.
Get-Video -Limit 5 -Order desc |
    Select-Object id, status, model, seconds, size, created_at

# Delete jobs that have already succeeded.
Get-Video -All |
    Where-Object status -in @('completed', 'succeeded') |
    ForEach-Object { $_ | Remove-Video }
```

`Get-Video -All` automatically pages until every job is returned.【F:Docs/Get-Video.md†L40-L63】 `Remove-Video` accepts IDs from the pipeline so you can compose cleanup flows easily.【F:Docs/Remove-Video.md†L16-L46】

## Troubleshooting tips

- `New-Video` retries are disabled by default. Supply `-MaxRetryCount` if you expect occasional 429 or 5xx responses.【F:Docs/New-Video.md†L61-L96】
- If you see a timeout while waiting, pass a larger `-TimeoutSec` to `Wait-Video` or `Get-VideoContent`.
- Always verify the final `status` property (`completed` or `succeeded`) before assuming the media is usable.
