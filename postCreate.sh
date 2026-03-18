#!/usr/bin/env bash
# postCreate.sh — Runs once inside the devcontainer after creation.
# Called by devcontainer.json postCreateCommand.
#
# Installs (all stacks):
#   - dotfiles (brentrockwood/dotfiles)
#   - Shell tools your .zshrc expects: zoxide, fzf, starship, neovim, tmux
#   - trufflehog (for security scanning)
#   - gh CLI
#   - Node.js 22 LTS via nvm (required by AI CLIs)
#   - AI CLIs: claude, codex, coderabbit + Claude Code coderabbit plugin
#
# Installs (stack-specific, driven by STACK env var from devcontainer.json):
#   - python: uv, Python 3.12
#   - typescript: pnpm, tsc, ts-node
#   - go: goimports, golangci-lint, gosec, godoc
#   - rust: cargo-audit, cargo-nextest, cargo-watch
#
# STACK env var must be set in devcontainer.json to one of:
#   python | typescript | go | rust

set -euo pipefail

STACK="${STACK:-}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

step() { echo -e "\n${BLUE}${BOLD}▶ $*${NC}"; }
ok()   { echo -e "  ${GREEN}✓${NC} $*"; }
warn() { echo -e "  ${YELLOW}⚠${NC} $*"; }
die()  { echo -e "\n${RED}✗ $*${NC}\n"; exit 1; }

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║       DevContainer post-create setup             ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════╝${NC}"
echo ""

if [[ -z "$STACK" ]]; then
  die "STACK environment variable is not set. Check devcontainer.json."
fi
ok "Stack: $STACK"

# ── System packages ──────────────────────────────────────────────────────────
step "Installing system packages"
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -qq
sudo apt-get install -y -qq \
  zsh \
  neovim \
  tmux \
  curl \
  wget \
  git \
  unzip \
  build-essential \
  ca-certificates \
  gnupg \
  lsb-release
ok "System packages installed"

# ── zoxide ───────────────────────────────────────────────────────────────────
step "Installing zoxide"
curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
ok "zoxide installed"

# ── fzf ──────────────────────────────────────────────────────────────────────
step "Installing fzf"
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --all --no-bash --no-fish
ok "fzf installed"

# ── starship ─────────────────────────────────────────────────────────────────
step "Installing starship"
curl -sSfL https://starship.rs/install.sh | sh -s -- --yes
ok "starship installed"

# ── gh CLI ───────────────────────────────────────────────────────────────────
step "Installing gh CLI"
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
  | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt-get update -qq
sudo apt-get install -y -qq gh
ok "gh CLI installed"

# ── trufflehog ───────────────────────────────────────────────────────────────
step "Installing trufflehog"
ARCH=$(uname -m)
case "$ARCH" in
  x86_64)  TH_ARCH="amd64" ;;
  aarch64) TH_ARCH="arm64" ;;
  armv7l)  TH_ARCH="armv7" ;;
  *) die "Unsupported architecture for trufflehog: $ARCH" ;;
esac
TRUFFLEHOG_VERSION="3.93.3"
TRUFFLEHOG_URL="https://github.com/trufflesecurity/trufflehog/releases/download/v${TRUFFLEHOG_VERSION}/trufflehog_${TRUFFLEHOG_VERSION}_linux_${TH_ARCH}.tar.gz"
curl -sSfL "$TRUFFLEHOG_URL" -o /tmp/trufflehog.tar.gz
sudo tar -xz -C /usr/local/bin -f /tmp/trufflehog.tar.gz trufflehog
rm /tmp/trufflehog.tar.gz
ok "trufflehog installed ($(trufflehog --version 2>&1 | head -1))"

# ── dotfiles ──────────────────────────────────────────────────────────────────
step "Installing dotfiles"
# DevPod's dotfilesRepository clones the repo but may not run install.sh.
# We ensure it's cloned and installed regardless.
DOTFILES_DIR="$HOME/dotfiles"
if [[ ! -d "$DOTFILES_DIR" ]]; then
  git clone https://github.com/brentrockwood/dotfiles.git "$DOTFILES_DIR"
  ok "Dotfiles cloned"
else
  ok "Dotfiles already present (DevPod pre-cloned)"
fi
bash "$DOTFILES_DIR/install.sh"
ok "Dotfiles installed (symlinks created)"

# ── Default shell → zsh ──────────────────────────────────────────────────────
step "Setting default shell to zsh"
ZSH_PATH="$(command -v zsh)"
if grep -q "$ZSH_PATH" /etc/shells; then
  ok "zsh already in /etc/shells"
else
  echo "$ZSH_PATH" | sudo tee -a /etc/shells
fi
sudo chsh -s "$ZSH_PATH" "$(whoami)"
ok "Default shell set to zsh"

