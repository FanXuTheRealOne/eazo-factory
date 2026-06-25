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
const run = JSON.parse(fs.readFileSync(runPath, "utf8"));
run.stage = stage;
run.status = status;
run.updated_at = now;
if (previewUrl) run.preview_url = previewUrl;
if (incrementReview) run.review_cycles = Number(run.review_cycles ?? 0) + 1;
fs.writeFileSync(runPath, JSON.stringify(run, null, 2) + "\n");
NODE
