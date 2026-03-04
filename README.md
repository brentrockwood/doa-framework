# DOA Framework

A system for collaborating effectively with AI agents on software projects.

## The Problem

AI agents are capable of writing code, running tests, and navigating complex
codebases — but without structure, sessions drift. Context gets lost between
conversations. Decisions get relitigated. The agent doesn't know what it agreed
to last time, what the branching strategy is, or whether it's allowed to push
directly to main.

Every session, your AI agent wakes up with catastrophic amnesia. The DOA
Framework is how you fight that.

## The Philosophy

Working with an AI agent is closer to onboarding a contractor than writing a
script. You need shared agreements, not just prompts. You need a record of what
was decided and why — not just what the code looks like today. And you need a
way to hand the agent the full picture at the start of every session without
repeating yourself.

The key insight is that constraints make agents *more* useful, not less. Clear
rules and processes let agents move faster by removing ambiguity about
expectations and procedures. Process failures become learning opportunities
that strengthen the system, with agents documenting their own violations to
improve future iterations.

## What's in the Framework

**The Development Operating Agreement (`project/doa.md`)**

The DOA is a document — written by you, for your AI agent — that establishes
the rules of engagement for a project. How are branches named? What can the
agent do autonomously, and what requires your sign-off? How does a session
start and end? What does `send 'er` mean?

You craft this to your needs. This repo ships a version that works across a
range of projects — use it as-is or adapt it. The agent reads it at the start
of every session. These are the rules.

Because every project's needs drift over time, each project gets its own copy.
It's not a shared dependency you point at — it's a starting point that evolves
with the project.

**The Project Template (`template/`)**

An empty shell of a project, shaped the way a DOA-aware project expects.
Directory structure, context files, documentation stubs, scripts — everything
in the right place so the agent can orient itself immediately. Covers Python
(uv), TypeScript (Node 22 + pnpm), and Go.

**The Bootstrap Tool (`doa`)**

A single command that wires it all together. Point it at a directory — new or
existing — and it evaluates what's there, determines what DOA components are
missing, and adopts the project into the framework. One command, one path,
behaviour determined by what's found at the target.

## How a Session Works

Every session follows the same rhythm, enforced by the DOA:

**Start:** read `project/project.md`, run `project/scripts/read-context -n 2`,
verify branch.

**Work:** agent operates within the rules, asks before doing anything
irreversible, keeps code quality high.

**End:** `project/scripts/add-context` with a summary, security scan, commit
(no push). Humans push.

`send 'er` triggers the full quality gate: scan → tests → lint → build → push
→ PR.

## The Context System

Between sessions, the agent reads two things: the DOA and the recent context
log. The context log is what makes continuity possible.

`project/context.md` is an append-only work log, updated after every
interaction. If your session crashes, your browser closes, or you switch agents
mid-project, you and the agent can pick up exactly where you left off. No
re-explaining the architecture. No relitigating last week's decisions. Just
read the last entry or two and get back to work.

Context is managed exclusively through scripts in `project/scripts/`. You
never write to `context.md` directly — the scripts handle formatting,
timestamps, hashing, and git state automatically.

- **`add-context`** — Appends a new entry. Called by the agent after every
  interaction. Entries include agent name, model version, a SHA-256 hash, and
  the current git commit. Never edited after being written.
- **`read-context`** — Reads recent entries. The agent uses this at session
  start. Supports header-only mode and entry count limits.
- **`rotate-context`** — Archives older entries when the log grows large,
  keeping the active file manageable without losing history.

## How `project.md` Works

When `doa` scaffolds a project, one of the first things it creates is
`project/project.md` — the primary operational document for the life of the
project. Architecture decisions, stack choices, feature checklists, open
questions.

During the planning phase, the agent is encouraged to ask questions, surface
ambiguities, and push back before implementation begins. Once planning closes,
`project.md` is **write-locked**: only humans can authorise changes. The agent
lives by what's in it.

Getting it right up front is worth the time.

## Repository Layout

```
doa-framework/
├── doa                         ← bootstrap tool (symlink into ~/bin)
├── template/                   ← project scaffold
│   ├── project/
│   │   ├── doa.md              ← canonical DOA (single source of truth)
│   │   ├── project.md
│   │   ├── context.md
│   │   └── scripts/            ← add-context, read-context, rotate-context
│   ├── devcontainers/          ← per-stack devcontainer configs
│   ├── scripts/
│   │   ├── security_scan.sh
│   │   └── notify              ← Telegram notifications
│   └── ...
├── devcontainers/              ← devcontainer templates by stack
├── postCreate.sh               ← runs inside container at creation
├── scripts/
│   └── security_scan.sh
├── project/                    ← this repo's own DOA project directory
│   ├── doa.md                  ← same canonical DOA (framework governs itself)
│   ├── project.md
│   ├── context.md
│   └── scripts/
├── CLAUDE.md                   ← points agents to project/doa.md
├── AGENTS.md
└── RUNBOOK.md                  ← complete operational documentation
```

## Quick Start

```bash
# Clone and install
git clone git@github.com:brentrockwood/doa-framework.git ~/doa-framework
ln -s ~/doa-framework/doa ~/bin/doa

# Bootstrap a new project
doa ~/src/my-new-project

# Adopt an existing project
doa ~/src/existing-project
```

See [RUNBOOK.md](RUNBOOK.md) for complete documentation.

## The Canonical DOA

`project/doa.md` is the single authoritative copy of the Development Operating
Agreement. When `doa` scaffolds a new project, it copies this file into the
new project's `project/doa.md`.

Only humans edit `doa.md`. Agents read it.

## Status

This is a personal framework, validated across a range of real projects — from
system utilities to web UIs to workflow services. Shared in case it's useful
to others. Feedback and forks welcome.
