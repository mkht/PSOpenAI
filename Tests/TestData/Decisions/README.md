# Decisions API test fixtures

These fixed requests and response recordings were verified against
POST https://api.openai.com/v1/decisions with gpt-6-luna on 2026-10-07.
Authentication used the process OPENAI_API_KEY environment variable.
No keys or HTTP authentication headers are stored here.

## Sources and conditions

- text-request.json is a manually written, fictional customer report with
  predicate, boolean choice, string choice, and score questions.
- image-request.json reuses ../ContentProvenanceChecks/not-detected.png.
  This 256 x 256 programmatic drawing contains a navy rectangle and an orange
  disc on white. Its creation conditions are documented in
  [the provenance fixture README](../ContentProvenanceChecks/README.md).
  The command sends it as an inline data URL with ImageDetail original.
- text-response.json and image-response.json record the first real responses,
  pretty-printed without changing response fields or values. A repeat run
  returned the same answers and token usage.
- Requests used TimeoutSec 90 and MaxRetryCount 0 on PowerShell 7.6.6. The
  validation made four requests in total: the two cases, then a rerun after
  revising the image score assertion. Total reported input tokens: 2058;
  reported output tokens: 0.

Image SHA-256: 0a733dbb6733e1afb21aeb3d93a22e11fcda04a1b2b9a6c63d4878c791e6ee68.

## Verified results

| Case | Live expectations | Observed result |
| --- | --- | --- |
| Text | Damage probability above 0.5; boolean false for usability; string refund for resolution; severity from 1.5 to 2 | Probability 1; false; refund; score 2; 546 input tokens |
| Image | Orange-shape probability above 0.5; geometric_drawing classification; score in 0..2 with a normalized distribution and matching weighted average | Probability 1; geometric_drawing; score 1; 483 input tokens |

Both responses preserved question names and order, typed choices, score
probabilities, and usage. The saved recordings are parsed in Offline tests.
Existing synthetic response tests separately cover refusal and fractional scores.

The image count score was 1 even though the fixture visibly contains two shapes.
An initial assertion requiring a score of at least 1.5 failed. The integration
test now checks the score's API contract and arithmetic instead of assuming that
the model's visual count is correct. The observed score is a recording of model
behavior, not the ground-truth shape count or a fixed future prediction.

## Run

With OPENAI_API_KEY available in the process environment:

```powershell
$configuration = & ./PesterConfiguration.ps1
$configuration.Run.Path = './Tests/Decisions/Request-Decision.tests.ps1'
$configuration.Filter.Tag = 'Online'
Invoke-Pester -Configuration $configuration
```

Online runs make two real API requests and print their responses. Use the
Offline tag to verify parsing and request construction without API calls.
Neither test mode regenerates the requests, image, or saved response recordings.

## References

- [Decisions API guide](https://developers.openai.com/api/docs/guides/decisions)
- [Create a decision](https://developers.openai.com/api/reference/resources/decisions/methods/create)
