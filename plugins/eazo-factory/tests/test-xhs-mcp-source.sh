#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

node - "$PLUGIN_ROOT" <<'NODE'
const fs = require("node:fs");
const path = require("node:path");
const pluginRoot = process.argv[2];

const sourceSkill = fs.readFileSync(path.join(pluginRoot, "skills/eazo-source/SKILL.md"), "utf8");
const factorySkill = fs.readFileSync(path.join(pluginRoot, "skills/eazo-factory/SKILL.md"), "utf8");
const schema = fs.readFileSync(path.join(pluginRoot, "references/source-brief-schema.md"), "utf8");
const guidePath = path.join(pluginRoot, "references/xhs-mcp-operator-guide.md");

if (!fs.existsSync(guidePath)) throw new Error("missing xhs MCP operator guide");
const guide = fs.readFileSync(guidePath, "utf8");

for (const needle of [
  "XHS MCP first",
  "authenticated browser profile",
  "note detail",
  "source/raw/xhs-note.json",
  "source/media/",
  "source/reference-ui/",
  "login_required",
  "mcp_unavailable",
]) {
  if (!sourceSkill.includes(needle)) throw new Error(`source skill missing ${needle}`);
}

for (const needle of [
  "xhs_mcp_status",
  "xhs_mcp_tool",
  "xhs_mcp_artifacts",
  "source/raw/xhs-note.json",
]) {
  if (!schema.includes(needle)) throw new Error(`schema missing ${needle}`);
}

for (const needle of [
  "XHS MCP",
  "已登录的小红书浏览器",
  "扫码登录",
  "Codex",
  "links.txt",
  "batch",
]) {
  if (!guide.includes(needle)) throw new Error(`guide missing ${needle}`);
}

if (!factorySkill.includes("For Xiaohongshu source material, `$eazo-source` must try XHS MCP first")) {
  throw new Error("factory skill missing XHS MCP routing rule");
}
NODE

echo "xhs mcp source test passed"
