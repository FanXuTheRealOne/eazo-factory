# product-spec.json schema

Purpose: stable contract for the product definition consumed by the factory pipeline.

Rules:
- Use the exact field names and top-level shape below.
- `schema_version` must be `"1.0"`.
- The app must define exactly one primary loop as an ordered list in `primary_loop`.
- Every item in `features` must include at least one acceptance condition in `acceptance`.
- `screens.id` values should be the screen identifiers referenced elsewhere in the run.
- `app_kind` must be either `"functional"` or `"experiential"`. Use `"functional"` only for utility-first apps such as calculators, trackers, converters, checklists, or CRUD tools.
- Every app must include a bilingual language-switching feature for `en-US` and `zh-CN`.
- Every non-functional app must set `audio.bgm_required` to `true` and include an ambient BGM feature. Browser autoplay limits mean BGM must start from a real mapped user control.

```json
{
  "schema_version": "1.0",
  "name": "Quiet Breath",
  "slug": "quiet-breath",
  "app_kind": "experiential",
  "summary": "A focused breathing companion.",
  "target_user": "People who need a two-minute reset.",
  "core_problem": "Stress spikes without an immediate calming ritual.",
  "primary_loop": [
    "Choose duration",
    "Start breathing session",
    "Follow paced animation",
    "Complete and save reflection"
  ],
  "features": [
    {
      "id": "breathing-session",
      "name": "Breathing session",
      "acceptance": ["A user can start and complete a timed session"]
    },
    {
      "id": "language-switching",
      "name": "English / Chinese switch",
      "acceptance": ["A user can switch all product copy between English and Chinese without leaving the app"]
    },
    {
      "id": "ambient-bgm",
      "name": "Ambient BGM",
      "acceptance": ["A user can turn on matching ambient background music after a tap"]
    }
  ],
  "screens": [
    {
      "id": "home",
      "purpose": "Choose and start a session",
      "states": ["idle", "active", "complete"]
    }
  ],
  "capabilities": {
    "auth": false,
    "database": false,
    "ai": false,
    "memory": true,
    "notifications": false,
    "mcp": false
  },
  "locales": ["en-US", "zh-CN"],
  "copy_direction": {
    "en-US": "Warm, concise, grounded",
    "zh-CN": "温和、简洁、自然"
  },
  "audio": {
    "bgm_required": true,
    "mood": "Slow warm ambient pads with soft breathing rhythm",
    "user_control": "BGM starts muted/off and can be toggled by the user"
  },
  "exclusions": ["Social feed", "Subscription flow", "Decorative buttons"]
}
```
