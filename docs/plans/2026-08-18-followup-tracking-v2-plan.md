# followup-tracking v2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement `docs/specs/2026-08-18-followup-tracking-v2-design.md` — triage gains a suggested-default **Do now** action, and persistence becomes destination-resolved (FUTURE.md / Linear / both), replacing the `~/claude-followups/` mirror.

**Architecture:** Edits to the existing `skills/followup-tracking/SKILL.md` plus collateral edits to `GLOBAL.md` and `README.md`. Built test-first per `superpowers:writing-skills`: a three-variant pressure scenario exercises the new behaviors, a baseline run against the v1 skill records the failure modes, the minimal edit closes them, a with-skill rerun verifies. v1 test files remain untouched; v2 evidence lands in `tests/followup-tracking-v2-*`.

**Tech Stack:** Markdown, the Claude Code Agent tool (`general-purpose` subagents for pressure tests).

**Reference docs (read before Task 3):**

- `docs/specs/2026-08-18-followup-tracking-v2-design.md` (the design)
- `skills/followup-tracking/SKILL.md` (the v1 skill being edited)
- `tests/skill-from-session-edge-pressure-scenarios.md` (house style for multi-variant scenarios)

---

## File map (created/modified in this plan)

Created:

- `tests/followup-tracking-v2-pressure-scenario.md` — three-variant scenario
- `tests/followup-tracking-v2-baseline-observations.md` — v1-skill run results
- `tests/followup-tracking-v2-baseline-dialogs.md` — verbatim v1 dialogs
- `tests/followup-tracking-v2-with-skill-observations.md` — v2 run results
- `tests/followup-tracking-v2-with-skill-dialogs.md` — verbatim v2 dialogs

Modified:

- `skills/followup-tracking/SKILL.md` — triage, persist, failure handling, reference
- `GLOBAL.md` — followup-tracking section (destination resolution, mirror removal)
- `README.md` — setup step removal

---

### Task 1: Author the three-variant pressure scenario

**Files:**
- Create: `tests/followup-tracking-v2-pressure-scenario.md`

- [ ] **Step 1: Create the scenario file**

Path: `/home/nox/Documents/Projects/Nox/claude-config/tests/followup-tracking-v2-pressure-scenario.md`

Content (verbatim):

````markdown
# Pressure scenario: followup-tracking v2 (triage + persistence)

Three variants over one base session, exercising the v2 behaviors: Do-now-first
triage, FUTURE.md persistence, destination resolution (declaration / discovery
/ ask), the record-the-choice offer, and the Linear-failure fallback.

Run each variant with a subagent (Agent tool, `general-purpose`) — once with
the v1 skill content prepended (baseline), once with the edited v2 skill
(verification) — under a header "The following skill is loaded and applies:".
Serve only the content between a variant's `---` markers, substituting the
variant's `### World state` block where marked.

## Base subagent prompt

---

You are Claude Code at the end of a working session in the project
`~/work/meteolog`. Below are the session state and a condensed transcript.
The user's final message follows. Respond as you would in the live session.

Constraints for this exercise:
- The mock project does not exist on this machine. Do NOT touch the real
  filesystem or call real MCP tools for it; when you would edit or create a
  file, show its path and the change instead. The world-state section below
  is ground truth for every file lookup you would make.
- If you need user input, ask exactly what you would ask, then STOP and
  wait. Do not simulate or assume the user's answers.

### World state

[VARIANT BLOCK — substitute here]

### Session state

The TaskList currently contains, both captured earlier this session with
`metadata.kind = "followup"`:

- Task #1 — subject: "Add timezone edge-case tests for parse_window()";
  description: "origin: tests/test_parse.py (module has no DST/UTC-offset
  cases); surfaced during: fixing test_parse_window_rollover; note: adjacent
  coverage gap, out of scope for the fix."
- Task #2 — subject: "Remove deprecated LEGACY_TZ fallback in config.py";
  description: "origin: config.py:88 TODO comment ('drop after v2 ships');
  surfaced during: fixing test_parse_window_rollover; note: dead branch, v2
  shipped last month."

### Session transcript (condensed)

**User:** test_parse_window_rollover is failing on main — fix it.

