# asset-library.json schema

Purpose: a compact inventory of the visual materials shown in `design/ui-reference.png` so the Builder can implement a consistent UI instead of guessing from one screenshot.

Rules:
- Use the exact top-level keys shown below.
- Keep assets small and reusable. Do not add product features or controls here.
- `mapped_control_id` is required only for interactive component specimens. Decorative and background assets use `null`.
- Every asset should be visible in the UI reference board.

```json
{
  "schema_version": "1.0",
  "style_lock": "Matisse cut-paper, warm wellness app, soft organic shapes, hand-cut edges",
  "assets": [
    {
      "id": "primary-button-shape",
      "type": "component",
      "name": "Primary action button",
      "mapped_control_id": "home-start-session",
      "implementation_hint": "Rounded pill with cut-paper shadow, high-contrast fill, 160ms press scale"
    },
    {
      "id": "breathing-orb",
      "type": "motif",
      "name": "Breathing orb",
      "mapped_control_id": null,
      "implementation_hint": "Layered blob scales slowly during the session"
    },
    {
      "id": "warm-paper-background",
      "type": "background",
      "name": "Warm paper background",
      "mapped_control_id": null,
      "implementation_hint": "Cream canvas with two translucent organic paper layers"
    }
  ]
}
```
