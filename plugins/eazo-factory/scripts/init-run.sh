#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=plugins/eazo-factory/scripts/lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

OUTPUT_ROOT="${1:-}"
SLUG="${2:-}"
[ -n "$OUTPUT_ROOT" ] || die "usage: init-run.sh OUTPUT_ROOT PROVISIONAL_SLUG"
[ -n "$SLUG" ] || die "usage: init-run.sh OUTPUT_ROOT PROVISIONAL_SLUG"
is_valid_slug "$SLUG" || die "invalid slug: $SLUG"
require_command node

mkdir -p "$OUTPUT_ROOT"
OUTPUT_ROOT="$(cd "$OUTPUT_ROOT" && pwd -P)"
RUNS_ROOT="$OUTPUT_ROOT/.eazo-factory-runs"
RUN_DIR="$RUNS_ROOT/$SLUG"
RUN_PATH="$RUN_DIR/factory-run.json"

[ ! -L "$RUNS_ROOT" ] || die "runs root must not be a symlink: $RUNS_ROOT"
mkdir -p "$RUNS_ROOT"
[ ! -L "$RUN_DIR" ] || die "run directory must not be a symlink: $RUN_DIR"
[ ! -L "$RUN_PATH" ] || die "run state must not be a symlink: $RUN_PATH"

if [ -f "$RUN_PATH" ]; then
  printf '%s\n' "$RUN_DIR"
  exit 0
fi
if [ -d "$RUN_DIR" ] && [ -n "$(ls -A "$RUN_DIR" 2>/dev/null)" ]; then
  die "run directory exists without factory-run.json: $RUN_DIR"
fi
mkdir -p "$RUN_DIR"

NOW="$(utc_now)"
node - "$RUN_PATH" "$NOW" <<'NODE'
const fs = require("node:fs");
const outputPath = process.argv[2];
const now = process.argv[3];
const payload = {
  schema_version: "1.0",
  plugin_version: "0.1.6",
  status: "in_progress",
  stage: "preflight",
  stage_history: [
    {
      stage: "preflight",
      status: "in_progress",
      entered_at: now,
    },
  ],
  started_at: now,
  updated_at: now,
  starter: {
    source: "https://github.com/EazoAI/eazo-creator-nextjs-template.git",
    branch: "main",
    commit: "",
  },
  artifacts: {},
  verification: [],
  review_cycles: 0,
  preview_url: null,
};
fs.writeFileSync(outputPath, JSON.stringify(payload, null, 2) + "\n", { flag: "wx" });
NODE

printf '%s\n' "$RUN_DIR"
