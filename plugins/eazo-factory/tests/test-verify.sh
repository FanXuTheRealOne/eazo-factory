#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURES="$PLUGIN_ROOT/tests/fixtures"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/eazo-verify.XXXXXX")"

cleanup() {
  rm -rf "$TMP_ROOT"
}

trap cleanup EXIT

WORK_FIXTURES="$TMP_ROOT/fixtures"
mkdir -p "$WORK_FIXTURES"
cp -R "$FIXTURES/valid-app" "$WORK_FIXTURES/valid-app"
cp -R "$FIXTURES/dead-button-app" "$WORK_FIXTURES/dead-button-app"
cp -R "$FIXTURES/client-ai-import-app" "$WORK_FIXTURES/client-ai-import-app"
cp -R "$FIXTURES/valid-app" "$WORK_FIXTURES/noninteractive-control-app"
cp -R "$FIXTURES/valid-app" "$WORK_FIXTURES/unguarded-ai-route-app"
cp -R "$FIXTURES/valid-app" "$WORK_FIXTURES/invalid-image-app"

node - "$WORK_FIXTURES" <<'NODE'
const fs = require("node:fs");
const path = require("node:path");
const root = process.argv[2];
const png = Buffer.from(
  "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=",
  "base64",
);
for (const app of [
  "valid-app",
  "dead-button-app",
  "client-ai-import-app",
  "noninteractive-control-app",
  "unguarded-ai-route-app",
]) {
  fs.writeFileSync(path.join(root, app, "design/ui-reference.png"), png);
}
fs.writeFileSync(
  path.join(root, "invalid-image-app", "design/ui-reference.png"),
  "not a png\n",
);
fs.writeFileSync(
  path.join(root, "noninteractive-control-app", "src/app/page.tsx"),
  'export default function Page() { return <main data-control-id="home-start-session">Fake</main>; }\n',
);
const routeDir = path.join(root, "unguarded-ai-route-app", "src/app/api/analyze");
fs.mkdirSync(routeDir, { recursive: true });
fs.writeFileSync(
  path.join(routeDir, "route.ts"),
  'import { ai } from "@eazo/sdk";\nexport async function POST() { return Response.json(await ai.chat({ messages: [] })); }\n',
);
NODE

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

run_verify "$WORK_FIXTURES/valid-app"

if run_verify "$WORK_FIXTURES/dead-button-app"; then
  echo "expected dead-button fixture to fail" >&2
  exit 1
fi
grep -q '"code": "dead_or_placeholder_control"' \
  "$WORK_FIXTURES/dead-button-app/review/verification.json"

if run_verify "$WORK_FIXTURES/client-ai-import-app"; then
  echo "expected client-ai-import fixture to fail" >&2
  exit 1
fi
grep -q '"code": "client_ai_import"' \
  "$WORK_FIXTURES/client-ai-import-app/review/verification.json"

if run_verify "$WORK_FIXTURES/noninteractive-control-app"; then
  echo "expected noninteractive control fixture to fail" >&2
  exit 1
fi
grep -q '"code": "noninteractive_control_mapping"' \
  "$WORK_FIXTURES/noninteractive-control-app/review/verification.json"

if run_verify "$WORK_FIXTURES/unguarded-ai-route-app"; then
  echo "expected unguarded AI route fixture to fail" >&2
  exit 1
fi
grep -q '"code": "unguarded_ai_route"' \
  "$WORK_FIXTURES/unguarded-ai-route-app/review/verification.json"

if run_verify "$WORK_FIXTURES/invalid-image-app"; then
  echo "expected invalid image fixture to fail" >&2
  exit 1
fi
grep -q '"code": "invalid_ui_reference"' \
  "$WORK_FIXTURES/invalid-image-app/review/verification.json"

bash "$PLUGIN_ROOT/scripts/validate-review.sh" "$WORK_FIXTURES/valid-app" --require-pass

node - "$WORK_FIXTURES/valid-app/review/control-audit.json" <<'NODE'
const fs = require("node:fs");
const auditPath = process.argv[2];
const audit = JSON.parse(fs.readFileSync(auditPath, "utf8"));
audit.entries[0].status = "fail";
fs.writeFileSync(auditPath, JSON.stringify(audit, null, 2) + "\n");
NODE
if bash "$PLUGIN_ROOT/scripts/validate-review.sh" "$WORK_FIXTURES/valid-app" --require-pass; then
  echo "expected failed control audit to fail the review gate" >&2
  exit 1
fi

cp \
  "$FIXTURES/valid-app/review/control-audit.json" \
  "$WORK_FIXTURES/valid-app/review/control-audit.json"
node - "$WORK_FIXTURES/valid-app/review/control-audit.json" <<'NODE'
const fs = require("node:fs");
const auditPath = process.argv[2];
const audit = JSON.parse(fs.readFileSync(auditPath, "utf8"));
audit.discovered_interactive_elements = [];
audit.coverage.discovered_interactive_count = 0;
audit.coverage.mapped_discovered_interactive_count = 0;
fs.writeFileSync(auditPath, JSON.stringify(audit, null, 2) + "\n");
NODE
if bash "$PLUGIN_ROOT/scripts/validate-review.sh" "$WORK_FIXTURES/valid-app" --require-pass; then
  echo "expected omitted discovered control to fail the review gate" >&2
  exit 1
fi

PREVIEW_URL="$(
  PATH="$TMP_ROOT/bin:$PATH" \
    bash "$PLUGIN_ROOT/scripts/start-preview.sh" "$WORK_FIXTURES/valid-app" 3088
)"
case "$PREVIEW_URL" in
  http://localhost:30??) ;;
  *)
    echo "unexpected preview URL: $PREVIEW_URL" >&2
    exit 1
    ;;
esac
test -s "$WORK_FIXTURES/valid-app/.eazo-factory-preview.pid"
test -f "$WORK_FIXTURES/valid-app/.eazo-factory-preview.log"
PREVIEW_PID="$(cat "$WORK_FIXTURES/valid-app/.eazo-factory-preview.pid")"
kill "$PREVIEW_PID" 2>/dev/null || true
rm -f \
  "$WORK_FIXTURES/valid-app/.eazo-factory-preview.pid" \
  "$WORK_FIXTURES/valid-app/.eazo-factory-preview.log"

echo "verification test passed"
