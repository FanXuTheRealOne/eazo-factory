---
name: eazo-build
description: Implement one Eazo app from product, design, and interaction artifacts using the official Eazo Next.js template. Use only after scaffolding and design are complete.
---

# Eazo Build

Implement the approved product and interaction contracts without inventing product scope.

## Required inputs

Confirm these files exist before editing source:

- `AGENTS.md`
- `package.json`
- `.env.example`
- `product-spec.json`
- `factory-run.json`
- `design/ui-reference.png`
- `design/design-tokens.json`
- `design/interaction-map.json`

Read `../../references/eazo-template-policy.md` and follow its authority order.

## Template study

Before product edits, read the generated app's current:

- `AGENTS.md`
- `package.json`
- `.env.example`
- `src/app/layout.tsx`

Then read only the official template examples for capabilities enabled in `product-spec.json`. Reuse the demonstrated Eazo pattern; do not reconstruct platform integration from memory.

## Implementation rules

1. Implement only features and states in `product-spec.json`.
2. Implement every control in `design/interaction-map.json`.
3. Put each product control ID directly on its rendered interactive element as a literal `data-control-id="<control-id>"` attribute. Do not satisfy the verifier with comments, constants, wrappers, or non-interactive elements.
4. Do not add buttons, links, tabs, toggles, menus, floating actions, or button-like decorations outside the interaction map, except controls rendered and owned by the Eazo SDK.
5. When no action exists, use text or artwork that cannot be mistaken for a control.
6. Preserve the official template architecture:
   - Bun, Next.js App Router, React, TypeScript, and Tailwind;
   - environment-driven app title and description;
   - `EazoProvider`, localization shell, and required user synchronization;
   - SDK-owned login UI.
7. Keep Eazo AI server-side:
   - call it only from API routes;
   - protect the route with `requireAuth`;
   - have client components call the route over HTTP.
8. Provide all product copy in both `en-US` and `zh-CN`.
9. Use `100dvh` and safe-area insets for full-height mobile layouts.
10. Report meaningful mutations through `memory.reportAction(...).catch(() => {})` only when memory is enabled.
11. Add database, notifications, AI, storage, or MCP code only when its capability is enabled.
12. Implement visible loading, empty, error, active, and completion states required by the product flow.

## Verification

Run:

```bash
bash <plugin-root>/scripts/verify-app.sh <app-directory>
```

Repair every deterministic blocking finding before handoff. Do not weaken the verifier, interaction map, or product acceptance criteria to make an implementation pass.

Update `factory-run.json` with implementation and verification artifact records. Return:

- absolute app path;
- files changed;
- verification result;
- any product acceptance condition that remains unimplemented.

Do not declare the app complete. The independent `$eazo-review` gate is mandatory.
