---
name: eazo-review
description: Independently review a generated Eazo app for core functionality, bugs, frontend quality, and every interactive control. Mandatory before an Eazo Factory app can pass; do not implement product features during the first review pass.
---

# Eazo Review

Act as an independent release gate. The Builder cannot review or approve its own work.

## Independence

Run in a fresh reviewer agent or fresh Codex review thread with no Builder reasoning. Use read-only access to application source. The reviewer may return structured review payloads to the orchestrator; the orchestrator writes them to `review/`. Never alter product source during the first review pass.

If a fresh reviewer context cannot be created, stop. The app cannot pass through self-review.

## Required inputs

Read:

- `product-spec.json`
- `design/ui-reference.png`
- `design/design-tokens.json`
- `design/interaction-map.json`
- `review/verification.json`
- `../../references/review-rubric.md`
- the selected art-direction reference

## Mandatory review procedure

1. Start or connect to the local preview.
2. Use browser tooling at a mobile viewport, beginning at 390 × 844.
3. Complete the entire primary loop and every product acceptance condition.
4. Inspect runtime console and failed network requests throughout the flow.
5. Visit every reachable state: initial, loading, empty, error where safely reproducible, active, and completion.
6. Discover every interactive element rendered in every visited state:
   - buttons;
   - links;
   - tabs;
   - toggles;
   - menus;
   - inputs and input affordances;
   - floating or icon actions;
   - elements styled or announced as actionable.
7. Activate every discovered interactive element.
8. Record its screen/state, label or selector, mapped control ID, action, and observed result.
9. Compare both directions:
   - every interaction-map control must have passing audit evidence;
   - every product-owned discovered interactive element must map to exactly one interaction-map control;
   - every Eazo SDK-owned discovered control must be recorded with `owner: "eazo_sdk"`, `mapped_control_id: null`, and a non-empty official SDK reference.
10. Fail any dead, decorative, redundant, placeholder, unnecessary, disabled-without-explanation, or unmapped control.
11. Compare the rendered result with the generated UI reference and design tokens. Review:
   - composition and hierarchy;
   - spacing and alignment;
   - typography and contrast;
   - responsive behavior and safe areas;
   - motion quality, tap feedback, state transitions, and reduced-motion behavior;
   - localization fit;
   - English / Chinese language switching;
   - matching BGM behavior when required, including user-controlled start/stop and no autoplay surprise;
   - art-direction fidelity;
   - loading, empty, error, and completion polish.
12. Score all five rubric categories and calculate the exact total.

Source inspection alone is never sufficient when browser tooling is available.

## Output

Return complete JSON payloads matching:

- `review/review.json`
- `review/control-audit.json`

The orchestrator writes the payloads without changing their verdict. Include evidence for every blocking or important finding.

The app cannot pass unless:

- total score is at least 85;
- core functionality is at least 25/30;
- bugs/runtime correctness is at least 20/25;
- no blocking or important finding exists;
- coverage status is `pass`;
- every interactive control audit entry passes.

When the verdict fails, return a bounded fix list ordered by severity. Do not fix code in the reviewer context.
