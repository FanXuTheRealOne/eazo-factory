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
if (manifest.version !== "0.1.0") throw new Error("wrong plugin version");
if (manifest.skills !== "./skills/") throw new Error("wrong skills path");

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
