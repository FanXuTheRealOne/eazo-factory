---
name: eazo-idea
description: Turn a user request, category, audience, or mood into one small buildable Eazo app specification. Use for Eazo app ideation and product scoping; do not write application code.
---

# Eazo Idea

Produce one bounded product contract for the Eazo Factory workflow.

## Inputs

- User request, category, audience, or mood.
- Target app directory where `product-spec.json` will be written.

## Workflow

1. Read `../../references/product-spec-schema.md` completely.
2. Identify one target user, one concrete problem, and one primary loop.
3. Keep the idea small enough for one focused mobile app:
   - define three to five features;
   - always include `language-switching` as one feature;
   - include `ambient-bgm` as one feature for every non-functional app;
   - avoid feeds, marketplaces, social networks, admin platforms, and speculative systems;
   - reject or reduce platform-sized scope before writing the artifact.
4. Classify `app_kind`:
   - `functional`: utility-first calculators, trackers, converters, checklists, CRUD tools, or tools where sound would distract from task completion;
   - `experiential`: meditation, journaling, ritual, wellness, focus, mood, creative, memory, or reflection apps.
5. Set `audio.bgm_required` to `true` for every `experiential` app and `false` for `functional` apps unless the user explicitly requests music.
6. Select only capabilities required by the primary loop. Default every Eazo capability to `false`; turn one on only when its absence would prevent a required feature.
7. Define screens and states needed to complete the loop. Do not add screens for hypothetical future features.
8. Give every feature:
   - a stable kebab-case `id`;
   - a concrete name;
   - at least one observable acceptance condition.
9. Include `locales: ["en-US", "zh-CN"]`, copy direction for both languages, and explicit exclusions.
10. Write valid JSON to `<app-directory>/product-spec.json` using the exact schema.
11. Parse the written file and validate:
   - exactly one non-empty primary loop;
   - three to five features;
   - one feature has `id: "language-switching"`;
   - every non-functional app has `audio.bgm_required: true` and a feature with `id: "ambient-bgm"`;
   - every feature has acceptance criteria;
   - screen and feature IDs are unique;
   - exclusions are non-empty;
   - no implementation code was created.

## Output

Return the absolute `product-spec.json` path and a concise statement of the primary loop and selected capabilities.

Stop with a clear error when the target directory is missing or the request cannot be reduced to one small app.
