# How to use Video generation

Powerful video generation models such as `sora-2` are available through PSOpenAI. These cmdlets let you request new clips, monitor their progress, download finished assets, remix existing videos, and clean up jobs when you are done.

OpenAI's official documentation for videos is here.  
https://platform.openai.com/docs/guides/video-generation

This guide shows end-to-end workflows and reusable snippets for each video-related cmdlet.


## Functions overview

| Scenario               | Cmdlet             | What it does                                                                           |
| ---------------------- | ------------------ | -------------------------------------------------------------------------------------- |
| Create a new job       | `New-Video`        | Submits a prompt, model, duration, and resolution to start rendering.                  |
| Retrieve job status    | `Get-Video`        | Retrieves a single job or lists jobs.                                                  |
| Download assets        | `Get-VideoContent` | Fetches the generated video, thumbnail, or spritesheet.                                |
| Remix an existing clip | `New-VideoRemix`   | Applies a new prompt to a existing video without regenerating everything from scratch. |
| Delete a job           | `Remove-Video`     | Removes a job you no longer need.                                                      |

## Prerequisites

1. Import the module and set your API key.
   ```powershell
   Import-Module ..\PSOpenAI.psd1 -Force
   $env:OPENAI_API_KEY = '<Put your API key here>'
   ```

## Generate and download a video

The script below creates a four-second vertical clip, waits until it finishes, and writes the MP4 to disk.

```powershell
# Start a new video generation job.
$VideoJob = New-Video `
    -Prompt 'A hummingbird drinking nectar in super slow motion, macro lens.' `
    -Model 'sora-2' `
    -Seconds 4 `
    -Size 720x1280

# Wait for completion.
while ($true) {
    Start-Sleep -Seconds 5
    $current = Get-Video -VideoId $VideoJob.id
    "[{0}] status = {1}, progress = {2}%" -f (Get-Date), $current.status, $current.progress
    if ($current.status -in @('completed', 'failed')) { break }
}

# Download the generated video.
$videoPath = Join-Path $PWD 'hummingbird.mp4'
Get-VideoContent -VideoId $VideoJob.id -OutFile $videoPath
```

Above example uses `New-Video` to start a job, then waits until the job completes by polling `Get-Video` every five seconds. Finally, it downloads the MP4 file with `Get-VideoContent`.

More simply, you can use `-WaitForCompletion` on `Get-VideoContent` to block until the job finishes and download the file in one step.

```powershell
New-Video -Model 'sora-2' -Prompt 'A cat flying with butterfly wings' -Seconds 4 -Size 1280x720 | `
    Get-VideoContent -OutFile (Join-Path $PWD 'flying_cat.mp4') -WaitForCompletion
```

## Remix an existing video

Once you have a completed job, apply targeted changes with `New-VideoRemix`.

```powershell
# Assume you have a completed video job with ID 'video_abc123'.
$sourceJob = Get-Video -VideoId 'video_abc123'

$remixJob = New-VideoRemix `
    -VideoId $sourceJob.id `
    -Prompt 'Replace the background with a vibrant cherry blossom garden, keep the subject intact.'

$remixJob | Get-VideoContent -OutFile (Join-Path $PWD 'cherry_blossom_remix.mp4') -WaitForCompletion
```

`New-VideoRemix` takes both the prompt and the source `VideoId`, so you can keep the structure of the original clip while updating specific elements. The resulting job behaves like any other video job, you can wait on it and download content the same way.

## List and clean up jobs

Use the list parameter set on `Get-Video` to review existing jobs and `Remove-Video` to delete ones you no longer need.

```powershell
# Show the 5 most recent jobs.
Get-Video -Limit 5 -Order desc |
  Select-Object id, status, created_at, expires_at

# Delete all jobs that have already expired.
Get-Video -All |
  Where-Object expires_at -le (Get-Date) |
    Remove-Video
```

`Remove-Video` accepts IDs from the pipeline so you can compose cleanup flows easily.
