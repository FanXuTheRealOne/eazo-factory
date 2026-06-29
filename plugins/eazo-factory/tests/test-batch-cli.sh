#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

cat > "$TMP_DIR/links.txt" <<'EOF'
# blank lines and comments are ignored
https://www.xiaohongshu.com/explore/one
https://www.xiaohongshu.com/explore/two
EOF

node "$PLUGIN_ROOT/bin/eazo-batch.mjs" run "$TMP_DIR/links.txt" \
  --out "$TMP_DIR/out" \
  --concurrency 2 \
  --style "warm Matisse paper cut" \
  --dry-run

REPORT="$(find "$TMP_DIR/out" -name batch-report.json -print -quit)"
if [[ -z "$REPORT" ]]; then
  echo "missing batch-report.json" >&2
  exit 1
fi

node - "$REPORT" <<'NODE'
const fs = require("node:fs");
const path = require("node:path");
const reportPath = process.argv[2];
const report = JSON.parse(fs.readFileSync(reportPath, "utf8"));

if (report.version !== 1) throw new Error("wrong report version");
if (report.mode !== "dry-run") throw new Error("wrong mode");
if (report.summary.total !== 2) throw new Error("wrong total");
if (report.summary.dryRun !== 2) throw new Error("wrong dry-run count");
if (report.summary.failed !== 0) throw new Error("unexpected failures");
if (report.options.concurrency !== 2) throw new Error("wrong concurrency");

for (const job of report.jobs) {
  if (job.status !== "dry_run") throw new Error("job was not dry_run");
  if (!job.promptPath || !fs.existsSync(job.promptPath)) throw new Error("missing prompt");
  if (!job.appDir || !job.appDir.includes("/apps/")) throw new Error("wrong appDir");
  const prompt = fs.readFileSync(job.promptPath, "utf8");
  if (!prompt.includes("@eazo-factory")) throw new Error("prompt does not invoke eazo-factory");
  if (!prompt.includes("批量模式")) throw new Error("prompt missing batch mode guard");
  if (!prompt.includes(job.appDir)) throw new Error("prompt missing app output dir");
  if (!prompt.includes("warm Matisse paper cut")) throw new Error("prompt missing style");
}

const ids = new Set(report.jobs.map((job) => job.id));
if (ids.size !== report.jobs.length) throw new Error("duplicate job ids");
const appDirs = new Set(report.jobs.map((job) => job.appDir));
if (appDirs.size !== report.jobs.length) throw new Error("duplicate app dirs");
NODE

echo "batch cli test passed"
