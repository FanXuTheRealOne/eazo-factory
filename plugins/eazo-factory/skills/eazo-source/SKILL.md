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
   - XHS MCP first: for Xiaohongshu URLs, first look for an available XHS MCP / Xiaohongshu MCP tool that can use an authenticated browser profile. If present, use it before generic browser or web access.
   - With XHS MCP, open the note URL through the MCP tool and extract note detail: title, author-visible public metadata, caption/body text, tags, image URLs/files, video cover or video metadata when available, and page screenshots.
   - Save raw MCP output to `<app-directory>/source/raw/xhs-note.json`. Record the tool name in `xhs_mcp_tool` and status in `xhs_mcp_status`.
   - Save downloaded post images, screenshots, video covers, and other usable media under `<app-directory>/source/media/`.
   - Copy or capture all UI-relevant post images/screenshots into `<app-directory>/source/reference-ui/` and list them in `reference_ui_images`.
   - If the XHS MCP exists but reports expired cookies, login wall, QR-login needed, CAPTCHA, anti-bot, or verification, set `xhs_mcp_status` to `login_required` or `blocked`, do not guess, and ask the user to log in through the MCP-controlled browser or upload screenshots.
   - If no XHS MCP tool is available, set `xhs_mcp_status` to `mcp_unavailable` and continue with generic browser/web access when available.
   - Otherwise use browser/web access when available.
   - Always inspect user-provided screenshots/images directly when present.
   - If the link hits a login wall, anti-bot page, verification wall, or empty/blocked response, do not guess. Ask the user to log in to Xiaohongshu in their local browser, then retry the link. Also mention screenshots as a fallback.
   - In English contexts, phrase this as: ask the user to log in to Xiaohongshu in their local browser, then retry the link, or provide screenshots as a fallback.
   - If the link is still blocked and no screenshot/text gives enough detail, stop with one sentence asking for screenshots.
   - Do not claim the source was extracted unless you actually saw usable post content, screenshots, or pasted text.
4. Build a video semantic packet for video-heavy Xiaohongshu posts. Do not infer the app from screenshots alone when the source is a video, app demo, tutorial, voiceover walkthrough, or screen recording.
   - Combine three evidence lanes before writing product intent: post copy, speech transcript, and keyframe storyboard.
   - Post copy: extract title, caption, visible overlay text, tags, pinned comments when available, and short UI labels. Record this as `post_copy_evidence`.
   - Speech transcript: if the MCP/browser/source provides video audio, transcript, captions, or downloadable media, transcribe the speech or use the available transcript. Save the transcript to `<app-directory>/source/transcript/video-transcript.txt` and summarize it as `speech_transcript_evidence`. If audio cannot be accessed, record the reason in `uncertainty_notes` instead of guessing.
   - Keyframe storyboard: capture ordered screenshots/keyframes across the video, especially scene changes, UI transitions, before/after states, feature demos, and explanatory moments. Save them under `<app-directory>/source/keyframes/` and write `<app-directory>/source/storyboard.json`.
   - meaning-first synthesis: create `video_semantic_packet` containing `app_meaning_summary`, `app_logic_hypothesis`, `feature_flow_from_video`, `visual_elements_from_video`, `post_copy_evidence`, `speech_transcript_evidence`, `keyframe_storyboard_evidence`, and `uncertainty_notes`.
   - If the three evidence lanes disagree, trust explicit speech/post copy over isolated visuals, then use keyframes to ground UI and interaction details.
5. Capture reference UI images. When the source is a Xiaohongshu link, a product/intro screenshot, or any visual material that shows UI and interaction, you MUST save the referenced UI as image files so the design stage can feed them into `$imagegen`:
   - Save every user-provided screenshot or image to `<app-directory>/source/reference-ui/` as `.png` or `.jpg`.
   - When you can load the Xiaohongshu note through a tool or browser, capture or download its post images (UI cards, carousel frames, layout) into the same directory.
   - Use stable, ordered filenames such as `ref-01.png`, `ref-02.png`.
   - Record every saved file in `reference_ui_images` with a short description and its `origin`.
   - Do not reproduce watermarks or creator identity in the generated app, source brief, or image prompt. Crop only when useful; otherwise keep the reference image unchanged so layout, components, and visual structure remain visible.
   - Skip this capture ONLY when the user explicitly says not to use a reference image, or specifies a different UI/style to build instead. When skipped, leave `reference_ui_images` empty and record the reason in `reference_ui_note`.
6. Produce one concise `source/source-brief.json`:
   - product intent;
   - target user;
   - primary loop;
   - feature candidates with source evidence;
   - UI observations: layout, components, visual style, imagery, copy tone, motion/audio clues;
   - `video_semantic_packet` for video-heavy sources, using the three evidence lanes rather than screenshots alone;
   - `reference_ui_images` captured in step 4 (and `reference_ui_note` when capture was skipped);
   - XHS MCP fields when the source is Xiaohongshu: `xhs_mcp_status`, `xhs_mcp_tool`, and `xhs_mcp_artifacts`;
   - must-recreate items;
   - avoid-copying items.
7. Convert source material into an original Eazo app direction. Preserve idea and UI logic, not watermarks, creator names, private data, or long verbatim captions.
8. Parse the written JSON and validate:
   - `schema_version` is `"1.0"`;
   - `product_intent`, `target_user`, and `primary_loop` are non-empty;
   - at least one feature candidate exists;
   - video-heavy sources include `video_semantic_packet.app_meaning_summary`, `app_logic_hypothesis`, and at least two evidence lanes unless blocked by source access;
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
