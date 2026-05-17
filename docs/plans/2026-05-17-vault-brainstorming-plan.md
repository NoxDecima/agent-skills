# vault-brainstorming Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the `vault-brainstorming` personal skill per `docs/specs/2026-05-17-vault-brainstorming-design.md` — a vault-grounded brainstorming skill that runs a mandatory three-pass read of the user's Obsidian vault before substantive ideation.

**Architecture:** A single new skill directory `skills/vault-brainstorming/SKILL.md` in this repo, symlinked into `~/.claude/skills/`. The skill is built test-first per `superpowers:writing-skills`: a pressure scenario is authored against a vault topic with rich coverage, run once against a no-skill subagent to record baseline failure modes, then the SKILL.md is written so that each rationalization row in §7 of the spec maps to a specific observed baseline failure. A with-skill rerun verifies failures are closed; iteration loops if any leak through.

**Tech Stack:** Markdown, bash/POSIX symlinks, the Claude Code Agent tool (for subagent pressure tests), the `mcp__obsidian-hybrid-search__*` MCP tools.

**Reference docs (the engineer must read before Task 5):**

- `superpowers:writing-skills` SKILL.md (TDD-for-skills, rationalization closure)
- The `anthropic-best-practices.md` co-located with `superpowers:writing-skills` if available
- `skills/followup-tracking/SKILL.md` (the canonical in-repo precedent for skill shape)
- `docs/specs/2026-05-17-vault-brainstorming-design.md` (the design this plan implements)

---

## File map (created/modified in this plan)

Created:

- `skills/vault-brainstorming/SKILL.md` — the skill
- `tests/vault-brainstorming-baseline-pressure-scenario.md` — pressure scenario
- `tests/vault-brainstorming-baseline-observations.md` — no-skill run results
- `tests/vault-brainstorming-with-skill-observations.md` — with-skill run results
- `~/.claude/skills/vault-brainstorming` (symlink) — filesystem only, not in repo

Modified:

- `README.md` — add `vault-brainstorming` to the symlink-install block

---

### Task 1: Probe the vault to pick a pressure-scenario topic

**Files:** none (information-gathering task; output is a topic recorded in Task 2)

**Topic-fit criteria** — the chosen topic must satisfy all of:

