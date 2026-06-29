---
name: eazo-design
description: Create a functional mobile UI reference and design system for an Eazo app using Codex $imagegen. Use after product-spec.json exists; do not implement code.
---

# Eazo Design

Turn the approved product contract into a functional visual contract before application code is written.

## Required references

Read these files completely:

- `<app-directory>/product-spec.json`
- `<app-directory>/source/source-brief.json` when present, including any `reference_ui_images` saved under `<app-directory>/source/reference-ui/`
- `../../references/design-system-schema.md`
- `../../references/interaction-map-schema.md`
- `../../references/asset-library-schema.md`
- exactly one file under `../../references/art-directions/`

Choose the art direction that best serves the product. Use a user-requested direction when it is one of the supported references.

## Workflow

1. Enumerate every required control from the product features, screen states, and primary loop.
   - Include one persistent language switch control for `language-switching`.
   - Include one BGM toggle/control when `product-spec.json.audio.bgm_required` is `true`.
2. Remove any control that is decorative, redundant, speculative, or unsupported by an acceptance condition.
3. Write `<app-directory>/design/interaction-map.json` before generating an image.
   - Use stable control IDs.
   - Bind every control to a valid product feature, screen, state transition, and acceptance condition.
   - Do not leave unlabeled or future controls.
4. Write `<app-directory>/design/image-prompt.md`. Ask for one single UI reference board, not just a screenshot:
   - a polished 390 × 844 mobile frame showing the primary app state;
   - a compact asset-library grid in the same image with the exact mapped button/toggle styles, decorative parts, background material, texture fragments, icon style, state elements, motion notes, and BGM mood;
   - each asset specimen should feel generated from the same locked style, like a coherent mini asset library;
   - source-derived UI layout, component shapes, visual motifs, content hierarchy, and copy tone when `source/source-brief.json` exists;
   - no extra navigation or decorative controls outside the interaction inventory;
   - clear distinction between shipped screen controls and non-interactive asset specimens.
5. Include the product purpose, selected art direction, mobile viewport, state shown, interaction inventory, hierarchy, motion direction, BGM mood when required, source UI observations when present, and this exact paragraph:

   > Every visible button, tab, link, toggle, menu item, input affordance, or floating action must correspond to the supplied interaction inventory and have a real implemented purpose. Do not add decorative buttons, speculative navigation, fake controls, disabled placeholders, or “coming soon” actions. Use static artwork or text when no interaction exists.

   Also include this exact paragraph:

   > The asset-library grid is a design reference, not additional product scope. Component specimens must be labeled with their mapped control IDs or neutral material names. Do not invent extra product actions just to fill the board.

   When source material exists, also include this exact paragraph:

   > Use the source material as product and visual inspiration: preserve its app idea, hierarchy, important UI elements, mood, and reusable visual parts. Create an original Eazo interface; do not copy watermarks, creator names, private profile data, or long captions verbatim.

6. Explicitly invoke `$imagegen` with that prompt and save one polished mobile reference board to `<app-directory>/design/ui-reference.png`.
   - When `source/source-brief.json` lists `reference_ui_images`, resolve each `path` relative to `<app-directory>` and verify the file exists and is readable. If any listed reference image is missing or unreadable, stop design and report the missing absolute path; do not silently generate without references.
   - Before invoking `$imagegen`, inspect/load every resolved reference image with `view_image` so the built-in image tool can see it in the conversation context. Label each loaded image explicitly as `reference image, not edit target`.
   - Pass the loaded reference images to `$imagegen` as visual reference inputs so the generated board follows the referenced UI layout, components, and visual structure.
   - Skip passing the reference images ONLY when the user explicitly asked not to use a reference image, or specified a different UI/style to build instead (as recorded in `reference_ui_note`).
   - Still produce an original Eazo interface: follow the referenced UI structure but do not reproduce watermarks, creator identity, or private data.
7. Inspect the generated image rather than trusting the prompt:
   - inventory every visible button-like or actionable element;
   - compare it against `interaction-map.json`;
   - verify labels and destinations are understandable;
   - verify no visual decoration resembles an accidental control.
8. If any visible product control is missing, decorative, speculative, or unmapped, edit or regenerate the image once. Do not legitimize an accidental control by adding it to the map unless the product specification genuinely requires it.
9. Write `<app-directory>/design/design-tokens.json` using the exact schema and selected art-direction slug. Include:
   - `reference_board` details;
   - a product-specific `motion.signature`;
   - `audio` matching the product BGM requirement.
10. Write `<app-directory>/design/asset-library.json` using the exact schema. It should inventory the reusable pieces from the reference board: mapped control specimens, decorative motifs, background layers, state elements, icons, textures, motion motifs, and BGM mood notes.
11. Parse all JSON files and confirm every visible product control has a real mapped purpose.

## Output gate

Do not hand off to implementation unless all six artifacts exist:

- `product-spec.json`
- `design/ui-reference.png`
- `design/image-prompt.md`
- `design/design-tokens.json`
- `design/interaction-map.json`
- `design/asset-library.json`

Return their absolute paths and the final number of mapped controls. Do not write application code.
