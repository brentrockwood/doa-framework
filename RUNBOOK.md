# DOA Framework Runbook

This document describes the complete project creation and development workflow.
It covers the tools, conventions, and the decisions behind them.

---

## Overview

Every project is bootstrapped by a single script — `doa` — which evaluates a
target directory and adopts it into the DOA Framework, regardless of what it
finds there:

- **Brand-new path** → full bootstrap: scaffold, GitHub repo, DevPod, PR
- **Existing unadopted project** → adopt in place: DOA files added, PR opened
- **Already-adopted project** → nothing to do, exits 0

One command, one path, behaviour determined by what's found at the target.

---

## Prerequisites

You need `git`, `gh` (GitHub CLI), `devpod`, and Bash 4+.

**macOS (Homebrew):**
```bash
brew install git gh devpod bash
```

**Debian/Ubuntu:**
```bash
apt install git
# gh: https://github.com/cli/cli/blob/trunk/docs/install_linux.md
# devpod: https://devpod.sh/docs/getting-started/install
# bash 4+ is the default on most Linux distributions
```

For other systems, install these tools using your package manager of choice.
`devpod` provides binaries for Linux, macOS, and Windows at
[devpod.sh](https://devpod.sh/docs/getting-started/install).

Verify everything is ready:

```bash
gh auth status
devpod version
git --version
bash --version   # must be 4+
```

Authenticate with GitHub if you haven't already:

```bash
gh auth login
```

---

## Dotfiles

DevPod can inject your dotfiles into every devcontainer it creates. Configure
this once and it applies to all workspaces automatically:

```bash
devpod context set-options --dotfiles-url https://github.com/<you>/dotfiles
```

See the [DevPod dotfiles documentation](https://devpod.sh/docs/developing-in-workspaces/dotfiles-in-a-workspace)
for full details, including support for install scripts and different shell
configurations.

The devcontainers in this framework are intentionally minimal — they install
stack tooling but leave shell environment to your dotfiles.

---

## Installation

```bash
# Fork or clone this repo
git clone git@github.com:<owner>/doa-framework.git ~/doa-framework

# Make the script available on your PATH.
# The simplest approach: symlink it somewhere already on your PATH.
ln -s ~/doa-framework/doa /usr/local/bin/doa   # may require sudo

# Alternatively, add a local bin directory to your PATH and symlink there:
mkdir -p ~/bin
ln -s ~/doa-framework/doa ~/bin/doa
# Then add to your shell profile: export PATH="$HOME/bin:$PATH"
```

How you manage your PATH is up to you. The script just needs to be executable
and findable.

---

## Usage

```
doa <path> [--dry-run] [--force] [--remote <host>]
```

| Argument | Description |
|----------|-------------|
| `<path>` | Target directory. Created if it does not exist. |
| `--dry-run` | Evaluate and print the migration plan. No files written, no git state modified. |
| `--force` | Bypass hard fails after an explicit per-fail confirmation prompt. |
| `--remote <host>` | Use a remote SSH host as the DevPod provider instead of local Docker. |

There are no subcommands. The path determines everything.

---

## Bootstrapping a New Project

```bash
doa ~/src/my-cool-tool
```

`doa` evaluates the (empty) directory and runs the full bootstrap:

```
1.  Evaluate:      check uncommitted files, partial adoption, security, gh auth, stack
2.  Plan:          determine which steps are needed
3.  Report:        print check results and migration plan
4.  Create:        project/ directory and scripts
5.  Write:         project/doa.md, project/project.md, .gitignore, secrets.env.example
6.  Git:           initialise repo, branch: main
7.  Context:       first entry written to project/context.md
8.  Commit:        DOA: Initial DOA framework scaffold
9.  GitHub:        private repo created, main + initial-scaffold branches pushed
10. DevPod:        workspace created (local Docker by default)
11. PR:            initial-scaffold → main
```

### Remote DevPod

If you have a remote machine available as a DevPod SSH provider, you can run
the workspace there instead of locally:

```bash
# Add your remote host as a DevPod SSH provider (one-time setup)
devpod provider add ssh
devpod provider configure ssh --option HOST=<your-host>

# Then pass --remote when bootstrapping
doa ~/src/my-cool-tool --remote <your-host>
```

The remote host needs Docker installed and your SSH key authorized. See the
[DevPod SSH provider docs](https://devpod.sh/docs/managing-providers/add-provider)
for setup details.

---

## Adopting an Existing Project

```bash
doa ~/src/existing-project
```

`doa` detects what DOA components are missing and adds only those. An existing
git history and GitHub remote are preserved. A PR is opened for the new DOA
files.

---

## Dry Run

```bash
doa ~/src/any-project --dry-run
```

Runs the full evaluation and prints the migration plan. Makes no changes to
files, git state, or GitHub.

---

## Forcing Past Failures

```bash
doa ~/src/dirty-project --force
```

If evaluation finds hard failures (uncommitted files, partial adoption,
security findings), `doa` normally exits 1. With `--force`, it prompts once
per failure and proceeds if you confirm. Each prompt is explicit about the risk.

---

## What Happens After `doa`

```bash
# SSH into the devcontainer
ssh <project-name>.devpod

# Inside the container:
cd /workspaces/<project-name>
project/scripts/read-context        # see what was done at creation
```

---

## Inside the Container

Stack-specific tools are installed by `postCreate.sh`. Shell environment
(prompt, aliases, editor config) comes from your dotfiles.

**Python:**
- `uv` — fast package/project manager (replaces pip/venv/pyenv)
- Python 3.12 via `uv python install 3.12`

**TypeScript:**
- Node 22 LTS via nvm
- pnpm
- TypeScript (`tsc`), ts-node

**Go:**
- Go toolchain
- `gopls`, `golangci-lint`

---

## Project Structure

Every project created by `doa` has this layout:

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

`doa` runs this scan during evaluate and will hard-fail (exit 1) if issues
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

## Customising the Framework

The framework is designed to be forked. After forking, the main things you'll
want to adapt are:

- **`project/doa.md`** — the operating agreement itself. Edit it to match your
  workflow, branching conventions, and agent preferences.
- **`template/`** — the project scaffold. Add, remove, or restructure files to
  match your conventions.
- **`postCreate.sh`** — what gets installed in each devcontainer. Add tools,
  remove ones you don't use.
- **`devcontainers/`** — per-stack `devcontainer.json` files. Extend or add
  stacks here.

New projects created after a change will automatically get it. Existing
projects do **not** auto-update — that's intentional. To apply devcontainer
changes to an existing workspace:

```bash
devpod up <project-name> --recreate
```

---

## Adding a New Stack

1. Create `devcontainers/<stack>/devcontainer.json`
2. Add a `<stack>)` case to `postCreate.sh` that installs the relevant tools
3. Add stack detection to `check_stack()` in the `doa` script
4. Add a gitignore block for the stack to `step_write_gitignore()`
5. Commit and push

---

## Troubleshooting

### `gh: not authenticated`

```bash
gh auth login
```

### `devpod: command not found`

Install DevPod for your platform: [devpod.sh](https://devpod.sh/docs/getting-started/install)

### `devpod up` fails: Docker not running

Start Docker on your machine and retry. On macOS:

```bash
open -a Docker
```

### `doa` fails: Bash version too old

```bash
bash --version   # must be 4+
```

On macOS, install a current version via Homebrew:

```bash
brew install bash
# Ensure it's first in PATH, or invoke directly:
/opt/homebrew/bin/bash ~/doa-framework/doa <path>
```

### Container builds but shell errors on startup

If `postCreate.sh` failed partway through, re-run it manually inside the
container:

```bash
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

All configuration in `doa` is overridable via environment variables.
Add these to your shell profile to change defaults:

```bash
# Your GitHub username
export NEW_PROJECT_GITHUB_USER="your-username"

# Template repo to clone as fallback if local template/ is absent
export NEW_PROJECT_TEMPLATE="github.com/<owner>/doa-framework"

# Where new projects are created (default: ~/src)
export NEW_PROJECT_SRC_DIR="$HOME/src"
```
