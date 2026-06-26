---
name: eazo-factory
description: Create one complete Eazo app from an idea or product request, including product scoping, $imagegen UI design, official-template implementation, mandatory independent review, fixes, and a local preview URL. Use when the user asks to make or generate an Eazo app.
---

# Eazo Factory

Create one independent app per invocation. Do not batch, deploy, publish, or push a remote repository. Prefer compact artifacts and one decisive pass over verbose planning.

## Resolve paths

Determine:

- plugin root: two directories above this skill;
- output root: user-provided location, or an `eazo-apps/` directory under the current workspace;
- app slug: supplied by `$eazo-idea`;
- final app directory: `<output-root>/<slug>`;
- staging directory: `<output-root>/.eazo-factory-runs/<slug>`.

The staging directory prevents pre-scaffold product and design artifacts from making the final destination non-empty.

## Stage machine

Execute every stage in order:

```text
preflight → idea → design → scaffold → build → verify → preview → independent review → optional one fix/re-review → final preview
```

Update `factory-run.json` at the durable milestones only: preflight, idea, design, scaffold, build, verify, preview, review, fix, final.

After each transition, call:

```bash
bash <plugin-root>/scripts/update-run.sh <run-path> <stage> <status> [preview-url] [increment-review]
```

Use `increment-review` value `1` only when starting a new independent review cycle. Add artifact and verification records to the same JSON without removing existing fields.

## Workflow

### 1. Preflight

Create resumable state before any check:

```bash
STAGING_DIR="$(bash <plugin-root>/scripts/init-run.sh <output-root> <provisional-slug>)"
```

This creates `factory-run.json` with stage `preflight`. Preserve it on every failure.

Confirm `$imagegen` is available in the current Codex skill/tool inventory. This capability cannot be inferred from a shell executable; record a failed preflight state and stop before creating product artifacts when it is unavailable.

Run:

```bash
bash <plugin-root>/scripts/preflight.sh <output-root> <provisional-slug>
```

Verify Codex, Git, Bun, Node, a writable output root, and access to the official Eazo template. Stop on failure.

### 2. Idea

Use the staging directory returned by `init-run.sh`. Explicitly invoke `$eazo-idea` with:

- the user's request;
- staging directory as target;
- expected output: `<staging>/product-spec.json`.

The product spec must include `language-switching`. It must include `ambient-bgm` unless the app is explicitly utility-first/functional.

Read the generated slug from the artifact. Rename the staging directory when the provisional slug differs, preserving `factory-run.json`, and update its stage to `idea`.

### 3. Design

Explicitly invoke `$eazo-design` with:

- `<staging>/product-spec.json`;
- staging directory as target;
- expected outputs:
  - `<staging>/design/ui-reference.png`;
  - `<staging>/design/image-prompt.md`;
  - `<staging>/design/design-tokens.json`;
  - `<staging>/design/interaction-map.json`;
  - `<staging>/design/asset-library.json`.

Require the UI image to be a single reference board: one polished mobile frame plus a compact asset library grid of matched controls, decorative parts, background material, icons, state elements, motion notes, and BGM mood. Do not request multiple separate image variations.

Retry `$imagegen` once with a simplified prompt when image generation fails. If the retry also fails, record a failed design state and stop. A runnable Eazo Factory release requires a valid UI reference image.

### 4. Scaffold

Run:

```bash
bash <plugin-root>/scripts/scaffold-app.sh <output-root> <slug>
```

Copy `product-spec.json` and the complete `design/` directory from staging into the final app. Preserve the scaffolded `factory-run.json` and update its artifact records. Never copy staging Git metadata.

Merge the staging run's original `started_at`, stage history, verification, review count, and artifact records into the scaffolded run state:

```bash
bash <plugin-root>/scripts/merge-run-state.sh <staging>/factory-run.json <app-directory>/factory-run.json
```

Do this before deleting staging.

Append a clearly delimited `Generated App Contract` section to the official template's `AGENTS.md`. Preserve all official instructions. The appended section must point to the product/design artifacts, forbid controls outside `interaction-map.json`, and require `verify-app.sh` plus the independent review gate.

### 5. Build

Explicitly invoke `$eazo-build` with:

- final app directory;
- plugin root;
- all product and design artifact paths;
- expected output: implemented source and passing deterministic verification.

### 6. Verify

Run:

```bash
bash <plugin-root>/scripts/verify-app.sh <app-directory>
```

Do not proceed while deterministic blocking findings remain.

### 7. Preview

Run:

```bash
bash <plugin-root>/scripts/start-preview.sh <app-directory>
```

Record the returned URL.

### 8. Independent review

The Builder cannot approve its own work.

1. Spawn a fresh reviewer subagent with read-only application-source access when subagent tools are available.
2. Otherwise start a fresh independent Codex review thread/run.
3. Give it only the final app artifacts, preview URL, `$eazo-review`, and required rubric context. Do not pass Builder reasoning or self-review.
4. Explicitly invoke `$eazo-review`.
5. Require complete `review.json` and `control-audit.json` payloads.
6. Write those payloads into `<app-directory>/review/` without changing the verdict.
7. Run `bash <plugin-root>/scripts/validate-review.sh <app-directory>` and reject malformed, incomplete, or internally inconsistent review payloads.

If no independent reviewer context can be created, stop. Self-review is not an acceptable fallback.

### 9. Optional fix and re-review

When the verdict fails:

1. send all blocking and important findings to a Builder/Fixer context;
2. fix only the reported defects;
3. run deterministic verification again;
4. restart preview if needed;
5. launch a fresh independent reviewer context and invoke `$eazo-review` again.

Allow at most one fix-and-review cycle. Never weaken product requirements, the interaction map, verifier, or rubric to obtain a pass. If the second verdict fails, return the app path, preview command, and bounded fix list instead of continuing to spend tokens.

### 10. Final preview

Start or confirm the final healthy preview only when:

- deterministic verification passes;
- review score is at least 85;
- no blocking or important finding exists;
- control coverage status is `pass`;
- every discovered interactive control is mapped and passes;
- core and bug category minimums pass.

Enforce these gates mechanically:

```bash
bash <plugin-root>/scripts/validate-review.sh <app-directory> --require-pass
```

Remove staging only after all artifacts are present in the final app. Preserve it on any interrupted or failed run.

## Final response

Return:

- absolute app path;
- local preview URL, or exact restart command when the process cannot remain running;
- exact official template commit;
- verification status;
- review score and cycle count;
- number of discovered and passing controls;
- unresolved non-blocking findings.

Never report success when a blocking or important finding, failed audit entry, unmapped control, decorative button, or dead action remains.