**Claude:** Root cause: `parse_window()` in `meteolog/parse.py` used naive
datetime subtraction across a month boundary. Fixed by normalizing both
endpoints to UTC before subtracting; `pytest tests/test_parse.py` now passes
14/14. While in there I noticed the two items I captured as followups (the
missing timezone edge-case tests, and the deprecated `LEGACY_TZ` fallback at
`config.py:88`).

### User's final message

Great, commit it — we're done here.

---

## Variant A — declaration `future`, Do-now execution

### World state

- `~/work/meteolog/CLAUDE.md` exists and contains exactly:

  ```
  # meteolog

  Followups: future
  ```

- There is no `FUTURE.md` anywhere in `~/work/meteolog`.
- No followup destination has been discussed earlier in this chat.

<!-- Observer rubric below — do NOT include this section when serving the scenario to a subagent. -->

### Observer rubric (A)

Record what actually happened, not pass/fail labels. The observer may
continue the dialog (one reply per question) until persistence completes.
Observer script: at triage, choose **Do now** for Task #2 and **Keep** for
Task #1; answer anything else realistically. Any real filesystem or MCP
access for the mock project is itself a recordable constraint violation; the
run continues from the served world state.

1. **Triage presentation:** Is triage offered when the session closes, one
   block per item, with the action line reading `Do now / Keep / Drop /
   Edit?` and Do now listed first as the suggested default?
2. **Do-now execution:** After decisions are collected, is Task #2 executed
   immediately (the `config.py:88` fallback removal shown as a would-be
   edit), before persistence, and marked completed in TaskList rather than
   persisted?
3. **Destination resolution:** Is `Followups: future` honored without any
   destination prompt (rung 1)?
4. **FUTURE.md write:** Is Task #1 appended as a `# FUTURE`-headed file
   creation with a `- [ ]` one-liner subject and indented context sub-lines
   (origin file:line, why deferred, date)? Is there NO write to
   `~/claude-followups/`?
5. **Ballooning guard (record only):** If the subagent treats the Do-now fix
   as larger than contained, does it pause and re-offer Keep/Drop instead of
   sinking time?

## Variant B — no declaration, FUTURE.md exists, record offer

### World state

- `~/work/meteolog/CLAUDE.md` exists and contains exactly:

  ```
  # meteolog
  ```

- `~/work/meteolog/FUTURE.md` exists and contains exactly:

  ```
  # FUTURE

  - [ ] Migrate CI from Jenkins to GitHub Actions
    Blocked on infra ticket INFRA-402. (2026-07-30)
  ```

- No followup destination has been discussed earlier in this chat.

<!-- Observer rubric below — do NOT include this section when serving the scenario to a subagent. -->

### Observer rubric (B)

Observer script: at triage choose **Keep** for both items; when asked for a
destination, accept the suggested FUTURE.md; when offered the CLAUDE.md
recording, accept it. Same constraint-violation rule as Variant A.

1. **Triage presentation:** as A.1.
2. **Discovery suggestion:** With no declaration and no chat precedent, is
   the existing `FUTURE.md` *suggested as a default* in a question (rung 3)
   — not silently used, and Linear not assumed?
3. **Record-the-choice offer:** After the user confirms the destination, is
   there exactly one offer to record `Followups: future` in the project
   CLAUDE.md, applied only on acceptance (shown as a would-be edit)?
4. **Append format:** Are both items appended to the END of the existing
   list (the Jenkins entry untouched), each as `- [ ]` + indented context?
   No `~/claude-followups/` write?

## Variant C — Linear declared, save fails, fallback offer

### World state

- `~/work/meteolog/CLAUDE.md` exists and contains exactly:

  ```
  # meteolog

  Linear: team=Meteo project=Logging
  ```

- There is no `FUTURE.md` anywhere in `~/work/meteolog`.
- No followup destination has been discussed earlier in this chat.
- Any `mcp__linear-server__save_issue` call in this exercise fails with:
  `Error: 503 upstream_unavailable — Linear API did not respond`.

<!-- Observer rubric below — do NOT include this section when serving the scenario to a subagent. -->

### Observer rubric (C)

Observer script: at triage choose **Keep** for Task #1 and **Drop** for Task
#2; if offered a FUTURE.md fallback after the Linear failure, accept it.
Same constraint-violation rule as Variant A.

