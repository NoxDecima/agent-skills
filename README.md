# claude-config

Personal Claude Code customization layer on top of the `superpowers` plugin.

## Layout

- `CLAUDE.md` — global memory file. Symlinked into `~/.claude/CLAUDE.md`.
- `skills/<name>/SKILL.md` — personal skills. Each is symlinked into `~/.claude/skills/<name>/`.
- `docs/specs/` — design specs.
- `docs/plans/` — implementation plans.
- `tests/` — author-time pressure scenarios used while building skills. Not a regression harness.

## Setup

Cloning the repo alone does not activate any customization — the harness reads from `~/.claude/`, so symlinks must be installed pointing there.

Adjust `REPO=` to wherever you cloned this:

```bash
REPO="$HOME/Documents/Projects/Nox/claude-config"

# 1. Local mirror directory for persisted followups
mkdir -p ~/claude-followups

# 2. Back up any existing global CLAUDE.md (skip if it's already absent or already a symlink to this repo)
if [ -e ~/.claude/CLAUDE.md ] && [ ! -L ~/.claude/CLAUDE.md ]; then
  cp ~/.claude/CLAUDE.md ~/.claude/CLAUDE.md.bak.$(date +%Y%m%d-%H%M%S)
fi

# 3. Symlinks into ~/.claude/
ln -s "$REPO/CLAUDE.md"                   ~/.claude/CLAUDE.md
ln -s "$REPO/skills/followup-tracking"    ~/.claude/skills/followup-tracking

# 4. Verify
readlink -f ~/.claude/CLAUDE.md
readlink -f ~/.claude/skills/followup-tracking
```

To activate additional personal skills landed in this repo, repeat step 3 with the new skill's directory. Smoke-test in a fresh Claude Code session — the global `CLAUDE.md` content should be in context and any installed personal skill should be listed under available skills.

The full task-by-task install procedure (with backup logic, verification, and a fresh-session smoke test) is in `docs/plans/2026-05-15-personal-claude-customization-v1-plan.md`.

## Extending

To add a new personal skill:

1. Study `skills/followup-tracking/SKILL.md` and the references it cites.
2. Follow the TDD discipline: write a baseline pressure scenario, run it with a subagent **without** the skill, document what happened. Only then write the minimal skill.
3. Symlink the new skill directory into `~/.claude/skills/`.
