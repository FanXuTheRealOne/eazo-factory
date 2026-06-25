#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=plugins/eazo-factory/scripts/lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

STAGING_RUN="${1:-}"
FINAL_RUN="${2:-}"
[ -n "$STAGING_RUN" ] || die "usage: merge-run-state.sh STAGING_RUN FINAL_RUN"
[ -n "$FINAL_RUN" ] || die "usage: merge-run-state.sh STAGING_RUN FINAL_RUN"
[ ! -L "$STAGING_RUN" ] || die "staging run state must not be a symlink: $STAGING_RUN"
[ ! -L "$FINAL_RUN" ] || die "final run state must not be a symlink: $FINAL_RUN"
[ -f "$STAGING_RUN" ] || die "staging run state does not exist: $STAGING_RUN"
[ -f "$FINAL_RUN" ] || die "final run state does not exist: $FINAL_RUN"

NOW="$(utc_now)"
node - "$STAGING_RUN" "$FINAL_RUN" "$NOW" <<'NODE'
const fs = require("node:fs");
const path = require("node:path");

const stagingPath = process.argv[2];
const finalPath = process.argv[3];
const now = process.argv[4];
const staging = JSON.parse(fs.readFileSync(stagingPath, "utf8"));
const final = JSON.parse(fs.readFileSync(finalPath, "utf8"));

final.started_at = staging.started_at || final.started_at;
final.updated_at = now;
final.stage_history = [
  ...(Array.isArray(staging.stage_history) ? staging.stage_history : []),
  ...(Array.isArray(final.stage_history) ? final.stage_history : []),
];
final.artifacts = {
  ...(staging.artifacts && typeof staging.artifacts === "object" ? staging.artifacts : {}),
  ...(final.artifacts && typeof final.artifacts === "object" ? final.artifacts : {}),
};
final.verification = [
  ...(Array.isArray(staging.verification) ? staging.verification : []),
  ...(Array.isArray(final.verification) ? final.verification : []),
];
final.review_cycles = Math.max(
  Number(staging.review_cycles ?? 0),
  Number(final.review_cycles ?? 0),
);

const tempPath = path.join(
  path.dirname(finalPath),
  `.factory-run.json.${process.pid}.${Date.now()}.tmp`,
);
fs.writeFileSync(tempPath, JSON.stringify(final, null, 2) + "\n", { flag: "wx" });
fs.renameSync(tempPath, finalPath);
NODE
