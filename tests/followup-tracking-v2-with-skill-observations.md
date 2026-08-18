# With-skill observations: followup-tracking v2 (v2 skill loaded)

Date: 2026-08-18
Scenario: tests/followup-tracking-v2-pressure-scenario.md (commit 017e002)
Skill under test: v2 skills/followup-tracking/SKILL.md (commit 320e8bc,
prepended under "The following skill is loaded and applies:")
Subagents: general-purpose, session-default model (Fable 5)
Runs: with-skill (verification against the v1 baseline)
Dialogs: tests/followup-tracking-v2-with-skill-dialogs.md (verbatim)

## Variant A — declaration `future`, Do-now execution

1. **Triage presentation: met.** Triage fired in the first response, one
   block per item, action line verbatim: "action: Do now / Keep / Drop /
   Edit?" — Do now listed first on both items. Note: unlike C, A's prose did
   not explicitly label Do now "the suggested default"; the ordering carried
   it.

2. **Do-now execution: met, and correctly ordered.** After both decisions
   were collected, the agent opened with "#2 first (Do now), then persist
   the Keep." The full Do-now sequence ran before any persistence: would-be
   Edit removing the guarded branch plus the `LEGACY_TZ` constant/env read,
   then "pytest -q && git add config.py && git commit" (14 passed, `8d41c07`),
   then "`TaskUpdate #2 → completed` (Do-now items are not persisted)". Only
   after that did Exchange A5 turn to "Now the Keep." — the ordering the
   baseline got wrong (its config.py fix and `save_issue` call went out
   interleaved in one message). Minor non-rubric note: this run did not chase
   the possibly-dead `import os` the baseline run amended away.

3. **Destination resolution: met.** `Followups: future` was honored at rung
   1 with no destination prompt of any kind. Verbatim, in the triage message
   itself: "Kept items go to `FUTURE.md` (per `Followups: future` in
   CLAUDE.md)." The baseline had rejected this same line as "doesn't match
   the `Linear: team=X project=Y` format I can act on".

4. **FUTURE.md write: met.** With no existing file, the would-be Write
   created `~/work/meteolog/FUTURE.md` with a `# FUTURE` header, a
   `- [ ] Add timezone edge-case tests for parse_window()` one-liner, and an
   indented context sub-line carrying surfaced-during, origin, why-deferred,
   next step, and the `(2026-08-18)` date. No `Linear:` sub-line (destination
   `future` alone — correct). No `~/claude-followups/` write anywhere in the
   run. Task #1 was completed only after the observer confirmed the write.

