#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPO_ROOT="$(cd "$PLUGIN_ROOT/../.." && pwd)"

node - "$PLUGIN_ROOT" "$REPO_ROOT" <<'NODE'
const fs = require("node:fs");
const path = require("node:path");

const [pluginRoot, repoRoot] = process.argv.slice(2);
const manifest = JSON.parse(
  fs.readFileSync(path.join(pluginRoot, ".codex-plugin/plugin.json"), "utf8"),
);
if (manifest.name !== "eazo-factory") throw new Error("wrong plugin name");
if (manifest.version !== "0.1.6") throw new Error("wrong plugin version");
if (manifest.skills !== "./skills/") throw new Error("wrong skills path");
if (manifest.author?.name !== "EazoAI") throw new Error("wrong author name");

const interfaceBlock = manifest.interface;
if (!interfaceBlock || typeof interfaceBlock !== "object") {
  throw new Error("missing interface block");
}
if (interfaceBlock.displayName !== "Eazo Factory") throw new Error("wrong displayName");
if (interfaceBlock.shortDescription !== "Generate reviewed Eazo apps from prompts, links, screenshots, or batches.") {
  throw new Error("wrong shortDescription");
}
if (
  interfaceBlock.longDescription !==
  "Eazo Factory turns one product prompt, Xiaohongshu link, screenshot set, or batch input file into standardized bilingual Eazo apps using the official Eazo Next.js template, optional authenticated XHS MCP source extraction, a $imagegen UI reference board with an asset library, deterministic checks, mandatory independent review, a batch runner for parallel Codex workers, and a visual onboarding guide for first-time users."
) {
  throw new Error("wrong longDescription");
}
if (interfaceBlock.developerName !== "EazoAI") throw new Error("wrong developerName");
if (interfaceBlock.category !== "Developer Tools") throw new Error("wrong category");
if (!Array.isArray(interfaceBlock.capabilities)) throw new Error("capabilities must be an array");
if (interfaceBlock.capabilities.length !== 6) throw new Error("wrong capabilities length");
if (interfaceBlock.capabilities[0] !== "Generate standardized Eazo apps from the official template") {
  throw new Error("wrong first capability");
}
if (interfaceBlock.capabilities[1] !== "Extract app briefs from Xiaohongshu links, XHS MCP, and screenshots") {
  throw new Error("wrong second capability");
}
if (interfaceBlock.capabilities[2] !== "Create UI reference boards with reusable asset libraries") {
  throw new Error("wrong third capability");
}
if (interfaceBlock.capabilities[3] !== "Audit every interactive control with an independent reviewer") {
  throw new Error("wrong fourth capability");
}
if (interfaceBlock.capabilities[4] !== "Batch-run many sources through parallel Codex workers") {
  throw new Error("wrong fifth capability");
}
if (interfaceBlock.capabilities[5] !== "Use authenticated Xiaohongshu MCP source collection when available") {
  throw new Error("wrong sixth capability");
}
if (!Array.isArray(interfaceBlock.defaultPrompt)) throw new Error("defaultPrompt must be an array");
if (interfaceBlock.defaultPrompt.length !== 1) throw new Error("wrong defaultPrompt length");
if (interfaceBlock.defaultPrompt[0] !== "Use @eazo-factory to show visual onboarding, create one Eazo app, or batch-run links from a file.") {
  throw new Error("wrong defaultPrompt value");
}
if (interfaceBlock.brandColor !== "#2F5D50") throw new Error("wrong brandColor");

const marketplace = JSON.parse(
  fs.readFileSync(path.join(repoRoot, ".agents/plugins/marketplace.json"), "utf8"),
);
if (marketplace.name !== "eazo-tools") throw new Error("wrong marketplace name");
const entry = marketplace.plugins.find((item) => item.name === "eazo-factory");
if (!entry) throw new Error("missing marketplace plugin entry");
if (entry.source.path !== "./plugins/eazo-factory") {
  throw new Error("wrong marketplace source path");
}
NODE

echo "manifest test passed"
