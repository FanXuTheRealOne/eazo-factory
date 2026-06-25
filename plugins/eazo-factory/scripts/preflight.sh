#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=plugins/eazo-factory/scripts/lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

CANONICAL_STARTER_URL="https://github.com/EazoAI/eazo-creator-nextjs-template.git"
CANONICAL_STARTER_BRANCH="main"

OUTPUT_ROOT="${1:-}"
SLUG="${2:-}"

[ -n "$OUTPUT_ROOT" ] || die "usage: preflight.sh OUTPUT_ROOT SLUG"
[ -n "$SLUG" ] || die "usage: preflight.sh OUTPUT_ROOT SLUG"

require_command git
require_command bun
require_command node
require_command codex

is_valid_slug "$SLUG" || die "invalid slug: $SLUG"

mkdir -p "$OUTPUT_ROOT" || die "unable to create output root: $OUTPUT_ROOT"
[ -d "$OUTPUT_ROOT" ] || die "output root is not a directory: $OUTPUT_ROOT"

WRITE_PROBE="$(mktemp "$OUTPUT_ROOT/.eazo-preflight-write-test.XXXXXX")" \
  || die "output root is not writable: $OUTPUT_ROOT"
rm -f "$WRITE_PROBE"

if [ -n "${EAZO_STARTER_PATH:-}" ]; then
  [ -d "$EAZO_STARTER_PATH/.git" ] || die "starter override missing .git: $EAZO_STARTER_PATH"
  [ -f "$EAZO_STARTER_PATH/AGENTS.md" ] || die "starter override missing AGENTS.md: $EAZO_STARTER_PATH"
  [ -f "$EAZO_STARTER_PATH/package.json" ] || die "starter override missing package.json: $EAZO_STARTER_PATH"
else
  git ls-remote --heads "$CANONICAL_STARTER_URL" "$CANONICAL_STARTER_BRANCH" >/dev/null 2>&1 \
    || die "unable to access starter: $CANONICAL_STARTER_URL"
fi

node - "$CANONICAL_STARTER_URL" "$OUTPUT_ROOT" <<'NODE'
const starterSource = process.argv[2];
const outputRoot = process.argv[3];

process.stdout.write(
  JSON.stringify({
    ok: true,
    starter_source: starterSource,
    output_root: outputRoot,
  }) + "\n",
);
NODE
