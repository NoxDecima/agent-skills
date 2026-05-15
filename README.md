# claude-config

Personal Claude Code customization layer on top of the `superpowers` plugin.

## Layout

- `CLAUDE.md` — global memory file. Symlinked into `~/.claude/CLAUDE.md`.
- `skills/<name>/SKILL.md` — personal skills. Each is symlinked into `~/.claude/skills/<name>/`.
- `docs/specs/` — design specs.
- `docs/plans/` — implementation plans.
- `tests/` — author-time pressure scenarios used while building skills. Not a regression harness.

## Setup

This repo is set up via the implementation plan at `docs/plans/2026-05-15-personal-claude-customization-v1-plan.md`. Symlinks must be created manually per that plan; cloning the repo alone does not activate any customization.

## Extending

To add a new personal skill:

1. Study `skills/followup-tracking/SKILL.md` and the references it cites.
2. Follow the TDD discipline: write a baseline pressure scenario, run it with a subagent **without** the skill, document what happened. Only then write the minimal skill.
3. Symlink the new skill directory into `~/.claude/skills/`.
