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

The canonical starter is the official Eazo repository:

```text
https://github.com/EazoAI/eazo-creator-nextjs-template.git
```

The plugin uses its `main` branch by default. A local checkout may be supplied as an explicit development override. If neither the canonical repository nor the override can be accessed, the plugin may complete ideation and design, but it must stop before scaffolding and report the missing prerequisite clearly.

Every run records the exact starter commit SHA so generated apps remain reproducible and differences can be traced when the official template changes.

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
│   ├── eazo-template-policy.md
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

The image prompt must enforce functional UI discipline:

- do not invent decorative buttons, tabs, toggles, menu items, links, or floating actions;
- every visible interactive control must map to a feature, state transition, or navigation destination defined in `product-spec.json`;
- prefer static visual elements over button-like shapes when no action exists;
- label controls clearly enough that the builder and reviewer can infer their intended behavior;
- include essential states for the primary loop without crowding the screen with speculative actions.

The design worker writes an `interaction-map.json` beside the image. Each visible control receives a stable ID, label, screen, action, destination or state change, and acceptance condition. The builder must implement this map; the reviewer uses it as the control inventory.

### Worker: `eazo-build`

Copies the configured Eazo starter, runs `bun run cleanup:demo`, initializes a new Git repository when needed, and implements the app from the product specification and design outputs.

The build worker must inspect the checked-out template's current `AGENTS.md`, `package.json`, `.env.example`, and relevant example implementations before writing product code. It must not recreate the platform integration from memory when the template already demonstrates the supported pattern.

It must follow the Eazo platform boundaries, especially:

- Bun-first Next.js 16, React 19, TypeScript, and Tailwind CSS v4;
- titles sourced from environment variables;
- SDK-owned login UI;
- server-only Eazo AI calls behind authenticated API routes;
- `en-US` and `zh-CN` localization;
- Mobile WebView safe areas and `100dvh`;
- fire-and-forget memory reporting after meaningful mutations;
- no unnecessary database, AI, notification, or MCP capability.

### Official-template authority

The generated app is standardized against the checked-out official template rather than a frozen copy embedded in the plugin.

When guidance differs, use this precedence:

1. the current official template's `AGENTS.md`;
2. the current official template's implementation and package scripts;
3. the template's `.env.example` and deployment configuration;
4. the plugin's bundled Eazo references;
5. general framework conventions.

The plugin must not silently upgrade or replace the template's framework, SDK, package manager, auth architecture, transport, or localization choices. It may remove demo features through the provided cleanup command and then add only the capabilities required by the product specification.

At the time this design was validated, the official `main` branch resolved to commit `0067f106872c7f5372916e4fdbd7455eee006a38` dated June 16, 2026. This SHA is an observation, not a permanent pin; each generation records the SHA actually used.

### Worker: `eazo-review`

Reviews the generated app in a fresh, read-only Codex context where available. It consumes the specification, design image, design tokens, source code, and verification output.

The review worker is mandatory. The orchestrator must not declare an app complete or return a successful final preview without a completed review artifact.

It verifies five required areas:

1. **Core functionality** — the primary loop and every required product-spec feature can be completed from the UI.
2. **Bugs and runtime correctness** — no build error, runtime exception, broken state, failed request, data-loss path, or obvious edge-case failure remains.
3. **Frontend quality** — the implemented page is visually coherent, polished, readable, mobile-safe, responsive, and faithful to the approved art direction.
4. **Interactive-control behavior** — every visible button, link, tab, toggle, menu item, input affordance, and floating action can be activated and produces the intended result.
5. **Control necessity** — no control exists merely for decoration or future functionality. Every implemented control must appear in `interaction-map.json` or be a required platform control supplied by the Eazo SDK.

The reviewer must inspect the rendered app, not only source code. When browser automation is available, it clicks or activates every control in the interaction inventory and records the result. Static source inspection is a fallback, not sufficient evidence for a successful review.

It returns findings grouped by severity:

- blocking: build failure, security issue, broken core flow, Eazo rule violation, dead control, decorative button, missing mapped interaction, or runtime error;
- important: substantial UX, visual, accessibility, localization, or maintainability defect;
- polish: non-blocking refinement.

The reviewer produces `review/review.json` and `review/control-audit.json`. The control audit contains every discovered interactive element, its mapped requirement, test action, observed result, and pass/fail status.

The orchestrator allows at most two automated fix-and-review cycles in version one. Remaining blocking findings stop the workflow and are reported to the user. An app with any failed or unmapped control cannot pass.

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
│   ├── design-tokens.json
│   └── interaction-map.json
├── review/
│   ├── verification.json
│   ├── review.json
│   └── control-audit.json
└── <Eazo application files>
```

`factory-run.json` records:

- plugin version;
- current stage;
- stage timestamps;
- configured starter source;
- starter branch and exact commit SHA;
- generated artifact paths;
- verification commands and exit codes;
- preview URL when available;
- final status.

The plugin writes this file even though version one is interactive. The later CLI can adopt the same state format for resume and batch operation.

## 5. Workflow

1. Run preflight checks for Codex, Git, Bun, writable output directory, image generation availability, and access to the canonical Eazo starter or an explicit local override.
2. Resolve the product concept and write `product-spec.json`.
3. Pause for user approval only when the concept is materially ambiguous or requests sensitive/destructive behavior. Otherwise continue.
4. Generate the UI reference image, design tokens, and complete interaction map. Reject and regenerate a design that contains controls with no specified behavior.
5. Clone or copy the Eazo starter, record its source commit, and detach the generated app from the template repository history.
6. Read and preserve the template's `AGENTS.md`; append only generated-app-specific requirements and verification commands without weakening official constraints.
7. Implement the primary product loop and every control in `interaction-map.json`. Do not add speculative controls outside the map unless they are required Eazo platform controls.
8. Run deterministic verification.
9. Start the app and capture at least one mobile-sized screenshot when browser tooling is available.
10. Run the independent review, including a rendered visual review and full interaction-control audit.
11. Fix blocking and important findings, then verify again, for at most two cycles.
12. Start the final preview only when the core-function review passes and every discovered control passes the audit. Return the app path, preview URL, verification summary, and unresolved non-blocking findings.

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
- every item in `interaction-map.json` has a corresponding implementation reference;
- no obvious placeholder event handlers, empty links, `href="#"`, or controls with no action are present;
- `factory-run.json` records the official template URL and exact commit;
- the project retains the template's Bun package-manager declaration and required Eazo dependencies;
- the Eazo provider, user synchronization, localization shell, and transport glue have not been removed when the selected capabilities require them;
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

- Official starter unavailable: try the explicit local override when supplied; otherwise stop before scaffolding and report the canonical repository URL.
- Official template guidance conflicts with a bundled plugin reference: follow the checked-out template and flag the bundled reference as stale.
- Image generation failure: retry once with a simplified prompt; if it still fails, continue only with explicit user approval using written design tokens.
- Image contains an unmapped or decorative control: revise the interaction map only when the control is genuinely required; otherwise regenerate or edit the image to remove it.
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

It will not vendor a second authoritative copy of the Eazo Next.js starter. Scaffolding uses the official repository directly by default, while a local cache or checkout may be used for offline development. This prevents the plugin from drifting away from the platform template.

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
- the complete main flow works at a mobile viewport;
- the reviewer has exercised every discovered interactive control;
- every control has a real, necessary action and passes `control-audit.json`;
- no placeholder, decorative, disabled-without-explanation, or dead button remains;
- the frontend review passes the visual-quality rubric;
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
