# source-brief.json schema

Purpose: normalized brief extracted from source material such as Xiaohongshu links, screenshots, image sets, pasted notes, or mixed media. It lets Eazo Factory treat "from this link/screenshot" like a normal app request.

Rules:
- Use this only when the user provides source material instead of, or in addition to, a direct app prompt.
- Preserve product intent, UI structure, visual motifs, and copy tone.
- For visual sources (Xiaohongshu links, product/intro screenshots, or any UI/interaction reference), you MUST capture the referenced UI as saved image files under `source/reference-ui/` and list them in `reference_ui_images`. These images are passed to `$imagegen` during design as visual references. Skip capture only when the user explicitly opts out or specifies a different UI/style; record that in `reference_ui_note`.
- Do not copy creator identity, watermarks, private profile data, or long verbatim text. Convert source material into an original Eazo app brief.
- If the source is inaccessible and no screenshots or text are available, stop with one concise request for screenshots.
- If a Xiaohongshu source is blocked by login or verification, treat it as `login-required`: do not create a brief from guesses; tell the user they should log in to Xiaohongshu in their local browser and resend the same link, or upload screenshots as a fallback.
- `login-required` means the user should log in locally before retrying the same URL; screenshots remain the fallback when authentication still blocks access.
- For Xiaohongshu sources, prefer XHS MCP when available. Record `xhs_mcp_status` as `success`, `mcp_unavailable`, `login_required`, `blocked`, or `failed`. Save raw MCP note detail to `source/raw/xhs-note.json` when available, and list saved raw/media/reference artifacts in `xhs_mcp_artifacts`.
- For video-heavy sources, create a `video_semantic_packet` by combining post copy, speech transcript, and keyframe storyboard evidence. Do not infer the app from screenshots alone. Save transcript text to `source/transcript/video-transcript.txt`, video keyframes under `source/keyframes/`, and ordered storyboard notes to `source/storyboard.json` when available.

```json
{
  "schema_version": "1.0",
  "source_type": "xiaohongshu_url",
  "source_urls": ["https://www.xiaohongshu.com/explore/example"],
  "source_assets": [
    {
      "id": "screenshot-1",
      "type": "screenshot",
      "description": "Mobile post screenshot showing a habit card layout and handwritten annotations"
    }
  ],
  "xhs_mcp_status": "success",
  "xhs_mcp_tool": "xhs.get_note_detail",
  "xhs_mcp_artifacts": [
    {
      "type": "raw_note_detail",
      "path": "source/raw/xhs-note.json",
      "description": "Raw note detail returned by the authenticated XHS MCP tool"
    },
    {
      "type": "media",
      "path": "source/media/image-01.jpg",
      "description": "Downloaded post image from the note"
    }
  ],
  "extracted_text": ["30 day plank challenge", "tap to start today's set"],
  "video_semantic_packet": {
    "app_meaning_summary": "The video explains a playful breathing app where users choose a mood room, follow a calm breathing guide, and reduce white noise.",
    "app_logic_hypothesis": "The source app is not just a cute character screen; it is a guided calm-down loop with room/mode selection, timed breathing, and ambient noise control.",
    "feature_flow_from_video": [
      "Select a practice category",
      "Read the current breathing instruction",
      "Start a timed session",
      "Toggle ambient/white noise",
      "Complete and save the calm state"
    ],
    "visual_elements_from_video": [
      "segmented category tabs",
      "soft mascot",
      "large instruction card",
      "bottom start action"
    ],
    "post_copy_evidence": [
      "Caption says the app helps users relax with simple breathing"
    ],
    "speech_transcript_evidence": [
      {
        "path": "source/transcript/video-transcript.txt",
        "summary": "Voiceover describes selecting a scene and following a slow breathing timer."
      }
    ],
    "keyframe_storyboard_evidence": [
      {
        "path": "source/keyframes/frame-001.png",
        "timestamp": "00:03",
        "meaning": "Shows the category selector and main calming mode"
      }
    ],
    "uncertainty_notes": []
  },
  "product_intent": "Turn a social fitness challenge post into a guided daily plank app.",
  "target_user": "Beginners who want lightweight daily core training.",
  "primary_loop": ["Open today's challenge", "Start timer", "Finish set", "See progress"],
  "feature_candidates": [
    {
      "id": "daily-challenge",
      "summary": "One guided plank challenge per day",
      "source_evidence": "Screenshot headline and checklist"
    }
  ],
  "ui_observations": {
    "layout": ["single-card mobile layout", "large progress number", "bottom primary action"],
    "components": ["pill timer", "progress ring", "checklist rows"],
    "visual_style": ["warm paper background", "rounded cards", "hand-drawn accents"],
    "imagery": ["fitness silhouette", "calendar marks"],
    "copy_tone": "encouraging, short, social-post style",
    "motion_audio_clues": ["timer pulse", "subtle completion chime"]
  },
  "reference_ui_images": [
    {
      "id": "ref-01",
      "path": "source/reference-ui/ref-01.png",
      "origin": "user_screenshot",
      "description": "Original post card layout captured as a UI reference for $imagegen"
    }
  ],
  "reference_ui_note": "",
  "must_recreate": ["daily challenge loop", "progress feeling", "warm motivational tone"],
  "avoid_copying": ["creator handle", "watermark", "exact long captions"],
  "confidence": "high",
  "open_questions": []
}
```
