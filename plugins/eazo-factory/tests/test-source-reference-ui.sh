#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

node - "$PLUGIN_ROOT" <<'NODE'
const fs = require("node:fs");
const path = require("node:path");

const [pluginRoot] = process.argv.slice(2);
const sourceSkill = fs.readFileSync(path.join(pluginRoot, "skills/eazo-source/SKILL.md"), "utf8");
const designSkill = fs.readFileSync(path.join(pluginRoot, "skills/eazo-design/SKILL.md"), "utf8");
const factorySkill = fs.readFileSync(path.join(pluginRoot, "skills/eazo-factory/SKILL.md"), "utf8");
const schema = fs.readFileSync(path.join(pluginRoot, "references/source-brief-schema.md"), "utf8");

const requiredSource = [
  "source/reference-ui/",
  "reference_ui_images",
  "reference_ui_note",
  "Do not reproduce watermarks or creator identity",
  "keep the reference image unchanged",
];

for (const needle of requiredSource) {
  if (!sourceSkill.includes(needle)) {
    throw new Error(`missing source reference-ui guidance: ${needle}`);
  }
}

const requiredDesign = [
  "resolve each `path` relative to `<app-directory>`",
  "missing or unreadable",
  "do not silently generate without references",
  "view_image",
  "reference image, not edit target",
  "Pass the loaded reference images to `$imagegen`",
];

for (const needle of requiredDesign) {
  if (!designSkill.includes(needle)) {
    throw new Error(`missing design reference-ui guidance: ${needle}`);
  }
}

const requiredSchema = [
  "reference_ui_images",
  "reference_ui_note",
  "\"path\": \"source/reference-ui/ref-01.png\"",
];

for (const needle of requiredSchema) {
  if (!schema.includes(needle)) {
    throw new Error(`missing source schema reference-ui field: ${needle}`);
  }
}

if (!factorySkill.includes("<staging>/source/reference-ui/")) {
  throw new Error("factory workflow must connect source reference-ui path into orchestration");
}
NODE

echo "source reference-ui test passed"
