# source-brief.json schema

Purpose: normalized brief extracted from source material such as Xiaohongshu links, screenshots, image sets, pasted notes, or mixed media. It lets Eazo Factory treat "from this link/screenshot" like a normal app request.

Rules:
- Use this only when the user provides source material instead of, or in addition to, a direct app prompt.
- Preserve product intent, UI structure, visual motifs, and copy tone.
- Do not copy creator identity, watermarks, private profile data, or long verbatim text. Convert source material into an original Eazo app brief.
- If the source is inaccessible and no screenshots or text are available, stop with one concise request for screenshots.

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
  "extracted_text": ["30 day plank challenge", "tap to start today's set"],
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
  "must_recreate": ["daily challenge loop", "progress feeling", "warm motivational tone"],
  "avoid_copying": ["creator handle", "watermark", "exact long captions"],
  "confidence": "high",
  "open_questions": []
}
```
