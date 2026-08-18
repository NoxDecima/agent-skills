# skill-from-session Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the `skill-from-session` personal skill per `docs/specs/2026-08-18-skill-from-session-design.md` — an end-of-session skill that reconstructs the just-completed workflow from the conversation, interviews the user one question at a time, confirms a final design, and only then writes a new SKILL.md to the right location.

**Architecture:** A single new skill directory `skills/skill-from-session/SKILL.md` in this repo, symlinked into `~/.claude/skills/`. Built test-first per `superpowers:writing-skills`: a pressure scenario (a mock session transcript ending in "turn what we just did into a skill") is run against a no-skill subagent to record baseline failure modes, then the SKILL.md is written so each mandated behavior closes an observed failure, then a with-skill rerun verifies closure.

**Tech Stack:** Markdown, bash/POSIX symlinks, the Claude Code Agent tool (`general-purpose` subagents for pressure tests).

**Reference docs (read before Task 3):**

- `superpowers:writing-skills` SKILL.md (TDD-for-skills, frontmatter/description conventions)
- `skills/vault-brainstorming/SKILL.md` (in-repo precedent for skill shape and phase structure)
- `docs/specs/2026-08-18-skill-from-session-design.md` (the design this plan implements)

---

## File map (created/modified in this plan)

Created:

- `tests/skill-from-session-baseline-pressure-scenario.md` — pressure scenario
- `tests/skill-from-session-baseline-observations.md` — no-skill run results
- `skills/skill-from-session/SKILL.md` — the skill
- `tests/skill-from-session-with-skill-observations.md` — with-skill run results
- `~/.claude/skills/skill-from-session` (symlink) — filesystem only, not in repo

Modified:

- `README.md` — add `skill-from-session` to the symlink-install and verify blocks

---

### Task 1: Author the pressure scenario

**Files:**
- Create: `tests/skill-from-session-baseline-pressure-scenario.md`

- [ ] **Step 1: Create the scenario file**

Path: `/home/nox/Documents/Projects/Nox/claude-config/tests/skill-from-session-baseline-pressure-scenario.md`

Content (verbatim):

````markdown
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
````

- [ ] **Step 2: Commit**

```bash
cd /home/nox/Documents/Projects/Nox/claude-config
git add tests/skill-from-session-baseline-pressure-scenario.md
git commit -m "Add skill-from-session baseline pressure scenario"
```

---

### Task 2: Baseline run (no skill) and observations

**Files:**
- Create: `tests/skill-from-session-baseline-observations.md`

- [ ] **Step 1: Dispatch the baseline subagent**

Use the Agent tool, `subagent_type: "general-purpose"`, with exactly the
"Subagent prompt" section from `tests/skill-from-session-baseline-pressure-scenario.md`
(everything between the two `---` markers, including the transcript and final
message). Do NOT include any skill content.

- [ ] **Step 2: Record observations**

Create `/home/nox/Documents/Projects/Nox/claude-config/tests/skill-from-session-baseline-observations.md`:

```markdown
# Baseline observations: skill-from-session (no skill loaded)

Date: <run date>
Scenario: tests/skill-from-session-baseline-pressure-scenario.md

## Per-rubric observations

1. Write gate: <what happened>
2. Reconstruction: <what happened>
3. Interview discipline: <what happened>
4. Parametrization: <what happened>
5. Destination: <what happened>
6. Generated-skill quality: <what happened>
7. Collision check: <what happened>

## Failure modes to close

- <bulleted list of the concrete failures the skill must prevent>
```

Fill every `<…>` with what the subagent actually did — quote short excerpts
where useful. The "Failure modes to close" list drives Task 3.

- [ ] **Step 3: Commit**

```bash
cd /home/nox/Documents/Projects/Nox/claude-config
git add tests/skill-from-session-baseline-observations.md
git commit -m "Record skill-from-session baseline (no-skill) observations"
```

---

### Task 3: Write the skill

**Files:**
- Create: `skills/skill-from-session/SKILL.md`

- [ ] **Step 1: Read the baseline observations**

Read `tests/skill-from-session-baseline-observations.md`. Every failure mode
listed there must map to an explicit mandate in the SKILL.md below. If the
baseline surfaced a failure the draft below does not cover, add a minimal
mandate for it; if the baseline shows a behavior below is unnecessary, still
keep spec-mandated behaviors (write gate, reconstruction, one-question
interview, destination logic) — they are design requirements, not hypotheses.

- [ ] **Step 2: Create the skill file**

Path: `/home/nox/Documents/Projects/Nox/claude-config/skills/skill-from-session/SKILL.md`

Content (verbatim; adjust only per Step 1):

