---
name: followup-tracking
description: ALWAYS invoke when a deferrable item is noticed during other work — a TODO comment in a touched file, a side-bug adjacent to the change, a hardcoded value, a missing test or docstring, or anything outside the assigned scope that a diligent reviewer would not silently drop. Symptoms include "TODO", "follow-up", "deferrable", "later", "not blocking", "out of scope", "while we're here", "we should also", "noticed".
---

# followup-tracking

## Overview

Capture deferrable items the moment you notice them, surface them at task completion, and persist only what the user confirms.

## Core principle (load-bearing)

**Capture is automatic. Persistence is explicit.**

- **Capture** = a `TaskCreate` call. Naming an item in a summary, calling it "untouched," or noting it parenthetically is **not** capture.
- **Persistence** (Linear, FUTURE.md) happens only on explicit user `Keep` during triage.

**Scope-compliance and capture are independent axes.** "Do not modify X" is a *modification* boundary. It is **not** a gag order. Items you may not edit, you must still record.

## When this skill fires

Fires on **noticing**, not on reasoning. If your eyes pass over any of the below while doing other work, capture is mandatory:

- A `TODO`, `FIXME`, or `XXX` comment in a file you read or touched
- A code smell adjacent to your change (hardcoded constant, missing pagination, unhandled error, magic number)
- A bug or risk in a function the task tells you not to modify
- An orthogonal concern at the file level: missing tests, missing module docstring, no type annotations, no error handling
- Anything you would think but not say aloud because "it's not what I was asked"

You do **not** need to articulate why an item is deferrable before capturing it. Noticing is the trigger.

## Phases

### 1. Capture (automatic, during work)

**Tool availability (mandatory step before first capture):** `TaskCreate`, `TaskList`, `TaskUpdate`, `TaskGet` are deferred tools — they will not appear in your default tool list. Before your first capture, you **must** load them by calling:

`ToolSearch({ query: "select:TaskCreate,TaskList,TaskUpdate,TaskGet", max_results: 4 })`

Once loaded, they remain callable for the rest of the session. **"The tools aren't available" is not an acceptable reason to skip capture or fall back to an inline list, prose mention, or any other substitute. ToolSearch is always available; loading is one call away.** Falling back without first calling ToolSearch is a violation.

**Narrow subagent-context fallback.** Subagent contexts have a different deferred-tool registry than the parent session, so `ToolSearch({ query: "select:TaskCreate,..." })` can legitimately return no matches there. *If and only if* you actually called ToolSearch and it demonstrably failed to load `TaskCreate` (e.g. an empty/no-match result), you may fall back to an inline list of followups in your final message. When you do this, you **must** explicitly state that the parent session needs to run `TaskCreate`-based triage on these items — persistence responsibility belongs to the parent. The fallback is forbidden unless ToolSearch was actually attempted and failed; "I assumed it wouldn't work" does not qualify.

The instant a deferrable item is noticed, call `TaskCreate`:

```
TaskCreate({
  subject: "<concise statement of the item>",
  description: "origin: <file:line or surrounding context>; surfaced during: <active task>; note: <one-line why-deferred or what's wrong>",
  metadata: {
    kind: "followup",
    severity: <optional: "low" | "medium" | "high">
  }
})
```

`metadata.kind = "followup"` is required so the triage phase can filter the list.

`metadata.severity` is **absent by default**. Omit the field entirely unless you would defend the ranking out loud; presence is the signal. Defaulting to "medium" or "low" because the field exists is a violation — if you find yourself reaching for a value to fill the slot, that is the cue to omit it.

Captured followups sit in TaskList alongside the active task.

**Before writing your task summary, audit.** Scan the file(s) you touched for: in-file `TODO`/`FIXME` comments, adjacent functions with visible smells, missing tests/docstring at the module level. Each must already correspond to a `TaskCreate` call or be captured now. If a sentence in your draft summary names an item ("X is untouched", "I didn't modify Y") and no `TaskCreate` exists for it, that is a violation — capture before sending the summary.

### 2. Triage (automatic at task completion, or on explicit user request)

