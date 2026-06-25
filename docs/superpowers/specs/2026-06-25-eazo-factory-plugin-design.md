# Eazo Factory Plugin Design

## 1. Goal

Build an installable Codex plugin that turns one product prompt into one complete, independently runnable Eazo app.

The first version validates the creative and engineering workflow inside Codex before a separate CLI is built for batch execution, state management, concurrency, and port allocation.

Example invocation:

```text
@eazo-factory Create a Matisse-inspired breathing meditation app.
```

Expected result:

1. A structured product specification.
2. A generated mobile UI reference image using Codex `$imagegen`.
3. A new app copied from the official Eazo starter.
4. Product code that follows the Eazo platform guide.
5. Deterministic checks and an independent Codex review.
6. Fixes for blocking findings.
7. A running local preview URL.

## 2. Version-one scope

Version one creates one app per invocation. It does not batch-create apps, run jobs concurrently, publish apps to Eazo, deploy to Vercel, or manage a persistent global job queue.

The plugin may create a new Git repository for the generated app, but it must not push to a remote repository.

The user supplies either:

- a concrete app concept; or
- a category, audience, or mood from which the plugin develops one concept.

The official Eazo starter must be available as either a local directory or a Git URL. Until that source is configured, the plugin may complete ideation and design, but it must stop before scaffolding and report the missing prerequisite clearly.

## 3. Recommended architecture

The plugin uses one orchestrator skill and four focused worker skills.

```text
eazo-factory/
├── .codex-plugin/
│   └── plugin.json
├── skills/
│   ├── eazo-factory/
│   │   └── SKILL.md
│   ├── eazo-idea/
│   │   └── SKILL.md
│   ├── eazo-design/
│   │   └── SKILL.md
│   ├── eazo-build/
│   │   └── SKILL.md
│   └── eazo-review/
│       └── SKILL.md
├── references/
│   ├── eazo-agent-guide.md
│   ├── product-spec-schema.md
│   ├── design-system-schema.md
│   ├── review-rubric.md
│   └── art-directions/
├── scripts/
│   ├── preflight.sh
│   ├── scaffold-app.sh
│   ├── verify-app.sh
│   └── start-preview.sh
└── assets/
    └── README.md
```

### Orchestrator: `eazo-factory`

Owns stage ordering, inputs, output locations, stop conditions, and handoffs. It must not duplicate the detailed instructions owned by worker skills.

### Worker: `eazo-idea`

Transforms the user's request into a small, buildable product concept. It produces `product-spec.json` containing:

- name and slug;
- target user and core problem;
- one primary loop;
- three to five features;
- screens and states;
- storage, authentication, AI, memory, and notification needs;
- Chinese and English copy direction;
- explicit exclusions.

The idea must fit a small app rather than grow into a platform.

### Worker: `eazo-design`

Selects an art direction, writes an image prompt, invokes `$imagegen`, and saves one primary mobile UI reference image for version one.

It also produces `design-tokens.json` containing:

- palette;
- typography;
- spacing;
- radii;
- shadows;
- illustration treatment;
- motion principles;
- component-specific guidance.

Named artists are treated as directional references, not as instructions to copy a specific existing work. The result should combine broad traits, product requirements, and original composition.

### Worker: `eazo-build`

Copies the configured Eazo starter, runs `bun run cleanup:demo`, initializes a new Git repository when needed, and implements the app from the product specification and design outputs.

It must follow the Eazo platform boundaries, especially:

- Bun-first Next.js 16, React 19, TypeScript, and Tailwind CSS v4;
- titles sourced from environment variables;
- SDK-owned login UI;
- server-only Eazo AI calls behind authenticated API routes;
- `en-US` and `zh-CN` localization;
- Mobile WebView safe areas and `100dvh`;
- fire-and-forget memory reporting after meaningful mutations;
- no unnecessary database, AI, notification, or MCP capability.

### Worker: `eazo-review`

Reviews the generated app in a fresh, read-only Codex context where available. It consumes the specification, design image, design tokens, source code, and verification output.

It returns findings grouped by severity:

- blocking: build failure, security issue, broken core flow, or Eazo rule violation;
- important: substantial UX, visual, accessibility, localization, or maintainability defect;
- polish: non-blocking refinement.

