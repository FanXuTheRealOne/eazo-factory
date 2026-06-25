#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=plugins/eazo-factory/scripts/lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

CANONICAL_STARTER_URL="https://github.com/EazoAI/eazo-creator-nextjs-template.git"
CANONICAL_STARTER_BRANCH="main"
PLUGIN_VERSION="0.1.0"

OUTPUT_ROOT="${1:-}"
SLUG="${2:-}"

[ -n "$OUTPUT_ROOT" ] || die "usage: scaffold-app.sh OUTPUT_ROOT SLUG"
[ -n "$SLUG" ] || die "usage: scaffold-app.sh OUTPUT_ROOT SLUG"

PREFLIGHT_JSON="$("$SCRIPT_DIR/preflight.sh" "$OUTPUT_ROOT" "$SLUG")"
STARTER_SOURCE="$(node -e 'process.stdout.write(JSON.parse(process.argv[1]).starter_source)' "$PREFLIGHT_JSON")"

DESTINATION="$OUTPUT_ROOT/$SLUG"

if [ -e "$DESTINATION" ] && [ ! -d "$DESTINATION" ]; then
  die "destination exists and is not a directory: $DESTINATION"
fi

if [ -d "$DESTINATION" ] && [ -n "$(ls -A "$DESTINATION" 2>/dev/null)" ]; then
  die "destination already exists and is not empty: $DESTINATION"
fi

if [ -n "${EAZO_STARTER_PATH:-}" ]; then
  git clone --no-local "$EAZO_STARTER_PATH" "$DESTINATION" >/dev/null 2>&1
else
  git clone --branch "$CANONICAL_STARTER_BRANCH" --depth 1 "$CANONICAL_STARTER_URL" "$DESTINATION" >/dev/null 2>&1
fi

STARTER_COMMIT="$(git -C "$DESTINATION" rev-parse HEAD)"

rm -rf "$DESTINATION/.git"
git -C "$DESTINATION" init >/dev/null 2>&1

node - "$DESTINATION/package.json" "$SLUG" <<'NODE'
const fs = require("node:fs");

const packageJsonPath = process.argv[2];
const slug = process.argv[3];
const pkg = JSON.parse(fs.readFileSync(packageJsonPath, "utf8"));
pkg.name = slug;
fs.writeFileSync(packageJsonPath, JSON.stringify(pkg, null, 2) + "\n");
NODE

(
  cd "$DESTINATION"
  bun run cleanup:demo >/dev/null 2>&1
)

mkdir -p "$DESTINATION/design" "$DESTINATION/review"

TIMESTAMP="$(utc_now)"

node - "$DESTINATION/factory-run.json" "$PLUGIN_VERSION" "$STARTER_SOURCE" "$CANONICAL_STARTER_BRANCH" "$STARTER_COMMIT" "$TIMESTAMP" <<'NODE'
const fs = require("node:fs");

const outputPath = process.argv[2];
const pluginVersion = process.argv[3];
const starterSource = process.argv[4];
const starterBranch = process.argv[5];
const starterCommit = process.argv[6];
const timestamp = process.argv[7];

const payload = {
  schema_version: "1.0",
  plugin_version: pluginVersion,
  status: "in_progress",
  stage: "scaffolded",
  started_at: timestamp,
  updated_at: timestamp,
  starter: {
    source: starterSource,
    branch: starterBranch,
    commit: starterCommit,
  },
  artifacts: {},
  verification: [],
  review_cycles: 0,
  preview_url: null,
};

fs.writeFileSync(outputPath, JSON.stringify(payload, null, 2) + "\n");
NODE
