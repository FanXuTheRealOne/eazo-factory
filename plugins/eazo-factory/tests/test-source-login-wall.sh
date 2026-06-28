#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

node - "$PLUGIN_ROOT" <<'NODE'
const fs = require("node:fs");
const path = require("node:path");

const [pluginRoot] = process.argv.slice(2);
const sourceSkill = fs.readFileSync(path.join(pluginRoot, "skills/eazo-source/SKILL.md"), "utf8");
const factorySkill = fs.readFileSync(path.join(pluginRoot, "skills/eazo-factory/SKILL.md"), "utf8");
const schema = fs.readFileSync(path.join(pluginRoot, "references/source-brief-schema.md"), "utf8");

const requiredSource = [
  "login wall",
  "登录",
  "ask the user to log in to Xiaohongshu in their local browser",
  "then retry the link",
  "screenshots as a fallback",
  "Do not claim the source was extracted",
];

for (const needle of requiredSource) {
  if (!sourceSkill.includes(needle)) {
    throw new Error(`missing source login-wall guidance: ${needle}`);
  }
}

const requiredFactory = [
  "登录自己的小红书账号",
  "重新发送同一个链接",
  "补充帖子截图",
];

for (const needle of requiredFactory) {
  if (!factorySkill.includes(needle)) {
    throw new Error(`missing factory login-wall guidance: ${needle}`);
  }
}

if (!schema.includes("login-required") || !schema.includes("user should log in")) {
  throw new Error("source schema must document login-required fallback state");
}
NODE

echo "source login-wall test passed"
