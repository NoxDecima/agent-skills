# Personal Claude Code Preferences

## Skill invocation

ALWAYS invoke `superpowers:using-superpowers` when starting any non-trivial task, including before asking clarifying questions. That meta-skill is responsible for dispatching the right downstream skill (brainstorming, debugging, verification-before-completion, etc.). Do not pick downstream skills directly — let `using-superpowers` route.

## Followup tracking

Capture deferrable items via the `followup-tracking` skill. The active list lives in TaskList (filter by `metadata.kind = "followup"`). On task completion, run the triage flow.

Persistence destinations: FUTURE.md, Linear, or both. Destination resolution (used by `followup-tracking`):

1. If this project's CLAUDE.md declares `Followups: linear | future | both` (optional `future=<path>`), use it without prompting. A CLAUDE.md with only a `Linear: team=X project=Y` line resolves to `linear`; that line also supplies the Linear coordinates.
2. Else if a destination was used earlier in this chat, suggest it as a default in a confirmation prompt.
3. Else if a `FUTURE.md` exists at the project root, suggest it as the default.
4. Else prompt the user with no defaults.

If the destination was resolved by asking (rungs 3–4), offer once to record it as a `Followups:` line in the project CLAUDE.md.

<!-- Reserved for additional small preferences as they arise. Keep this file under 200 lines total. -->
