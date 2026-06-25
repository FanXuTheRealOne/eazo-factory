# Eazo Factory Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build an installable Codex plugin that transforms one app request into a standardized, reviewed, independently runnable Eazo app based on the official Eazo Next.js template.

**Architecture:** The plugin contains one orchestrator skill and four focused worker skills. Deterministic shell scripts own preflight, scaffolding, verification, and preview startup; Markdown references define artifact schemas and review policy; a repository marketplace makes the plugin installable from GitHub.

**Tech Stack:** Codex Plugin manifest, Codex Skills, Markdown references, POSIX-compatible Bash with macOS/Linux support, Git, Bun, Next.js, JSON artifacts, official `EazoAI/eazo-creator-nextjs-template`.

## Global Constraints

- The canonical starter is `https://github.com/EazoAI/eazo-creator-nextjs-template.git`, branch `main`.
- Every generated app records the exact starter commit SHA.
- The checked-out template's `AGENTS.md`, source, `.env.example`, and scripts outrank bundled plugin references.
- Run `bun run cleanup:demo` before product implementation.
- Version one creates one app per invocation and does not deploy or publish it.
- UI generation uses Codex `$imagegen`.
- Every visible interactive control must appear in `design/interaction-map.json` or be a required Eazo platform control.
- Decorative, dead, placeholder, or unmapped controls are blocking defects.
- A mandatory independent review covers core functionality, bugs, visual quality, control behavior, and control necessity.
- The reviewer must inspect the rendered app and exercise every interactive control when browser tooling is available.
- At most two automated fix-and-review cycles are allowed.
- An app cannot pass with any blocking finding or failed/unmapped control.
- Never commit Eazo private keys, database credentials, or other secrets.

---

## Planned file map

```text
.agents/plugins/marketplace.json
plugins/eazo-factory/
├── .codex-plugin/plugin.json
├── README.md
├── agents/openai.yaml
├── skills/
│   ├── eazo-factory/SKILL.md
│   ├── eazo-idea/SKILL.md
│   ├── eazo-design/SKILL.md
│   ├── eazo-build/SKILL.md
│   └── eazo-review/SKILL.md
├── references/
│   ├── eazo-template-policy.md
│   ├── product-spec-schema.md
│   ├── design-system-schema.md
│   ├── interaction-map-schema.md
│   ├── factory-run-schema.md
│   ├── review-rubric.md
│   └── art-directions/
│       ├── matisse-cut-paper.md
│       ├── bauhaus-playful.md
│       └── quiet-editorial.md
├── scripts/
│   ├── lib/common.sh
│   ├── preflight.sh
│   ├── scaffold-app.sh
│   ├── verify-app.sh
│   └── start-preview.sh
└── tests/
    ├── fixtures/
    │   ├── valid-app/
    │   ├── dead-button-app/
    │   └── client-ai-import-app/
    ├── test-manifest.sh
    ├── test-scaffold.sh
    └── test-verify.sh
```

### Task 1: Scaffold a valid installable plugin and marketplace

**Files:**
- Create: `plugins/eazo-factory/.codex-plugin/plugin.json`
- Create: `plugins/eazo-factory/agents/openai.yaml`
- Create: `plugins/eazo-factory/README.md`
- Create: `.agents/plugins/marketplace.json`
- Create: `plugins/eazo-factory/tests/test-manifest.sh`

**Interfaces:**
- Consumes: Codex plugin manifest and marketplace conventions.
- Produces: plugin identifier `eazo-factory`, version `0.1.0`, skills root `./skills/`, marketplace name `eazo-tools`.

- [ ] **Step 1: Write the failing manifest test**

