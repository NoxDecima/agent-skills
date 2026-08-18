# Baseline observations: followup-tracking v2 (v1 skill loaded)

Date: 2026-08-18
Scenario: tests/followup-tracking-v2-pressure-scenario.md (commit 017e002)
Skill under test: v1 skills/followup-tracking/SKILL.md (prepended under "The
following skill is loaded and applies:")
Subagents: general-purpose, session-default model (Fable 5)
Dialogs: tests/followup-tracking-v2-baseline-dialogs.md (verbatim)

## Variant A — declaration `future`, Do-now execution

1. **Triage presentation: not met (v2 shape).** Triage did fire when the
   session closed — the first response ran per-item triage alongside the
   commit — but each block's action line was the v1 `action: Keep / Drop /
   Edit?`. No Do-now option was offered on either item; the observer's "Do
   now" for #2 was an off-menu answer.

2. **Do-now execution: improvised, and executed well.** On the observer's
   off-menu "Do now — just fix it in this session", the agent promoted the
   task ("`TaskUpdate #2 → in_progress` (promoted from followup to in-session
   work)"), showed the removal as a pure-deletion would-be edit covering the
   guarded branch plus the `LEGACY_TZ` constant, ran grep + pytest before
   committing, then caught and amended away the now-dead `import os`. #2 was
   marked completed, never persisted. This is exactly the v2-desired outcome
   — but it happened only because the user forced it; the skill gave no such
   option. The v2 edit must make this first-class, not improvised.

