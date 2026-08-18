# claude-config

Personal Claude Code customization layer on top of the `superpowers` plugin.

## Layout

- `GLOBAL.md` — global memory (applies to every Claude Code session). Symlinked into `~/.claude/CLAUDE.md`.
- `CLAUDE.md` — project memory (auto-loaded by the harness when working in this repo). Holds the project-scope Linear destination and any conventions specific to editing this repo.
- `skills/<name>/SKILL.md` — personal skills. Each is symlinked into `~/.claude/skills/<name>/`.
- `docs/specs/` — design specs.
- `docs/plans/` — implementation plans.
- `tests/` — author-time pressure scenarios used while building skills. Not a regression harness.

## Setup

Cloning the repo alone does not activate any customization — the harness reads from `~/.claude/`, so symlinks must be installed pointing there.

Adjust `REPO=` to wherever you cloned this:

```bash
REPO="$HOME/Documents/Projects/Nox/claude-config"

# 1. Back up any existing global CLAUDE.md (skip if it's already absent or already a symlink to this repo)
if [ -e ~/.claude/CLAUDE.md ] && [ ! -L ~/.claude/CLAUDE.md ]; then
  cp ~/.claude/CLAUDE.md ~/.claude/CLAUDE.md.bak.$(date +%Y%m%d-%H%M%S)
fi

# 2. Symlinks into ~/.claude/
#    Note: only GLOBAL.md is symlinked. The repo's CLAUDE.md is the
#    *project* memory file and is auto-loaded by the harness whenever
#    you work inside this repo — no symlink needed for it.
ln -s "$REPO/GLOBAL.md"                   ~/.claude/CLAUDE.md
ln -s "$REPO/skills/followup-tracking"    ~/.claude/skills/followup-tracking
ln -s "$REPO/skills/vault-brainstorming"  ~/.claude/skills/vault-brainstorming
ln -s "$REPO/skills/project-catchup"      ~/.claude/skills/project-catchup
ln -s "$REPO/skills/skill-from-session"   ~/.claude/skills/skill-from-session

# 3. Verify
readlink -f ~/.claude/CLAUDE.md
readlink -f ~/.claude/skills/followup-tracking
readlink -f ~/.claude/skills/vault-brainstorming
readlink -f ~/.claude/skills/project-catchup
readlink -f ~/.claude/skills/skill-from-session
```

To activate additional personal skills landed in this repo, repeat step 2 with the new skill's directory. Smoke-test in a fresh Claude Code session — `GLOBAL.md`'s content should be in context, the project `CLAUDE.md` should also be in context when the cwd is this repo, and any installed personal skill should be listed under available skills.

The full task-by-task install procedure (with backup logic, verification, and a fresh-session smoke test) is in `docs/plans/2026-05-15-personal-claude-customization-v1-plan.md`.

## Extending

To add a new personal skill:

1. Study `skills/followup-tracking/SKILL.md` and the references it cites.
2. Follow the TDD discipline: write a baseline pressure scenario, run it with a subagent **without** the skill, document what happened. Only then write the minimal skill.
3. Rerun the scenario **with** the skill loaded and record that the baseline failures are closed before calling it done.
4. Symlink the new skill directory into `~/.claude/skills/`.
