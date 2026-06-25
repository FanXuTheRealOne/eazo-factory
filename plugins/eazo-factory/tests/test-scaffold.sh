#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/eazo-scaffold.XXXXXX")"

cleanup() {
  rm -rf "$TMP_ROOT"
}

trap cleanup EXIT

FAKE_BIN="$TMP_ROOT/bin"
FAKE_STARTER="$TMP_ROOT/fake-starter"
OUTPUT_ROOT="$TMP_ROOT/output"

mkdir -p "$FAKE_BIN" "$FAKE_STARTER/src/app" "$FAKE_STARTER/demo-dir" "$OUTPUT_ROOT"

cat >"$FAKE_BIN/bun" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

if [ "${1:-}" != "run" ] || [ -z "${2:-}" ]; then
  printf 'unexpected bun invocation\n' >&2
  exit 1
fi

script_name="$2"

script_command="$(
  node - "$PWD/package.json" "$script_name" <<'NODE'
const fs = require("node:fs");

const packageJsonPath = process.argv[2];
const scriptName = process.argv[3];
const pkg = JSON.parse(fs.readFileSync(packageJsonPath, "utf8"));
const command = pkg.scripts && pkg.scripts[scriptName];
if (typeof command !== "string" || command.length === 0) {
  process.exit(1);
}
process.stdout.write(command);
NODE
)"

exec /bin/sh -c "$script_command"
EOF
chmod +x "$FAKE_BIN/bun"

cat >"$FAKE_STARTER/package.json" <<'EOF'
{
  "name": "nextjs-template",
  "private": true,
  "packageManager": "bun@1.3.9",
  "scripts": {
    "cleanup:demo": "rm -rf demo-only.txt demo-dir"
  }
}
EOF

cat >"$FAKE_STARTER/AGENTS.md" <<'EOF'
# Starter instructions

Keep this file unchanged.
EOF

cat >"$FAKE_STARTER/.env.example" <<'EOF'
EAZO_API_URL=
EOF

cat >"$FAKE_STARTER/src/app/layout.tsx" <<'EOF'
export default function RootLayout({ children }) {
  return children;
}
EOF

printf 'demo file\n' >"$FAKE_STARTER/demo-only.txt"
printf 'nested demo\n' >"$FAKE_STARTER/demo-dir/example.txt"

git -C "$FAKE_STARTER" init >/dev/null 2>&1
git -C "$FAKE_STARTER" branch -M main >/dev/null 2>&1
git -C "$FAKE_STARTER" config user.name "Test User"
git -C "$FAKE_STARTER" config user.email "test@example.com"
git -C "$FAKE_STARTER" add .
git -C "$FAKE_STARTER" commit -m "starter" >/dev/null 2>&1

PATH="$FAKE_BIN:$PATH" \
EAZO_STARTER_PATH="$FAKE_STARTER" \
bash "$PLUGIN_ROOT/scripts/scaffold-app.sh" "$OUTPUT_ROOT" "test-app"

test -f "$OUTPUT_ROOT/test-app/package.json"
test -f "$OUTPUT_ROOT/test-app/factory-run.json"
test -f "$OUTPUT_ROOT/test-app/AGENTS.md"
test -d "$OUTPUT_ROOT/test-app/.git"
test -d "$OUTPUT_ROOT/test-app/design"
test -d "$OUTPUT_ROOT/test-app/review"
test ! -e "$OUTPUT_ROOT/test-app/demo-only.txt"
test ! -e "$OUTPUT_ROOT/test-app/demo-dir"
test -f "$FAKE_STARTER/demo-only.txt"
test -d "$FAKE_STARTER/demo-dir"
test "$(cat "$OUTPUT_ROOT/test-app/AGENTS.md")" = "$(cat "$FAKE_STARTER/AGENTS.md")"
test "$(git -C "$OUTPUT_ROOT/test-app" remote | wc -l | tr -d ' ')" = "0"

node - "$OUTPUT_ROOT/test-app/package.json" "$OUTPUT_ROOT/test-app/factory-run.json" <<'NODE'
const fs = require("node:fs");

const packageJson = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
const run = JSON.parse(fs.readFileSync(process.argv[3], "utf8"));

if (packageJson.name !== "test-app") throw new Error("package name not rewritten");
if (!run.starter || !run.starter.commit) throw new Error("missing starter commit");
if (run.starter.source !== "https://github.com/EazoAI/eazo-creator-nextjs-template.git") {
  throw new Error("wrong starter source");
}
if (run.starter.branch !== "main") throw new Error("wrong starter branch");
if (run.stage !== "scaffolded") throw new Error("wrong stage");
if (run.status !== "in_progress") throw new Error("wrong status");
if (typeof run.started_at !== "string" || typeof run.updated_at !== "string") {
  throw new Error("missing timestamps");
}
NODE

echo "scaffold test passed"