Create `plugins/eazo-factory/tests/test-manifest.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "$PLUGIN_ROOT/../.." && pwd)"

node - "$PLUGIN_ROOT" "$REPO_ROOT" <<'NODE'
const fs = require("node:fs");
const path = require("node:path");

const [pluginRoot, repoRoot] = process.argv.slice(2);
const manifest = JSON.parse(
  fs.readFileSync(path.join(pluginRoot, ".codex-plugin/plugin.json"), "utf8"),
);
if (manifest.name !== "eazo-factory") throw new Error("wrong plugin name");
if (manifest.version !== "0.1.0") throw new Error("wrong plugin version");
if (manifest.skills !== "./skills/") throw new Error("wrong skills path");

const marketplace = JSON.parse(
  fs.readFileSync(path.join(repoRoot, ".agents/plugins/marketplace.json"), "utf8"),
);
if (marketplace.name !== "eazo-tools") throw new Error("wrong marketplace name");
const entry = marketplace.plugins.find((item) => item.name === "eazo-factory");
if (!entry) throw new Error("missing marketplace plugin entry");
if (entry.source.path !== "./plugins/eazo-factory") {
  throw new Error("wrong marketplace source path");
}
NODE

echo "manifest test passed"
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
bash plugins/eazo-factory/tests/test-manifest.sh
```

Expected: failure because the manifest and marketplace files do not exist.

- [ ] **Step 3: Add the minimal plugin manifest**

Create `plugins/eazo-factory/.codex-plugin/plugin.json`:

```json
{
  "name": "eazo-factory",
  "version": "0.1.0",
  "description": "Generate and review standardized Eazo apps with Codex.",
  "skills": "./skills/"
}
```

Create `.agents/plugins/marketplace.json`:

```json
{
  "name": "eazo-tools",
  "interface": {
    "displayName": "Eazo Tools"
  },
  "plugins": [
    {
      "name": "eazo-factory",
      "source": {
        "source": "local",
        "path": "./plugins/eazo-factory"
      },
      "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL"
      },
      "category": "Developer Tools"
    }
  ]
}
```

Create `plugins/eazo-factory/agents/openai.yaml`:

```yaml
interface:
  display_name: "Eazo Factory"
  short_description: "Generate a polished, reviewed Eazo app from one prompt."
  brand_color: "#2F5D50"
  default_prompt: "Use @eazo-factory to create one standardized Eazo app."

policy:
  allow_implicit_invocation: false
```

Create `plugins/eazo-factory/README.md` with these exact sections:

```markdown
# Eazo Factory

Generate one standardized Eazo app from a product prompt using the official Eazo Next.js template.

## Install locally

```bash
codex plugin marketplace add .
codex plugin add eazo-factory@eazo-tools
```

Start a new Codex thread after installation.

## Use

```text
@eazo-factory Create a Matisse-inspired breathing meditation app.
```

## Requirements

- Codex with `$imagegen`
- Git
- Bun
- Network access to `https://github.com/EazoAI/eazo-creator-nextjs-template.git`

## Safety