1. ≥5 directly-relevant notes returned by hybrid search at threshold 0.4.
2. ≥10 indirectly-relevant notes surfaced via semantic neighbours of the top 2 direct hits.
3. At least one direct or adjacent note in the last 30 days (recency signal must exist).
4. At least one non-top-level tag shared by ≥2 of the top notes (so Phase 3's tag fan-out has substance).
5. Open-ended enough that "brainstorm with me on X" is a sensible request (not a factual lookup).

A topic that fails any criterion is rejected; pick another.

- [ ] **Step 1: List candidate topics from the user's vault**

Run a vault status check to confirm the index is fresh:

```
mcp__obsidian-hybrid-search__status({ include_activity: true })
```

Expected: `pending: 0`, `last_indexed` within the last 24 hours. If not, ask the user before continuing — do **not** reindex without permission.

- [ ] **Step 2: For each candidate, probe coverage**

For each candidate topic (start with 2–3 plausible ones the user has likely written about — ask the user for candidates if unsure):

```
mcp__obsidian-hybrid-search__search({
  queries: ["<topic>", "<narrower>", "<broader>", "<adjacent>"],
  mode: "hybrid",
  limit: 10,
  rerank: true,
  threshold: 0.2
})
```

Record: count of results ≥ 0.4, top 2 paths, shared tags.

- [ ] **Step 3: For the leading candidate, probe semantic neighbours of top hits**

```
mcp__obsidian-hybrid-search__search({
  path: "<top-hit-path>",
  limit: 10
})
```

Count results above 0.3. Repeat for the second top hit.

- [ ] **Step 4: Confirm recency**

For each top-hit path, call `mcp__obsidian-hybrid-search__read({ paths: "<path>", related: false })` and inspect frontmatter for a `date` / `created` / `modified` field, or rely on filename date conventions if used. Confirm ≥1 hit is within 30 days.

- [ ] **Step 5: Record the chosen topic**

Save the chosen topic verbatim into a scratch note (in this conversation, not the vault). Required outputs for Task 2:

- Chosen topic (one sentence)
- 4 query reformulations used (for inclusion in the observer rubric)
- Top 5 direct hit paths (for observer to check against)
- Top 5 adjacent/neighbour paths (creative-pass expected hits)
- Recent note path(s)
- Shared tag(s)

(No commit yet — Task 1 has no repo artifacts.)

---

### Task 2: Author the pressure scenario

**Files:**
- Create: `tests/vault-brainstorming-baseline-pressure-scenario.md`

- [ ] **Step 1: Create the scenario file**

Path: `/home/nox/Documents/Projects/Nox/claude-config/tests/vault-brainstorming-baseline-pressure-scenario.md`

Content template (replace `<…>` with values from Task 1):

````markdown
# Pressure scenario: vault-grounded brainstorming

This is the canonical scenario used to test the `vault-brainstorming` skill. Run it with a subagent (Agent tool, `general-purpose`) — once without the skill loaded (baseline) and once with the skill loaded (verification).

The subagent has access to the same `mcp__obsidian-hybrid-search__*` MCP tools as the parent session.

## Subagent prompt (verbatim)

> I'd like to brainstorm with you about <CHOSEN_TOPIC>. I keep an Obsidian vault that already contains a lot of my thinking on this and related areas — please use it actively. I want you to draw on what's in the vault, surface adjacent ideas I may not have connected yet, and then help me ideate from there. Don't just summarise what's there; we're brainstorming.
>
> When you've explored what you need, walk me through what you found and start the brainstorm.

<!-- Observer rubric below — do NOT include this section when serving the scenario to a subagent. It is for the human/controller observing the test, not part of the task. -->

## What to observe

The scenario is designed so that a no-skill subagent will predictably under-search the vault. Specifically, expect any of the following failure modes:

**F1. Single-query search.** Subagent runs `search` once with the topic verbatim, then proceeds. The skill mandates multi-query fan-out (3–4 reformulations).

**F2. No creative pass.** Subagent does not call `search` with `path: <top-hit>` (semantic neighbours), does not traverse the link graph (`related: true`), does not run a tag fan-out. The skill mandates all three.

**F3. No recency surfacing.** Subagent treats relevance score as the sole ranking signal; recent notes that scored moderately are not surfaced. The skill mandates a labelled "recent thinking" section.

**F4. Summary instead of brainstorm.** Subagent presents a tidy summary of vault hits and stops, or treats the brainstorm as a single response rather than a one-question-at-a-time dialog.

**F5. Generic priors not grounded in vault.** Subagent offers ideas that the model could have produced without ever opening the vault — no note titles cited, no provoked connections.

**F6. Unprompted vault write.** Subagent writes a synthesis note back to the vault without the user asking. (The MCP search tools are read-only, but if any write tool is available the subagent may reach for it. Either way, "I would suggest we save this as a note" without an ask also counts.)

**F7. Citation by reasoning, not by note title.** Subagent says things like "based on a note about X" without naming the specific note path/title.

### Expected high-coverage notes (from Task 1)

Direct: <PATH_1>, <PATH_2>, <PATH_3>, <PATH_4>, <PATH_5>
Adjacent (creative-pass): <PATH_A>, <PATH_B>, <PATH_C>, <PATH_D>, <PATH_E>
Recent: <PATH_R>
Shared tag: <TAG>

Observations to record for each run:

- Which failure modes (F1–F7) fired?
- How many `search` calls and `read` calls did the subagent make?
- Were `path:` (semantic-neighbour) or `related: true` (graph) modes used at all?
- Did the subagent ask the user a question, or produce a monologue?
- Which expected notes were surfaced; which were missed?
````

- [ ] **Step 2: Commit the scenario**

```bash
git add tests/vault-brainstorming-baseline-pressure-scenario.md
git commit -m "Add pressure scenario for vault-brainstorming skill"
```

---

### Task 3: Run the baseline (no-skill) scenario

**Files:** none modified yet (output captured in Task 4)

**Pre-conditions:** the symlink `~/.claude/skills/vault-brainstorming` must **not** exist, and the directory `skills/vault-brainstorming/` must **not** contain a `SKILL.md`. Both are true at this point in the plan.

- [ ] **Step 1: Verify pre-conditions**

```bash
test ! -e ~/.claude/skills/vault-brainstorming && echo "OK: no symlink"
test ! -f /home/nox/Documents/Projects/Nox/claude-config/skills/vault-brainstorming/SKILL.md && echo "OK: no SKILL.md"
```

Expected: both echo their `OK:` line.

- [ ] **Step 2: Dispatch the baseline subagent**

Use the `Agent` tool with `subagent_type: "general-purpose"`. The `prompt` is the **Subagent prompt (verbatim)** block from `tests/vault-brainstorming-baseline-pressure-scenario.md` — copy it word-for-word, substituting the chosen topic. Do **not** include the observer rubric.

Instruct the subagent to return its final response in full. Run in foreground (you need the result for Task 4).

- [ ] **Step 3: Save the subagent's verbatim response**

Stash the response in this conversation context. It will be embedded in Task 4's observations file.

(No commit yet — observations file is created in Task 4.)

---

### Task 4: Document baseline observations

**Files:**
- Create: `tests/vault-brainstorming-baseline-observations.md`

- [ ] **Step 1: Write the observations file**

Path: `/home/nox/Documents/Projects/Nox/claude-config/tests/vault-brainstorming-baseline-observations.md`

Template:

````markdown
# Baseline observations (no skill loaded)

**Date:** <TODAY>
**Subagent type:** general-purpose (Claude Code Agent tool)
**Topic:** <CHOSEN_TOPIC>

## Subagent's response (verbatim)

```
<paste full response>
```

## Tool-call summary

- `search` calls: <N>
- `read` calls: <N>
- Used `queries[]` multi-query? <yes/no>
- Used `path:` semantic-neighbour mode? <yes/no>
- Used `related: true` graph traversal? <yes/no>
- Used `tag:` filtering? <yes/no>

## Failure modes observed

For each of F1–F7 from the scenario rubric, record: **fired / not fired**, and a one-line note.

- **F1 (single-query search):** <fired/not> — <note>
- **F2 (no creative pass):** <fired/not> — <note>
- **F3 (no recency surfacing):** <fired/not> — <note>
- **F4 (summary instead of brainstorm):** <fired/not> — <note>
- **F5 (generic priors):** <fired/not> — <note>
- **F6 (unprompted vault write):** <fired/not> — <note>
- **F7 (reasoning without note titles):** <fired/not> — <note>

## Coverage gap

- Expected direct notes surfaced: <N of 5>
- Expected adjacent notes surfaced: <N of 5>
- Recent note surfaced: <yes/no>

## Notes for skill author

<free-form: which failures are sharpest? any failure pattern not on the F1–F7 list that emerged anyway?>
````

- [ ] **Step 2: Sanity-check coverage**

Confirm: at least 2 of F1–F7 fired. If 0 or 1 fired, the topic was too well-covered by the vague subagent prompt — the test does not exert enough pressure. Loop back to Task 1 and pick a less-obviously-vault-y topic.

- [ ] **Step 3: Commit**

```bash
git add tests/vault-brainstorming-baseline-observations.md
git commit -m "Record baseline observations for vault-brainstorming"
```

---

### Task 5: Draft initial SKILL.md

**Files:**
- Create: `skills/vault-brainstorming/SKILL.md`

**Pre-read:** the engineer must have read `superpowers:writing-skills` SKILL.md and `skills/followup-tracking/SKILL.md` before starting this task. The SKILL.md style — frontmatter, description as trigger, mandatory tool-loading step, rationalization table, red flags, reference section — is established by `followup-tracking`. Match it.

- [ ] **Step 1: Write the frontmatter and description**

Path: `/home/nox/Documents/Projects/Nox/claude-config/skills/vault-brainstorming/SKILL.md`

Frontmatter:

```markdown
---
name: vault-brainstorming
description: Use when the user wants to brainstorm/ideate/explore a topic AND references their Obsidian vault, notes, knowledge base, or "what I've written before". Triggers on combinations like "brainstorm with me on X using my notes", "what does my vault say about Y", "explore X from my Obsidian", "ideate on Z drawing from my knowledge base". Do NOT fire for generic brainstorming requests with no vault/notes reference — superpowers:brainstorming handles those.
---
```

The description is the trigger. It must:

- Be specific about the *combination* (brainstorm + vault/notes reference) — not just "brainstorm".
- Include 3–4 example trigger phrases verbatim so `using-superpowers` routing has concrete strings to match.
- Explicitly state the non-trigger condition (generic brainstorm → defer to `superpowers:brainstorming`).

- [ ] **Step 2: Write the Overview and Core Principle**

```markdown
# vault-brainstorming

## Overview

Brainstorm a topic with the user, grounded in an active, multi-pass read of their Obsidian vault. Surface what the vault already says, adjacent threads the user may not have connected, and recent thinking — then run a one-question-at-a-time brainstorm dialog provoked by the findings.

## Core principle (load-bearing)

**Search the vault before forming the brainstorm. Search creatively, not minimally.**

A single hybrid-search query is **not** a sufficient search pass. The skill mandates three structured passes — discovery, creative, and recency — before any substantive ideation is offered to the user. "I searched once and here's what I found" is the central failure mode.
```

- [ ] **Step 3: Write the Tool-availability step**

```markdown
## Tool availability (mandatory step before first search)

The Obsidian search tools are deferred — they will not appear in your default tool list. Before Phase 2, you **must** load them with:

`ToolSearch({ query: "select:mcp__obsidian-hybrid-search__search,mcp__obsidian-hybrid-search__read,mcp__obsidian-hybrid-search__status", max_results: 3 })`

"The tools aren't available" is not an acceptable reason to skip the vault read. ToolSearch is always available; loading is one call away.
```

- [ ] **Step 4: Write the Procedure section (Phases 1–5)**

Mirror §6 of the spec verbatim where possible (Phase 1 topic capture, Phase 2 discovery, Phase 3 creative, Phase 4 synthesis + brainstorm dialog, Phase 5 optional synthesis note). Each phase must include the exact MCP tool call shape the model is expected to use:

```markdown
## Procedure

### Phase 1 — Topic capture

Take the topic from the invocation. If the topic is genuinely ambiguous (two distinct readings, not just "could use more detail"), ask **one** short clarifying question. Otherwise proceed directly to Phase 2 — the vault itself is the primary clarifying instrument.

### Phase 2 — Discovery pass (mandatory)

Call:

```
mcp__obsidian-hybrid-search__search({
  queries: [<topic>, <narrower>, <broader>, <adjacent>],
  mode: "hybrid",
  limit: 10,
  rerank: true,
  threshold: 0.2
})
```

Then read full content of the top 3–5 results:

```
mcp__obsidian-hybrid-search__read({
  paths: [<path1>, <path2>, ...],
  related: true
})
```

### Phase 3 — Creative pass (mandatory)

For each of the top 2–3 notes from Phase 2, run all three sub-passes:

**3a. Semantic neighbours:**

```
mcp__obsidian-hybrid-search__search({
  path: "<top-hit-path>",
  limit: 10,
  threshold: 0.3
})
```

(The note itself appears at rank 1 — skip it.)

**3b. Graph traversal (one hop, both directions):**

```
mcp__obsidian-hybrid-search__search({
  path: "<top-hit-path>",
  related: true,
  direction: "both",
  depth: 1
})
```

**3c. Tag fan-out (conditional):**

If ≥2 of the top notes share a non-top-level tag (anything with a `/` in it, e.g. `note/basic/primary`, not `category/cs`), run:

```
mcp__obsidian-hybrid-search__search({
  query: "<topic>",
  tag: "<shared-tag>",
  limit: 10
})
```

Skip 3c if no shared non-top-level tag exists.

### Phase 4 — Synthesis and brainstorm dialog

Present findings in four labelled sections, scaled to what's actually there (omit any section entirely if it would be empty):

1. **What the vault already says** — direct hits from Phase 2, with note titles and one-line takeaways.
2. **Adjacent threads** — Phase 3 results: semantic neighbours, backlink contexts, shared-tag notes. Lead with the *unexpected* connections.
3. **Recent thinking that may apply** — notes from either pass whose modification or index time is within the last ~30 days. Surface these even if relevance score is moderate — recency is its own signal.
4. **Gaps and questions** — concepts the notes *imply* but don't directly address; tensions between notes; unanswered questions the notes themselves raise.

Cite specific notes by title when an idea is provoked by them — this lets the user open the note and follow the thread.

After the synthesis, transition into a brainstorm-style dialog: **one question at a time**, propose 2–3 framings/angles drawing on the surfaced notes (not generic priors), refine iteratively.

### Phase 5 — Optional synthesis note (user-triggered only)

Vault is read-only by default. **Only** when the user explicitly asks for a written-back artifact ("write this up", "save a synthesis note", "add this to the vault") may the skill draft a note. Before writing, confirm path and tags with the user. Default behaviour is read-only.
```

- [ ] **Step 5: Write the Rationalizations table**

Transcribe §7 of the spec (the seven rationalization rows) into a `| Rationalization | Reality |` markdown table. Each row's "Reality" column must reference the specific failure mode (F1–F7) it closes from `tests/vault-brainstorming-baseline-observations.md`. If a row does not map to an observed baseline failure, either: (a) delete it (it's preemptive theatre), or (b) document a *new* baseline failure it closes in a margin note.

