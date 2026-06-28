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
   - If the link hits a login wall, anti-bot page, verification wall, or empty/blocked response, do not guess. Ask the user to log in to Xiaohongshu in their local browser, then retry the link. Also mention screenshots as a fallback.
   - In English contexts, phrase this as: ask the user to log in to Xiaohongshu in their local browser, then retry the link, or provide screenshots as a fallback.
   - If the link is still blocked and no screenshot/text gives enough detail, stop with one sentence asking for screenshots.
   - Do not claim the source was extracted unless you actually saw usable post content, screenshots, or pasted text.
4. Capture reference UI images. When the source is a Xiaohongshu link, a product/intro screenshot, or any visual material that shows UI and interaction, you MUST save the referenced UI as image files so the design stage can feed them into `$imagegen`:
   - Save every user-provided screenshot or image to `<app-directory>/source/reference-ui/` as `.png` or `.jpg`.
   - When you can load the Xiaohongshu note through a tool or browser, capture or download its post images (UI cards, carousel frames, layout) into the same directory.
   - Use stable, ordered filenames such as `ref-01.png`, `ref-02.png`.
   - Record every saved file in `reference_ui_images` with a short description and its `origin`.
   - Strip or ignore watermarks and creator identity, but keep the referenced UI layout, components, and visual structure intact.
   - Skip this capture ONLY when the user explicitly says not to use a reference image, or specifies a different UI/style to build instead. When skipped, leave `reference_ui_images` empty and record the reason in `reference_ui_note`.
5. Produce one concise `source/source-brief.json`:
   - product intent;
   - target user;
   - primary loop;
   - feature candidates with source evidence;
   - UI observations: layout, components, visual style, imagery, copy tone, motion/audio clues;
   - `reference_ui_images` captured in step 4 (and `reference_ui_note` when capture was skipped);
   - must-recreate items;
   - avoid-copying items.
6. Convert source material into an original Eazo app direction. Preserve idea and UI logic, not watermarks, creator names, private data, or long verbatim captions.
7. Parse the written JSON and validate:
   - `schema_version` is `"1.0"`;
   - `product_intent`, `target_user`, and `primary_loop` are non-empty;
   - at least one feature candidate exists;
   - for a visual source, `reference_ui_images` is non-empty unless the user opted out (then `reference_ui_note` explains why);
   - `confidence` is `high`, `medium`, or `low`.

## Login wall response

When Xiaohongshu blocks access and no usable screenshots/text are available, return no `source/source-brief.json`. Stop with this one-sentence shape in the user's language:

```text
这个小红书链接现在被登录/验证挡住了；请先在本地浏览器登录自己的小红书账号后重新发送同一个链接，或者直接补充帖子截图，我再继续复刻。
```

For English:

```text
This Xiaohongshu link is behind a login/verification wall; please log in to Xiaohongshu in your local browser and send the same link again, or upload screenshots as a fallback.
```

## Output

Return the absolute `source/source-brief.json` path, source type, confidence, the number of captured reference UI images (or the opt-out reason), and one-line product intent.