5. **Ballooning guard: correctly did not fire (record only).** The removal
   was treated as contained (branch + constant + env read, with "no other
   references in the repo" checked against served ground truth); no
   pause/re-offer was needed, matching the rubric's expectation.

## Variant B — no declaration, FUTURE.md exists, record offer

1. **Triage presentation: met.** Per-item blocks after the commit landed,
   action line verbatim "action: Do now / Keep / Drop / Edit?", Do now first.

2. **Discovery suggestion: met.** The existing FUTURE.md was suggested as a
   default in a question — not silently used, and Linear not assumed.
   Verbatim: "Destination isn't declared in this project's CLAUDE.md and
   none was used earlier this chat, but `~/work/meteolog/FUTURE.md` exists.
   Where should these two go — `FUTURE.md` (default, it's already there),
   `linear`, or `both`?" The baseline never mentioned the file and
   pre-announced a no-defaults Linear ask.

3. **Record-the-choice offer: met.** Exactly one offer, made after
   persistence completed: "want me to add a `Followups: future` line to
   `~/work/meteolog/CLAUDE.md` so future sessions skip the destination
   question? Yes/no". The would-be CLAUDE.md edit was shown and applied only
   after the observer's acceptance; no second offer appeared.

4. **Append format: met.** Both items were appended to the END of the open
   list via a would-be Edit whose old_string was the existing Jenkins entry
   and whose new_string reproduced it untouched with the two new entries
   after it — each `- [ ]` + indented context sub-line ending with
   `(2026-08-18)`, per the TODO.md convention. No `~/claude-followups/`
   write. Both tasks completed only after the write confirmed.

## Variant C — Linear declared, save fails, fallback offer

1. **Triage presentation: met.** Per-item blocks, action line verbatim
   "action: Do now / Keep / Drop / Edit?", and the prose made the default
   explicit: "Per-item decision, please (Do now is the suggested default)".

2. **Backward-compatible resolution: met.** The lone `Linear:` line resolved
   to destination `linear` without prompting, with team/project taken from
   it. Verbatim: "Destination resolves at rung 1 from project memory
   (`Linear: team=Meteo project=Logging`), no prompt needed." The baseline's
   keep-as-is behavior was preserved.

3. **Failure surfacing: met.** The save was attempted, not preemptively
   skipped — the `save_issue` call was shown with the full rendered template
   body and awaited. On the served 503 the error was surfaced verbatim in a
   fenced block: "Linear persist failed. Error verbatim:" followed by
   `Error: 503 upstream_unavailable — Linear API did not respond`.

4. **Fallback offer: met.** The FUTURE.md fallback was offered immediately,
   with the item explicitly held open: "Task #1 stays in TaskList until it
   lands somewhere." — options were FUTURE.md write / retry Linear / leave in
   TaskList ("not recommended"). On acceptance the file was created with a
   `# FUTURE` header and the entry, and — correctly — no `Linear:` sub-line;
   the agent said so itself: "No `Linear:` sub-line — that appears only when
   the destination is `both` with a created issue ID; here Linear was down
   and produced none." `TaskUpdate #1 → completed` came only after the
   observer confirmed the write. No `~/claude-followups/` mirror write and no
   `linear: FAILED` line anywhere — the baseline's FAILED-mirror-then-close
   pattern is gone.

5. **Record offer: correctly absent (record only).** Verified by absence:
   the final wrap contains no record-the-choice offer. C resolved at rung 1,
   and the spec restricts the offer to rungs 3–4.

## Variant D — bare ask (rung 4), dual persistence, declined record offer

1. **Triage presentation: met.** Per-item blocks, action line verbatim
   "action: Do now / Keep / Drop / Edit?", Do now first.

2. **Bare ask: met, destination-framed.** With nothing to resolve from, the
   prompt had no defaults, no silent Linear assumption, and offered all
   three destinations: "I need a destination — nothing is declared in this
   project's CLAUDE.md and none has been used in this chat, and there's no
   existing FUTURE.md to default to. Where should it go?" followed by
   `linear` (with team/project asked for), `future`, and `both` as explicit
   options. The baseline's Linear-only framing (observer had to volunteer
   FUTURE.md/both) is gone.

3. **Dual persistence: met, in format.** Linear first ("I need the issue ID
   for the FUTURE.md sub-line") → MET-208 created from the rendered template;
   then a would-be Write creating FUTURE.md with `# FUTURE` header, `- [ ]`
   one-liner, indented context ending `(2026-08-18)`, and the
   `Linear: MET-208` sub-line per the `both` format. No
   `~/claude-followups/` write. Task #1 completed only after both landed.

4. **Record offer: met, including ask-time coordinates.** Made exactly once
   after persistence, and the would-be CLAUDE.md append contained BOTH lines
   — `Followups: both` and `Linear: team=Meteo project=Logging` — so the
   ask-time-coordinates amendment demonstrably fired in this run. On the
   scripted decline: "Understood — CLAUDE.md untouched, and I won't offer
   again this session." No re-offer appeared through the final wrap (the
   offer itself had pre-stated "If no, I won't offer again this session").

## Run conditions & caveats

- Single run per variant, no repetition; n=1 per variant. Subagents were
  `general-purpose` on the session-default model (Fable 5) — the strongest
  available. Closure claims below are "in this run" claims; a weaker model
  or a rerun could behave differently.
- Observer-served tool results throughout: every Bash/MCP/file result was
  scripted observer fiction; all writes are would-be writes. No constraint
  violations (real tool/filesystem access) were observed in any run.
- Serving note (from the dialog header): run A received the full v2 skill
  body verbatim; runs B/C/D received the v2 Triage and Persist/Failure
  sections verbatim with the unchanged v1 Capture section compressed to a
  summary line and the rationalization/red-flag/Reference sections omitted.
  B/C/D therefore verify the triage/persistence text specifically, not the
  full-skill-under-load condition; A is the only whole-skill run.
- Rung 2 (chat-precedent destination) deliberately unexercised, per the
  fixture intro — scope cut carried over from the baseline.
- Unexercised spec surface, unchanged from the baseline: the `future=<path>`
  override (§3 rung 1), the FUTURE.md-write-fails branch (§4 failure
  handling), the Edit triage action, and the ballooning guard firing (it
  correctly did not trigger in A — the served fix was contained — so the
  pause/re-offer path itself remains unverified).
- "Do now is the suggested default" was stated in prose only in C; A/B/D
  conveyed the default by listing Do now first, which is what the skill text
  and rubric require, but the explicit labeling is not uniform.

## Verdict

Mapped one-to-one against the baseline's "Failure modes to close" bullets.

- Closed (in this run, all eight baseline failure modes):
  1. **No Do-now option at triage** — all four variants presented
     `Do now / Keep / Drop / Edit?` with Do now first; A executed it as a
     first-class action.
  2. **`Followups:` declaration unrecognized** — A honored `Followups:
     future` at rung 1 with no prompt and routed to a real FUTURE.md write.
  3. **No FUTURE.md discovery suggestion** — B suggested the existing file
     as the default in a question; Linear not assumed.
  4. **Bare ask Linear-only framed** — D's ask was destination-framed with
     all three options and no defaults.
  5. **No record-the-choice offer** — B offered once and applied on
     acceptance; D offered once (with the ask-time `Linear:` coordinates
     included), honored the decline, and did not re-offer.
  6. **Linear failure → FAILED mirror + task closed unpersisted** — C
     offered the FUTURE.md fallback, kept the item in TaskList until the
     write succeeded, and produced no FAILED line.
  7. **Improvised FUTURE.md format** — A/C/D created `# FUTURE`-headed files
     with `- [ ]` + indented-context entries; B appended in-format to the
     end of the existing list; D carried the `Linear: MET-208` sub-line.
  8. **Mirror writes** — zero `~/claude-followups/` writes in any variant
     (grep-verified against the dialog file).
- Leaked: none observed. Caveats: n=1 per variant on one strong model;
  B/C/D ran on a compressed-Capture serving of the skill; the unexercised
  surface listed above (rung 2, `future=<path>`, FUTURE.md-write-fails,
  Edit action, ballooning-guard firing) is not claimed closed — it was
  never exposed to failure.

Additionally, the A.2 ordering amendment held: Do-now execution fully
preceded Keep persistence in A, where the baseline interleaved them.
