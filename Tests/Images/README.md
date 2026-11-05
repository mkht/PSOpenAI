# GPT Image 2.6 verification

The Offline tests use fixed, synthetic GIF/SVG base64 payloads and synthetic usage objects. They verify serialization, byte preservation, file-format inference, omitted options, and separate SVG author usage. They do not call the API or regenerate images. Image edit tests reuse the existing files in `Docs/images`.

## Live checks on 2026-11-05

Executed separately with the `Online` tag using the local module and an environment-provided API key. Each successful request used `Quality=low`, `Complexity=low`, `NumberOfImages=1`, `TimeoutSec=180`, and `MaxRetryCount=0`. Generated outputs were inspected in memory, not added as test fixtures.

| Operation | Request | Observed result |
| --- | --- | --- |
| Flare GIF generation | `gpt-image-2.6-flare`, `512x512`, `FrameCount=2`, `FrameDurationMs=200`; prompt: "A simple blue ball bouncing on a white background, two frame loop." | `output_format=gif`; decoded bytes have a GIF signature. |
| Sunburst SVG generation | `gpt-image-2.6-sunburst`, `1024x1024`, `Svg=@{ model='gpt-6-luna'; reasoning=@{ effort='low' } }`; prompt: "A simple blue circle icon on a white background." | `output_format=svg`; decoded UTF-8 XML has an `svg` root; `svg_usage.model=gpt-6-luna` is separate from image `usage`. |
| Sunburst PNG edit | `gpt-image-2.6-sunburst`, `1024x1024`, existing `Docs/images/sand_with_feather.png`; prompt: "Make the feather blue. Keep the rest unchanged." | `output_format=png`; decoded bytes have the PNG signature. |

Initial requests established two configuration requirements: the tested two-frame GIF at `1024x1024` was rejected because its internal sheet exceeded the model's edge limit; SVG required `svg.model` on this account. The unqualified author name `gpt-6` was unavailable; the accessible `gpt-6-luna` model succeeded. These are observations for this account and date, not client-side model restrictions.

GIF editing and Responses image generation were checked offline only. The API schema and [SDK PR #4247](https://github.com/openai/openai-python/pull/4247) expose GIF edit fields, while the [image guide](https://developers.openai.com/api/docs/guides/image-generation) describes GIF generation only. Frame counts follow the API schema's 2-16 range, despite the guide listing a broader range. Images accepts frame delays of at least 20 ms; the Responses schema caps them at 2000 ms. Endpoint availability and model-specific pixel limits remain API decisions.
