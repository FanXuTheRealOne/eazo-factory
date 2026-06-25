#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=plugins/eazo-factory/scripts/lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

RUN_PATH="${1:-}"
STAGE="${2:-}"
STATUS="${3:-in_progress}"
PREVIEW_URL="${4:-}"
INCREMENT_REVIEW="${5:-0}"

[ -n "$RUN_PATH" ] || die "usage: update-run.sh RUN_PATH STAGE [STATUS] [PREVIEW_URL] [INCREMENT_REVIEW]"
[ -n "$STAGE" ] || die "usage: update-run.sh RUN_PATH STAGE [STATUS] [PREVIEW_URL] [INCREMENT_REVIEW]"
[ ! -L "$RUN_PATH" ] || die "run state must not be a symlink: $RUN_PATH"
[ -f "$RUN_PATH" ] || die "run state does not exist: $RUN_PATH"
case "$INCREMENT_REVIEW" in
  0|1) ;;
  *) die "INCREMENT_REVIEW must be 0 or 1" ;;
esac

NOW="$(utc_now)"
node - "$RUN_PATH" "$STAGE" "$STATUS" "$PREVIEW_URL" "$INCREMENT_REVIEW" "$NOW" <<'NODE'
const fs = require("node:fs");
const runPath = process.argv[2];
const stage = process.argv[3];
const status = process.argv[4];
const previewUrl = process.argv[5];
const incrementReview = process.argv[6] === "1";
const now = process.argv[7];
const directory = require("node:path").dirname(runPath);
const run = JSON.parse(fs.readFileSync(runPath, "utf8"));
run.stage = stage;
run.status = status;
run.updated_at = now;
run.stage_history = Array.isArray(run.stage_history) ? run.stage_history : [];
run.stage_history.push({ stage, status, entered_at: now });
if (previewUrl) run.preview_url = previewUrl;
if (incrementReview) run.review_cycles = Number(run.review_cycles ?? 0) + 1;
const tempPath = require("node:path").join(
  directory,
  `.factory-run.json.${process.pid}.${Date.now()}.tmp`,
);
fs.writeFileSync(tempPath, JSON.stringify(run, null, 2) + "\n", { flag: "wx" });
fs.renameSync(tempPath, runPath);
NODE
