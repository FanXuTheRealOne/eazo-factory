#!/usr/bin/env bash

die() { printf 'error: %s\n' "$*" >&2; exit 1; }

require_command() { command -v "$1" >/dev/null 2>&1 || die "missing command: $1"; }

is_valid_slug() { [[ "$1" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; }

utc_now() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }
