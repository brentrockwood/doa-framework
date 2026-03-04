# Project System Runbook

This document describes the complete project creation and development workflow.
It covers the tools, repositories, conventions, and the decisions behind them.

---

## Overview

Every project is bootstrapped by a single script — `dob` — which evaluates a
target directory and adopts it into the DOA Framework, regardless of what it
finds there:

- **Brand-new path** → full bootstrap: scaffold, GitHub repo, DevPod, PR
- **Existing unadopted project** → adopt in place: DOA files added, PR opened
- **Already-adopted project** → nothing to do, exits 0

One command, one path, behaviour determined by what's found at the target.

---

## Why "dob" and "DOA"?

`dob` stands for **DOA Bootstrap**. `DOA` stands for **Development Operating
Agreement** — the contract between you and any AI agent working on a project.
These names are intentional, not a typo.

---

## Repositories

| Repo | Purpose |
|------|---------|
| `brentrockwood/dob` | This repo. The `dob` script and devcontainer templates. |
| `brentrockwood/doa` | The DOA Framework: `doa.md`, `project/scripts/`. |
| `brentrockwood/prjTemplate` | The project scaffold. Used as a reference template. |
| `brentrockwood/dotfiles` | Shell environment. Installed into every devcontainer. |
| `brentrockwood/<project>` | Each project created by `dob`. Private by default. |

---

## Prerequisites

The following must be installed on your Mac before using `dob`:

```bash
# Package manager
brew install gh git

# DevPod CLI
brew install devpod

# Authenticate GitHub CLI
gh auth login
```

Verify everything is ready:

```bash
gh auth status
devpod version
git --version
```

`dob` also requires **Bash 4+**. macOS ships with Bash 3. Install the current
version via Homebrew:

```bash
brew install bash
```

---

## Installation

```bash
# Clone this repo
git clone git@github.com:brentrockwood/dob.git ~/dob

# Symlink the script into your PATH
ln -s ~/dob/dob ~/bin/dob
chmod +x ~/bin/dob

# Make sure ~/bin is in PATH — add to ~/.zshrc.local if not already:
# export PATH="$HOME/bin:$PATH"
```

---

## Usage

```
dob <path> [--dry-run] [--force] [--remote]
```

| Argument | Description |
|----------|-------------|
| `<path>` | Target directory. Created if it does not exist. |
| `--dry-run` | Evaluate and print the migration plan. No files written, no git state modified. |
| `--force` | Bypass hard fails after an explicit per-fail confirmation prompt. |
| `--remote` | Use `dh1` SSH DevPod provider instead of local Docker. |

There are no subcommands. The path determines everything.

---

## Bootstrapping a New Project

```bash
dob ~/src/my-cool-tool
```

`dob` evaluates the (empty) directory and runs the full bootstrap:

```
1.  Evaluate:      check uncommitted files, partial adoption, security, gh auth, stack
2.  Plan:          determine which steps are needed
3.  Report:        print check results and migration plan
4.  Create:        project/ directory and scripts
5.  Write:         project/doa.md, project/project.md, .gitignore, secrets.env.example
6.  Git:           initialise repo, branch: main
7.  Context:       first entry written to project/context.md
8.  Commit:        DOB: Initial DOA framework scaffold
9.  GitHub:        private repo created, main + initial-scaffold branches pushed
10. DevPod:        workspace created (local Docker by default)
11. PR:            initial-scaffold → main
```

### Remote option (dh1)

```bash
dob ~/src/my-cool-tool --remote
```

Uses `dh1` (SSH provider) instead of local Docker.

---

## Adopting an Existing Project

```bash
dob ~/src/existing-project
```

`dob` detects what DOA components are missing and adds only those. An existing
git history and GitHub remote are preserved. A PR is opened for the new DOA
files.

---

## Dry Run

```bash
dob ~/src/any-project --dry-run
```

Runs the full evaluation and prints the migration plan. Makes no changes to
files, git state, or GitHub.

---

## Forcing Past Failures

```bash
dob ~/src/dirty-project --force
```

If evaluation finds hard failures (uncommitted files, partial adoption,
security findings), `dob` normally exits 1. With `--force`, it prompts once
per failure and proceeds if you confirm. Each prompt is explicit about the risk.

---

## What happens after `dob`

```bash
# SSH into the devcontainer
ssh <project-name>.devpod

# Inside the container:
cd /workspaces/<project-name>
project/scripts/read-context        # see what was done at creation
```

---

## Inside the Container

Every devcontainer has:

| Tool | Notes |
|------|-------|
| zsh | Default shell, vi mode, Starship prompt |
| neovim | `vi` alias, config from dotfiles |
| tmux | Config from dotfiles |
| zoxide | `z` for directory jumping |
| fzf | History search, completion |
| starship | Prompt |
| gh | GitHub CLI |
| trufflehog | Deep secrets scanning |
| git | Pre-installed |

Plus stack-specific tools:

**Python:**
- `uv` — fast package/project manager (replaces pip/venv/pyenv)
- Python 3.12 via `uv python install 3.12`

**TypeScript:**
- Node 22 LTS via nvm
- pnpm
- TypeScript (`tsc`), ts-node

**Go:**
- Go toolchain via `mise` or direct install
- `gopls`, `golangci-lint`

---

## Project Structure

Every project created by `dob` has this layout:

