#!/usr/bin/env bash
set -euo pipefail

PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/eazo-scaffold.XXXXXX")"

cleanup() {
  rm -rf "$TMP_ROOT"
}

trap cleanup EXIT

FAKE_BIN="$TMP_ROOT/bin"
mkdir -p "$FAKE_BIN"

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

create_fake_starter() {
  starter_dir="$1"
  cleanup_command="$2"

  mkdir -p "$starter_dir/src/app" "$starter_dir/demo-dir"

  cat >"$starter_dir/package.json" <<EOF
{
  "name": "nextjs-template",
  "private": true,
  "packageManager": "bun@1.3.9",
  "scripts": {
    "cleanup:demo": $cleanup_command
  }
}
EOF

  cat >"$starter_dir/AGENTS.md" <<'EOF'
# Starter instructions

Keep this file unchanged.
EOF

  cat >"$starter_dir/.env.example" <<'EOF'
EAZO_API_URL=
EOF

  cat >"$starter_dir/src/app/layout.tsx" <<'EOF'
export default function RootLayout({ children }) {
  return children;
}
EOF

  printf 'demo file\n' >"$starter_dir/demo-only.txt"
  printf 'nested demo\n' >"$starter_dir/demo-dir/example.txt"

  git -C "$starter_dir" init >/dev/null 2>&1
  git -C "$starter_dir" branch -M main >/dev/null 2>&1
  git -C "$starter_dir" config user.name "Test User"
  git -C "$starter_dir" config user.email "test@example.com"
  git -C "$starter_dir" add .
  git -C "$starter_dir" commit -m "starter" >/dev/null 2>&1
}

assert_run_state() {
  run_path="$1"
  expected_status="$2"
  expected_stage="$3"

  node - "$run_path" "$expected_status" "$expected_stage" <<'NODE'
const fs = require("node:fs");

const run = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
const expectedStatus = process.argv[3];
const expectedStage = process.argv[4];

if (!run.starter || !run.starter.commit) throw new Error("missing starter commit");
if (run.starter.source !== "https://github.com/EazoAI/eazo-creator-nextjs-template.git") {
  throw new Error("wrong starter source");
}
if (run.starter.branch !== "main") throw new Error("wrong starter branch");
if (run.status !== expectedStatus) throw new Error("wrong status");
if (run.stage !== expectedStage) throw new Error("wrong stage");
if (typeof run.started_at !== "string" || typeof run.updated_at !== "string") {
  throw new Error("missing timestamps");
}
NODE
}

assert_package_name() {
  package_json_path="$1"
  expected_name="$2"

  node - "$package_json_path" "$expected_name" <<'NODE'
const fs = require("node:fs");

const packageJson = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
const expectedName = process.argv[3];

if (packageJson.name !== expectedName) throw new Error("package name not rewritten");
NODE
}

run_scaffold() {
  starter_dir="$1"
  output_root="$2"
  slug="$3"

  PATH="$FAKE_BIN:$PATH" \
  EAZO_STARTER_PATH="$starter_dir" \
  bash "$PLUGIN_ROOT/scripts/scaffold-app.sh" "$output_root" "$slug"
}

run_scaffold_from_cwd() {
  starter_dir="$1"
  cwd="$2"
  output_root="$3"
  slug="$4"

  (
    cd "$cwd"
    PATH="$FAKE_BIN:$PATH" \
    EAZO_STARTER_PATH="$starter_dir" \
    bash "$PLUGIN_ROOT/scripts/scaffold-app.sh" "$output_root" "$slug"
  )
}

assert_empty_dir() {
  dir_path="$1"
  test -d "$dir_path"
  test -z "$(ls -A "$dir_path")"
}

HAPPY_STARTER="$TMP_ROOT/fake-starter-happy"
HAPPY_OUTPUT_ROOT="$TMP_ROOT/output-happy"
create_fake_starter "$HAPPY_STARTER" '"rm -rf demo-only.txt demo-dir"'
mkdir -p "$HAPPY_OUTPUT_ROOT"

run_scaffold "$HAPPY_STARTER" "$HAPPY_OUTPUT_ROOT" "test-app"

