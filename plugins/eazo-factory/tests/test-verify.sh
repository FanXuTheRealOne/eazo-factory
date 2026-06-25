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
cp -R "$FIXTURES/valid-app" "$WORK_FIXTURES/extra-control-app"
cp -R "$FIXTURES/valid-app" "$WORK_FIXTURES/comment-auth-app"
cp -R "$FIXTURES/valid-app" "$WORK_FIXTURES/transitive-ai-route-app"
cp -R "$FIXTURES/valid-app" "$WORK_FIXTURES/fake-template-shell-app"
cp -R "$FIXTURES/valid-app" "$WORK_FIXTURES/empty-map-app"
cp -R "$FIXTURES/valid-app" "$WORK_FIXTURES/authenticated-ai-route-app"

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
  "extra-control-app",
  "comment-auth-app",
  "transitive-ai-route-app",
  "fake-template-shell-app",
  "empty-map-app",
  "authenticated-ai-route-app",
]) {
  fs.writeFileSync(path.join(root, app, "design/ui-reference.png"), png);
}
fs.writeFileSync(
  path.join(root, "invalid-image-app", "design/ui-reference.png"),
  Buffer.concat([
    Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]),
    Buffer.alloc(37),
  ]),
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
fs.writeFileSync(
  path.join(root, "extra-control-app", "src/app/page.tsx"),
  '"use client";\nexport default function Page() { return <><button data-control-id="home-start-session" onClick={() => {}}>Begin</button><button onClick={() => alert("extra")}>Extra</button></>; }\n',
);
const commentRouteDir = path.join(root, "comment-auth-app", "src/app/api/analyze");
fs.mkdirSync(commentRouteDir, { recursive: true });
fs.writeFileSync(
  path.join(commentRouteDir, "route.ts"),
  'import { ai } from "@eazo/sdk";\n// requireAuth();\nexport async function POST() { return Response.json(await ai.chat({ messages: [] })); }\n',
);
const transitiveRoot = path.join(root, "transitive-ai-route-app", "src");
const transitiveRouteDir = path.join(transitiveRoot, "app/api/analyze");
fs.mkdirSync(transitiveRouteDir, { recursive: true });
fs.mkdirSync(path.join(transitiveRoot, "lib"), { recursive: true });
fs.writeFileSync(
  path.join(transitiveRoot, "lib/ai-helper.ts"),
  'import { ai } from "@eazo/sdk";\nexport const runAi = () => ai.chat({ messages: [] });\n',
);
fs.writeFileSync(
  path.join(transitiveRouteDir, "route.ts"),
  'import { runAi } from "@/lib/ai-helper";\nexport async function POST() { return Response.json(await runAi()); }\n',
);
fs.writeFileSync(
  path.join(root, "fake-template-shell-app", "src/app/layout.tsx"),
  'const EazoProvider = ({ children }) => children;\nconst I18nProvider = ({ children }) => children;\nconst UserSyncEffect = () => null;\nconst title = process.env.NEXT_PUBLIC_APP_TITLE;\nconst description = process.env.NEXT_PUBLIC_APP_DESCRIPTION;\nexport default function RootLayout({ children }) { return <I18nProvider><EazoProvider><UserSyncEffect />{children}</EazoProvider></I18nProvider>; }\n',
);
fs.writeFileSync(
  path.join(root, "empty-map-app", "design/interaction-map.json"),
  JSON.stringify({ schema_version: "1.0", controls: [] }, null, 2) + "\n",
);
const authenticatedRouteDir = path.join(root, "authenticated-ai-route-app", "src/app/api/analyze");
fs.mkdirSync(authenticatedRouteDir, { recursive: true });
fs.writeFileSync(
  path.join(authenticatedRouteDir, "route.ts"),
  'import { ai, requireAuth } from "@eazo/sdk";\nexport async function POST(request: Request) { await requireAuth(request); return Response.json(await ai.chat({ messages: [] })); }\n',
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
run_verify "$WORK_FIXTURES/authenticated-ai-route-app"

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

if run_verify "$WORK_FIXTURES/extra-control-app"; then
  echo "expected extra-control fixture to fail" >&2
  exit 1
fi
grep -q '"code": "unmapped_source_control"' \
  "$WORK_FIXTURES/extra-control-app/review/verification.json"

if run_verify "$WORK_FIXTURES/comment-auth-app"; then
  echo "expected comment-only auth fixture to fail" >&2
  exit 1
fi
grep -q '"code": "unguarded_ai_route"' \
  "$WORK_FIXTURES/comment-auth-app/review/verification.json"

if run_verify "$WORK_FIXTURES/transitive-ai-route-app"; then
  echo "expected transitive AI route fixture to fail" >&2
  exit 1
fi
grep -q '"code": "unguarded_ai_route"' \
  "$WORK_FIXTURES/transitive-ai-route-app/review/verification.json"

if run_verify "$WORK_FIXTURES/fake-template-shell-app"; then
  echo "expected fake template shell fixture to fail" >&2
  exit 1
fi
grep -q '"code": "missing_template_shell"' \
  "$WORK_FIXTURES/fake-template-shell-app/review/verification.json"

if run_verify "$WORK_FIXTURES/empty-map-app"; then
  echo "expected empty interaction map fixture to fail" >&2
  exit 1
fi
grep -q '"code": "empty_interaction_map"' \
  "$WORK_FIXTURES/empty-map-app/review/verification.json"

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
audit.entries[0].acceptance_reference = "product-spec.features[session].acceptance[99]";
audit.entries[0].acceptance_text = "Made up acceptance";
fs.writeFileSync(auditPath, JSON.stringify(audit, null, 2) + "\n");
NODE
if bash "$PLUGIN_ROOT/scripts/validate-review.sh" "$WORK_FIXTURES/valid-app" --require-pass; then
  echo "expected bogus acceptance reference to fail the review gate" >&2
  exit 1
fi

cp \
  "$FIXTURES/valid-app/review/control-audit.json" \
  "$WORK_FIXTURES/valid-app/review/control-audit.json"
cp \
  "$FIXTURES/valid-app/review/review.json" \
  "$WORK_FIXTURES/valid-app/review/review.json"
node - "$WORK_FIXTURES/valid-app/review/review.json" <<'NODE'
const fs = require("node:fs");
const reviewPath = process.argv[2];
const review = JSON.parse(fs.readFileSync(reviewPath, "utf8"));
review.findings = [{
  severity: "important",
  summary: "Important defect",
  evidence: "Observed during review",
  required_action: "Fix it",
}];
fs.writeFileSync(reviewPath, JSON.stringify(review, null, 2) + "\n");
NODE
if bash "$PLUGIN_ROOT/scripts/validate-review.sh" "$WORK_FIXTURES/valid-app" --require-pass; then
  echo "expected important finding to fail the review gate" >&2
  exit 1
fi

cp \
  "$FIXTURES/valid-app/review/review.json" \
  "$WORK_FIXTURES/valid-app/review/review.json"
node - "$WORK_FIXTURES/valid-app/review/review.json" <<'NODE'
const fs = require("node:fs");
const reviewPath = process.argv[2];
const review = JSON.parse(fs.readFileSync(reviewPath, "utf8"));
review.schema_version = "9.9";
fs.writeFileSync(reviewPath, JSON.stringify(review, null, 2) + "\n");
NODE
if bash "$PLUGIN_ROOT/scripts/validate-review.sh" "$WORK_FIXTURES/valid-app" --require-pass; then
  echo "expected invalid review schema version to fail the review gate" >&2
  exit 1
fi

cp \
  "$FIXTURES/valid-app/review/review.json" \
  "$WORK_FIXTURES/valid-app/review/review.json"
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
