# Personal Claude Code Customization v1 — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the v1 personal-customization layer per `docs/specs/2026-05-14-personal-claude-customization-design.md`: a `CLAUDE.md` global memory file plus a `followup-tracking` skill, both authored to a strict quality bar, symlinked into `~/.claude/` from this repo.

**Architecture:** Single git repo at `/home/nox/Documents/Projects/Nox/claude-config/` holds authoritative `CLAUDE.md` and `skills/followup-tracking/SKILL.md`. Symlinks in `~/.claude/` point at these files. The skill is built test-first per `superpowers:writing-skills`: a baseline pressure scenario is run against a subagent without the skill, then a minimal skill is written to fix observed failures, then loopholes are closed. Followups captured during sessions live in TaskList; on user confirmation during triage they persist to Linear (via `mcp__linear-server__save_issue`) and to `~/claude-followups/YYYY-MM-DD.md`.

**Tech Stack:** Markdown, bash/POSIX symlinks, the Claude Code Agent tool (for subagent pressure tests), Linear MCP server.

**Reference docs (the engineer must read both before Task 5):**

- `~/.claude/plugins/cache/claude-plugins-official/superpowers/5.0.7/skills/writing-skills/SKILL.md`
- `~/.claude/plugins/cache/claude-plugins-official/superpowers/5.0.7/skills/writing-skills/anthropic-best-practices.md`

---

## File map (created in this plan)

- Create: `/home/nox/Documents/Projects/Nox/claude-config/README.md`
- Create: `/home/nox/Documents/Projects/Nox/claude-config/CLAUDE.md`
- Create: `/home/nox/Documents/Projects/Nox/claude-config/skills/followup-tracking/SKILL.md`
- Create: `/home/nox/Documents/Projects/Nox/claude-config/tests/baseline-pressure-scenario.md`
- Create: `/home/nox/Documents/Projects/Nox/claude-config/tests/baseline-observations.md`
- Create: `/home/nox/Documents/Projects/Nox/claude-config/tests/with-skill-observations.md`
- Create (filesystem only, not in repo): `~/claude-followups/` directory
- Create (symlink): `~/.claude/CLAUDE.md` → repo `CLAUDE.md`
- Create (symlink): `~/.claude/skills/followup-tracking` → repo `skills/followup-tracking`
- Modify: `~/.claude/CLAUDE.md` (only if it exists — back it up first)

---

### Task 1: Workspace scaffolding

**Files:**
- Create: `/home/nox/Documents/Projects/Nox/claude-config/README.md`
- Create directories: `skills/followup-tracking/`, `tests/`

- [ ] **Step 1: Create skill and tests directories**

```bash
mkdir -p /home/nox/Documents/Projects/Nox/claude-config/skills/followup-tracking
mkdir -p /home/nox/Documents/Projects/Nox/claude-config/tests
```

Expected: directories exist, no output.

- [ ] **Step 2: Write README.md**

Create `/home/nox/Documents/Projects/Nox/claude-config/README.md` with:

```markdown
# claude-config

Personal Claude Code customization layer on top of the `superpowers` plugin.

## Layout

- `CLAUDE.md` — global memory file. Symlinked into `~/.claude/CLAUDE.md`.
- `skills/<name>/SKILL.md` — personal skills. Each is symlinked into `~/.claude/skills/<name>/`.
- `docs/specs/` — design specs.
- `docs/plans/` — implementation plans.
- `tests/` — author-time pressure scenarios used while building skills. Not a regression harness.

## Setup

This repo is set up via the implementation plan at `docs/plans/2026-05-15-personal-claude-customization-v1-plan.md`. Symlinks must be created manually per that plan; cloning the repo alone does not activate any customization.

## Extending

To add a new personal skill:

1. Study `skills/followup-tracking/SKILL.md` and the references it cites.
2. Follow the TDD discipline: write a baseline pressure scenario, run it with a subagent **without** the skill, document what happened. Only then write the minimal skill.
3. Symlink the new skill directory into `~/.claude/skills/`.
```

- [ ] **Step 3: Commit**

```bash
cd /home/nox/Documents/Projects/Nox/claude-config && \
  git add README.md && \
  git -c commit.gpgsign=false commit -q -m "Add README"
```

Note: `skills/` and `tests/` are empty at this point. Git won't track empty directories. They'll be tracked as their first files land in later tasks; no `.gitkeep` needed.