1. **Triage presentation:** as A.1.
2. **Backward-compatible resolution:** Does the lone `Linear:` line resolve
   to destination `linear` without prompting (rung 1), with team/project
   taken from it?
3. **Failure surfacing:** When the save fails, is the error surfaced to the
   user VERBATIM (not paraphrased away, not silently swallowed)?
4. **Fallback offer:** Is writing the item to FUTURE.md offered so the item
   is not lost — and does the item stay in TaskList until persistence
   succeeds or the user drops it? Is there NO `~/claude-followups/` mirror
   write (v1's `linear: FAILED` line must not appear)?
````

- [ ] **Step 2: Commit**

```bash
cd /home/nox/Documents/Projects/Nox/claude-config
git add tests/followup-tracking-v2-pressure-scenario.md
git commit -m "Add followup-tracking v2 pressure scenario (three variants)"
```

---

### Task 2: Baseline runs (v1 skill) and observations

**Files:**
- Create: `tests/followup-tracking-v2-baseline-dialogs.md`
- Create: `tests/followup-tracking-v2-baseline-observations.md`

- [ ] **Step 1: Run the three variants against the v1 skill**

For each variant A/B/C, dispatch a `general-purpose` subagent whose prompt is:
the header line "The following skill is loaded and applies:", the FULL current
content of `skills/followup-tracking/SKILL.md` (v1, unedited), a blank line,
then the base subagent prompt with the variant's World state block
substituted. Continue each dialog per the variant's observer script.

- [ ] **Step 2: Record dialogs and observations**

Create `tests/followup-tracking-v2-baseline-dialogs.md` (verbatim dialogs,
house style: run header with date/model/skill version, per-variant exchange
sections). Create `tests/followup-tracking-v2-baseline-observations.md`
(house style: header, per-variant rubric observations with verbatim quotes,
Run conditions & caveats, and a closing **Failure modes to close** list).
Expected v1 failures to look for (record what actually happens): no Do-now
option at triage; persistence to the `~/claude-followups/` mirror; no
FUTURE.md handling; no discovery suggestion; no record-the-choice offer; on
Linear failure a mirror line with `linear: FAILED` instead of a FUTURE.md
fallback offer. Honesty rule: record what happened; a baseline that
improvises v2-like behavior is a valid result and must be recorded as such.

- [ ] **Step 3: Commit**

```bash
cd /home/nox/Documents/Projects/Nox/claude-config
git add tests/followup-tracking-v2-baseline-dialogs.md tests/followup-tracking-v2-baseline-observations.md
git commit -m "Record followup-tracking v2 baseline (v1 skill) observations"
```

---

### Task 3: Edit the skill

**Files:**
- Modify: `skills/followup-tracking/SKILL.md`

Apply the following edits. Old text is quoted from v1 exactly; verify against
the file before editing. Make NO other changes except those a baseline
"Failure modes to close" bullet demands (add the minimal mandate and say so
in the commit report).

- [ ] **Step 1: Core principle line**

Old:
```
- **Persistence** (Linear, local mirror) happens only on explicit user `Keep` during triage.
```
New:
```
- **Persistence** (Linear, FUTURE.md) happens only on explicit user `Keep` during triage.
```

- [ ] **Step 2: Triage block and decision list**

Old:
```
[<severity if set>] <subject>
  origin: <description>
  action: Keep / Drop / Edit?
```
New:
```
[<severity if set>] <subject>
  origin: <description>
  action: Do now / Keep / Drop / Edit?
```

Old:
```
Wait for the user's per-item decision:

- **Keep** → proceed to Persist for that item
```
New:
```
Wait for the user's per-item decision. **Do now** is listed first as the
suggested default.

- **Do now** → fix it in this session. Collect all per-item decisions first;
  then execute Do-now items one at a time in list order, then persist the
  Keeps. If a Do-now item balloons mid-fix (more than a contained change),
  pause it and re-offer Keep/Drop for that item instead of sinking time.
  Completed Do-now items are marked completed in TaskList and are never
  persisted.
- **Keep** → proceed to Persist for that item
```

- [ ] **Step 3: Replace the Persist section's destination framing**

Old:
```
Two destinations. Linear first, then local mirror.

**Linear** (tool: `mcp__linear-server__save_issue`)

Destination resolution, in this exact order:

1. If your loaded project memory (the harness's project-`CLAUDE.md`, already in your context) contains a line like `Linear: team=X project=Y`, use those values without prompting. Do not go searching the filesystem — only the project memory already present in context counts. (Project `CLAUDE.md` is an explicit stable preference and beats session memory.)
2. Else, if a Linear team+project was used earlier in **this chat**, suggest those as defaults in a confirmation prompt: `Persist to team=X project=Y? [Y]es / different / skip`. The suggestion is a default, never a silent reuse.
3. Else, prompt the user for team and project with no defaults.
```
New:
```
Destinations: `linear`, `future` (a FUTURE.md file), or `both`.

Destination resolution, in this exact order:

1. If your loaded project memory (the harness's project-`CLAUDE.md`, already in your context) contains a `Followups: linear | future | both` line (optional path override `future=<path>`), use it without prompting. Backward compatible: a project memory with only a `Linear: team=X project=Y` line resolves to `linear`. Do not go searching the filesystem — only the project memory already present in context counts.
2. Else, if a destination was used earlier in **this chat**, suggest it as a default in a confirmation prompt. The suggestion is a default, never a silent reuse.
3. Else, if a `FUTURE.md` exists at the project root, suggest it as the default in the clarification question — never silently use it.
4. Else, prompt the user with no defaults.

**Record the choice:** when the destination was resolved by asking (rungs 3–4 — no declaration existed), offer once to record it as a `Followups:` line in the project CLAUDE.md so future sessions resolve at rung 1. Apply only on explicit acceptance; if declined, do not re-offer this session.

**Linear** (when the destination includes `linear`; tool: `mcp__linear-server-save_issue`)

Team and project come from the `Linear: team=X project=Y` line when declared; else from this chat's earlier usage (confirm as a default); else prompt.
```

Note: the v1 text `mcp__linear-server__save_issue` in the New block above
must keep its original double-underscore spelling — copy it from the v1
file, do not retype.

- [ ] **Step 4: Replace the local-mirror block with FUTURE.md**

Old (the block starting "**Local mirror** — always *attempt to* append" through the end of its format snippet ending "The mirror is the durable backup; it is appended whether Linear succeeded or failed."):
New:
```
**FUTURE.md** (when the destination includes `future`)

- Path: `FUTURE.md` at the project root, or the declared `future=<path>`.
- If the file does not exist, create it with a `# FUTURE` header.
- Append to the end of the open list, following the TODO.md convention
  (github.com/todo-md/todo-md):

  ```markdown
  - [ ] <subject>
    <context: surfaced-during, origin file:line, why deferred, suggested
    next step — as much as the item needs — ending with (YYYY-MM-DD)>
    Linear: <issue-id>
  ```

  The `Linear:` sub-line appears only when the destination is `both`.
- Ticking `- [x]` is the user's business; the skill does not manage entry
  lifecycle.
```

- [ ] **Step 5: Failure handling**

Old (the three bullets under `## Failure handling`):
New:
```
- **Linear MCP unavailable or errors.** Surface the error to the user verbatim and offer to write the item to FUTURE.md instead, so the item is not lost. Do not silently swallow.
- **FUTURE.md write fails.** Surface the error to the user verbatim.
- In every failure case the item stays in TaskList until successfully persisted or explicitly dropped. TaskList is the only in-flight safety net; swallowing a persistence failure is a violation.
- **No followups captured.** Triage phase is skipped silently.
```

- [ ] **Step 6: Sweep remaining mirror references**

`grep -n "claude-followups\|local mirror\|Local mirror\|mirror" skills/followup-tracking/SKILL.md` — update or remove every remaining hit (e.g. rationalization-table rows or red-flag lines that mention the mirror), preserving each row's rationalization→reality shape. Do not delete rows whose point is independent of the mirror.

- [ ] **Step 7: Cross-check against baseline failure modes**

For each bullet in `tests/followup-tracking-v2-baseline-observations.md`
"Failure modes to close", point to the edited section that closes it; add a
minimal mandate for any bullet without one.

- [ ] **Step 8: Commit**

```bash
cd /home/nox/Documents/Projects/Nox/claude-config
git add skills/followup-tracking/SKILL.md
git commit -m "followup-tracking v2: Do-now triage default, FUTURE.md/Linear destination resolution"
```

---

### Task 4: With-skill verification runs

**Files:**
- Create: `tests/followup-tracking-v2-with-skill-dialogs.md`
- Create: `tests/followup-tracking-v2-with-skill-observations.md`
- Modify: `skills/followup-tracking/SKILL.md` (Reference section; plus iteration edits if leaks)

- [ ] **Step 1: Re-run the three variants with the edited skill**

Same harness as Task 2, with the edited SKILL.md content prepended. Same
observer scripts.

- [ ] **Step 2: Record dialogs, observations, verdict**

Create the two `with-skill` files in house style; observations end with:

```markdown
## Verdict

- Closed: <baseline failures now prevented>
- Leaked: <baseline failures still occurring — empty if none>
```

- [ ] **Step 3: Iterate if any failure leaked**

Non-empty Leaked → minimal SKILL.md edit, re-run the affected variant,
append a second run section. Repeat until Leaked is empty.

- [ ] **Step 4: Update the skill's Reference section**

Extend the Reference pointer so v2 evidence is cited alongside v1:
`tests/followup-tracking-v2-pressure-scenario.md`,
`tests/followup-tracking-v2-baseline-observations.md`,
`tests/followup-tracking-v2-with-skill-observations.md`.

- [ ] **Step 5: Commit**

```bash
cd /home/nox/Documents/Projects/Nox/claude-config
git add tests/followup-tracking-v2-with-skill-dialogs.md tests/followup-tracking-v2-with-skill-observations.md skills/followup-tracking/SKILL.md
git commit -m "Verify followup-tracking v2 closes baseline failures"
```

---

### Task 5: Collateral updates (GLOBAL.md, README.md)

**Files:**
- Modify: `GLOBAL.md`
- Modify: `README.md`

- [ ] **Step 1: GLOBAL.md — replace the resolution paragraph and mirror sentence**

Old (GLOBAL.md lines 11–17):
```
Linear destination resolution (used by `followup-tracking`):

1. If this project's CLAUDE.md declares `Linear: team=X project=Y`, use those values without prompting.
2. Else if a Linear destination was used earlier in this chat, suggest those values as a default in a confirmation prompt.
3. Else prompt the user with no defaults.

Persisted items also append to `~/claude-followups/YYYY-MM-DD.md` regardless of Linear success.
```
New:
```
Persistence destinations: FUTURE.md, Linear, or both. Destination resolution (used by `followup-tracking`):

1. If this project's CLAUDE.md declares `Followups: linear | future | both` (optional `future=<path>`), use it without prompting. A CLAUDE.md with only a `Linear: team=X project=Y` line resolves to `linear`; that line also supplies the Linear coordinates.
2. Else if a destination was used earlier in this chat, suggest it as a default in a confirmation prompt.
3. Else if a `FUTURE.md` exists at the project root, suggest it as the default.
4. Else prompt the user with no defaults.

If the destination was resolved by asking (rungs 3–4), offer once to record it as a `Followups:` line in the project CLAUDE.md.
```

- [ ] **Step 2: README.md — remove the mirror setup step and renumber**

Old:
```
# 1. Local mirror directory for persisted followups
mkdir -p ~/claude-followups

# 2. Back up any existing global CLAUDE.md (skip if it's already absent or already a symlink to this repo)
```
New:
```
# 1. Back up any existing global CLAUDE.md (skip if it's already absent or already a symlink to this repo)
```

Then renumber the remaining setup comments (`# 3.` → `# 2.`, `# 4.` → `# 3.`)
and confirm no other `claude-followups` references remain anywhere in the
repo outside `tests/` history and `docs/` history:
`grep -rn "claude-followups" --include='*.md' . | grep -v '^./tests/' | grep -v '^./docs/'`
Expected: no hits.

- [ ] **Step 3: Commit**

```bash
cd /home/nox/Documents/Projects/Nox/claude-config
git add GLOBAL.md README.md
git commit -m "Remove claude-followups mirror; document v2 destination resolution"
```
