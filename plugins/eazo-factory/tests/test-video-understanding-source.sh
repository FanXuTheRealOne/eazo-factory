#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

node - "$PLUGIN_ROOT" <<'NODE'
const fs = require("node:fs");
const path = require("node:path");
const pluginRoot = process.argv[2];

const sourceSkill = fs.readFileSync(path.join(pluginRoot, "skills/eazo-source/SKILL.md"), "utf8");
const ideaSkill = fs.readFileSync(path.join(pluginRoot, "skills/eazo-idea/SKILL.md"), "utf8");
const designSkill = fs.readFileSync(path.join(pluginRoot, "skills/eazo-design/SKILL.md"), "utf8");
const schema = fs.readFileSync(path.join(pluginRoot, "references/source-brief-schema.md"), "utf8");

for (const needle of [
  "video semantic packet",
  "post copy",
  "speech transcript",
  "keyframe storyboard",
  "source/transcript/video-transcript.txt",
  "source/keyframes/",
  "source/storyboard.json",
  "meaning-first synthesis",
  "Do not infer the app from screenshots alone",
]) {
  if (!sourceSkill.includes(needle)) throw new Error(`source skill missing ${needle}`);
}

for (const needle of [
  "video_semantic_packet",
  "post_copy_evidence",
  "speech_transcript_evidence",
  "keyframe_storyboard_evidence",
  "app_meaning_summary",
  "app_logic_hypothesis",
  "uncertainty_notes",
]) {
  if (!schema.includes(needle)) throw new Error(`schema missing ${needle}`);
}

for (const needle of [
  "video_semantic_packet",
  "app_meaning_summary",
  "app_logic_hypothesis",
]) {
  if (!ideaSkill.includes(needle)) throw new Error(`idea skill missing ${needle}`);
}

for (const needle of [
  "keyframe storyboard",
  "visual elements from evidence",
  "do not decorate from isolated screenshots",
]) {
  if (!designSkill.includes(needle)) throw new Error(`design skill missing ${needle}`);
}
NODE

echo "video understanding source test passed"
