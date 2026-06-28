---
name: eazo-source
description: Use when an Eazo app request comes from source material such as Xiaohongshu links, screenshots, image sets, pasted social posts, or “make this into an app” references.
---

# Eazo Source

Turn source material into a compact app brief. Do not scaffold, design, or write product code.

## Inputs

- User request containing one or more URLs, screenshots, images, or pasted post text.
- Target app directory where `source/source-brief.json` will be written.

## Workflow

1. Read `../../references/source-brief-schema.md` completely.
2. Detect source type:
   - `xiaohongshu_url` for `xiaohongshu.com`, `xhslink.com`, `xhs.cn`, or 小红书 links;
   - `screenshots` for attached images;
   - `mixed` when both links and screenshots/text are present.
3. Extract source facts:
   - If a Xiaohongshu tool is available and authenticated, use it to fetch the note detail when feed id/token can be derived.
   - Otherwise use browser/web access when available.
   - Always inspect user-provided screenshots/images directly when present.
   - If the link is blocked and no screenshot/text gives enough detail, stop with one sentence asking for screenshots.
4. Produce one concise `source/source-brief.json`:
   - product intent;
   - target user;
   - primary loop;
   - feature candidates with source evidence;
   - UI observations: layout, components, visual style, imagery, copy tone, motion/audio clues;
   - must-recreate items;
   - avoid-copying items.
5. Convert source material into an original Eazo app direction. Preserve idea and UI logic, not watermarks, creator names, private data, or long verbatim captions.
6. Parse the written JSON and validate:
   - `schema_version` is `"1.0"`;
   - `product_intent`, `target_user`, and `primary_loop` are non-empty;
   - at least one feature candidate exists;
   - `confidence` is `high`, `medium`, or `low`.

## Output

Return the absolute `source/source-brief.json` path, source type, confidence, and one-line product intent.