Triage runs once, when the next message after capture would close the current task (commit/PR/"looks good"/topic change). If unsure whether the task is closing, run triage — bias toward firing.

When the active task is about to be summarized or handed off, list captured followups to the user, one block per item:

```
[<severity if set>] <subject>
  origin: <description>
  action: Do now / Keep / Drop / Edit?
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
- **Drop** → delete from TaskList; not persisted anywhere
- **Edit** → take revised subject/description, re-present that item

If zero followups were captured, skip this phase silently. Do not fabricate items to triage.

### 3. Persist (only on Keep)

Destinations: `linear`, `future` (a FUTURE.md file), or `both`.

Destination resolution, in this exact order:

1. If your loaded project memory (the harness's project-`CLAUDE.md`, already in your context) contains a `Followups: linear | future | both` line (optional path override `future=<path>`), use it without prompting. Backward compatible: a project memory with only a `Linear: team=X project=Y` line resolves to `linear`. Do not go searching the filesystem for memory/declaration files — only the project memory already present in context counts (rung 3's FUTURE.md existence check is the one permitted lookup).
2. Else, if a destination was used earlier in **this chat**, suggest it as a default in a confirmation prompt. The suggestion is a default, never a silent reuse.
3. Else, if a `FUTURE.md` exists at the project root, suggest it as the default in the clarification question — never silently use it.
4. Else, prompt the user with no defaults.

**Record the choice:** when the destination was resolved by asking (rungs 3–4), offer once to record it as a `Followups:` line in the project CLAUDE.md so future sessions resolve at rung 1. Apply only on explicit acceptance; if declined, do not re-offer this session. If the user also supplied Linear team/project at ask-time, the accepted offer records the `Linear: team=X project=Y` line alongside the `Followups:` line, so neither is re-asked.

**Linear** (when the destination includes `linear`; tool: `mcp__linear-server__save_issue`)

Team and project come from the `Linear: team=X project=Y` line when declared; else from this chat's earlier usage (confirm as a default); else prompt.

**Linear call shape:**

`mcp__linear-server__save_issue({ title, description, team, project })`

Field mapping:

- `title` ← TaskCreate subject (the user can clean it up at triage Edit if it doesn't already read like a good issue title).
- `team`, `project` ← resolved above. `title` and `team` are required by Linear; the call will hard-fail if either is missing (this is distinct from the destination resolution above — destination rung 4 finds the *destination*; the team/project come from the Linear coordinate chain in this block). `project` is optional but recommended.
- `description` ← **rendered markdown body using the template below**, not the raw `TaskCreate.description` string. The raw capture string is for the in-session TaskList view; the Linear body is the artifact that other people (and future-you) will read, and it should be scannable.

**Linear description template:**

```markdown
## Context

Surfaced during: <surfacing task / branch / PR>.

## Observation

<what was noticed, 1–3 sentences expanded from the captured note>

## Reference

- `<file:line>` — <one-line context>

## Why deferred

<one-line reason; e.g. "out of scope for surfacing task">

## Suggested next step

<concrete one-line action sketch; omit the entire section if no sketch is available>
```

Rendering rules:

- Use `##` headings exactly as shown.
- Wrap file paths, symbol names, and command snippets in inline backticks.
- **Omit any section entirely** when its content would be empty or "n/a" — never produce a heading with no content beneath it.
- Reconstruct missing fields from surrounding capture context when possible; only fall back to a generic placeholder like "Out of scope for the surfacing task." if no better content is available.

Create the issue. Capture the returned Linear issue ID for the FUTURE.md `Linear:` sub-line (used when the destination is `both`).

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

## Failure handling

- **Linear MCP unavailable or errors.** Surface the error to the user verbatim and offer to write the item to FUTURE.md instead, so the item is not lost. Do not silently swallow.
- **FUTURE.md write fails.** Surface the error to the user verbatim.
- In every failure case the item stays in TaskList until successfully persisted or explicitly dropped. TaskList is the only in-flight safety net; swallowing a persistence failure is a violation.
- **No followups captured.** Triage phase is skipped silently.

