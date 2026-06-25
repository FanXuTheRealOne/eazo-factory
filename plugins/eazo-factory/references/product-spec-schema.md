# product-spec.json schema

Purpose: stable contract for the product definition consumed by the factory pipeline.

Rules:
- Use the exact field names and top-level shape below.
- `schema_version` must be `"1.0"`.
- The app must define exactly one primary loop as an ordered list in `primary_loop`.
- Every item in `features` must include at least one acceptance condition in `acceptance`.
- `screens.id` values should be the screen identifiers referenced elsewhere in the run.

```json
{
  "schema_version": "1.0",
  "name": "Quiet Breath",
  "slug": "quiet-breath",
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
  "exclusions": ["Social feed", "Subscription flow", "Decorative buttons"]
}
```