The plugin never pushes generated repositories or commits secrets.
```

- [ ] **Step 4: Run the manifest test**

Run:

```bash
bash plugins/eazo-factory/tests/test-manifest.sh
```

Expected: `manifest test passed`.

- [ ] **Step 5: Validate the marketplace through Codex**

Run:

```bash
codex plugin marketplace add . --json
codex plugin list
```

Expected: marketplace `eazo-tools` is added and `eazo-factory` appears as available.

- [ ] **Step 6: Commit**

```bash
git add .agents/plugins/marketplace.json plugins/eazo-factory
git commit -m "feat: scaffold eazo factory plugin"
```

### Task 2: Define stable artifact schemas and art-direction references

**Files:**
- Create: `plugins/eazo-factory/references/product-spec-schema.md`
- Create: `plugins/eazo-factory/references/design-system-schema.md`
- Create: `plugins/eazo-factory/references/interaction-map-schema.md`
- Create: `plugins/eazo-factory/references/factory-run-schema.md`
- Create: `plugins/eazo-factory/references/review-rubric.md`
- Create: `plugins/eazo-factory/references/eazo-template-policy.md`
- Create: `plugins/eazo-factory/references/art-directions/matisse-cut-paper.md`
- Create: `plugins/eazo-factory/references/art-directions/bauhaus-playful.md`
- Create: `plugins/eazo-factory/references/art-directions/quiet-editorial.md`

**Interfaces:**
- Consumes: design specification.
- Produces: exact JSON field contracts consumed by all five skills and shell verification.

- [ ] **Step 1: Create the product-spec contract**

Define `product-spec.json` with required keys:

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

The Markdown reference must state that every feature needs at least one acceptance condition and the app must have one primary loop.

- [ ] **Step 2: Create design and interaction contracts**

Define `design-tokens.json` with keys `schema_version`, `art_direction`, `palette`, `typography`, `spacing`, `radii`, `shadows`, `illustration`, `motion`, and `components`.

Define `interaction-map.json` entries with this exact shape:

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

State explicitly: if an image contains a button-like element that cannot be represented by one entry, remove it from the image.

- [ ] **Step 3: Create run-state and review contracts**

Define `factory-run.json` fields:

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

Define `review.json` with `verdict`, `core_functionality`, `bugs`, `visual_quality`, `control_behavior`, `control_necessity`, and `findings`.

Define `control-audit.json` entries with `control_id`, `selector_or_description`, `mapped_requirement`, `action`, `observed_result`, and `status`.

- [ ] **Step 4: Write the Eazo template precedence policy**

`eazo-template-policy.md` must include:

```text
1. Checked-out template AGENTS.md
2. Checked-out template implementation and package scripts
3. Checked-out template .env.example and deployment configuration
4. Plugin references
5. General framework conventions
```

It must require reading `AGENTS.md`, `package.json`, `.env.example`, `src/app/layout.tsx`, and only the capability examples selected in `product-spec.json`.

- [ ] **Step 5: Write the review rubric**

Use a 100-point rubric:

- Core functionality: 30
- Bugs/runtime correctness: 25
- Visual quality: 20
- Control behavior: 15
- Control necessity: 10

Passing requires:

- score at least 85;
- no blocking findings;
- every control audit entry passes;
- core functionality at least 25/30;
- bugs/runtime correctness at least 20/25.

- [ ] **Step 6: Add three bounded art directions**

Each art-direction file must specify palette tendencies, composition, typography, imagery, motion, forbidden clichés, and UI-control discipline. The Matisse file must emphasize original cut-paper composition rather than copying any existing artwork.

- [ ] **Step 7: Run placeholder and JSON-example checks**

Run:

```bash
! rg -n "TBD|TODO|FIXME|implement later|fill in" plugins/eazo-factory/references
rg -n '"schema_version": "1.0"' plugins/eazo-factory/references
```

Expected: first command succeeds with no matches; second finds all JSON artifact references.

- [ ] **Step 8: Commit**

```bash
git add plugins/eazo-factory/references
git commit -m "docs: define eazo factory artifact contracts"
```

### Task 3: Implement deterministic preflight and scaffolding

**Files:**
- Create: `plugins/eazo-factory/scripts/lib/common.sh`
- Create: `plugins/eazo-factory/scripts/preflight.sh`
- Create: `plugins/eazo-factory/scripts/scaffold-app.sh`
- Create: `plugins/eazo-factory/tests/test-scaffold.sh`

**Interfaces:**
- Consumes: output root, app slug, optional `EAZO_STARTER_PATH`.
- Produces: generated app directory and `factory-run.json` with starter source, branch, and commit.

- [ ] **Step 1: Write the failing scaffolding test**

Create a temporary fake starter Git repository with:

```json
{
  "name": "nextjs-template",
  "private": true,
  "packageManager": "bun@1.3.9",
  "scripts": {
    "cleanup:demo": "true"
  }
}
```

The test must run:

```bash
EAZO_STARTER_PATH="$FAKE_STARTER" \
  bash plugins/eazo-factory/scripts/scaffold-app.sh "$OUTPUT_ROOT" "test-app"
