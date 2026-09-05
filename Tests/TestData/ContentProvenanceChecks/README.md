# Content provenance test fixtures

These committed fixtures are used by the Online tests in
Tests/ContentProvenanceChecks/Request-ContentProvenanceCheck.tests.ps1.
Tests upload the existing files; they never regenerate them.

| File | Source | Expected C2PA | Expected SynthID |
| --- | --- | --- | --- |
| detected.png | OpenAI gpt-image-2, generated on 2026-09-05 | detected (trusted or valid) | detected |
| not-detected.png | Programmatic drawing with System.Drawing; no generative model | not_detected (not_present) | not_detected |

Both expectations were verified against the real API on 2026-09-05.
Docs/images/babylion.png was also checked, but returned not_detected for
both signals and therefore is not used as the positive fixture.

Keep detected.png byte-for-byte intact. Re-encoding, optimizing, or removing
metadata can change its provenance signals. A not_detected result is not proof
that an image was not AI-generated.

## Run

From the repository root, with OPENAI_API_KEY set in the process environment:

```powershell
Invoke-Pester -Tag Online -Path Tests/ContentProvenanceChecks/Request-ContentProvenanceCheck.tests.ps1
```

Online tests make real API requests. Offline tests remain mocked.
Each Online test sends one file, with a 60-second timeout and at most two
retries for transient errors.

## Fixture creation

The positive fixture was created once with the following command. Do not run
this as test setup: it incurs generation costs and replaces the verified fixture.

```powershell
Request-ImageGeneration -Model gpt-image-2 `
    -Prompt 'A photograph of a small orange ceramic teapot on a wooden table, natural window light, no text.' `
    -Quality low -Size 1024x1024 `
    -OutFile Tests/TestData/ContentProvenanceChecks/detected.png `
    -TimeoutSec 180 -ErrorAction Stop
```

The negative fixture is a 256 x 256 PNG with a white background, a navy
96 x 96 rectangle at (32, 32), and an orange 96 x 96 ellipse at (128, 128).
It was drawn using System.Drawing.Bitmap and Graphics, then saved as PNG.

## Reference

[OpenAI content provenance guide](https://developers.openai.com/api/docs/guides/content-provenance)

## SHA-256

- detected.png: 16712110752927792add37ed98c3e388c639239837b2cb8fa2028b61e332f8ab
- not-detected.png: 0a733dbb6733e1afb21aeb3d93a22e11fcda04a1b2b9a6c63d4878c791e6ee68
