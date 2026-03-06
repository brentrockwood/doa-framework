#!/usr/bin/env bats
# Tests for project/scripts/notify
# curl is stubbed via a fake binary injected at the front of PATH.
# No real Telegram credentials are required.

load 'test_helper'

setup() {
  # Create a per-test bin dir for curl stubs
  export STUB_BIN="$BATS_TEST_TMPDIR/bin"
  mkdir -p "$STUB_BIN"
}

# Helper: write a stub curl that exits 0 and prints a fixed response to stdout.
stub_curl() {
  local response="$1"
  cat > "$STUB_BIN/curl" << EOF
#!/usr/bin/env bash
printf '%s' '$response'
EOF
  chmod +x "$STUB_BIN/curl"
}

# ── no-args guard ─────────────────────────────────────────────────────────────

@test "no-args: exits 1 with usage on stderr" {
  run bash -c "PATH='$STUB_BIN:$PATH' '$SCRIPTS_DIR/notify' 2>&1"
  [[ "$status" -eq 1 ]]
  [[ "$output" == *"Usage"* ]] || [[ "$output" == *"usage"* ]]
}

# ── mocked success path ───────────────────────────────────────────────────────

@test "success: exits 0 when Telegram API returns ok:true" {
  stub_curl '{"ok":true}'

  run bash -c "PATH='$STUB_BIN:$PATH' TELEGRAM_BOT_TOKEN=fake TELEGRAM_BOT_CHATID=fake '$SCRIPTS_DIR/notify' 'hello'"

  [[ "$status" -eq 0 ]]
}

# ── mocked API-error path ─────────────────────────────────────────────────────

@test "api-error: exits 1 when Telegram API returns ok:false" {
  stub_curl '{"ok":false,"description":"bad token"}'

  run bash -c "PATH='$STUB_BIN:$PATH' TELEGRAM_BOT_TOKEN=fake TELEGRAM_BOT_CHATID=fake '$SCRIPTS_DIR/notify' 'hello' 2>&1"

  [[ "$status" -eq 1 ]]
  [[ "$output" == *"bad token"* ]]
}

# ── network failure ───────────────────────────────────────────────────────────

@test "network-failure: exits 1 when curl returns empty response" {
  # Stub curl to produce no output (simulates timeout or network error)
  cat > "$STUB_BIN/curl" << 'EOF'
#!/usr/bin/env bash
# produce no output
EOF
  chmod +x "$STUB_BIN/curl"

  run bash -c "PATH='$STUB_BIN:$PATH' TELEGRAM_BOT_TOKEN=fake TELEGRAM_BOT_CHATID=fake '$SCRIPTS_DIR/notify' 'hello' 2>&1"

  [[ "$status" -eq 1 ]]
  [[ "$output" == *"No response"* ]] || [[ "$output" == *"Error"* ]]
}