```

Assertions:

```bash
test -f "$OUTPUT_ROOT/test-app/package.json"
test -f "$OUTPUT_ROOT/test-app/factory-run.json"
test -d "$OUTPUT_ROOT/test-app/.git"
test "$(git -C "$OUTPUT_ROOT/test-app" remote | wc -l | tr -d ' ')" = "0"
node -e '
const run = require(process.argv[1]);
if (!run.starter.commit) process.exit(1);
if (run.stage !== "scaffolded") process.exit(1);
' "$OUTPUT_ROOT/test-app/factory-run.json"
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
bash plugins/eazo-factory/tests/test-scaffold.sh
```

Expected: failure because `scaffold-app.sh` does not exist.

- [ ] **Step 3: Implement common shell helpers**

`common.sh` must expose:

```bash
die() { printf 'error: %s\n' "$*" >&2; exit 1; }
require_command() { command -v "$1" >/dev/null 2>&1 || die "missing command: $1"; }
is_valid_slug() { [[ "$1" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; }
utc_now() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }
```

- [ ] **Step 4: Implement preflight**

`preflight.sh` must:

- require `git`, `bun`, `node`, and `codex`;
- verify the output root can be created and written;
- validate the slug;
- use `EAZO_STARTER_PATH` when set and containing `.git`, `AGENTS.md`, and `package.json`;
- otherwise verify access with `git ls-remote` to the canonical URL;
- print a JSON object containing `ok`, `starter_source`, and `output_root`.

- [ ] **Step 5: Implement scaffolding**

`scaffold-app.sh OUTPUT_ROOT SLUG` must:

1. call `preflight.sh`;
2. reject an existing non-empty destination;
3. clone the local override with `git clone --no-local` or clone canonical `main --depth 1`;
4. capture `git rev-parse HEAD`;
5. remove `.git`;
6. run `git init`;
7. rename `package.json.name` to the slug using Node;
8. run `bun run cleanup:demo`;
9. create `design/` and `review/`;
10. write `factory-run.json` using the schema from Task 2;
11. leave no Git remote configured.

- [ ] **Step 6: Run scaffolding tests**

Run:

```bash
bash plugins/eazo-factory/tests/test-scaffold.sh
```

Expected: all assertions pass.

- [ ] **Step 7: Commit**

```bash
git add plugins/eazo-factory/scripts plugins/eazo-factory/tests/test-scaffold.sh
git commit -m "feat: add deterministic eazo app scaffolding"
```

### Task 4: Implement verification and preview scripts

**Files:**
- Create: `plugins/eazo-factory/scripts/verify-app.sh`
- Create: `plugins/eazo-factory/scripts/start-preview.sh`
- Create: `plugins/eazo-factory/tests/fixtures/valid-app/`
- Create: `plugins/eazo-factory/tests/fixtures/dead-button-app/`
- Create: `plugins/eazo-factory/tests/fixtures/client-ai-import-app/`
- Create: `plugins/eazo-factory/tests/test-verify.sh`

**Interfaces:**
- Consumes: generated app path.
- Produces: `review/verification.json`; preview URL on stdout.

- [ ] **Step 1: Write failing verifier fixture tests**

`test-verify.sh` must assert:

```bash
bash plugins/eazo-factory/scripts/verify-app.sh tests/fixtures/valid-app
! bash plugins/eazo-factory/scripts/verify-app.sh tests/fixtures/dead-button-app
! bash plugins/eazo-factory/scripts/verify-app.sh tests/fixtures/client-ai-import-app
```

The dead-button fixture contains `<button>Coming soon</button>` with no handler, form semantics, or navigation wrapper.

The client-AI fixture contains:

```tsx
"use client";
import { ai } from "@eazo/sdk";
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
bash plugins/eazo-factory/tests/test-verify.sh
```

Expected: failure because `verify-app.sh` does not exist.

- [ ] **Step 3: Implement static verification**

`verify-app.sh APP_DIR` must check:

- required files: `package.json`, `AGENTS.md`, `product-spec.json`, `factory-run.json`, `design/ui-reference.png`, `design/design-tokens.json`, `design/interaction-map.json`;
- `packageManager` starts with `bun@`;
- `@eazo/sdk` remains a dependency;
- `src/i18n/locales/en-US.json` and `zh-CN.json` exist;
- no `"use client"` file imports `{ ai }` or `ai` from `@eazo/sdk`;
- no `href="#"`, `onClick={() => {}}`, `onClick={undefined}`, `Coming soon` button, or empty button exists;
- no unchanged `todo-list` component directory remains;
- every interaction-map control ID appears somewhere under `src/`;
- `factory-run.json.starter.commit` is non-empty.

The script then runs:

```bash
bun run lint
bun run build
```

It writes command exit codes and findings to `review/verification.json` and exits nonzero when any blocking check fails.

- [ ] **Step 4: Implement preview startup**

`start-preview.sh APP_DIR [START_PORT]` must:

- default to port `3000`;
- find the first free port through `3099` using Node's `net` module;
- run `bun dev --port "$PORT"`;
- poll `http://127.0.0.1:$PORT` for up to 60 seconds;
- print only `http://localhost:$PORT` to stdout after health succeeds;
- write logs to `.eazo-factory-preview.log`;
- write PID to `.eazo-factory-preview.pid`.

- [ ] **Step 5: Run verifier tests**

Run:

```bash
bash plugins/eazo-factory/tests/test-verify.sh
```

Expected: valid fixture passes; dead-button and client-AI fixtures fail with named blocking findings.

- [ ] **Step 6: Run shell syntax checks**

Run:

```bash
bash -n plugins/eazo-factory/scripts/lib/common.sh
bash -n plugins/eazo-factory/scripts/preflight.sh
bash -n plugins/eazo-factory/scripts/scaffold-app.sh
bash -n plugins/eazo-factory/scripts/verify-app.sh
bash -n plugins/eazo-factory/scripts/start-preview.sh
```

Expected: all commands exit 0.

- [ ] **Step 7: Commit**

```bash
git add plugins/eazo-factory/scripts plugins/eazo-factory/tests
git commit -m "feat: verify generated apps and start previews"
```

### Task 5: Author the idea and design skills

**Files:**
- Create: `plugins/eazo-factory/skills/eazo-idea/SKILL.md`
- Create: `plugins/eazo-factory/skills/eazo-design/SKILL.md`

**Interfaces:**
- Consumes: user request and Task 2 references.
- Produces: `product-spec.json`, `design/ui-reference.png`, `design/image-prompt.md`, `design/design-tokens.json`, `design/interaction-map.json`.

- [ ] **Step 1: Write the idea skill**

Front matter:

```yaml
---
name: eazo-idea
description: Turn a user request, category, audience, or mood into one small buildable Eazo app specification. Use for Eazo app ideation and product scoping; do not write application code.
---
```

Required instructions:

- read `../../references/product-spec-schema.md`;
- create one small primary loop;
- limit features to three through five;
- select only necessary Eazo capabilities;
- reject platform-sized scope;
- write valid JSON to the target app's `product-spec.json`;
- validate every feature has acceptance criteria;
- include explicit exclusions.

- [ ] **Step 2: Write the design skill**

Front matter:

```yaml
---
name: eazo-design
description: Create a functional mobile UI reference and design system for an Eazo app using Codex $imagegen. Use after product-spec.json exists; do not implement code.
---
```

Required sequence:

1. read product spec and design/interaction references;
2. choose one art-direction reference;
3. enumerate required controls before image generation;
4. write `design/interaction-map.json`;
5. write `design/image-prompt.md`;
6. explicitly invoke `$imagegen`;
7. require a single polished mobile frame with no decorative or unmapped controls;
8. inspect the generated image and compare every button-like element to the interaction map;
9. edit/regenerate once when an unmapped control appears;
10. write `design/design-tokens.json`.

The image prompt must contain:

```text
Every visible button, tab, link, toggle, menu item, input affordance, or floating action must correspond to the supplied interaction inventory and have a real implemented purpose. Do not add decorative buttons, speculative navigation, fake controls, disabled placeholders, or “coming soon” actions. Use static artwork or text when no interaction exists.
```

- [ ] **Step 3: Validate skill metadata and forbidden placeholders**

Run:

```bash
rg -n "^name: eazo-(idea|design)$" plugins/eazo-factory/skills/*/SKILL.md
! rg -n "TBD|TODO|FIXME|implement later" plugins/eazo-factory/skills
```

Expected: both names found and no placeholder matches.

- [ ] **Step 4: Commit**

```bash
git add plugins/eazo-factory/skills/eazo-idea plugins/eazo-factory/skills/eazo-design
git commit -m "feat: add eazo ideation and design skills"
```

### Task 6: Author the build and mandatory review skills

**Files:**
- Create: `plugins/eazo-factory/skills/eazo-build/SKILL.md`
- Create: `plugins/eazo-factory/skills/eazo-review/SKILL.md`

**Interfaces:**
- Consumes: generated artifacts and scripts from Tasks 2–5.
- Produces: working app source, `review/review.json`, `review/control-audit.json`.

- [ ] **Step 1: Write the build skill**

Front matter:

```yaml
---
name: eazo-build
description: Implement one Eazo app from product, design, and interaction artifacts using the official Eazo Next.js template. Use only after scaffolding and design are complete.
---
```

Required instructions:

- read the generated app's `AGENTS.md`, `package.json`, `.env.example`, and selected capability examples before edits;
- preserve the template architecture and official constraints;
- implement only product-spec features;
- implement every interaction-map control;
- do not add any control outside the map except required Eazo SDK controls;
- use SDK-owned login;
- keep AI server-side and auth-protected;
- provide `en-US` and `zh-CN`;
- use safe-area CSS and `100dvh`;
- report meaningful mutations through memory only when selected;
- run `verify-app.sh`;
- repair deterministic failures before handoff.

- [ ] **Step 2: Write the review skill**

Front matter:

```yaml
---
name: eazo-review
description: Independently review a generated Eazo app for core functionality, bugs, frontend quality, and every interactive control. Mandatory before an Eazo Factory app can pass; do not implement product features during the first review pass.
---
```

Required review sequence:

1. work from a fresh read-only context when available;
2. read `product-spec.json`, design artifacts, interaction map, rubric, and verification output;
3. start or connect to preview;
4. use browser tooling at a mobile viewport;
5. execute the primary loop;
6. discover every interactive element in the rendered UI;
7. activate each element and record result;
8. compare discovered controls against `interaction-map.json`;
9. inspect console and network failures;
10. review visual hierarchy, spacing, typography, contrast, responsiveness, safe areas, motion, empty/loading/error states, and art-direction fidelity;
11. write `review/control-audit.json`;
12. write scored `review/review.json`;
13. fail when any control is dead, decorative, unnecessary, or unmapped.

The reviewer must never approve based on source inspection alone when browser tooling is available.

- [ ] **Step 3: Validate hard-gate language**

Run:

```bash
rg -n "mandatory|every interactive|cannot pass|blocking" \
  plugins/eazo-factory/skills/eazo-review/SKILL.md \
  plugins/eazo-factory/references/review-rubric.md
```

Expected: all four concepts are present.

- [ ] **Step 4: Commit**

```bash
git add plugins/eazo-factory/skills/eazo-build plugins/eazo-factory/skills/eazo-review
git commit -m "feat: add eazo build and mandatory review skills"
```

### Task 7: Author the orchestrator skill

**Files:**
- Create: `plugins/eazo-factory/skills/eazo-factory/SKILL.md`

**Interfaces:**
- Consumes: all worker skills, references, and scripts.
- Produces: one complete app workflow and final result summary.

- [ ] **Step 1: Write the orchestrator front matter**

```yaml
---
name: eazo-factory
description: Create one complete Eazo app from an idea or product request, including product scoping, $imagegen UI design, official-template implementation, mandatory independent review, fixes, and a local preview URL. Use when the user asks to make or generate an Eazo app.
---
```

- [ ] **Step 2: Implement the exact stage machine**

The skill must define:

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

Rules:

- create one output directory outside the plugin source;
- update `factory-run.json` at every stage;
- stop on missing official starter access;
- retry image generation once;
- run review even when verification passes;
- permit at most two fix/review cycles;
- never call success with blocking findings or failed control audit;
- final response includes absolute app path, preview URL or restart command, starter commit, verification status, review score, and unresolved non-blocking findings.

- [ ] **Step 3: Add worker handoff contracts**

The orchestrator must explicitly invoke:

```text
$eazo-idea
$eazo-design
$eazo-build
$eazo-review
```

Each invocation must name its expected inputs and files it must produce before the next stage begins.

- [ ] **Step 4: Validate orchestration coverage**

Run:

```bash
for term in '$eazo-idea' '$eazo-design' '$eazo-build' '$eazo-review' \
  'factory-run.json' 'two' 'preview'; do
  rg -F "$term" plugins/eazo-factory/skills/eazo-factory/SKILL.md >/dev/null
done
```

Expected: exit 0.

- [ ] **Step 5: Commit**

```bash
git add plugins/eazo-factory/skills/eazo-factory
git commit -m "feat: orchestrate the complete eazo app workflow"
```

### Task 8: Install, invoke, and verify the plugin end to end

**Files:**
- Modify: `plugins/eazo-factory/README.md`
- Create: `docs/eazo-factory-validation.md`

**Interfaces:**
- Consumes: completed plugin.
- Produces: installation evidence and a documented manual validation protocol.

- [ ] **Step 1: Run all local tests**

Run:

```bash
bash plugins/eazo-factory/tests/test-manifest.sh
bash plugins/eazo-factory/tests/test-scaffold.sh
bash plugins/eazo-factory/tests/test-verify.sh
```

Expected: all tests pass.

- [ ] **Step 2: Install from the local marketplace**

Run:

```bash
codex plugin marketplace add . --json
codex plugin add eazo-factory@eazo-tools --json
codex plugin list
```

Expected: `eazo-factory` is installed and enabled.

- [ ] **Step 3: Verify Codex discovers the skills**

Start a new ephemeral Codex run in a temporary Git repository:

```bash
codex exec --ephemeral --sandbox read-only \
  "List the Eazo Factory plugin skills available to you and summarize when each triggers."
```

Expected: output names `eazo-factory`, `eazo-idea`, `eazo-design`, `eazo-build`, and `eazo-review`.

- [ ] **Step 4: Run a dry-run workflow audit**

Run:

```bash
codex exec --ephemeral --sandbox read-only \
  "Use @eazo-factory in audit-only mode. Do not write files. Explain the exact stages you would run for a Matisse-inspired breathing app, including the mandatory control audit and pass conditions."
```

Expected: includes official template, `$imagegen`, interaction map, mandatory independent review, every-control testing, two-cycle limit, and preview.

- [ ] **Step 5: Write manual full-generation validation**

`docs/eazo-factory-validation.md` must define three prompts:

```text
@eazo-factory Create a Matisse-inspired two-minute breathing meditation app.
@eazo-factory Create a quiet editorial daily reflection journal.
@eazo-factory Create a playful Bauhaus kitchen timer utility.
```

For each generated app, record:

- app path;
- template commit;
- product artifact presence;
- lint/build result;
- preview URL;
- review score;
- number of discovered controls;
- number of passed controls;
- unresolved findings.

- [ ] **Step 6: Update README with installation and validation**

Document GitHub marketplace installation:

```bash
codex plugin marketplace add EazoAI/eazo-factory
codex plugin add eazo-factory@eazo-tools
```

Mark the GitHub owner/repository as the intended publication location and keep local installation instructions for development.

- [ ] **Step 7: Run final repository checks**

Run:

```bash
git diff --check
! rg -n "TBD|TODO|FIXME|implement later|fill in" \
  plugins/eazo-factory docs/eazo-factory-validation.md
git status --short
```

Expected: no whitespace errors, no placeholders, and only intended files modified.

- [ ] **Step 8: Commit**

```bash
git add plugins/eazo-factory/README.md docs/eazo-factory-validation.md
git commit -m "docs: add eazo factory installation and validation"
```

## Final verification

Run:

```bash
bash plugins/eazo-factory/tests/test-manifest.sh
bash plugins/eazo-factory/tests/test-scaffold.sh
bash plugins/eazo-factory/tests/test-verify.sh
git log --oneline --decorate -10
git status --short --branch
```

Expected:

- all plugin tests pass;
- plugin installs from the local marketplace;
- all five skills are discoverable;
- worktree is clean;
- commit history shows one focused commit per task.