# ── Node.js (all stacks — required by AI CLIs and typescript tooling) ─────────
step "Installing Node.js 22 LTS via nvm"
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
source "$NVM_DIR/nvm.sh"
nvm install 22
nvm alias default 22
nvm use default
ok "Node $(node --version) installed via nvm"

# ── AI CLIs (all stacks) ──────────────────────────────────────────────────────
step "Installing AI CLIs"

# Claude CLI
npm install -g @anthropic-ai/claude-code
if ! command -v claude &>/dev/null; then
  die "claude CLI installed but not found in PATH"
fi
ok "claude installed ($(claude --version 2>&1 | head -1))"

# Codex CLI
npm install -g @openai/codex
if ! command -v codex &>/dev/null; then
  die "codex CLI installed but not found in PATH"
fi
ok "codex installed ($(codex --version 2>&1 | head -1))"

# CodeRabbit CLI
curl -fsSL https://cli.coderabbit.ai/install.sh | sh
grep -qxF 'export PATH="$HOME/.local/bin:$PATH"' ~/.zshrc \
  || echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
export PATH="$HOME/.local/bin:$PATH"
if ! command -v coderabbit &>/dev/null; then
  die "coderabbit CLI installed but not found in PATH"
fi
ok "coderabbit installed ($(coderabbit --version 2>&1 | head -1))"

# Register CodeRabbit plugin with Claude Code (requires both claude and coderabbit)
step "Registering CodeRabbit plugin with Claude Code"
if command -v claude &>/dev/null && command -v coderabbit &>/dev/null; then
  claude plugin install coderabbit
  ok "CodeRabbit plugin registered with Claude Code"
else
  warn "Skipping plugin registration — claude or coderabbit not available"
fi

# ── Stack-specific tools ──────────────────────────────────────────────────────
step "Installing stack tools: $STACK"
case "$STACK" in
  python)
    # Install uv (fast Python package/project manager)
    curl -LsSf https://astral.sh/uv/install.sh | sh
    # uv installs into ~/.local/bin — persist for future shells and add to current PATH
    grep -qxF 'export PATH="$HOME/.local/bin:$PATH"' ~/.zshrc \
      || echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
    export PATH="$HOME/.local/bin:$PATH"
    # Install Python 3.12 via uv
    uv python install 3.12
    ok "uv installed ($(uv --version))"
    ok "Python 3.12 available via uv"
    ;;

  typescript)
    # Node.js is installed in the common section above.
    # This case adds TypeScript-specific global packages only.
    npm install -g pnpm
    npm install -g typescript ts-node
    ok "pnpm $(pnpm --version) installed"
    ok "TypeScript $(tsc --version) installed"
    ;;

  go)
    # goimports: formatter and import organizer (mandatory in Go projects)
    go install golang.org/x/tools/cmd/goimports@latest
    # golangci-lint: runs many linters in one pass
    go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
    # gosec: security scanner (required by send 'er gate)
    go install github.com/securego/gosec/v2/cmd/gosec@latest
    # godoc: local documentation server
    go install golang.org/x/tools/cmd/godoc@latest
    # Add Go bin to PATH for this session (dotfiles will handle future shells)
    GOPATH="$(go env GOPATH)"
    export PATH="$PATH:$GOPATH/bin"
    ok "goimports installed"
    ok "golangci-lint installed ($(golangci-lint --version))"
    ok "gosec installed ($(gosec --version 2>&1 | head -1))"
    ok "godoc installed"
    ;;

  rust)
    # rustfmt and clippy ship with the stable toolchain via rustup.
    # These installs add audit, test runner, and dev-loop tooling.
    cargo install cargo-audit
    cargo install cargo-nextest --locked
    cargo install cargo-watch
    ok "cargo-audit installed ($(cargo audit --version 2>&1 | head -1))"
    ok "cargo-nextest installed ($(cargo nextest --version 2>&1 | head -1))"
    ok "cargo-watch installed ($(cargo watch --version 2>&1 | head -1))"
    ok "rustfmt available ($(rustfmt --version 2>&1 | head -1))"
    ok "clippy available ($(cargo clippy --version 2>&1 | head -1))"
    ;;

  *)
    die "Unknown STACK: $STACK. Valid values: python, typescript, go, rust"
    ;;
esac

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}${BOLD}║            DevContainer ready                    ║${NC}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Stack: ${BOLD}$STACK${NC}"
echo -e "  Shell: zsh (vi mode, starship prompt)"
echo -e "  Tools: nvim, tmux, zoxide, fzf, gh, trufflehog, node, claude, codex, coderabbit"
echo ""
echo -e "  ${YELLOW}Note: Open a new shell or run 'exec zsh' for full environment.${NC}"
echo ""
