#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

node - "$PLUGIN_ROOT" <<'NODE'
const fs = require("node:fs");
const path = require("node:path");

const [pluginRoot] = process.argv.slice(2);
const skill = fs.readFileSync(path.join(pluginRoot, "skills/eazo-factory/SKILL.md"), "utf8");

const required = [
  "## 三种使用方式",
  "### 1. 一句话生成 App",
  "### 2. 从小红书链接复刻",
  "### 3. 从截图/素材生成",
  "📌 适合",
  "🧩 你怎么发",
  "🖼 效果示意",
  "复制示例",
  "## 3 ways to use it",
  "### 1. Build from one sentence",
  "### 2. Recreate from a Xiaohongshu link",
  "### 3. Build from screenshots/assets",
];

for (const needle of required) {
  if (!skill.includes(needle)) {
    throw new Error(`missing onboarding requirement: ${needle}`);
  }
}

const chineseLayout = skill.match(/Required Chinese layout:[\s\S]*?For English users/);
if (!chineseLayout) throw new Error("missing Chinese onboarding layout block");
const illustrationCount = (chineseLayout[0].match(/🖼 效果示意/g) || []).length;
if (illustrationCount !== 3) {
  throw new Error(`expected 3 Chinese example illustrations, got ${illustrationCount}`);
}

const copyExampleCount = (chineseLayout[0].match(/复制示例/g) || []).length;
if (copyExampleCount !== 3) {
  throw new Error(`expected 3 Chinese copy examples, got ${copyExampleCount}`);
}
NODE

echo "onboarding test passed"
