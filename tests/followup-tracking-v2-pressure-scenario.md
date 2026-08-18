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