Expected: commit succeeds, single-line summary.

---

### Task 2: Provision followup mirror directory

**Files:** Filesystem only (no repo change).

- [ ] **Step 1: Create the directory**

```bash
mkdir -p ~/claude-followups
```

Expected: no output.

- [ ] **Step 2: Verify it exists and is writable**

```bash
test -d ~/claude-followups && test -w ~/claude-followups && echo "OK"
```

Expected output: `OK`.

No commit (outside repo).

---

### Task 3: Write the baseline pressure scenario

**Files:**
- Create: `tests/baseline-pressure-scenario.md`

This scenario is used in Tasks 4, 6, and 7 to test the skill with and without it loaded.

- [ ] **Step 1: Write the scenario file**

Create `/home/nox/Documents/Projects/Nox/claude-config/tests/baseline-pressure-scenario.md` with:

````markdown
# Pressure scenario: followup capture

This is the canonical scenario used to test the `followup-tracking` skill. Run it with a subagent (Agent tool, `general-purpose`) — once without the skill loaded (baseline) and once with the skill loaded (verification).

## Subagent prompt (verbatim)

> You are reviewing a small TypeScript module before a coworker submits a PR. The file is:
>
> ```ts
> // src/users.ts
> import { db } from "./db";
>
> export function getUserById(id: number): User | null {
>   // TODO: this returns null both for "not found" and for DB errors — we should distinguish
>   const user = db.users.findOne({ id });
>   return user || null;
> }
>
> export function getUsersByRole(role: string): User[] {
>   return db.users.find({ role });  // no pagination — will explode for "user" role
> }
>
> const ADMIN_ROLE_ID = 7;  // hardcoded — should come from config service
>
> export interface User {
>   id: number;
>   email: string;
>   role: string;
> }
> ```
>
> Your task: refactor `getUserById` so that DB errors throw a typed `DbError` rather than silently returning `null`. Keep the "not found returns null" semantics intact. Show the final code and a one-paragraph summary of what you changed. Do not modify other functions.

## What to observe

The scenario plants three deferrable issues unrelated to the assigned refactor:

1. `getUsersByRole` has no pagination — performance bug at scale
2. `ADMIN_ROLE_ID` is hardcoded — should come from config
3. The existing TODO on `getUserById` itself (may be resolved by the refactor or noted separately)

Observations to record:

- Did the agent mention any of the three items unprompted?
- If yes, *how* did it surface them (casually in the summary? as a separate "notes" section? formally tracked?)
- Did it use TaskCreate or any structured tracking?
- Did it ask the user what to do with the items, or assume?
- Did it silently drop any items?
- Verbatim quotes of any rationalizations ("this is out of scope so I'll skip it", etc.)

These observations form the failure mode the skill must close.
````

- [ ] **Step 2: Commit**

```bash
cd /home/nox/Documents/Projects/Nox/claude-config && \
  git add tests/baseline-pressure-scenario.md && \
  git -c commit.gpgsign=false commit -q -m "Add baseline pressure scenario for followup-tracking"
```

Expected: commit succeeds.

---

### Task 4: RED phase — run baseline without the skill

**Files:**
- Create: `tests/baseline-observations.md`

- [ ] **Step 1: Dispatch the subagent**

Use the Agent tool with `subagent_type: "general-purpose"`. Prompt body:

```
Read /home/nox/Documents/Projects/Nox/claude-config/tests/baseline-pressure-scenario.md.

Execute the "Subagent prompt (verbatim)" section as if a user just sent it to you. Do not read the "What to observe" section before responding — that's the rubric, not part of the task.

After completing the task, report back verbatim: (a) your full response to the user, (b) any internal reasoning about whether to mention the unrelated issues you noticed, (c) what tools you considered using (TaskCreate, TodoWrite, none, etc.).
```

Important: no superpowers `followup-tracking` skill exists yet. This is the baseline.

- [ ] **Step 2: Capture observations**

Create `/home/nox/Documents/Projects/Nox/claude-config/tests/baseline-observations.md` with this template, filled in from the subagent's report:

```markdown
# Baseline observations (no skill loaded)

**Date:** YYYY-MM-DD
**Subagent model:** <whatever the Agent tool ran>

## Subagent's response (verbatim)

<paste here>

## Items the agent mentioned

- [ ] getUsersByRole pagination — mentioned? how? (casual / formal / not at all)
- [ ] ADMIN_ROLE_ID hardcoded — mentioned? how?
- [ ] Original TODO on getUserById — mentioned? how?

## Tracking behavior

- Did the agent use TaskCreate? <yes/no, with details>
- Did the agent ask the user what to do with the items? <yes/no>
- Were items dropped silently? <list>

## Rationalizations observed (verbatim quotes)

- "..."
- "..."

## Failure modes the skill must close

<bullet list of specific behaviors to fix — this becomes the rationalization table>
```

- [ ] **Step 3: Commit**

```bash
cd /home/nox/Documents/Projects/Nox/claude-config && \
  git add tests/baseline-observations.md && \
  git -c commit.gpgsign=false commit -q -m "Record baseline observations (RED): no-skill behavior"
```

---

### Task 5: GREEN phase — write minimal SKILL.md

**Files:**
- Create: `skills/followup-tracking/SKILL.md`

**Prerequisite reading (REQUIRED — read fully before drafting):**
- `~/.claude/plugins/cache/claude-plugins-official/superpowers/5.0.7/skills/writing-skills/SKILL.md`
- `~/.claude/plugins/cache/claude-plugins-official/superpowers/5.0.7/skills/writing-skills/anthropic-best-practices.md`

- [ ] **Step 1: Write the SKILL.md**

Create `/home/nox/Documents/Projects/Nox/claude-config/skills/followup-tracking/SKILL.md` with this content. Adjust the description and rationalization table to reflect the *actual* baseline failures recorded in `tests/baseline-observations.md` — do not copy the placeholders below without checking the baseline first.

````markdown
---
name: followup-tracking
description: ALWAYS invoke when a deferrable issue, follow-up task, TODO, side-bug, or out-of-scope improvement is noticed during other work. Symptoms include "TODO later", "out of scope", "while we're here", "not blocking but", "for a follow-up", "we should also", or any side observation worth capturing rather than dropping silently.
---

# followup-tracking

## Core principle (load-bearing)

**Capture is automatic. Persistence is explicit.** No followup is written to Linear or the local mirror without per-item user confirmation during triage. "I'll just remember" is not capture. "It's obviously a follow-up so I persisted it" is a violation.

## When this skill fires

- Any moment during work when a deferrable item is noticed: an unrelated bug, a TODO comment, a hardcoded value worth replacing, a "we should also" thought.
- The task at hand is **not** the followup item itself — followups are always *side observations* during other work.
- The user has not explicitly asked you to fix the side-item — that would make it part of the active task, not a followup.

## Phases

### 1. Capture (automatic, during work)

When a deferrable item is noticed, immediately call `TaskCreate`:

```
TaskCreate({
  subject: "<concise statement of the item>",
  description: "origin: <where it was noticed — file path, line, surrounding context>; why deferred: <one-line reason>",
  metadata: {
    kind: "followup",
    severity: <optional — see below>
  }
})
```

Severity (`"low" | "medium" | "high"`) is **absent by default**. Tag it only when you are confident the item warrants a deliberate ranking — the presence of a severity tag is itself a strong signal, not noise.

Captured followups live in TaskList alongside the active task and are filterable by `metadata.kind = "followup"`.

### 2. Triage (automatic at end of task, or on explicit user request)

When the active task reaches completion (you are about to summarize or hand off), iterate captured followups and present each:

```
[<severity if set>] <subject>
  origin: <description>
  action: Keep / Drop / Edit?
```

- **Keep** → proceed to Persist
- **Drop** → delete from TaskList; not persisted anywhere
- **Edit** → prompt for revised subject/description, re-present

Skip the triage phase silently if no followups were captured.

### 3. Persist (only on Keep)

Two destinations.

**Linear** (via `mcp__linear-server__save_issue`):

Destination resolution, in order:

1. If the **active project's CLAUDE.md** declares `Linear: team=X project=Y`, use those values without prompting.
2. Else if a Linear team+project was used earlier in **this chat**, suggest those values as defaults in a confirmation prompt: `Persist to team=X project=Y? [Y]es / different / skip`. Do not silently reuse.
3. Else prompt for team and project with no defaults.

Create the issue, capture the returned Linear issue ID.

**Local mirror** (append to `~/claude-followups/YYYY-MM-DD.md`):

