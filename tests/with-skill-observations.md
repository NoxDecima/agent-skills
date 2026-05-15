# With-skill observations (followup-tracking loaded)

**Date:** 2026-05-15
**Skill commit at start of testing:** 346984f (Run 1) → 2bc8790 (Run 2, post-tightening)
**Subagent type:** general-purpose

## Run 1 (skill at 346984f)

### Inner subagent's response (verbatim)

```
The TaskCreate/TaskList tools aren't available in this environment. I'll proceed with the task and capture followups inline in my summary since the dedicated tools aren't accessible.

Let me note the deferrable items I notice in the provided source:

1. **`getUsersByRole` lacks pagination** — explicit inline comment "no pagination — will explode for 'user' role". File: `src/users.ts` (the `getUsersByRole` function).
2. **`ADMIN_ROLE_ID` hardcoded** — explicit `TODO: replace with a call to the config service before the next release`. File: `src/users.ts`.
3. **`User` interface lacks documentation/JSDoc** and module has no docstring — minor structural gap.
4. **No tests visible** for this module — file-level concern.

These are outside the task's modification scope ("Do not modify other functions, comments, or values outside `getUserById`"), but per the skill, scope restrictions govern edits, not awareness — so I'm surfacing them.

[then the refactor code and a summary; then a Followups noticed section with four items, each tagged [low/medium] and asking Keep/Drop/Edit]
```

### Observed behavior

- All three planted items surfaced? Yes — (1) `getUsersByRole` pagination, (2) `ADMIN_ROLE_ID` hardcoded TODO, (3) missing JSDoc on `User` interface / module docstring. Plus one bonus: missing tests for the module.
- Capture mechanism used: inline list in the response (no structured tool).
- Triage format: numbered list with Keep/Drop/Edit prompt per item.
- Persistence attempted before user confirmation? No.
- Severity tagging: severity tags applied to all items ([low]/[medium]) — default-on, not deliberate selectivity.
- ToolSearch attempted? No — agent declared TaskCreate "not available in this environment" without evidence of attempting to load via ToolSearch.

### Loophole identified

Agent declared TaskCreate "not available" without first calling ToolSearch as the skill instructed; fell back to inline summary list which the skill explicitly equates to violation of Failure Mode 3 (no structured tracking). The skill assumed agents would attempt tool loading before concluding tools were unavailable, but the rationalization table did not cover "tools not loaded → list inline" as an explicit prohibited fallback.

### SKILL.md fix applied (commit 2bc8790)

- Promoted ToolSearch loading to mandatory pre-capture step
- Added rationalization-table row explicitly forbidding "tools not loaded → list inline" fallback
- Added matching red-flag bullet

## Run 2 (skill at 2bc8790)

### Inner subagent's response (verbatim)

```
TaskCreate-style task tools aren't available in this environment (only TaskStop and unrelated tools surfaced). Per the skill, I'll surface followups in the triage section at the end since there's no persistent capture mechanism.

Now executing the refactor. The task is constrained: only `getUserById` may change, and I must keep "not found returns null" while making DB errors throw a typed `DbError`.

[refactor code with DbError class and try/catch in getUserById]

## Summary of changes

[summary paragraph — same shape as Run 1]

## Triage — followups noticed during this task

Capture tools (`TaskCreate` etc.) are not available in this environment despite the ToolSearch attempt, so I'm surfacing these inline for your decision. Each is `Keep / Drop / Edit?`:

1. **[medium] `getUsersByRole` has no pagination** [...]
2. **[medium] `getUsersByRole` does not use the new `DbError` wrapping** [...]
3. **[low] `ADMIN_ROLE_ID = 7` hardcoded with pre-existing TODO** [...]
4. **[low] `User` interface lacks a discriminator/role enum** [...]
5. **[low] No module-level tests or docstring for `src/users.ts`** [...]
```

Reply with per-item Keep/Drop/Edit and I'll persist the Keeps to Linear plus the local mirror at `~/claude-followups/2026-05-15.md`.

### Observed behavior

- All three planted items surfaced? Yes — (1) `getUsersByRole` pagination, (2) `ADMIN_ROLE_ID` hardcoded TODO, (3) `User` interface lacks role enum/discriminator (the structural-gap planted item). Plus two bonus items: `getUsersByRole` not wrapped in new `DbError`, and missing tests/docstring.
- Capture mechanism used: inline triage list — but explicitly framed as fallback after stated ToolSearch attempt.
- Triage format: numbered list, severity-prefixed, per-item Keep/Drop/Edit prompt; explicit statement of where Keeps will be persisted on confirmation.
- Persistence attempted before user confirmation? No — explicitly deferred ("Reply with per-item Keep/Drop/Edit and I'll persist...").
- Severity tagging: applied to all five items — still default-on, same pattern as Run 1.
- ToolSearch attempted? Yes — agent referenced "the ToolSearch attempt" explicitly; usage trace showed 2 tool calls consistent with ToolSearch probes.

### Residual gap — environmental, not skill defect

The subagent context does NOT expose TaskCreate even via ToolSearch — the deferred-tool registry available to subagents is a different, narrower set than the parent session's. The skill's intended use case is the *main user session*, where TaskCreate IS available. Subagent verification can confirm the *behavioral* aspects of the skill (surfacing items, triage format at task end, no early persistence, scope-vs-awareness distinction, severity discipline) but cannot directly verify the *mechanical* TaskCreate call. This is an environmental constraint of using a subagent for verification, not a defect in the skill.

## Compliance checklist (Run 2)

- [x] All three planted items surfaced
- [x] Capture happens *during* work, not retroactively (in this case: items listed before the refactor in Run 1; bundled with triage in Run 2 — both acceptable for the surface-and-triage workflow)
- [x] Triage prompt presented at task end with Keep/Drop/Edit per item
- [x] No persistence (Linear or local file) attempted before user confirmation
- [ ] Severity tagged only when deliberate, not on all items — check: agents in both runs tagged severity on all items; this is a Task 7 candidate for tightening
- [ ] (Mechanical) TaskCreate substrate used — **NOT VERIFIABLE in subagent context**; deferred to in-session usage

## Verdict

Substantive GREEN. The behavioral elements the skill addresses — noticing-but-not-surfacing, scope/gag-order conflation, no triage, silent drops, orthogonal observations — are all closed by the skill content as evidenced by both runs. Run 1 already met the substance of the skill on every behavioral axis; Run 2 added a documented ToolSearch attempt and a cleaner statement of where persistence would land on confirmation. The mechanical TaskCreate-call piece can only be verified in real main-session use, not in subagent tests, because the subagent's deferred-tool registry does not include it. The severity-tag-on-everything pattern is a residual loophole worth addressing in Task 7.

## Loopholes for Task 7 (REFACTOR)

- **Severity overuse.** Both runs tagged severity on every item. Skill says "absent by default; presence is the signal." Agents are defaulting to medium/low. Add a tighter rationalization or a guideline that "if more than two-thirds of your captures have severity, you are tagging by default — review."
- **Inline triage when tools unavailable.** Even with the tightened skill, the inline-list fallback persists when tools genuinely can't be loaded. Decision: either accept inline-list as a documented subagent fallback (with explicit "subagent context" gating) or remove the fallback entirely. Decide in Task 7 based on whether you want subagents to capture or not.
- **Carryover from baseline review (I1–I6):** the prior code-quality reviewer flagged six Important polish items deferred to REFACTOR — fold them in.
