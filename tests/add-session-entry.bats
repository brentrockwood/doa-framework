#!/usr/bin/env bats
# Tests for project/scripts/add-session-entry

load 'test_helper'

# ── required-arg validation ───────────────────────────────────────────────────

@test "args: missing --agent exits 1 with error" {
  run bash -c "'$SCRIPTS_DIR/add-session-entry' --model 'M' --output '$BATS_TEST_TMPDIR/out.md' 'body' 2>&1"
  [[ "$status" -eq 1 ]]
  [[ "$output" == *"agent"* ]]
}

@test "args: missing --model exits 1 with error" {
  run bash -c "'$SCRIPTS_DIR/add-session-entry' --agent 'A' --output '$BATS_TEST_TMPDIR/out.md' 'body' 2>&1"
  [[ "$status" -eq 1 ]]
  [[ "$output" == *"model"* ]]
}

@test "args: invalid --type exits 1 with error" {
  run bash -c "'$SCRIPTS_DIR/add-session-entry' --agent 'A' --model 'M' --type 'badtype' --output '$BATS_TEST_TMPDIR/out.md' 'body' 2>&1"
  [[ "$status" -eq 1 ]]
  [[ "$output" == *"type"* ]]
}

# ── body input methods ────────────────────────────────────────────────────────

@test "body: from positional argument" {
  local out="$BATS_TEST_TMPDIR/out.md"

  "$SCRIPTS_DIR/add-session-entry" --agent "A" --model "M" --output "$out" "positional body"

  grep -q "positional body" "$out"
}

@test "body: from --file" {
  local out="$BATS_TEST_TMPDIR/out.md"
  local body_file="$BATS_TEST_TMPDIR/body.txt"
  echo "file body content" > "$body_file"

  "$SCRIPTS_DIR/add-session-entry" --agent "A" --model "M" --output "$out" --file "$body_file"

  grep -q "file body content" "$out"
}

@test "body: from stdin" {
  local out="$BATS_TEST_TMPDIR/out.md"

  echo "stdin body content" | "$SCRIPTS_DIR/add-session-entry" --agent "A" --model "M" --output "$out"

  grep -q "stdin body content" "$out"
}

@test "body: empty positional arg exits 1" {
  run bash -c "'$SCRIPTS_DIR/add-session-entry' --agent 'A' --model 'M' --output '$BATS_TEST_TMPDIR/out.md' '' 2>&1"
  [[ "$status" -eq 1 ]]
}

@test "body: empty stdin exits 1" {
  run bash -c "'$SCRIPTS_DIR/add-session-entry' --agent 'A' --model 'M' --output '$BATS_TEST_TMPDIR/out.md' < /dev/null 2>&1"
  [[ "$status" -eq 1 ]]
}

@test "body: --file not found exits 1 with error" {
  run bash -c "'$SCRIPTS_DIR/add-session-entry' --agent 'A' --model 'M' --output '$BATS_TEST_TMPDIR/out.md' --file '$BATS_TEST_TMPDIR/no-such.txt' 2>&1"
  [[ "$status" -eq 1 ]]
  [[ "$output" == *"not found"* ]] || [[ "$output" == *"Error"* ]]
}

# ── file initialisation ───────────────────────────────────────────────────────

@test "init: creates output file with header when it does not exist" {
  local out="$BATS_TEST_TMPDIR/new_session.md"

  "$SCRIPTS_DIR/add-session-entry" --agent "A" --model "M" --output "$out" "first entry"

  [[ -f "$out" ]]
  # File should have been initialized with the standard header
  grep -q "AI Session Transcript" "$out"
}

@test "init: second call appends without reinitialising header" {
  local out="$BATS_TEST_TMPDIR/session.md"

  "$SCRIPTS_DIR/add-session-entry" --agent "A" --model "M" --output "$out" "first entry"
  "$SCRIPTS_DIR/add-session-entry" --agent "A" --model "M" --output "$out" "second entry"

  # Header should appear exactly once
  local header_count
  header_count=$(grep -c "AI Session Transcript" "$out")
  [[ "$header_count" -eq 1 ]]
  grep -q "first entry" "$out"
  grep -q "second entry" "$out"
}

# ── entry format ──────────────────────────────────────────────────────────────

@test "format: entry contains type, agent, model, and date" {
  local out="$BATS_TEST_TMPDIR/out.md"

  "$SCRIPTS_DIR/add-session-entry" --agent "MyAgent" --model "my-model" --type "summary" --output "$out" "body text"

  grep -q "summary" "$out"
  grep -q "MyAgent" "$out"
  grep -q "my-model" "$out"
  # Date field in the heading line
  grep -qE "\[20[0-9]{2}-" "$out"
}

@test "format: default type is prompt" {
  local out="$BATS_TEST_TMPDIR/out.md"

  "$SCRIPTS_DIR/add-session-entry" --agent "A" --model "M" --output "$out" "body"

  grep -q "prompt" "$out"
}

@test "format: all three valid types are accepted" {
  local out="$BATS_TEST_TMPDIR/out.md"

  "$SCRIPTS_DIR/add-session-entry" --agent "A" --model "M" --type "prompt"   --output "$out" "p"
  "$SCRIPTS_DIR/add-session-entry" --agent "A" --model "M" --type "response" --output "$out" "r"
  "$SCRIPTS_DIR/add-session-entry" --agent "A" --model "M" --type "summary"  --output "$out" "s"

  grep -q "prompt"   "$out"
  grep -q "response" "$out"
  grep -q "summary"  "$out"
}
