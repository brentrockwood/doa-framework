# DOA Framework

A system for collaborating effectively with AI agents on software projects.

## The Problem

AI agents are capable of writing code, running tests, and navigating complex codebases — but without structure, sessions drift. Context gets lost between conversations. Decisions get relitigated. The agent doesn't know what it agreed to last time, what the branching strategy is, or whether it's allowed to push directly to main.

Every morning, your AI agent wakes up with catastrophic amnesia. The DOA Framework is how you fight that.

## The Philosophy

Working with an AI agent is closer to onboarding a contractor than writing a script. You need shared agreements, not just prompts. You need a record of what was decided and why, not just what the code looks like today. And you need a way to hand the agent the full picture at the start of every session without repeating yourself.

This framework has three parts that each solve a different piece of that problem.

## The Three Pieces

**[Development Operating Agreement (DOA)](https://github.com/brentrockwood/doa)**

The DOA is a document — written by you, for your AI agent — that establishes the rules of engagement for a project. How are branches named? What can the agent do autonomously, and what requires your sign-off? How is the project structured? What stack are we using?

You craft this to your needs. We have a version that works for us that you can use as-is or modify. The agent reads it at the beginning of every session. These are the rules.

Because every project's needs drift over time, each project gets its own copy of the DOA. It's not a shared dependency you point at — it's a starting point you fork. When the project teaches you something new, you update the DOA, and the agent's behavior updates with it.

**[Project Template (prjTemplate)](https://github.com/brentrockwood/prjTemplate)**

An empty shell of a project, shaped the way a DOA-aware project expects. Directory structure, context files, documentation stubs — everything in the right place so the agent can orient itself immediately.

This one works for us right now. Your conventions might differ, and the template is meant to be forked.

**[new-project workflow](https://github.com/brentrockwood/new-project)**

A tool that wires it all together. Run it once, get a new repository with the template applied and a copy of the DOA checked in and ready to evolve. Our version is built around TypeScript and Python projects running inside [devpods](https://devpod.sh/). Yours might cover different stacks or environments — we welcome input and pull requests.

Ideally you run this once per project and never think about the scaffolding again.

## How a Project Starts: `project.md`

When `new-project` scaffolds a fresh project, one of the first things it creates is `project/project.md` — the primary operational document for the life of that project.

This is where architecture decisions live, stack choices are recorded, and feature checklists are tracked. But it's more than a document — it's a collaborative artifact. During the planning phase, the agent is encouraged to ask questions, surface ambiguities, and push back on decisions before implementation begins. Once planning closes, `project.md` is effectively write-locked: only humans can authorize changes to it. Decisions that get superseded stay in the document, marked as such, so you always have the full history of why things are the way they are.

The agent lives by what's in `project.md`. Getting it right up front is worth the time.

## The Context System

Between sessions, the agent reads two things: the DOA and the recent context log. The context log is what makes continuity possible.

`project/context.md` is an append-only work log, updated after every interaction. Not just major milestones — every interaction. If your session crashes, your browser closes, or you switch agents mid-project, you and the agent can pick up exactly where you left off. No re-explaining the architecture. No relitigating last week's decisions. Just read the last entry or two and get back to work.

The log is also an auditable artifact. Git tells you what changed. The context log tells you why a decision was made, what was tried and abandoned, and what the plan is for next session.

### The Scripts

Context is managed exclusively through a set of scripts that live in `project/scripts/`. You never write to `context.md` directly — the scripts handle formatting, timestamps, hashing, and git state automatically. This makes the log deterministic and reliable regardless of which agent or tool is writing to it. Each script comes with a README covering usage in detail.

**`add-context`** — Adds a new entry to the log. Called by the agent after every interaction, and by you whenever something significant happens outside a session. Entries include the agent name, model version, a SHA-256 hash of the body, and the current git commit hash. They are never edited after being written.

**`read-context`** — Reads recent entries from the log. The agent uses this at the start of every session to resume context. You can read headers only, or full entries, and control how many to retrieve.

**`rotate-context`** — Archives older entries when the log grows large, keeping the most recent entries in the active file. Older entries don't disappear — they move to a timestamped overflow file. Run this manually after particularly active sessions, or when the file gets unwieldy.

## How They Fit Together

```
new-project
  ├── pulls scaffold from → prjTemplate
  └── copies in → DOA (as a living document your project owns)
        └── includes → project/scripts/ (context management)
```

## Where to Start

Read the DOA first — it explains the philosophy in concrete terms and gives you something to react to. Then use `new-project` to spin up a project and see how it all fits together in practice.

If you want to adapt the scaffold to your own conventions, start with `prjTemplate`. If you want to change how projects are created or add new stack support, start with `new-project`.

## Status

This is a personal framework, validated across a handful of real projects. It's being shared in case it's useful to others. Feedback and forks welcome.