## Rationalizations — these are violations, not exceptions

Each row names a pattern observed in the baseline (no-skill) run on the canonical pressure scenario.

| Rationalization | Reality |
|---|---|
| "I said 'X is untouched' in my summary — so I've already disclosed it." | Naming an item as untouched is **not** capture. Capture means `TaskCreate`. Run the pre-summary audit (see Capture phase: "Before writing your task summary, audit"): any item named in the summary must already have a `TaskCreate`, or be captured now before sending. The summary line does not substitute for the followup — do the audit. (Failure mode 1: noticed-but-not-surfaced.) |
| "The user said 'do not modify X' — surfacing it would be out of scope." | "Do not modify" governs **edits**, not **awareness**. Scope-compliance and capture are independent axes. Record the item; you are not editing it. (Failure mode 2: scope/gag-order conflation.) |
| "I'll just mention it in my summary paragraph instead of a tool call." | Free-form prose has no schema and gets lost on compaction. Use `TaskCreate` with `metadata.kind = "followup"`. (Failure mode 3: no structured tracking.) |
| "TaskCreate isn't in my tool list — I'll list the items inline in my summary instead." | ToolSearch IS in your tool list, and the skill mandates loading TaskCreate via ToolSearch before first capture. Inline lists, prose mentions, parenthetical asides, and "summary appendix" lists are all the same failure: non-`TaskCreate` substrates that bypass triage and persistence. Run ToolSearch, then capture. (Loophole observed in Task 6 Run 1.) |
| "Missing tests / missing docstring are about the whole file, not my change — that's not a followup." | File-level and structural concerns count. Missing tests, missing module docstring, missing type annotations, missing error handling for the touched module are all capture-eligible. (Failure mode 4: orthogonal observations dropped.) |
| "I'll just silently move on — the user can ask if they want to know." | Silence is the failure mode. Default to capture. The user reviews at triage and can drop it then — that is the user-can-ask channel. (Failure mode 5: no question to user.) |
| "I never articulated 'out of scope', so I'm not skipping anything." | Drop-by-omission is still a drop. Noticing without capturing is the violation, regardless of whether you articulated a reason. (Failure mode 6: unrationalized silent drops.) |
| "I'll just remember it for later in the conversation." | You will not. Conversation context is not durable storage. Use `TaskCreate`. |
| "This is obviously something the user wants tracked — I'll create the Linear issue directly." | Persistence is explicit. Capture into TaskList; wait for `Keep` at triage. Auto-persisting bypasses the user's review. |
| "Severity is required, so I'll guess medium." | Severity is **absent by default**. If you would not defend the ranking, omit it. |
| "I'll tag every item with low or medium just to be safe / for consistency." | The field's *presence* is the signal; tagging everything destroys that signal. Omitting severity is the normal case, not the exception. If you find yourself reaching for "low" or "medium" because the slot exists, that is the cue to omit the field entirely. (L1 — observed in Task 6 verification runs.) |

## Red flags — stop and re-read this skill

- About to write a summary that names an item ("X is untouched", "Y wasn't modified", "the TODO above Z") with no corresponding `TaskCreate`
- About to send a task summary without auditing the touched file(s) for in-file TODOs, adjacent smells, and module-level gaps
- About to drop an item because the task said "do not modify" it
- About to drop an orthogonal concern (tests, docs, types) because it's "not what I was asked"
- About to persist to Linear without an explicit `Keep` from the user
- About to invent severity to fill the field
- Thinking "this is too small to be worth a `TaskCreate`"
- Thinking "I'll just remember it"
- Thinking "the TaskCreate tools aren't loaded so I'll list the items inline" — ToolSearch loads them; the inline-list fallback is a violation, not an adaptation

If any of these fire, the skill is being violated. Stop, capture what should be captured, then continue.

## Reference

REQUIRED BACKGROUND for editing this skill: superpowers:writing-skills (TDD-for-skills, rationalization closure).

The canonical pressure scenario this skill was written against is in `tests/baseline-pressure-scenario.md`; the failure modes it must close are in `tests/baseline-observations.md`.
