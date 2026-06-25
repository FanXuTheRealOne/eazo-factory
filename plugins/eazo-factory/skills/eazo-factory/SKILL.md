---
name: eazo-factory
description: Create one complete Eazo app from an idea or product request, including product scoping, $imagegen UI design, official-template implementation, mandatory independent review, fixes, and a local preview URL. Use when the user asks to make or generate an Eazo app.
---

# Eazo Factory

Create one independent app per invocation. Do not batch, deploy, publish, or push a remote repository.

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
preflight
→ idea
→ design
→ scaffold
→ build
→ verify
→ preview
→ independent review
→ fix
→ re-verify
→ re-review
→ final preview
```

Update `factory-run.json` at every stage with status, stage, timestamps, artifact records, verification records, review cycle count, and preview URL.

## Workflow

### 1. Preflight

Run:

```bash
bash <plugin-root>/scripts/preflight.sh <output-root> <provisional-slug>
```

Verify Codex, Git, Bun, Node, a writable output root, `$imagegen`, and access to the official Eazo template. Stop on failure.

### 2. Idea

Create the staging directory. Explicitly invoke `$eazo-idea` with:

- the user's request;
- staging directory as target;
- expected output: `<staging>/product-spec.json`.

Read the generated slug from the artifact. Rename the staging directory when the provisional slug differs.

### 3. Design

Explicitly invoke `$eazo-design` with:

- `<staging>/product-spec.json`;
- staging directory as target;
- expected outputs:
  - `<staging>/design/ui-reference.png`;
  - `<staging>/design/image-prompt.md`;
  - `<staging>/design/design-tokens.json`;
  - `<staging>/design/interaction-map.json`.

Retry `$imagegen` once with a simplified prompt when image generation fails. Stop if the retry fails; do not silently continue without a UI reference.

### 4. Scaffold

Run:

```bash
bash <plugin-root>/scripts/scaffold-app.sh <output-root> <slug>
```

Copy `product-spec.json` and the complete `design/` directory from staging into the final app. Preserve the scaffolded `factory-run.json` and update its artifact records. Never copy staging Git metadata.

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

If no independent reviewer context can be created, stop. Self-review is not an acceptable fallback.

### 9. Fix and review loop

When the verdict fails:

1. send all blocking and important findings to a Builder/Fixer context;
2. fix only the reported defects;
3. run deterministic verification again;
4. restart preview if needed;
5. launch a fresh independent reviewer context and invoke `$eazo-review` again.

Allow at most two fix-and-review cycles. Never weaken product requirements, the interaction map, verifier, or rubric to obtain a pass.

### 10. Final preview

Start or confirm the final healthy preview only when:

- deterministic verification passes;
- review score is at least 85;
- no blocking finding exists;
- control coverage status is `pass`;
- every discovered interactive control is mapped and passes;
- core and bug category minimums pass.

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

Never report success when a blocking finding, failed audit entry, unmapped control, decorative button, or dead action remains.