````markdown
---
name: skill-from-session
description: Invoke at the END of a session when the user asks to turn the workflow that just happened in THIS conversation into a persistent, reusable skill. Trigger phrases include "turn this into a skill", "make a skill from what we just did", "capture this workflow", "skillify this session", "I want to reuse this flow" (or close variants referring to the current session's work). Do NOT invoke for creating a skill from scratch, from a spec, or from an idea — that is `superpowers:writing-skills` territory. The trigger is a completed, repeatable workflow present in the current conversation.
---

# skill-from-session

## Overview

Turn the workflow that just happened in this session into a persistent skill.
Reconstruct what was done from the conversation, refine it through a
one-question-at-a-time interview, confirm the final design, and only then
write the SKILL.md to the right location.

The entire source material is the current conversation — never go hunting for
transcript files on disk.

<HARD-GATE>
Write NOTHING to disk until the user has approved the final design summary in
Phase 3. Drafting the skill file "to save time" before approval is a
violation.
</HARD-GATE>

## Phase 1 — Reconstruction

Scan the conversation and present the workflow you observed as **numbered
steps**, naming the tools/commands used at each step. Then let the user
correct it before asking anything else.

- If the session contains **more than one** candidate workflow (e.g., the main
  flow plus an unrelated side-fix), list them and ask which to capture.
- If the session contains **no coherent repeatable workflow**, say exactly
  that and stop. Do not fabricate a workflow to have something to capture.

## Phase 2 — Interview

One question per message. Multiple choice preferred. Ask **only** questions
whose answers change the resulting file — skip anything the reconstruction or
the conversation already settled. Cover, in order:

1. **Generalization** — which steps were one-off vs. essential. Every value
   that varies per use becomes a named parameter in the skill. Secrets and
   user-/machine-specific paths are ALWAYS parametrized (env-var reference or
   placeholder), never hardcoded — even if the user doesn't mention them.
2. **Trigger** — when should future-Claude invoke this skill; collect 2–4
   concrete trigger phrases.
3. **Scope & destination** —
   - general (useful in any project) → `~/.claude/skills/<name>/SKILL.md`
   - project-specific → `<project>/.claude/skills/<name>/SKILL.md`
   Do not assume a dotfiles/claude-config repo exists; write to the real
   destination directly.
4. **Name** — propose one kebab-case name; user confirms or renames.

## Phase 3 — Confirmation gate

Present the final design in chat: name, trigger description, destination
path, numbered step outline, parameters. Ask for explicit approval.
Revisions loop back to this gate. Nothing is written until approval.

## Phase 4 — Write

After approval:

1. Check the destination for an existing `<name>/` — on collision, offer
   update vs. rename before touching anything.
2. Create the destination directory if missing.
3. Write the SKILL.md following `superpowers:writing-skills` principles:
   - frontmatter: kebab-case `name`, rich third-person `description` opening
     with when to invoke and including the trigger phrases from Phase 2
   - an Overview stating purpose in 1–3 sentences
   - a concrete numbered procedure with real commands/tool calls,
     parameters clearly marked
   - known failure modes and their fixes, if the session surfaced any
     (e.g., an auth token expiring mid-flow and how it was recovered)
4. Report the written path. If the destination is inside a git repo, note
   the file is uncommitted; do not commit unless asked.

This is a light capture: do NOT run the TDD-for-skills baseline-test loop on
the generated skill — the session itself is the evidence the workflow works.
````

- [ ] **Step 3: Cross-check against baseline failure modes**

For each bullet under "Failure modes to close" in
`tests/skill-from-session-baseline-observations.md`, point to the SKILL.md
line/section that prevents it. If any bullet has no counterpart, add the
minimal mandate that closes it.

- [ ] **Step 4: Commit**

```bash
cd /home/nox/Documents/Projects/Nox/claude-config
git add skills/skill-from-session/SKILL.md
git commit -m "Add skill-from-session skill"
```

---

### Task 4: With-skill verification run

**Files:**
- Create: `tests/skill-from-session-with-skill-observations.md`

- [ ] **Step 1: Dispatch the with-skill subagent**

Agent tool, `subagent_type: "general-purpose"`. Prompt = the header line
"The following skill is loaded and applies:" + the full content of
`skills/skill-from-session/SKILL.md` + a blank line + the same "Subagent
prompt" section from the pressure scenario used in Task 2.

- [ ] **Step 2: Record observations**

Create `/home/nox/Documents/Projects/Nox/claude-config/tests/skill-from-session-with-skill-observations.md`
with the same structure as the baseline file (7 rubric entries), plus:

```markdown
## Verdict

- Closed: <baseline failures now prevented>
- Leaked: <baseline failures still occurring — empty if none>
```

- [ ] **Step 3: Iterate if any failure leaked**

If "Leaked" is non-empty: edit `skills/skill-from-session/SKILL.md` with the
minimal added mandate, re-run Step 1–2 (append a second run section to the
observations file), repeat until Leaked is empty.

- [ ] **Step 4: Commit**

```bash
cd /home/nox/Documents/Projects/Nox/claude-config
git add tests/skill-from-session-with-skill-observations.md skills/skill-from-session/SKILL.md
git commit -m "Verify skill-from-session closes baseline failures"
```

---

### Task 5: Install symlink and update README

**Files:**
- Modify: `README.md` (symlink-install and verify blocks)
- Create: `~/.claude/skills/skill-from-session` (symlink, filesystem only)

- [ ] **Step 1: Create the symlink**

```bash
ln -s "$HOME/Documents/Projects/Nox/claude-config/skills/skill-from-session" ~/.claude/skills/skill-from-session
readlink -f ~/.claude/skills/skill-from-session
```

Expected output: `/home/nox/Documents/Projects/Nox/claude-config/skills/skill-from-session`

- [ ] **Step 2: Update README**

In `README.md`, in the step-3 symlink block, after the line

```
ln -s "$REPO/skills/project-catchup"      ~/.claude/skills/project-catchup
```

add:

```
ln -s "$REPO/skills/skill-from-session"   ~/.claude/skills/skill-from-session
```

and in the step-4 verify block, after

```
readlink -f ~/.claude/skills/project-catchup
```

add:

```
readlink -f ~/.claude/skills/skill-from-session
```

- [ ] **Step 3: Commit**

```bash
cd /home/nox/Documents/Projects/Nox/claude-config
git add README.md
git commit -m "Install skill-from-session symlink; document in README"
```
