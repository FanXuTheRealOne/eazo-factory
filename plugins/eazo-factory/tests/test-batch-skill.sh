#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [[ ! -f "$PLUGIN_ROOT/skills/eazo-batch/SKILL.md" ]]; then
  echo "missing eazo-batch skill" >&2
  exit 1
fi

node - "$PLUGIN_ROOT" <<'NODE'
const fs = require("node:fs");
const path = require("node:path");
const pluginRoot = process.argv[2];
const batchSkill = fs.readFileSync(path.join(pluginRoot, "skills/eazo-batch/SKILL.md"), "utf8");
const factorySkill = fs.readFileSync(path.join(pluginRoot, "skills/eazo-factory/SKILL.md"), "utf8");

for (const needle of [
  "eazo-batch.mjs",
  "codex exec",
  "--concurrency",
  "batch-report.json",
  "Do not manually loop",
  "links.txt",
  "jobs.json",
]) {
  if (!batchSkill.includes(needle)) throw new Error(`batch skill missing ${needle}`);
}

for (const needle of [
  "Batch mode",
  "$eazo-batch",
  "批量",
  "Do not run the single-app stage machine",
]) {
  if (!factorySkill.includes(needle)) throw new Error(`factory skill missing ${needle}`);
}
NODE

echo "batch skill test passed"
