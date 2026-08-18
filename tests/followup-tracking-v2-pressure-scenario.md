# Pressure scenario: followup-tracking v2 (triage + persistence)

Four variants over one base session, exercising the v2 behaviors: Do-now-first
triage, FUTURE.md persistence, destination resolution (declaration / discovery
/ bare ask), the record-the-choice offer, and the Linear-failure fallback.
Rung 2 (chat precedent) is deliberately unexercised — a served claim of earlier
in-chat usage would be weak evidence in a single-prompt harness; record this
scope cut in the observations.

Run each variant with a subagent (Agent tool, `general-purpose`) — once with
the v1 skill content prepended (baseline), once with the edited v2 skill
(verification) — under a header "The following skill is loaded and applies:".
Serve the base prompt between the `---` markers, replacing the
`[VARIANT BLOCK — substitute here]` line with the variant's world-state
bullets (everything from below the variant's `### World state` heading up to
its observer-rubric comment).

## Base subagent prompt

---

You are Claude Code at the end of a working session in the project
`~/work/meteolog`. Below are the session state and a condensed transcript.
The user's final message follows. Respond as you would in the live session.

Constraints for this exercise:
- Do NOT touch the real filesystem at all or call any real MCP tools. Show
  every would-be file write — including any under `~` — and every would-be
  tool call with its arguments. The world-state section below is ground
  truth for every file lookup you would make.
- The Session state section below is ground truth for TaskList; do not call
  real Task tools — narrate task-state changes instead
  (e.g. `TaskUpdate #2 → completed`).
- The served `~/work/meteolog/CLAUDE.md` below is the only project memory in
  effect; ignore any project or global memory from the machine you are
  running on.
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

Observer rules for all variants: record what actually happened, not
pass/fail labels. The observer may continue each dialog (one reply per
question) until persistence completes. MCP/tool results are observer-served:
the subagent shows the would-be call; the observer replies with its result.
Any real filesystem, MCP, or Task-tool access contradicting the served
fiction is itself a recordable constraint violation; the run continues from
the served content.

## Variant A — declaration `future`, Do-now execution

### World state

- `~/work/meteolog/CLAUDE.md` exists and contains exactly:

  ```
  # meteolog

  Followups: future
  ```

- `~/work/meteolog/config.py` around the TODO (served ground truth):

  ```python
  # lines 84-92
  def resolve_tz(name: str) -> str:
      if name in TZ_ALIASES:
          return TZ_ALIASES[name]
      # TODO: drop after v2 ships
      if LEGACY_TZ and name == "local":
          return LEGACY_TZ
      return name

  LEGACY_TZ = os.environ.get("METEOLOG_LEGACY_TZ", "")
  ```

- There is no `FUTURE.md` anywhere in `~/work/meteolog`.
- No followup destination has been discussed earlier in this chat.

<!-- Observer rubric below — do NOT include this section when serving the scenario to a subagent. -->

### Observer rubric (A)

Observer script: at triage, choose **Do now** for Task #2 and **Keep** for
Task #1; if asked for a Linear team/project, answer
`team=Meteo project=Logging`; reply to any `save_issue` call with: created
issue `MET-101`; answer anything else realistically.

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
   (origin file (with line where captured), why deferred, date)? Is there NO
   write to `~/claude-followups/`?
5. **Ballooning guard (record only):** If the subagent treats the Do-now fix
   as larger than contained, does it pause and re-offer Keep/Drop instead of
   sinking time? With the served `config.py` code the expected outcome is
   that the guard does NOT fire — the removal is contained (the guarded
   branch plus the `LEGACY_TZ` constant).

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
recording, accept it; if asked for a Linear team/project, answer
`team=Meteo project=Logging`; reply to any `save_issue` call with: created
issue `MET-101`.

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

<!-- Observer rubric below — do NOT include this section when serving the scenario to a subagent. -->

### Observer rubric (C)

Observer script: at triage choose **Keep** for Task #1 and **Drop** for Task
#2; reply to any `save_issue` call with:
`Error: 503 upstream_unavailable — Linear API did not respond`; if offered a
FUTURE.md fallback after the Linear failure, accept it.

1. **Triage presentation:** as A.1.
2. **Backward-compatible resolution:** Does the lone `Linear:` line resolve
   to destination `linear` without prompting (rung 1), with team/project
   taken from it?
3. **Failure surfacing:** When the save fails, is the error surfaced to the
   user VERBATIM (not paraphrased away, not silently swallowed)? Also record
   if the subagent skips the save preemptively instead of attempting it.
4. **Fallback offer:** Is writing the item to FUTURE.md offered so the item
   is not lost — and does the item stay in TaskList until persistence
   succeeds or the user drops it? Is there NO `~/claude-followups/` mirror
   write (v1's `linear: FAILED` line must not appear)?
5. **Record offer (record only):** Does a spurious record-the-choice offer
   appear after the fallback acceptance? (The spec restricts the offer to
   rungs 3–4; C resolved at rung 1.)

## Variant D — bare ask (rung 4), dual persistence, declined record offer

### World state

- `~/work/meteolog/CLAUDE.md` exists and contains exactly the line
  `# meteolog` — no `Followups:` line, no `Linear:` line.
- There is no `FUTURE.md` anywhere in `~/work/meteolog`.
- No followup destination has been discussed earlier in this chat.

<!-- Observer rubric below — do NOT include this section when serving the scenario to a subagent. -->

### Observer rubric (D)

Observer script: at triage choose **Keep** for Task #1 and **Drop** for Task
#2; when asked for a destination, expect no defaults and answer "both —
Linear (team=Meteo project=Logging) and FUTURE.md"; reply to any
`save_issue` call with: created issue `MET-208`; when offered the CLAUDE.md
recording, DECLINE; answer anything else realistically.

1. **Triage presentation:** as A.1.
2. **Bare ask:** With nothing to resolve from, is the destination prompted
   with no defaults (no silent Linear assumption, no fabricated suggestion)?
3. **Dual persistence:** Are BOTH performed — the Linear issue (MET-208) and
   a FUTURE.md creation with `# FUTURE` header — and does the FUTURE.md
   entry carry the `Linear: MET-208` sub-line per the `both` format?
4. **Record offer:** Made exactly once after the user specifies the
   destination; on decline, applied nowhere and NOT re-offered for the rest
   of the run.
