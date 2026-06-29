# factory-run.json schema

Purpose: stable run-state contract for the current factory execution and produced artifacts.

Rules:
- Use the exact field names and nesting below.
- `status` and `stage` should be updated in place as work advances.
- `stage_history` is append-only and records every transition as `{ "stage", "status", "entered_at" }`.
- `starter.source` must be `https://github.com/EazoAI/eazo-creator-nextjs-template.git`.
- `starter.branch` must be `main`.
- `artifacts` stores produced artifact records keyed by artifact name.
- Each artifact record must use the stable shape `{ "artifact_type", "path", "source_reference", "status", "updated_at" }`.
- `verification` stores ordered verification records for the current run.
- Each verification record must use the stable shape `{ "id", "kind", "name", "command", "status", "evidence", "ran_at" }`.

```json
{
  "schema_version": "1.0",
  "plugin_version": "0.1.6",
  "status": "in_progress",
  "stage": "design",
  "stage_history": [
    {
      "stage": "preflight",
      "status": "in_progress",
      "entered_at": "2026-06-25T00:00:00Z"
    },
    {
      "stage": "design",
      "status": "in_progress",
      "entered_at": "2026-06-25T00:02:00Z"
    }
  ],
  "started_at": "2026-06-25T00:00:00Z",
  "updated_at": "2026-06-25T00:00:00Z",
  "starter": {
    "source": "https://github.com/EazoAI/eazo-creator-nextjs-template.git",
    "branch": "main",
    "commit": ""
  },
  "artifacts": {
    "product_spec": {
      "artifact_type": "json",
      "path": "artifacts/product-spec.json",
      "source_reference": "references/product-spec-schema.md",
      "status": "ready",
      "updated_at": "2026-06-25T00:00:00Z"
    }
  },
  "verification": [
    {
      "id": "content-check-001",
      "kind": "contract_check",
      "name": "schema-version-reference-check",
      "command": "rg -n '\"schema_version\": \"1.0\"' plugins/eazo-factory/references",
      "status": "pass",
      "evidence": "Six schema_version example matches found across artifact references.",
      "ran_at": "2026-06-25T00:00:00Z"
    }
  ],
  "review_cycles": 0,
  "preview_url": null
}
```
