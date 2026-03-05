#!/usr/bin/env bash
# Shared helpers for doa-framework BATS test suites.

REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
SCRIPTS_DIR="$REPO_ROOT/project/scripts"

# Create an isolated temporary git repo and echo its path.
# Callers are responsible for cleanup (rm -rf).
make_git_repo() {
  local d
  d="$(mktemp -d)"
  git -C "$d" init -q
  git -C "$d" config user.email "test@test.local"
  git -C "$d" config user.name "Test"
  touch "$d/.keep"
  git -C "$d" add .keep
  git -C "$d" commit -q -m "init"
  echo "$d"
}

# Append one or more context entries to FILE.
# Usage: write_context_entries FILE body1 [body2 ...]
write_context_entries() {
  local file="$1"; shift
  local sep=""
  for body in "$@"; do
    printf '%s---\ndate: 2024-01-01T00:00:00+0000\nhash: testhash==\nagent: TestAgent\nmodel: test-model\n---\n\n%s\n\nEOF\n' \
      "$sep" "$body" >> "$file"
    sep=$'\n'
  done
}
