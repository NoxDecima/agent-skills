# Personal Claude Code Preferences

## Skill invocation

ALWAYS invoke `superpowers:using-superpowers` when starting any non-trivial task, including before asking clarifying questions. That meta-skill is responsible for dispatching the right downstream skill (brainstorming, debugging, verification-before-completion, etc.). Do not pick downstream skills directly — let `using-superpowers` route.

## Followup tracking

Capture deferrable items via the `followup-tracking` skill. The active list lives in TaskList (filter by `metadata.kind = "followup"`). On task completion, run the triage flow.

Linear destination resolution (used by `followup-tracking`):

1. If this project's CLAUDE.md declares `Linear: team=X project=Y`, use those values without prompting.
2. Else if a Linear destination was used earlier in this chat, suggest those values as a default in a confirmation prompt.
3. Else prompt the user with no defaults.

Persisted items also append to `~/claude-followups/YYYY-MM-DD.md` regardless of Linear success.

<!-- Reserved for additional small preferences as they arise. Keep this file under 200 lines total. -->