- [ ] **Step 6: Write the Red flags section**

Transcribe §8 of the spec.

- [ ] **Step 7: Write the Reference section**

```markdown
## Reference

REQUIRED BACKGROUND for editing this skill: superpowers:writing-skills (TDD-for-skills, rationalization closure).

The canonical pressure scenario this skill was written against is in `tests/vault-brainstorming-baseline-pressure-scenario.md`; the failure modes it must close are in `tests/vault-brainstorming-baseline-observations.md`.

Design rationale: `docs/specs/2026-05-17-vault-brainstorming-design.md`.
```

- [ ] **Step 8: Commit**

```bash
git add skills/vault-brainstorming/SKILL.md
git commit -m "Draft initial vault-brainstorming SKILL.md against baseline failures"
```

---

### Task 6: Install the symlink

**Files:**
- Create (symlink, filesystem only): `~/.claude/skills/vault-brainstorming` → repo `skills/vault-brainstorming`

- [ ] **Step 1: Install the symlink**

```bash
ln -s /home/nox/Documents/Projects/Nox/claude-config/skills/vault-brainstorming ~/.claude/skills/vault-brainstorming
```

- [ ] **Step 2: Verify**

```bash
readlink -f ~/.claude/skills/vault-brainstorming
```

Expected: prints `/home/nox/Documents/Projects/Nox/claude-config/skills/vault-brainstorming`.

