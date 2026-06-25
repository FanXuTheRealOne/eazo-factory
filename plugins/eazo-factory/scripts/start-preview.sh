#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=plugins/eazo-factory/scripts/lib/common.sh
. "$SCRIPT_DIR/lib/common.sh"

APP_DIR="${1:-}"
START_PORT="${2:-3000}"

[ -n "$APP_DIR" ] || die "usage: start-preview.sh APP_DIR [START_PORT]"
[ -d "$APP_DIR" ] || die "app directory does not exist: $APP_DIR"
case "$START_PORT" in
  ''|*[!0-9]*) die "start port must be an integer" ;;
esac
[ "$START_PORT" -le 3099 ] || die "start port must be at most 3099"

APP_DIR="$(cd "$APP_DIR" && pwd -P)"
require_command bun
require_command node

PORT="$(
  node - "$START_PORT" <<'NODE'
const net = require("node:net");
const start = Number(process.argv[2]);

function isFree(port) {
  return new Promise((resolve) => {
    const server = net.createServer();
    server.unref();
    server.once("error", () => resolve(false));
    server.listen({ host: "127.0.0.1", port }, () => {
      server.close(() => resolve(true));
    });
  });
}

(async () => {
  for (let port = start; port <= 3099; port += 1) {
    if (await isFree(port)) {
      process.stdout.write(String(port));
      return;
    }
  }
  process.exit(1);
})();
NODE
)" || die "no free preview port between $START_PORT and 3099"

LOG_PATH="$APP_DIR/.eazo-factory-preview.log"
PID_PATH="$APP_DIR/.eazo-factory-preview.pid"

(
  cd "$APP_DIR"
  nohup bun dev --port "$PORT" >"$LOG_PATH" 2>&1 &
  printf '%s\n' "$!" >"$PID_PATH"
)

PID="$(cat "$PID_PATH")"
HEALTHY=0
ATTEMPT=0
while [ "$ATTEMPT" -lt 60 ]; do
  if ! kill -0 "$PID" 2>/dev/null; then
    break
  fi
  if node - "$PORT" <<'NODE' >/dev/null 2>&1
const http = require("node:http");
const port = Number(process.argv[2]);
const request = http.get(
  { host: "127.0.0.1", port, path: "/", timeout: 1000 },
  (response) => {
    response.resume();
    process.exit(response.statusCode >= 200 && response.statusCode < 400 ? 0 : 1);
  },
);
request.on("timeout", () => request.destroy(new Error("timeout")));
request.on("error", () => process.exit(1));
NODE
  then
    HEALTHY=1
    break
  fi
  ATTEMPT=$((ATTEMPT + 1))
  sleep 1
done

if [ "$HEALTHY" -ne 1 ]; then
  kill "$PID" 2>/dev/null || true
  rm -f "$PID_PATH"
  die "preview failed to become healthy; see $LOG_PATH"
fi

printf 'http://localhost:%s\n' "$PORT"
