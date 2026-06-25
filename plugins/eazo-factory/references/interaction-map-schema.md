# interaction-map.json schema

Purpose: stable contract for all interactive controls that appear in the shipped experience.

Rules:
- Use the exact top-level shape and control field names below.
- Every button, input, link, tab, toggle, or other actionable control must map to one `controls` entry.
- `feature_id` must match a `features.id` from `product-spec.json`.
- `destination` should point to a valid screen and state combination.
- If an image contains a button-like element that cannot be represented by one entry, remove it from the image.

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
      "acceptance": "Timer starts and paced breathing animation becomes visible"
    }
  ]
}
```