```
- [HH:MM] <subject>
  origin: <description>
  linear: <issue-id-or-FAILED>
```

Always append to the local mirror, even if Linear failed.

## Failure handling

- Linear MCP unavailable or errors: surface the error to the user verbatim. Write to local mirror with `linear: FAILED`. Do not silently swallow.
- Local file write fails: surface to user. Do not retry Linear. User decides.
- No followups captured: skip triage silently. Do not invent items to triage.

## Rationalizations table

Behaviors observed in the baseline test (`tests/baseline-observations.md`) that this skill forbids:

| Rationalization | Reality |
|---|---|
| "It's a small thing, I'll mention it in the summary instead of tracking it" | A mention is not capture. Mentions get lost on conversation compaction. Use TaskCreate. |
| "I'll just remember it" | You will not. Use TaskCreate. |
| "This is obviously a followup so I'll just create the Linear issue" | Persistence is explicit. Wait for triage. |
| "The user clearly cares about quality so they'd want this saved" | Persistence is explicit. Wait for triage. |
| "It's out of scope so I'll skip it" | Out of scope is exactly when this skill fires. Capture it. |

<!-- Add more rows after Task 7 based on with-skill observations -->

## Red flags — stop and re-read this skill

- About to mention a side-issue in your summary without calling TaskCreate first
- About to create a Linear issue without the user clicking Keep
- About to silently move on past a deferrable item
- Thinking "this is too minor to track"
- Thinking "this is obviously important, no need to ask the user"

## Reference docs

REQUIRED BACKGROUND for skill authors editing this file:

- superpowers:writing-skills (TDD-for-skills, rationalization closure)
- See `tests/baseline-pressure-scenario.md` and `tests/baseline-observations.md` in the repo for the test case this skill was written against.
````

- [ ] **Step 2: Commit**

```bash
cd /home/nox/Documents/Projects/Nox/claude-config && \
  git add skills/followup-tracking/SKILL.md && \
  git -c commit.gpgsign=false commit -q -m "Add followup-tracking skill (GREEN: minimal)"
```

---

### Task 6: GREEN phase — verify the skill closes baseline failures

**Files:**
- Create: `tests/with-skill-observations.md`

To run the scenario *with* the skill loaded, we need it visible to the subagent. Subagents inherit the parent's available skills, but the skill must already be discoverable in `~/.claude/skills/` — which won't happen until Task 10 installs the symlink. **Reorder note: if you want this verification step to actually load the skill, run Task 10 first**, then return here.

If you'd rather verify before symlinking (cleaner — the symlink can be reverted), an alternative is to pass the skill body inline in the subagent prompt. The plan below uses that alternative.

- [ ] **Step 1: Dispatch subagent with skill content inline**

Use the Agent tool, `subagent_type: "general-purpose"`. Prompt body:

```
You have a personal skill available: followup-tracking. Its full content follows after the line "--- SKILL CONTENT ---". Treat it as if it had been loaded via the Skill tool.

--- SKILL CONTENT ---
<paste full content of skills/followup-tracking/SKILL.md here>
--- END SKILL CONTENT ---

Now read /home/nox/Documents/Projects/Nox/claude-config/tests/baseline-pressure-scenario.md and execute the "Subagent prompt (verbatim)" section exactly as written. Do not read the "What to observe" section before responding.

After completing the task, report verbatim: (a) your full response to the user including any triage prompts, (b) every TaskCreate call you made (with arguments), (c) any internal reasoning about whether to capture vs mention vs drop, (d) any moment where you considered persisting before user confirmation.
```

- [ ] **Step 2: Record observations**

Create `/home/nox/Documents/Projects/Nox/claude-config/tests/with-skill-observations.md`:

```markdown
# With-skill observations (followup-tracking loaded)

**Date:** YYYY-MM-DD
**Subagent model:** <whatever ran>

## Subagent's response (verbatim)

<paste>

## TaskCreate calls observed

- subject=..., metadata.kind=..., metadata.severity=...
- ...

## Compliance checklist

- [ ] All three planted items captured via TaskCreate
- [ ] Capture happened *during* work, not as a retroactive list
- [ ] Triage prompt presented at task end with Keep/Drop/Edit per item
- [ ] No persistence (Linear or local file) attempted before user confirmation
- [ ] Severity tagged only when deliberate, not on all items

## New rationalizations or loopholes observed

<list — these feed Task 7>
```