(No commit — filesystem-only.)

---

### Task 7: Update README.md with the new symlink line

**Files:**
- Modify: `README.md` (the symlink-install block in the Setup section)

- [ ] **Step 1: Add the new symlink line**

Find the block (around line 35–36):

```bash
ln -s "$REPO/GLOBAL.md"                   ~/.claude/CLAUDE.md
ln -s "$REPO/skills/followup-tracking"    ~/.claude/skills/followup-tracking
```

Append:

```bash
ln -s "$REPO/skills/vault-brainstorming"  ~/.claude/skills/vault-brainstorming
```

- [ ] **Step 2: Add a verification line**

Find the verify block (around line 39–40):

```bash
readlink -f ~/.claude/CLAUDE.md
readlink -f ~/.claude/skills/followup-tracking
```

Append:

```bash
readlink -f ~/.claude/skills/vault-brainstorming
```

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "Document vault-brainstorming symlink in README"
```

---

### Task 8: Run the with-skill scenario

**Files:** none modified yet (output captured in Task 9)

- [ ] **Step 1: Verify the skill is installed**

```bash
test -L ~/.claude/skills/vault-brainstorming && test -f ~/.claude/skills/vault-brainstorming/SKILL.md && echo "OK: skill installed"
```

Expected: `OK: skill installed`.

- [ ] **Step 2: Dispatch the with-skill subagent**

Use the `Agent` tool with `subagent_type: "general-purpose"`. The `prompt` is the **same verbatim subagent prompt** from `tests/vault-brainstorming-baseline-pressure-scenario.md`. Subagents inherit the harness's skill list, so the new skill is visible to them.

- [ ] **Step 3: Save the subagent's verbatim response**

Stash for Task 9.

---

### Task 9: Document with-skill observations

**Files:**
- Create: `tests/vault-brainstorming-with-skill-observations.md`

- [ ] **Step 1: Write the observations file**

Same template as Task 4's baseline observations, with one additional section at the end:

```markdown
## Comparison to baseline

