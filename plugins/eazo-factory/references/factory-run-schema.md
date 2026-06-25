# factory-run.json schema

Purpose: stable run-state contract for the current factory execution and produced artifacts.

Rules:
- Use the exact field names and nesting below.
- `status` and `stage` should be updated in place as work advances.
- `artifacts` stores produced artifact paths or URLs by artifact name.
- `verification` stores ordered verification records for the current run.

```json
{
  "schema_version": "1.0",
  "plugin_version": "0.1.0",
  "status": "in_progress",
  "stage": "design",
  "started_at": "2026-06-25T00:00:00Z",
  "updated_at": "2026-06-25T00:00:00Z",
  "starter": {
    "source": "https://github.com/EazoAI/eazo-creator-nextjs-template.git",
    "branch": "main",
    "commit": ""
  },
  "artifacts": {},
  "verification": [],
  "review_cycles": 0,
  "preview_url": null
}
```