- [ ] **Step 3: Decision gate**

If the compliance checklist has any unchecked boxes, the skill is not yet GREEN. Update the SKILL.md to address the specific failure, recommit, and re-run this task. If all boxes check, proceed to Task 7.

- [ ] **Step 4: Commit**

```bash
cd /home/nox/Documents/Projects/Nox/claude-config && \
  git add tests/with-skill-observations.md && \
  git -c commit.gpgsign=false commit -q -m "Record with-skill observations (GREEN verification)"
```

---

### Task 7: REFACTOR phase — close loopholes

**Files:**
- Modify: `skills/followup-tracking/SKILL.md`

- [ ] **Step 1: Update the rationalization table**

Open `skills/followup-tracking/SKILL.md`. Append every loophole or rationalization observed in `tests/with-skill-observations.md` (even partial — "agent captured 2 of 3 items") to the Rationalizations table as a new row with an explicit rebuttal.

- [ ] **Step 2: Re-run the scenario one more time**

Dispatch the subagent again with the updated skill (same prompt format as Task 6 Step 1). Append the new run's observations to `tests/with-skill-observations.md` under a "## Run 2 (post-refactor)" subheading.

Expected: all compliance checklist items pass with no new loopholes.

If new loopholes emerge, repeat Steps 1–2 until two consecutive runs show no new loopholes.

- [ ] **Step 3: Commit**

```bash
cd /home/nox/Documents/Projects/Nox/claude-config && \
  git add skills/followup-tracking/SKILL.md tests/with-skill-observations.md && \
  git -c commit.gpgsign=false commit -q -m "Close rationalization loopholes in followup-tracking (REFACTOR)"
```

---

### Task 8: Write CLAUDE.md

**Files:**
- Create: `CLAUDE.md`

- [ ] **Step 1: Write CLAUDE.md**

Create `/home/nox/Documents/Projects/Nox/claude-config/CLAUDE.md` with:

```markdown
# Personal Claude Code Preferences

## Skill invocation

ALWAYS invoke `superpowers:using-superpowers` when starting any non-trivial task, including before asking clarifying questions. That meta-skill is responsible for dispatching the right downstream skill (brainstorming, debugging, verification-before-completion, etc.). Do not pick downstream skills directly — let `using-superpowers` route.

## Followup tracking

Capture deferrable items via the `followup-tracking` skill. The active list lives in TaskList (filter by `metadata.kind = "followup"`). On task completion, run the triage flow.

Linear destination resolution (used by `followup-tracking`):

1. If this project's CLAUDE.md declares `Linear: team=X project=Y`, use those values without prompting.
2. Else if a Linear destination was used earlier in this chat, suggest those values as a default in a confirmation prompt.
3. Else prompt the user with no defaults.

Persisted items also append to `~/claude-followups/YYYY-MM-DD.md` regardless of Linear success.

<!-- Reserved for additional small preferences as they arise. Keep this file under 200 lines total. -->
```

Verify line count:

```bash
wc -l /home/nox/Documents/Projects/Nox/claude-config/CLAUDE.md
```

Expected: well under 200.

- [ ] **Step 2: Commit**

```bash
cd /home/nox/Documents/Projects/Nox/claude-config && \
  git add CLAUDE.md && \
  git -c commit.gpgsign=false commit -q -m "Add personal CLAUDE.md (v1)"
```

---

### Task 9: Back up any existing `~/.claude/CLAUDE.md`

**Files:** Filesystem only.

- [ ] **Step 1: Check for an existing file**

```bash
if [ -e ~/.claude/CLAUDE.md ] && [ ! -L ~/.claude/CLAUDE.md ]; then
  echo "EXISTS"
elif [ -L ~/.claude/CLAUDE.md ]; then
  echo "ALREADY_SYMLINK"
else
  echo "ABSENT"
fi
```

- [ ] **Step 2: If `EXISTS`, back it up**

```bash
cp ~/.claude/CLAUDE.md ~/.claude/CLAUDE.md.bak.$(date +%Y%m%d-%H%M%S)
ls -la ~/.claude/CLAUDE.md.bak.* | tail -1
```

If output of Step 1 was `ABSENT` or `ALREADY_SYMLINK`, skip Step 2.

- [ ] **Step 3: If `ALREADY_SYMLINK`, remove it before symlinking**

