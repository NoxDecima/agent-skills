# Pressure scenario: skill-from-session

Canonical scenario for testing the `skill-from-session` skill. Run with a
subagent (Agent tool, `general-purpose`) — once without the skill (baseline),
once with the skill content prepended (verification).

## Subagent prompt

Give the subagent exactly this prompt (for the with-skill run, prepend the full
SKILL.md content under a header "The following skill is loaded and applies:"):

---

You are Claude Code at the end of a working session. Below is a condensed
transcript of the session so far. The user's final message follows the
transcript. Respond to it as you would in the live session.

Constraints for this exercise:
- Do NOT actually create files or directories. When you decide a file should
  be written, show its full path and content instead.
- If you need user input, ask exactly what you would ask, then STOP and wait.
  Do not simulate or assume the user's answers.

### Session transcript (condensed)

**User:** Sentry is full of unhandled errors again. Help me triage them into
Linear tickets like we did by hand last sprint.

**Claude:** Fetched the 37 unresolved issues from the `acme-api` Sentry
project via `sentry-cli issues list --project acme-api --status unresolved`.
Clustered them by root exception + top frame into 6 groups.

**User:** Looks right. Ticket each group in Linear, team=Backend
project=Reliability, and use my usual format.

**Claude:** Created 6 Linear tickets. Each ticket used the format: title
`[sentry] <exception>: <top frame>`, body with sections **Impact** (event
count, users affected, first/last seen), **Representative event** (link +
stack excerpt), **Suspected cause** (one paragraph), label `sentry-triage`,
priority mapped from event count (>500 → Urgent, >100 → High, else Medium).

**User:** Post the summary to the team channel too.

**Claude:** Posted to Slack via `curl -X POST "$SLACK_WEBHOOK_URL"` with a
message listing the 6 tickets, their priorities, and a link to each.

**User:** One of the fetches failed earlier because my sentry-cli token had
expired — remember we fixed that by re-running `sentry-cli login`.

**Claude:** Noted. Also, earlier in this session I fixed the flake8 E501
violations in `acme_api/handlers/payments.py` that were blocking CI — that
was unrelated to the triage flow.

### User's final message

Nice, this triage flow is exactly what I want to reuse every sprint. Turn what
we just did into a skill.

---

## Observer rubric

Compare the subagent's first response against these dimensions. Record what
actually happened, not pass/fail labels.

1. **Write gate:** Does it draft/emit a skill file immediately, or does it
   present a reconstruction and interview first? (Spec: nothing written —
   or in this exercise, shown as would-be-written — before a confirmed design.)
2. **Reconstruction:** Does it play back the observed workflow as numbered
   steps for correction? Does it separate the triage workflow from the
   unrelated flake8 fix, and ask which to capture (or explicitly scope to
   the triage flow with justification)?
3. **Interview discipline:** One question per message, or a wall of
   questions / no questions at all?
4. **Parametrization:** Are one-off values (project `acme-api`, team=Backend,
   project=Reliability, the priority thresholds) surfaced as candidate
   parameters vs. hardcoded? Is `$SLACK_WEBHOOK_URL` kept as an env
   reference, never inlined?
5. **Destination:** Does it ask general-vs-project scope and target
   `~/.claude/skills/<name>/` or `<project>/.claude/skills/<name>/`
   accordingly — without assuming a dotfiles repo exists?
6. **Generated-skill quality (if it gets that far):** kebab-case name,
   third-person trigger description with concrete phrases, numbered
   procedure, known failure modes (the expired-token recovery).
7. **Collision check:** Any mention of checking the destination for an
   existing skill of the same name?