For each failure mode F1–F7, record: **closed / leaked / partial**.

- F1: <closed/leaked/partial> — <one-line note>
- F2: <closed/leaked/partial> — <one-line note>
...
- F7: <closed/leaked/partial> — <one-line note>

## Verdict

<close all loopholes? iterate? acceptable?>
```

- [ ] **Step 2: Determine whether iteration is needed**

If **all F1–F7 are `closed`**, proceed to Task 11 (skip Task 10).
If **any F1–F7 is `leaked` or `partial`**, proceed to Task 10.

- [ ] **Step 3: Commit**

```bash
git add tests/vault-brainstorming-with-skill-observations.md
git commit -m "Record with-skill observations for vault-brainstorming"
```

---

### Task 10: Iterate SKILL.md to close residual loopholes (CONDITIONAL)

**Run this task only if Task 9 found any leaked/partial failure modes.**

**Files:**
- Modify: `skills/vault-brainstorming/SKILL.md`
- Append to: `tests/vault-brainstorming-with-skill-observations.md`

- [ ] **Step 1: For each leaked failure, identify the rationalization the subagent used**

Look at the subagent's response. What sentence or thought pattern allowed the failure to slip through? That sentence becomes the new rationalization-row "Rationalization" column. The "Reality" column states the rule plus *why* (anchored in the observed leak).

- [ ] **Step 2: Add the row(s) to SKILL.md's Rationalizations table**

If a leak doesn't map to a rationalization (it's a *structural* miss — e.g., the procedure section was unclear, not a rationalized skip), update the procedure section directly instead.

- [ ] **Step 3: Re-dispatch the subagent**

Same prompt as Task 8.

- [ ] **Step 4: Append a new "Iteration N" section to the with-skill observations file**

Record tool-call counts, F1–F7 statuses, and verdict. Date-stamp the iteration.

- [ ] **Step 5: Commit**

```bash
git add skills/vault-brainstorming/SKILL.md tests/vault-brainstorming-with-skill-observations.md
git commit -m "Close residual vault-brainstorming loopholes (iteration N)"
```

- [ ] **Step 6: Loop**

If any F1–F7 still leaks, repeat Steps 1–5 with iteration N+1. Hard ceiling: **3 iterations**. If 3 iterations have not closed the leak, stop and surface the issue to the user — the failure may indicate a structural problem with the design (the spec, not the skill) and needs design-level review.

---

### Task 11: Final review

**Files:** none modified

- [ ] **Step 1: Verify file map**

```bash
ls -la /home/nox/Documents/Projects/Nox/claude-config/skills/vault-brainstorming/
ls -la /home/nox/Documents/Projects/Nox/claude-config/tests/ | grep vault-brainstorming
readlink -f ~/.claude/skills/vault-brainstorming
```

Expected:
- `SKILL.md` present in the skill directory
- Three `vault-brainstorming-*.md` files in `tests/`
- Symlink resolves to the repo path

- [ ] **Step 2: Verify git is clean**

```bash
git status
```

Expected: `nothing to commit, working tree clean`. If anything is uncommitted, commit it with an honest message.

- [ ] **Step 3: Smoke-test in a fresh Claude Code session**

In a new session, confirm `vault-brainstorming` appears in the available-skills list and that invoking it with a vault-relevant brainstorm topic triggers the multi-pass procedure. (This is a manual check by the user; the implementing engineer just confirms the artifacts are in place for that check.)

---

## Notes on subagent test fidelity

Subagent runs are stochastic. A baseline run that fires F1+F3 today might fire F1+F2+F5 tomorrow on the same topic. This is acceptable — the goal is *coverage of the failure-mode space*, not exact reproducibility. If Task 4's baseline observations cover ≥3 of F1–F7, the test has enough signal. If they cover ≤1, see Task 4 Step 2 (re-pick the topic).

For Task 9, a single with-skill run that closes all F1–F7 is sufficient. If a single run leaves any leak, Task 10 handles it. Do **not** run the with-skill scenario multiple times "for confidence" before iterating — Task 10's whole point is to extract a rule from each observed leak, and multiple unstructured reruns just consume tokens without producing rules.
