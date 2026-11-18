# Notes for AI agents (OpenCode, Gemini, Claude and others)

AI Showdown is a fun parody 3D fighting game in Godot 4.7.2. Three agents work on it in
parallel, each with its own area:

- **Claude**: orchestrator and core code (fight engine, moves, supers, AI, modes, tests).
- **OpenCode**: character design (fighter likeness pass, NPC models, super props).
- **Gemini**: stages (realism, props, sounds, crowd content), story writing, docs.

## Your branch

| Agent | Branch |
|---|---|
| Claude | `main` (the main branch; Claude merges into it) |
| Gemini (code tasks, see docs/TASKS.md §9) | `gemini/work` |
| Cline (Nemotron 3.5 Super VL), taking over OpenCode's tasks | `opencode/work` |

Work and push only on your own branch; merge the main branch into yours at the start of each
task. Report progress in `docs/status/<agent>.md`; Claude merges your branch. Details:
docs/TASKS.md §1.

## Read first, in this order

1. [docs/TASKS.md](docs/TASKS.md): the task board, **file ownership**, the contracts between
   agents and the workflow. Only take tasks assigned to you; only edit files you own.
2. [docs/HANDOFF.md](docs/HANDOFF.md): setup, the fighter rebuild order, traps.
3. [docs/ROADMAP.md](docs/ROADMAP.md): the design you are building toward.
4. [docs/CONTRIBUTING.md](docs/CONTRIBUTING.md): field-by-field reference.

## Rules

- Godot 4.7.2. After any change run
  `godot --headless --path . -s res://tests/sim_test.gd`; it must print `0 failure(s)`.
- Fighter looks: one fighter at a time; the owner approves each. Any change must be clearly
  distinct, not subtle (HANDOFF §3).
- Generated files (`data/characters/`, `data/moves/`) are never hand-edited: change the
  generator in `tools/`, re-run it, commit the output.
- The fight simulation is deterministic (60 Hz, rollback). Visual work must not change it.
- Parody only: made-up names, no humiliating, sexual or ethnic-caricature content. NPCs are
  made-up generic people, never real persons.
- New assets must be CC0 / CC-BY (credited in `assets/CREDITS.md`) or made by us.
- Keep the credit "Based on 3D Fighter by Clint Christopher Canada (MIT / CC BY 4.0)".
- Commit messages start with the task id: `[O2] Jensen GPU prop`.