3. **Destination resolution: not met.** The `Followups: future` declaration
   was not honored. Verbatim: "this project's CLAUDE.md says `Followups:
   future`, which doesn't match the `Linear: team=X project=Y` format I can
   act on, and there's no `FUTURE.md` in the repo." The agent then asked for
   Linear coordinates ("which Linear team + project should kept items go to
   (or tell me what `Followups: future` is meant to point at)?") — a prompt
   that rung 1 forbids. To its credit it flagged the unknown line instead of
   silently ignoring it, but it could only fall back to Linear.

4. **FUTURE.md write: not met.** No FUTURE.md was created. #1 went to Linear
   (MET-101) plus a would-be append to `~/claude-followups/2026-08-18.md` —
   the v1 mirror v2 removes.

5. **Ballooning guard: correctly did not fire (record only).** The removal
   was treated as contained (branch + constant + dead import), matching the
   rubric's expectation for the served code. No pause/re-offer was needed.

## Variant B — no declaration, FUTURE.md exists, record offer

1. **Triage presentation: not met (v2 shape).** Triage fired after the commit
   landed, one block per item, action line `action: Keep / Drop / Edit?`. No
   Do-now option.

2. **Discovery suggestion: not met.** The existing `~/work/meteolog/FUTURE.md`
   (served in world state) was never mentioned in any exchange. Instead the
   agent assumed Linear as the destination and pre-announced the bare ask:
   "if you Keep anything I'll have to ask you for the Linear team and project
   with no defaults." Under v1's resolution chain that is correct behavior —
   v1 knows only Linear — but rung 3 (suggest the discovered FUTURE.md as a
   default) simply does not exist in v1.

3. **Record-the-choice offer: not met.** After the observer supplied
   `team=Meteo project=Logging`, no offer was made to record the destination
   in the project CLAUDE.md. (The observer's script never got to exercise the
   FUTURE.md branch because it was never suggested; per observer rules the
   run continued with the Linear coordinates.)

4. **Append format: not met.** Nothing was appended to FUTURE.md. Both items
   went to Linear (MET-101, MET-102) and were appended to
   `~/claude-followups/2026-08-18.md` via a Bash heredoc. Within v1's own
   spec the execution was clean: severity correctly omitted ("severity was
   never set at capture, so it's omitted, not defaulted"), `linear:` IDs
   recorded, tasks completed only after the write confirmed.

## Variant C — Linear declared, save fails, fallback offer

1. **Triage presentation: not met (v2 shape).** Triage fired in the first
   response, per-item blocks, `action: Keep / Drop / Edit?`. No Do-now
   option.

2. **Backward-compatible resolution: met.** The lone `Linear: team=Meteo
   project=Logging` line resolved without any prompt: "Kept items persist to
   Linear `team=Meteo project=Logging` (declared in `~/work/meteolog/
   CLAUDE.md`, so no destination prompt needed)." This is correct v1
   behavior and already matches v2's rung-1 backward-compat clause — the v2
   edit must preserve it.

3. **Failure surfacing: met.** The save was attempted, not preemptively
   skipped (the `save_issue` call was shown and awaited). On the served 503
   the error was surfaced verbatim: "Linear failed — surfacing verbatim:
   `Error: 503 upstream_unavailable — Linear API did not respond`."

4. **Fallback offer: not met.** No FUTURE.md fallback was offered. Instead,
   per v1's failure handling, the agent wrote the mirror line with
   `linear: FAILED` and called it "the durable record either way", then ran
   `TaskUpdate #1 → completed` — the task closed despite failed persistence,
   leaving the item nowhere but a FAILED-tagged mirror line. It did flag the
   gap honestly in prose ("Open thread: the Linear issue for #1 was never
   created. Retry ... when their API recovers"), but a prose note in a
   session wrap is not persistence, and TaskList no longer holds the item.
   v2's rule — item stays in TaskList until persisted or dropped — is the
   direct fix.

5. **Record offer: correctly absent (record only).** No spurious
   record-the-choice offer appeared (resolution was rung 1; v1 has no such
   offer anyway).

## Variant D — bare ask (rung 4), dual persistence, declined record offer

1. **Triage presentation: not met (v2 shape).** Triage in the first response,
   per-item blocks, `action: Keep / Drop / Edit?`. No Do-now option.

2. **Bare ask: shape met, framing not.** With nothing to resolve from, the
   agent prompted with genuinely no defaults and no fabricated suggestion:
   "this project's CLAUDE.md has no `Linear:` line and no destination was
   used earlier in this chat, so I'll need a Linear team + project from you
   (no defaults to offer)." That matches v2's rung-4 shape — but the question
   was Linear-only framed (which team/project), not a destination question
   (FUTURE.md / Linear / both). The observer had to volunteer "both — Linear
   (team=Meteo project=Logging) and FUTURE.md" unprompted.

3. **Dual persistence: improvised, format not met.** On explicit instruction
   the agent did perform both writes: Linear issue MET-208 and a new
   `~/work/meteolog/FUTURE.md` — plus the v1 mirror append. The improvised
   FUTURE.md does not follow the TODO.md convention: header `# Future work`
   (not `# FUTURE`), entry as a prose one-liner "- MET-208 — Add timezone
   edge-case tests for parse_window(): ..." with no `- [ ]` checkbox, no
   indented context sub-lines, and no `Linear: MET-208` sub-line (the ID is
   inlined into the subject). Good instincts alongside: it noted the file
   was untracked and offered to commit it.

4. **Record offer: not met.** No record-the-choice offer was ever made, so
   the scripted decline was never exercised.

## Run conditions & caveats

- Single run per variant, no repetition. Subagents were `general-purpose` on
  the session-default model (Fable 5) — the strongest available; the good
  improvised behaviors (A's Do-now execution, D's dual write) may be
  model-dependent and are not evidence the v1 skill text produces them.
- Observer-served tool results throughout: every Bash/MCP/file result the
  subagents saw was scripted observer fiction per the scenario's constraints;
  all writes are would-be writes, nothing touched a real filesystem or
  Linear. No constraint violations (real tool access) were observed in any
  run.
- Rung 2 (chat-precedent destination) is deliberately unexercised, per the
  fixture intro: a served claim of earlier in-chat usage would be weak
  evidence in a single-prompt harness. This scope cut carries over to the
  verification run.
- Where v1 behaved well it is recorded as such above: stop-and-wait tool
  discipline held in all four runs; severity was correctly omitted
  everywhere; C's rung-1 resolution, save attempt, and verbatim error
  surfacing are keep-as-is behaviors, not gaps.

## Failure modes to close

Every bullet is a concrete gap the Task 3 skill edit must close; the v2
design section that closes it is noted in parentheses.

- **No Do-now option at triage.** All four variants presented `action:
  Keep / Drop / Edit?`; Do now was never offered, and A executed it only as
  an off-menu user instruction. (Design §1.)
- **`Followups:` declaration unrecognized.** A's `Followups: future` was
  explicitly rejected ("doesn't match the `Linear: team=X project=Y` format
  I can act on") and triggered a destination prompt on what should be a
  rung-1 no-prompt resolution. (Design §3 rung 1.)
- **No FUTURE.md discovery suggestion.** B's existing `FUTURE.md` was never
  mentioned; Linear was assumed and a no-defaults Linear ask pre-announced.
  (Design §3 rung 3.)
- **Bare ask is Linear-only framed.** D asked for a Linear team + project,
  not for a destination; FUTURE.md/both entered only because the observer
  volunteered them. (Design §3 rung 4.)
- **No record-the-choice offer.** Neither B nor D offered to record the
  user-supplied destination as a `Followups:` line in the project CLAUDE.md.
  (Design §3, record-the-choice.)
- **Linear failure → `linear: FAILED` mirror line instead of a FUTURE.md
  fallback; task closed despite unpersisted item.** C surfaced the error
  correctly but then wrote a FAILED mirror line, called it the durable
  record, and marked the task completed — the item left TaskList with no
  successful persistence anywhere. (Design §4.)
- **Improvised FUTURE.md format does not follow the TODO.md convention.**
  D's file used a `# Future work` header and a prose one-liner — no `- [ ]`
  checkbox, no indented context sub-lines, no `Linear:` sub-line. (Design
  §2, FUTURE.md format.)
- **Mirror writes still present everywhere.** All four variants announced
  `~/claude-followups/2026-08-18.md` appends; v2 removes the mirror from the
  flow entirely, including its failure-handling role. (Design §2, §5.)
