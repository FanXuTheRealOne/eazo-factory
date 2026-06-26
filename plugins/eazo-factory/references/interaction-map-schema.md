# interaction-map.json schema

Purpose: stable contract for all interactive controls that appear in the shipped experience.

Rules:
- Use the exact top-level shape and control field names below.
- Every button, input, link, tab, toggle, or other actionable control must map to one `controls` entry.
- `screen` must match a `screens.id` value from `product-spec.json`.
- `feature_id` must match a `features.id` from `product-spec.json`.
- `destination` must be either a valid `<screen-id>:<state>` pair where both values exist in `product-spec.json`, or a documented external/platform destination.
- When `destination` is external or platform-owned, `destination_reference.type` must be `"external_platform"` and `destination_reference.documentation` must explain the destination.
- If an image contains a button-like element that cannot be represented by one entry, remove it from the image.
- Every app must include one mapped language switch control bound to `feature_id: "language-switching"`.
- Every non-functional app with required BGM must include one mapped audio/BGM control bound to `feature_id: "ambient-bgm"`.

```json
{
  "schema_version": "1.0",
  "controls": [
    {
      "id": "home-start-session",
      "screen": "home",
      "control_type": "button",
      "label": {
        "en-US": "Begin",
        "zh-CN": "开始"
      },
      "feature_id": "breathing-session",
      "action": "Start the selected breathing session",
      "destination": "home:active",
      "destination_reference": {
        "type": "product_screen_state",
        "screen_id": "home",
        "state": "active"
      },
      "acceptance": "Timer starts and paced breathing animation becomes visible"
    },
    {
      "id": "global-language-toggle",
      "screen": "home",
      "control_type": "toggle",
      "label": {
        "en-US": "中文",
        "zh-CN": "EN"
      },
      "feature_id": "language-switching",
      "action": "Switch all product copy between English and Chinese",
      "destination": "home:idle",
      "destination_reference": {
        "type": "product_screen_state",
        "screen_id": "home",
        "state": "idle"
      },
      "acceptance": "All product copy switches between English and Chinese without navigation"
    }
  ]
}
```