```
<project>/
├── .devcontainer/
│   ├── devcontainer.json       ← stack-specific, committed
│   └── postCreate.sh           ← runs at container creation
├── src/                        ← your code
├── tests/
├── docs/
├── scripts/
│   └── security_scan.sh        ← grep + Trufflehog
├── project/                    ← AI agent operational files
│   ├── doa.md                  ← Development Operating Agreement
│   ├── project.md              ← implementation plan (write-locked)
│   ├── context.md              ← session work log
│   └── scripts/
│       ├── add-context         ← append to context.md
│       ├── read-context        ← read recent entries
│       └── rotate-context      ← archive old entries
├── README.md
├── DEPLOYMENT.md
├── .gitignore
├── .env.example
└── secrets.env.example
```

---

## The Development Operating Agreement (DOA)

Every project includes `project/doa.md`. This is the contract between you and
any AI agent working on the project. Key points:

- Every session starts by reading `project/project.md` and running
  `project/scripts/read-context -n 2`
- Every session ends with `project/scripts/add-context` and a commit
- `project/project.md` is **write-locked** — only humans can change it
- `project/context.md` is **append-only** — entries are never edited
- `send 'er` is the phrase that triggers the full quality gate + push + PR

Agents are expected to follow the DOA without being reminded.

---

## Context Management

The `project/scripts/` tools manage `context.md`:

```bash
# Add an entry (agent does this after every interaction)
project/scripts/add-context \
  --agent "Claude Code" \
  --model "claude-sonnet-4-6" \
  "Summary of what was done and what's next."

# Read last 2 entries (start of session)
project/scripts/read-context -n 2 -f project/context.md

# Read just headers
project/scripts/read-context --headers-only -n 5

# Rotate when file gets large (default: 1MB)
project/scripts/rotate-context
```

---

## Security Scanning

Every project has `scripts/security_scan.sh` which runs:

1. **Sensitive file check** — secrets.env, credentials.json, token.json, etc.
   Verifies each is gitignored.
2. **Pattern scan** — grep for API keys, tokens, passwords, private keys, IPs,
   database URLs across all source files.
3. **Git history check** — looks for sensitive filenames ever committed.
4. **Trufflehog** — deep entropy-based scan. Always available inside the
   devcontainer. Gracefully skipped on the host if not installed.

Run it:

```bash
./scripts/security_scan.sh

# Or via the full check suite:
./scripts/run_checks.sh
```

Exit codes: `0` = clean, `1` = issues found, `2` = script error.

`dob` runs this scan during evaluate and will hard-fail (exit 1) if issues
are found. Use `--force` to bypass after confirmation.

---

## send 'er

`send 'er` is a phrase spoken to an AI agent that triggers the full
release gate:

1. Security scan on entire project
2. All tests must pass
3. Linter must be clean
4. Build (if applicable)
5. Summary shown, push confirmed
6. Push to origin
7. PR opened

---

## Updating the Template

When you improve the template (e.g. add a tool, fix a script, update the DOA):

```bash
cd ~/dob   # or wherever you keep it
# make changes
git add -A
git commit -m "describe what changed"
git push
```

New projects created after the push will automatically get the improvements.
Existing projects do **not** auto-update — that's intentional.

---

## Updating the Devcontainer

If `postCreate.sh` or `devcontainer.json` changes in this repo:

```bash
cd ~/dob
git add -A
git commit -m "DevContainer: describe what changed"
git push
```

To apply the change to an existing workspace:

```bash
# On the host:
devpod up <project-name> --recreate
```

---

## Adding a New Stack

To add a new stack (e.g. Rust):

1. Create `devcontainers/rust/devcontainer.json` in this repo
2. Add a `rust)` case to `postCreate.sh` that installs Rust tools
3. Add stack detection to `check_stack()` in the `dob` script
4. Add a gitignore block for the stack to `step_write_gitignore()`
5. Commit and push this repo

---

## dh1 (Remote Docker)

`dh1` is an LXC on the Proxmox rack. Use it via the SSH provider:

```bash
devpod provider add ssh
```

Then pass `--remote` to `dob`:

```bash
dob ~/src/my-project --remote
```

This passes `--provider ssh --provider-option HOST=dh1` to `devpod up`.
dh1 must have Docker installed and your SSH key authorized.

---

## Troubleshooting

### `gh: not authenticated`

```bash
gh auth login
# Choose: GitHub.com → SSH → browser auth
```

### `devpod: command not found`

```bash
brew install devpod
# or download from https://devpod.sh
```

### `devpod up` fails: Docker not running

```bash
open -a Docker   # start Docker Desktop on Mac
# wait for the whale to settle, then retry
```

### `dob` requires Bash 4+ but macOS has Bash 3

```bash
brew install bash
# then invoke as: /opt/homebrew/bin/bash ~/dob/dob <path>
# or ensure Homebrew bash is first in PATH
```

### Container builds but `.zshrc` errors on startup

Your `.zshrc` expects `zoxide`, `fzf`, and `starship` to be installed.
`postCreate.sh` installs them, but if it failed partway through:

```bash
# Inside the container:
bash /workspaces/<project>/.devcontainer/postCreate.sh
```

### `add-context` not executable

```bash
chmod +x project/scripts/add-context \
         project/scripts/read-context \
         project/scripts/rotate-context
```

---

## Environment Variables

All configuration in `dob` is overridable via environment variables.
Add these to `~/.zshrc.local` to change defaults:

```bash
# GitHub username (default: brentrockwood)
export NEW_PROJECT_GITHUB_USER="brentrockwood"

# Template repo to reference (default: github.com/brentrockwood/prjTemplate)
export NEW_PROJECT_TEMPLATE="github.com/brentrockwood/prjTemplate"

# Where new projects land on your Mac (default: ~/src)
export NEW_PROJECT_SRC_DIR="$HOME/src"

# DOA repo for scripts/doa.md source (default: brentrockwood/doa)
export DOB_DOA_REPO="brentrockwood/doa"
```
