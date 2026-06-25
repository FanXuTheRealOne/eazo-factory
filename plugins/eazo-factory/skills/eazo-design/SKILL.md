---
name: eazo-design
description: Create a functional mobile UI reference and design system for an Eazo app using Codex $imagegen. Use after product-spec.json exists; do not implement code.
---

# Eazo Design

Turn the approved product contract into a functional visual contract before application code is written.

## Required references

Read these files completely:

- `<app-directory>/product-spec.json`
- `../../references/design-system-schema.md`
- `../../references/interaction-map-schema.md`
- exactly one file under `../../references/art-directions/`

Choose the art direction that best serves the product. Use a user-requested direction when it is one of the supported references.

## Workflow

1. Enumerate every required control from the product features, screen states, and primary loop.
2. Remove any control that is decorative, redundant, speculative, or unsupported by an acceptance condition.
3. Write `<app-directory>/design/interaction-map.json` before generating an image.
   - Use stable control IDs.
   - Bind every control to a valid product feature, screen, state transition, and acceptance condition.
   - Do not leave unlabeled or future controls.
4. Write `<app-directory>/design/image-prompt.md`. Include the product purpose, selected art direction, mobile viewport, state shown, interaction inventory, hierarchy, and this exact paragraph:

   > Every visible button, tab, link, toggle, menu item, input affordance, or floating action must correspond to the supplied interaction inventory and have a real implemented purpose. Do not add decorative buttons, speculative navigation, fake controls, disabled placeholders, or “coming soon” actions. Use static artwork or text when no interaction exists.

5. Explicitly invoke `$imagegen` with that prompt and save one polished mobile frame to `<app-directory>/design/ui-reference.png`.
6. Inspect the generated image rather than trusting the prompt:
   - inventory every visible button-like or actionable element;
   - compare it against `interaction-map.json`;
   - verify labels and destinations are understandable;
   - verify no visual decoration resembles an accidental control.
7. If any visible control is missing, decorative, speculative, or unmapped, edit or regenerate the image once. Do not legitimize an accidental control by adding it to the map unless the product specification genuinely requires it.
8. Write `<app-directory>/design/design-tokens.json` using the exact schema and selected art-direction slug.
9. Parse both JSON files and confirm every visible control has a real mapped purpose.

## Output gate

Do not hand off to implementation unless all five artifacts exist:

- `product-spec.json`
- `design/ui-reference.png`
- `design/image-prompt.md`
- `design/design-tokens.json`
- `design/interaction-map.json`

Return their absolute paths and the final number of mapped controls. Do not write application code.
