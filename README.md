# doa-framework

**One repo to rule them all.**

doa-framework is the consolidated home of the DOA Framework — a system for
structured AI agent collaboration on software projects.

## What's in here

```
doa-framework/
├── doa                    ← the bootstrap tool (symlink into ~/bin)
├── template/              ← project scaffold (formerly prjTemplate)
│   ├── project/
│   │   ├── doa.md         ← canonical DOA (single source of truth)
│   │   ├── project.md
│   │   ├── context.md
│   │   └── scripts/       ← add-context, read-context, rotate-context, notify
│   ├── src/
│   ├── scripts/
│   └── ...
├── devcontainers/         ← devcontainer templates by stack
├── postCreate.sh          ← runs inside container at creation
├── scripts/
│   └── security_scan.sh
├── project/               ← this repo's own DOA project directory
│   ├── doa.md             ← same canonical DOA (doa-framework governs itself)
│   ├── project.md
│   ├── context.md
│   └── scripts/
└── RUNBOOK.md
```

## Quick start

```bash
git clone git@github.com:brentrockwood/doa-framework.git ~/doa-framework
ln -s ~/doa-framework/doa ~/bin/doa
doa ~/src/my-new-project
```

See [RUNBOOK.md](RUNBOOK.md) for complete documentation.

## The DOA

The Development Operating Agreement lives at `project/doa.md`. It is the
single authoritative copy. When `doa` scaffolds a new project, it copies this
file into `template/project/doa.md` → `<new-project>/project/doa.md`.

Only humans edit `doa.md`. Agents read it.

## Previously

This repo consolidates:
- `brentrockwood/new-project` → deprecated, see doa-framework
- `brentrockwood/prjTemplate` → deprecated, see doa-framework/template/
- `brentrockwood/doa` → deprecated, see doa-framework/project/doa.md
- `brentrockwood/doa-framework` → replaced by this repo (was landing page only)
