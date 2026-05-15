# claude-config — Project Memory

This repo is the source of the personal Claude Code customization layer. Edits in `skills/` and `GLOBAL.md` flow to `~/.claude/` via symlinks (see `README.md` for setup). Skill edits must follow TDD-for-skills (see `superpowers:writing-skills`): write a baseline pressure scenario, run it without the skill, document the failure modes, then write the minimal skill that closes them.

Linear: team=Nox project=claude-config
