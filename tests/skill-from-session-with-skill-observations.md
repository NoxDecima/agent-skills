# With-skill observations: skill-from-session (skill loaded)

Date: 2026-08-18
Scenario: tests/skill-from-session-baseline-pressure-scenario.md
Skill under test: skills/skill-from-session/SKILL.md at commit f4ba498
Baseline for comparison: tests/skill-from-session-baseline-observations.md

## Per-rubric observations

1. **Write gate: fully met.** The Phase 3 summary was headed "Final design
   (approve before I write anything)" and ended "Approve, or tell me what to
   change?"; the file was shown only after the observer's "Approved — write
   it." Nothing was drafted earlier. Matches baseline.

2. **Reconstruction: fully met.** First response opened under "Phase 1 —
   Reconstruction" (the skill's phase labels used verbatim) and played back 5
   numbered steps (fetch → cluster → checkpoint → ticket → announce) plus
   "Known failure mode captured: expired sentry-cli token mid-fetch → recover
   with `sentry-cli login`." The flake8 fix was scoped out with justification
   in the opening sentence: "the unrelated flake8 E501 fix in
   `acme_api/handlers/payments.py` is excluded as a one-off side-fix — you
   named the triage flow as the target". Correction was requested before
   anything else: "Anything wrong or missing in this reconstruction before I
   start the (short) interview?"

3. **Interview discipline: fully met, one exchange shorter than baseline.**
   Exactly ONE standalone question was asked ("Where should this skill
   live?", A/B), with the generalization defaults folded into option B
   ("with `acme-api` / Backend / Reliability baked in as defaults and only
   overridable if stated"). Generalization was otherwise settled by the
   reconstruction's veto lists (approved in observer reply 1); Trigger and
   Name were handled by "trigger phrases and name I'll propose in the final
   summary for your veto", and both did appear there ("**Name:**
   `sentry-triage` (veto/rename if you want)" plus four trigger phrases).
   Judged against the skill's Phase 2 rules this is compliant: propose-with-
   veto is explicitly permitted for Trigger/Name, and only questions whose
   answers change the file are mandated — destination was the one open such
   question. All four Phase 2 topics were covered; the flow needed 3 observer
   replies vs. the baseline's 4, with no topic dropped.

4. **Parametrization: fully met — the observation-driven mandate visibly
   fired.** The FIRST response already contained the labeled split "Values
   I'd treat as parameters vs. baked-in (you can veto either way in the next
   steps)": "**Parameters**" (Sentry project, Linear team/project, webhook as
   `$SLACK_TRIAGE_WEBHOOK`) vs. "**Baked in as fixed**" (ticket format,
   clustering key, priority thresholds 500/100). The baseline surfaced the
   fixed-value decision only parenthetically in its second exchange; here it
   is an up-front veto list — the behavior the Phase 2 item 1 mandate was
   added to force. The literal webhook URL from the transcript never appears:
   the design summary states "env var `$SLACK_TRIAGE_WEBHOOK` only, never a
   literal URL (it's a secret and this file is team-shared)", and the write
   phase adds that the env var must be exported before first invocation.

5. **Destination: fully met.** The single interview question offered both
   concrete paths — "`~/.claude/skills/<name>/SKILL.md`" (general) vs.
   "`<acme-api repo>/.claude/skills/<name>/SKILL.md`" (project-specific) —
   with the parameter consequences of each option spelled out. No
   dotfiles-repo assumption anywhere.

6. **Generated-skill quality: fully met, one minor gap noted.** Kebab-case
   `sentry-triage`; third-person description opening with when to invoke
   ("Invoke when the user asks to triage Sentry errors") and four concrete
   trigger phrases; short Overview; Parameters section with overridable
   defaults; numbered 5-step procedure with the checkpoint as an explicit
   STOP; a Failure modes section covering the expired-token recovery plus a
   second, self-added one (`$SLACK_TRIAGE_WEBHOOK` unset → "do steps 1–4
   anyway, report that the Slack announcement was skipped"). The
   uncommitted-in-git note required by Phase 4 step 4 appears: "inside a git
   repo, so it would land uncommitted; committing/PR is the team's call."
   Minor gap: the simulated write phase never mentions creating the missing
   destination directory (Phase 4 step 2) — immaterial here because writes
   were simulated, but recorded for honesty; the baseline did mention
   `mkdir -p`.

7. **Collision check: met, at the point the skill specifies.** The write
   phase opens with "(Live flow would first check
   `.claude/skills/sentry-triage/` in the acme-api repo for a collision and
   offer update vs. rename.)" — exactly Phase 4 step 1. Unlike the baseline
   it was not additionally pre-announced in the design summary; the skill
   does not require that, so this is compliant, not a regression. The
   actual-collision branch remains unexercised (nothing on disk).

## Run conditions & caveats

- Single run, no repetition. Same subagent type and model as the baseline
  (`general-purpose`, session-default Fable 5), so the comparison is
  like-for-like but still one sample per condition.
- Full SKILL.md (commit f4ba498) was prepended under "The following skill is
  loaded and applies:", then the scenario's Subagent prompt verbatim.
  Observer continuation per the rubric preamble: 3 observer replies. Full
  dialog recorded verbatim in
  `tests/skill-from-session-with-skill-dialog.md`.
- File writes were simulated per the exercise constraint, so Phase 4 disk
  behavior (collision check execution, directory creation) is
  announced/inferred, not observed.
- The generated skill differs from the baseline's in small judgment calls
  (unset-webhook handling: skip-and-report here vs. ask-for-it in baseline;
  failure-mode phrasing). Both are within spec; the rubric fixes structure
  and format, not these choices.

## Verdict

- Closed:
  - **Fixed-vs-parameter transparency (baseline's fragile spot).** The
    Phase 2 mandate demonstrably changed behavior: the parameters-vs-baked-in
    veto split appeared fully labeled in the first response, where the
    baseline surfaced it only partially and later. This is the one place the
    skill had to move behavior rather than merely pin it, and it did.
  - **Failure-mode placement.** The expired-token failure mode got its own
    line in the Phase 3 design summary ("Failure mode included: …"), where
    the baseline carried it only inside the step list.
  - **Model/run dependence (partially).** The behavior the baseline showed by
    disposition is now pinned by explicit skill text and was reproduced under
    it across all 7 rubric dimensions — but this is one run on the same
    strong model; the pin is verified once, not proven robust across models.
- Leaked: none observed — no baseline behavior regressed and no rubric
  dimension was missed. Spec paths unexercised in the baseline remain
  unexercised here, unchanged by this run: the no-coherent-workflow stop, the
  never-hunt-for-transcript-files rule, the multiple-candidate-workflows ask
  (flake8 was again an easy unilateral scope-out), and the actual-collision
  update-vs-rename branch.