test -f "$HAPPY_OUTPUT_ROOT/test-app/package.json"
test -f "$HAPPY_OUTPUT_ROOT/test-app/factory-run.json"
test -f "$HAPPY_OUTPUT_ROOT/test-app/AGENTS.md"
test -d "$HAPPY_OUTPUT_ROOT/test-app/.git"
test -d "$HAPPY_OUTPUT_ROOT/test-app/design"
test -d "$HAPPY_OUTPUT_ROOT/test-app/review"
test ! -e "$HAPPY_OUTPUT_ROOT/test-app/demo-only.txt"
test ! -e "$HAPPY_OUTPUT_ROOT/test-app/demo-dir"
test -f "$HAPPY_STARTER/demo-only.txt"
test -d "$HAPPY_STARTER/demo-dir"
test "$(cat "$HAPPY_OUTPUT_ROOT/test-app/AGENTS.md")" = "$(cat "$HAPPY_STARTER/AGENTS.md")"
test "$(git -C "$HAPPY_OUTPUT_ROOT/test-app" remote | wc -l | tr -d ' ')" = "0"
assert_package_name "$HAPPY_OUTPUT_ROOT/test-app/package.json" "test-app"
assert_run_state "$HAPPY_OUTPUT_ROOT/test-app/factory-run.json" "in_progress" "scaffolded"

RELATIVE_STARTER="$TMP_ROOT/fake-starter-relative"
RELATIVE_CWD="$TMP_ROOT/relative-cwd"
RELATIVE_OUTPUT_ROOT="relative-output"
RELATIVE_DESTINATION="$RELATIVE_CWD/$RELATIVE_OUTPUT_ROOT/relative-app"
create_fake_starter "$RELATIVE_STARTER" '"printf '\''relative cleanup marker\n'\''"'
mkdir -p "$RELATIVE_CWD"

run_scaffold_from_cwd "$RELATIVE_STARTER" "$RELATIVE_CWD" "$RELATIVE_OUTPUT_ROOT" "relative-app"

test -f "$RELATIVE_DESTINATION/package.json"
test -f "$RELATIVE_DESTINATION/factory-run.json"
test -f "$RELATIVE_DESTINATION/review/cleanup-demo.log"
grep -q "relative cleanup marker" "$RELATIVE_DESTINATION/review/cleanup-demo.log"
assert_package_name "$RELATIVE_DESTINATION/package.json" "relative-app"
assert_run_state "$RELATIVE_DESTINATION/factory-run.json" "in_progress" "scaffolded"

SYMLINK_STARTER="$TMP_ROOT/fake-starter-symlink"
SYMLINK_OUTPUT_ROOT="$TMP_ROOT/output-symlink"
SYMLINK_TARGET="$TMP_ROOT/external-target"
SYMLINK_LOG="$TMP_ROOT/symlink-command.log"
create_fake_starter "$SYMLINK_STARTER" '"rm -rf demo-only.txt demo-dir"'
mkdir -p "$SYMLINK_OUTPUT_ROOT" "$SYMLINK_TARGET"
ln -s "$SYMLINK_TARGET" "$SYMLINK_OUTPUT_ROOT/symlink-app"

if run_scaffold "$SYMLINK_STARTER" "$SYMLINK_OUTPUT_ROOT" "symlink-app" >"$SYMLINK_LOG" 2>&1; then
  echo "expected symlink destination scaffold to fail" >&2
  exit 1
fi

grep -q "symlink" "$SYMLINK_LOG"
test -L "$SYMLINK_OUTPUT_ROOT/symlink-app"
assert_empty_dir "$SYMLINK_TARGET"

FAIL_STARTER="$TMP_ROOT/fake-starter-cleanup-fail"
FAIL_OUTPUT_ROOT="$TMP_ROOT/output-cleanup-fail"
FAIL_LOG="$TMP_ROOT/cleanup-command.log"
create_fake_starter "$FAIL_STARTER" '"printf '\''cleanup stdout marker\n'\''; printf '\''cleanup stderr marker\n'\'' >&2; exit 17"'
mkdir -p "$FAIL_OUTPUT_ROOT"

if run_scaffold "$FAIL_STARTER" "$FAIL_OUTPUT_ROOT" "broken-app" >"$FAIL_LOG" 2>&1; then
  echo "expected cleanup failure scaffold to fail" >&2
  exit 1
fi

test -d "$FAIL_OUTPUT_ROOT/broken-app/.git"
test -f "$FAIL_OUTPUT_ROOT/broken-app/factory-run.json"
test -f "$FAIL_OUTPUT_ROOT/broken-app/review/cleanup-demo.log"
grep -q "cleanup stdout marker" "$FAIL_LOG"
grep -q "cleanup stderr marker" "$FAIL_LOG"
grep -q "cleanup stdout marker" "$FAIL_OUTPUT_ROOT/broken-app/review/cleanup-demo.log"
grep -q "cleanup stderr marker" "$FAIL_OUTPUT_ROOT/broken-app/review/cleanup-demo.log"
assert_package_name "$FAIL_OUTPUT_ROOT/broken-app/package.json" "broken-app"
assert_run_state "$FAIL_OUTPUT_ROOT/broken-app/factory-run.json" "failed" "cleanup_demo_failed"

echo "scaffold test passed"
