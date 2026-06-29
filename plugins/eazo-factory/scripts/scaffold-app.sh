#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=plugins/eazo-factory/scripts/lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

CANONICAL_STARTER_URL="https://github.com/EazoAI/eazo-creator-nextjs-template.git"
CANONICAL_STARTER_BRANCH="main"
PLUGIN_VERSION="0.1.6"

OUTPUT_ROOT="${1:-}"
SLUG="${2:-}"

[ -n "$OUTPUT_ROOT" ] || die "usage: scaffold-app.sh OUTPUT_ROOT SLUG"
[ -n "$SLUG" ] || die "usage: scaffold-app.sh OUTPUT_ROOT SLUG"

write_factory_run() {
  output_path="$1"
  status="$2"
  stage="$3"
  started_at="$4"
  updated_at="$5"
  starter_source="$6"
  starter_branch="$7"
  starter_commit="$8"

  node - "$output_path" "$PLUGIN_VERSION" "$status" "$stage" "$started_at" "$updated_at" "$starter_source" "$starter_branch" "$starter_commit" <<'NODE'
const fs = require("node:fs");

const outputPath = process.argv[2];
const pluginVersion = process.argv[3];
const status = process.argv[4];
const stage = process.argv[5];
const startedAt = process.argv[6];
const updatedAt = process.argv[7];
const starterSource = process.argv[8];
const starterBranch = process.argv[9];
const starterCommit = process.argv[10];

const payload = {
  schema_version: "1.0",
  plugin_version: pluginVersion,
  status,
  stage,
  stage_history: [
    {
      stage,
      status,
      entered_at: updatedAt,
    },
  ],
  started_at: startedAt,
  updated_at: updatedAt,
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
}

PREFLIGHT_JSON="$("$SCRIPT_DIR/preflight.sh" "$OUTPUT_ROOT" "$SLUG")"
STARTER_SOURCE="$(node -e 'process.stdout.write(JSON.parse(process.argv[1]).starter_source)' "$PREFLIGHT_JSON")"
ABSOLUTE_OUTPUT_ROOT="$(cd "$OUTPUT_ROOT" && pwd -P)"

DESTINATION="$ABSOLUTE_OUTPUT_ROOT/$SLUG"
RUN_STATE_PATH="$DESTINATION/factory-run.json"
CLEANUP_LOG_PATH="$DESTINATION/review/cleanup-demo.log"

if [ -L "$DESTINATION" ]; then
  die "destination must not be a symlink: $DESTINATION"
fi

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

mkdir -p "$DESTINATION/review"

node - "$DESTINATION/package.json" "$SLUG" <<'NODE'
const fs = require("node:fs");

const packageJsonPath = process.argv[2];
const slug = process.argv[3];
const pkg = JSON.parse(fs.readFileSync(packageJsonPath, "utf8"));
pkg.name = slug;
fs.writeFileSync(packageJsonPath, JSON.stringify(pkg, null, 2) + "\n");
NODE

STARTED_AT="$(utc_now)"
write_factory_run "$RUN_STATE_PATH" "in_progress" "cleanup_pending" "$STARTED_AT" "$STARTED_AT" "$STARTER_SOURCE" "$CANONICAL_STARTER_BRANCH" "$STARTER_COMMIT"

if ! (
  cd "$DESTINATION"
  bun run cleanup:demo 2>&1 | tee "$CLEANUP_LOG_PATH"
); then
  FAILED_AT="$(utc_now)"
  write_factory_run "$RUN_STATE_PATH" "failed" "cleanup_demo_failed" "$STARTED_AT" "$FAILED_AT" "$STARTER_SOURCE" "$CANONICAL_STARTER_BRANCH" "$STARTER_COMMIT"
  exit 1
fi

mkdir -p "$DESTINATION/design"

COMPLETED_AT="$(utc_now)"
write_factory_run "$RUN_STATE_PATH" "in_progress" "scaffolded" "$STARTED_AT" "$COMPLETED_AT" "$STARTER_SOURCE" "$CANONICAL_STARTER_BRANCH" "$STARTER_COMMIT"
