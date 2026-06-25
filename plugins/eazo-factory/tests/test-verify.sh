#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURES="$PLUGIN_ROOT/tests/fixtures"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/eazo-verify.XXXXXX")"

cleanup() {
  rm -rf "$TMP_ROOT"
  rm -rf \
    "$FIXTURES/valid-app/review" \
    "$FIXTURES/dead-button-app/review" \
    "$FIXTURES/client-ai-import-app/review"
}

trap cleanup EXIT

mkdir -p "$TMP_ROOT/bin"
cat >"$TMP_ROOT/bin/bun" <<'BUN'
#!/usr/bin/env bash
set -euo pipefail

if [ "${1:-}" = "run" ] && [ -n "${2:-}" ]; then
  exec node - "$PWD/package.json" "$2" <<'NODE'
const fs = require("node:fs");
const { spawnSync } = require("node:child_process");
const pkg = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
const command = pkg.scripts?.[process.argv[3]];
if (typeof command !== "string") process.exit(2);
const result = spawnSync("/bin/sh", ["-c", command], { stdio: "inherit" });
process.exit(result.status ?? 1);
NODE
fi

if [ "${1:-}" = "dev" ] && [ "${2:-}" = "--port" ] && [ -n "${3:-}" ]; then
  exec node - "$3" <<'NODE'
const http = require("node:http");
const port = Number(process.argv[2]);
http.createServer((_request, response) => {
  response.writeHead(200, { "content-type": "text/plain" });
  response.end("ok");
}).listen(port, "127.0.0.1");
NODE
fi

printf 'unexpected bun invocation\n' >&2
exit 2
BUN
chmod +x "$TMP_ROOT/bin/bun"

run_verify() {
  PATH="$TMP_ROOT/bin:$PATH" bash "$PLUGIN_ROOT/scripts/verify-app.sh" "$1"
}

run_verify "$FIXTURES/valid-app"

if run_verify "$FIXTURES/dead-button-app"; then
  echo "expected dead-button fixture to fail" >&2
  exit 1
fi
grep -q '"code": "dead_or_placeholder_control"' \
  "$FIXTURES/dead-button-app/review/verification.json"

if run_verify "$FIXTURES/client-ai-import-app"; then
  echo "expected client-ai-import fixture to fail" >&2
  exit 1
fi
grep -q '"code": "client_ai_import"' \
  "$FIXTURES/client-ai-import-app/review/verification.json"

PREVIEW_URL="$(
  PATH="$TMP_ROOT/bin:$PATH" \
    bash "$PLUGIN_ROOT/scripts/start-preview.sh" "$FIXTURES/valid-app" 3088
)"
case "$PREVIEW_URL" in
  http://localhost:30??) ;;
  *)
    echo "unexpected preview URL: $PREVIEW_URL" >&2
    exit 1
    ;;
esac
test -s "$FIXTURES/valid-app/.eazo-factory-preview.pid"
test -f "$FIXTURES/valid-app/.eazo-factory-preview.log"
PREVIEW_PID="$(cat "$FIXTURES/valid-app/.eazo-factory-preview.pid")"
kill "$PREVIEW_PID" 2>/dev/null || true
rm -f \
  "$FIXTURES/valid-app/.eazo-factory-preview.pid" \
  "$FIXTURES/valid-app/.eazo-factory-preview.log"

echo "verification test passed"
