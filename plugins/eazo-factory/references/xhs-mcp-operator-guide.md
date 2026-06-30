# XHS MCP Operator Guide

This guide explains how Eazo Factory should work when Xiaohongshu source links are handled through an XHS MCP server.

## Mental model

```text
Codex
  ↓
Eazo Factory plugin
  ↓
XHS MCP
  ↓
已登录的小红书浏览器
```

- Eazo Factory decides what app to build.
- XHS MCP is the source collector.
- The MCP-controlled browser carries the Xiaohongshu login state.

## First-time setup

1. Install or start a community Xiaohongshu / XHS MCP server that supports browser login and note detail extraction.
2. Let the MCP open its browser.
3. 在 MCP 打开的浏览器里扫码登录小红书。
4. Confirm the MCP keeps an authenticated browser profile or cookie store.
5. Restart Codex or reload MCP tools if needed so Codex can see the XHS MCP tools.

The exact tool names vary by MCP implementation. Common shapes are similar to:

```text
xhs.open_note
xhs.get_note_detail
xhs.download_images
xhs.screenshot_note
```

## Single-link workflow

User prompt:

```text
@eazo-factory 从这个小红书链接复刻成 Eazo App:
https://www.xiaohongshu.com/explore/...
```

Expected workflow:

```text
1. eazo-source detects Xiaohongshu URL
2. eazo-source tries XHS MCP first
3. MCP opens the note with the authenticated browser profile
4. MCP returns note detail, text, images, video cover/metadata, and screenshots
5. eazo-source saves:
   - source/raw/xhs-note.json
   - source/media/*
   - source/reference-ui/ref-*.png
6. eazo-source writes source/source-brief.json
7. eazo-design feeds reference UI images into $imagegen
8. eazo-build creates the app
9. eazo-review verifies the app
```

## Video demo understanding workflow

For Xiaohongshu videos that introduce or demo an app, do not rely on one screenshot. The source stage should collect three lanes:

```text
post copy + speech transcript + keyframe storyboard
```

Save:

```text
source/transcript/video-transcript.txt
source/keyframes/frame-001.png
source/keyframes/frame-002.png
source/storyboard.json
```

Then write `video_semantic_packet` in `source/source-brief.json`:

```text
app_meaning_summary
app_logic_hypothesis
feature_flow_from_video
visual_elements_from_video
post_copy_evidence
speech_transcript_evidence
keyframe_storyboard_evidence
uncertainty_notes
```

Downstream stages should use the packet to understand what the video means before copying visual motifs. This prevents apps that look vaguely similar but do not make sense.

## Batch workflow

Create `links.txt`:

```text
https://www.xiaohongshu.com/explore/...
https://www.xiaohongshu.com/explore/...
```

Ask Codex:

```text
@eazo-factory 帮我把 ./links.txt 里的小红书链接批量生成 Eazo App，输出到 ./outputs，最多同时跑 2 个
```

The batch runner starts multiple `codex exec` workers. Each worker calls `@eazo-factory`, and each `@eazo-factory` run tries XHS MCP for its link.

Recommended concurrency:

```text
--concurrency 2
```

Do not open too many Xiaohongshu notes in parallel; high concurrency can trigger verification or rate limits.

## Failure handling

If MCP is unavailable:

```text
xhs_mcp_status = "mcp_unavailable"
```

Continue with browser/web access or ask for screenshots.

If login expired:

```text
xhs_mcp_status = "login_required"
```

Tell the user to reopen the MCP browser and扫码登录 again, then retry the same link.

If CAPTCHA or anti-bot blocks access:

```text
xhs_mcp_status = "blocked"
```

Do not guess. Ask the user for screenshots or manually exported content.

## Privacy and copying rules

- Do not preserve creator handles, watermarks, private profile data, or long verbatim captions in the generated app.
- Use the post as product/source inspiration.
- Save images as reference material for design, but create an original Eazo UI.