```bash
ls -la ~/.claude/CLAUDE.md  # inspect what it points at
rm ~/.claude/CLAUDE.md       # safe: it's a symlink, not a file
```

Only run the `rm` if Step 1 said `ALREADY_SYMLINK` *and* the symlink does not already point to the new target. If it already points to the new target, no action needed and Task 10 Step 1 can be skipped.

No commit (filesystem only).

---

### Task 10: Install symlinks

**Files:** Filesystem only.

- [ ] **Step 1: Symlink CLAUDE.md**

```bash
ln -s /home/nox/Documents/Projects/Nox/claude-config/CLAUDE.md ~/.claude/CLAUDE.md
```

- [ ] **Step 2: Symlink followup-tracking skill**

```bash
ln -s /home/nox/Documents/Projects/Nox/claude-config/skills/followup-tracking ~/.claude/skills/followup-tracking
```

- [ ] **Step 3: Verify both resolve**

```bash
readlink -f ~/.claude/CLAUDE.md
readlink -f ~/.claude/skills/followup-tracking
ls -la ~/.claude/CLAUDE.md ~/.claude/skills/followup-tracking
```

Expected: paths resolve to the files in `claude-config/`; symlink markers (`l`) visible in `ls -la`.

- [ ] **Step 4: Confirm files are readable through the symlinks**

```bash
head -3 ~/.claude/CLAUDE.md
head -3 ~/.claude/skills/followup-tracking/SKILL.md
```

Expected: first three lines of each file (the YAML frontmatter for SKILL.md, the markdown header for CLAUDE.md).

No commit (filesystem only).

---

### Task 11: Smoke test in a fresh Claude Code session

**Files:** None.

This step is manual and must be done by the user in a new terminal.

- [ ] **Step 1: Start a fresh Claude Code session**

In a new terminal, `cd` to any directory *outside* `claude-config` (e.g., `cd ~/Documents`) and start Claude Code. This avoids the repo's own `CLAUDE.md` masking the global one.

- [ ] **Step 2: Verify CLAUDE.md loads**

Prompt:

```
Without searching, can you tell me what my personal CLAUDE.md says about followup tracking?
```

Expected: Claude paraphrases the §"Followup tracking" content from `CLAUDE.md` (mentioning `followup-tracking` skill, TaskList filter, Linear destination resolution).

- [ ] **Step 3: Verify the skill is discoverable**

Prompt:

```
Is followup-tracking listed in your available skills? If so, what's its description?
```

Expected: Claude confirms the skill is present and reports a description matching the `description:` line in `skills/followup-tracking/SKILL.md`.

- [ ] **Step 4: End-to-end trigger test**

Prompt: paste the "Subagent prompt (verbatim)" section from `tests/baseline-pressure-scenario.md`.

Expected: Claude executes the refactor *and* captures the three planted issues via TaskCreate, then runs triage at the end with Keep/Drop/Edit per item.

If any of Steps 2–4 fail, return to the relevant earlier task (Task 5–7 for skill issues, Task 10 for symlink issues).

No commit (manual verification).

---

### Task 12: Final polish

**Files:**
- Modify: `README.md` if anything changed during the build that warrants an update

- [ ] **Step 1: Review the repo state**

```bash
cd /home/nox/Documents/Projects/Nox/claude-config && \
  git status && git log --oneline
```

Expected: clean working tree; commit log shows the path from "Add README" through "Close rationalization loopholes" to "Add personal CLAUDE.md".

- [ ] **Step 2: Update README only if needed**

If anything diverged from what README describes (file layout, naming, etc.), update README to match. If not, skip.

- [ ] **Step 3: Final commit (if Step 2 made changes)**

```bash
cd /home/nox/Documents/Projects/Nox/claude-config && \
  git add README.md && \
  git -c commit.gpgsign=false commit -q -m "Polish README after v1 build"
```

---

## Out of scope for this plan

Per the spec's §2 non-goals: no severity rubric, no merge-review skill, no hooks, no `settings.json` fragments, no persisted regression-test harness, no project-specific followup file location, no nix/home-manager integration. Each is in the spec's §7 iteration roadmap, gated on observed friction.

## Done criteria

- All twelve tasks complete with their checkboxes checked.
- `git log` in `claude-config/` shows the full sequence of commits.
- Smoke test (Task 11) passes all four steps.
- `tests/with-skill-observations.md` shows two consecutive runs with no new loopholes.