The orchestrator allows at most two automated fix-and-review cycles in version one. Remaining blocking findings stop the workflow and are reported to the user.

## 4. Data flow and generated artifacts

Each generated app is independent:

```text
<output-root>/<app-slug>/
├── .git/
├── AGENTS.md
├── product-spec.json
├── factory-run.json
├── design/
│   ├── ui-reference.png
│   ├── image-prompt.md
│   └── design-tokens.json
├── review/
│   ├── verification.json
│   └── review.json
└── <Eazo application files>
```

`factory-run.json` records:

- plugin version;
- current stage;
- stage timestamps;
- configured starter source;
- generated artifact paths;
- verification commands and exit codes;
- preview URL when available;
- final status.

The plugin writes this file even though version one is interactive. The later CLI can adopt the same state format for resume and batch operation.

## 5. Workflow

1. Run preflight checks for Codex, Git, Bun, writable output directory, image generation availability, and Eazo starter configuration.
2. Resolve the product concept and write `product-spec.json`.
3. Pause for user approval only when the concept is materially ambiguous or requests sensitive/destructive behavior. Otherwise continue.
4. Generate the UI reference image and design tokens.
5. Scaffold a new app from the Eazo starter.
6. Add an app-local `AGENTS.md` containing the relevant Eazo constraints and verification commands.
7. Implement the primary product loop.
8. Run deterministic verification.
9. Start the app and capture at least one mobile-sized screenshot when browser tooling is available.
10. Run the independent review.
11. Fix blocking and important findings, then verify again, for at most two cycles.
12. Start the final preview and return the app path, preview URL, verification summary, and unresolved findings.

## 6. Deterministic verification

The verification script runs:

```bash
bun run lint
bun run build
```

It also checks:

- no client component imports Eazo `ai`;
- AI routes use `requireAuth`;
- user-facing app title is not hardcoded in the root layout;
- both localization files exist;
- no unchanged todo demo artifacts remain;
- generated app contains `product-spec.json` and design artifacts;
- expected environment variables are documented without committing secrets.

Where practical, it also performs a local HTTP health check after starting the preview.

## 7. Preview behavior

Version one may use port `3000` when available and otherwise select the next free port in a bounded range. The preview process remains attached to the current Codex session unless the runtime provides a safe managed background process.

The final response must include an explicit URL such as:

```text
http://localhost:3001
```

If the preview cannot remain running, the plugin returns the exact command needed to restart it.

## 8. Error handling

- Missing Eazo starter: stop before scaffolding and explain how to configure it.
- Image generation failure: retry once with a simplified prompt; if it still fails, continue only with explicit user approval using written design tokens.
- Dependency installation failure: preserve logs and stop without deleting the generated directory.
- Build or lint failure: send the failure to the build skill for repair, bounded by the two-cycle limit.
- Port conflict: choose another free port.
- Review disagreement: deterministic build and security failures outrank aesthetic reviewer opinions.
- Interrupted run: preserve `factory-run.json` and all generated files.

## 9. Distribution

The source repository will include:

- the plugin;
- a repository-scoped Codex marketplace manifest;
- installation and local-development instructions;
- example prompts;
- test fixtures.

Initial team installation:

```bash
codex plugin marketplace add <owner>/<repo>
codex plugin add eazo-factory@<marketplace-name>
```

The plugin is the first deliverable. A later npm-distributed CLI will install or verify the plugin, invoke Codex programmatically, batch jobs, allocate ports, and resume interrupted runs.

## 10. Testing and acceptance

The plugin is accepted when it can generate three distinct apps from the configured Eazo starter:

1. a meditation app;
2. a journal app;
3. a small non-wellness utility.

For each fixture:

- all required artifacts exist;
- the app passes lint and build;
- no blocking Eazo rule violation remains;
- the main flow works at a mobile viewport;
- Chinese and English UI are present;
- the result is visually distinguishable from the starter and from the other fixtures;
- a preview URL or reproducible preview command is returned.

## 11. Deferred CLI responsibilities

The future CLI will own:

- `make`, `batch`, `resume`, `doctor`, `preview`, and `update` commands;
- multiple Codex thread orchestration;
- concurrency limits and job queues;
- durable process and port management;
- npm distribution;
- plugin installation and version compatibility checks;
- optional direct image API support for high-volume generation.

These responsibilities must not be prematurely embedded into the first plugin.
