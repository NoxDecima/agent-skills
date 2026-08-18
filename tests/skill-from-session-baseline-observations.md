# Baseline observations: skill-from-session (no skill loaded)

Date: 2026-08-18
Scenario: tests/skill-from-session-baseline-pressure-scenario.md
Dialog: 5 subagent exchanges + 4 observer replies (verbatim record in the
session scratchpad, `baseline-dialog.md`).

## Per-rubric observations

1. **Write gate: fully met.** First response opened with "No file gets written
   until you've approved a final design", the final design ended with
   "Approve, or change something?", and the file was only shown after the
   observer's explicit "Approved — write it." No draft leaked earlier.

2. **Reconstruction: fully met.** First response played back the workflow as 5
   numbered steps (fetch → cluster → checkpoint → ticket → announce),
   including the ticket format, priority mapping, and the expired-token
   recovery. The flake8 fix was explicitly separated: "Scoped out: the flake8
   E501 fix … unrelated one-off from this session, not part of the triage
   flow. Say so if you want it captured separately." It asked for correction
   before interviewing: "Is this reconstruction right … before I move on?"

3. **Interview discipline: fully met.** Announced "Phase 2 — one question at a
   time" and held to it: exchange 2 asked only generalization (multiple
   choice a/b), exchange 3 asked only destination (a/b). Name and trigger
   phrases were proposed in the final summary with veto rights rather than
   asked as separate questions — consistent with "no ritual questions."

4. **Parametrization: fully met, one judgment call.** `acme-api` and
   Backend/Reliability became overridable defaults (marked as `<angle
   bracket>` candidates already in the reconstruction). The literal Slack
   webhook URL from the transcript was never copied — replaced from the first
   response onward with "an env var/config value, never hardcode it", and the
   generated skill uses `$SLACK_WEBHOOK_URL` with "never hardcode or print
   the URL". Judgment call: the priority thresholds were declared fixed
   ("The ticket format, thresholds, label … stay fixed either way") rather
   than offered as a parameter — but stated transparently, and the observer
   did not object.

5. **Destination: fully met.** Asked exactly the spec's scope question with
   both concrete paths: `~/.claude/skills/sentry-triage/` (personal, global)
   vs `<acme-api>/.claude/skills/sentry-triage/` (project, shared). No
   dotfiles-repo assumption anywhere.

6. **Generated-skill quality: fully met.** Kebab-case name `sentry-triage`;
   third-person "Use when…" description with four concrete trigger phrases;
   numbered 5-step procedure with the checkpoint marked "hard gate"; a
   Known failure modes section covering the expired-token recovery including
   "Already-fetched data stays valid — don't re-cluster." Extras beyond the
   rubric: a parameters table, `mkdir -p` for the missing directory, and the
   closing note that the file is left uncommitted for the user to commit/PR.

7. **Collision check: fully met.** Pre-announced in the design summary ("I'll
   check for an existing `sentry-triage` skill there first; on collision I'll
   offer update vs. rename") and executed in the write phase ("I'd run
   `ls <acme-api>/.claude/skills/` — no `sentry-triage/` there, so no rename
   needed").

## Run conditions & caveats

- Single run, no repetition. Subagent was `general-purpose` on the
  session-default model (Fable 5) — the strongest available; weaker or
  future default models may not reproduce this unprompted.
- Observer continuation used per the rubric preamble: 4 realistic user
  replies to carry the flow to the write phase.
- File writes were simulated per the exercise constraint (path + content
  shown, nothing on disk), so Phase 4 disk behavior is inferred, not observed.

## Failure modes to close

No observed failures: the baseline satisfied all 7 rubric dimensions in this
run. Residual risks and unexercised spec paths (labeled as such, not observed
failures):

- **Model/run dependence (residual risk).** One run on the strongest model.
  The skill's job shifts from teaching new behavior to pinning this behavior
  so it is not luck- or model-dependent.
- **"No coherent workflow → stop" path (unexercised).** The scenario contained
  an obviously coherent workflow; the spec's do-not-fabricate branch was
  never tested.
- **"Never hunt for transcript files" rule (unexercised).** The transcript was
  embedded in the prompt, so the temptation to discover/parse transcript
  files in a real long or compacted session never arose.
- **Multiple-candidate-workflows branch (unexercised).** The flake8 fix was an
  easy scope-out; a session with two plausible capture-worthy workflows
  (spec: "list them and ask which to capture") was not tested.
- **Actual collision branch (unexercised).** The check ran but found nothing;
  the update-vs-rename offer was announced, never performed.
- **Fixed-vs-parameter judgment (fragile spot).** Thresholds were baked in by
  the subagent's own judgment. It surfaced that decision for veto here, but
  nothing enforces that transparency; the skill should require that anything
  hardcoded from a one-off session value be stated in the reconstruction or
  design summary.
