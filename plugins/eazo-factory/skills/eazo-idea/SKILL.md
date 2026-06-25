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
   - avoid feeds, marketplaces, social networks, admin platforms, and speculative systems;
   - reject or reduce platform-sized scope before writing the artifact.
4. Select only capabilities required by the primary loop. Default every Eazo capability to `false`; turn one on only when its absence would prevent a required feature.
5. Define screens and states needed to complete the loop. Do not add screens for hypothetical future features.
6. Give every feature:
   - a stable kebab-case `id`;
   - a concrete name;
   - at least one observable acceptance condition.
7. Include `en-US` and `zh-CN` copy direction and explicit exclusions.
8. Write valid JSON to `<app-directory>/product-spec.json` using the exact schema.
9. Parse the written file and validate:
   - exactly one non-empty primary loop;
   - three to five features;
   - every feature has acceptance criteria;
   - screen and feature IDs are unique;
   - exclusions are non-empty;
   - no implementation code was created.

## Output

Return the absolute `product-spec.json` path and a concise statement of the primary loop and selected capabilities.

Stop with a clear error when the target directory is missing or the request cannot be reduced to one small app.
