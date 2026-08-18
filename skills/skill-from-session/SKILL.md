---
name: skill-from-session
description: Invoke at the END of a session when the user asks to turn the workflow that just happened in THIS conversation into a persistent, reusable skill. Trigger phrases include "turn this into a skill", "make a skill from what we just did", "capture this workflow", "skillify this session", "I want to reuse this flow" (or close variants referring to the current session's work). Do NOT invoke for creating a skill from scratch, from a spec, or from an idea — that is `superpowers:writing-skills` territory. The trigger is a completed, repeatable workflow present in the current conversation.
---

# skill-from-session

## Overview

Turn the workflow that just happened in this session into a persistent skill.
Reconstruct what was done from the conversation, refine it through a
one-question-at-a-time interview, confirm the final design, and only then
write the SKILL.md to the right location.

The entire source material is the current conversation — never go hunting for
transcript files on disk.

<HARD-GATE>
Write NOTHING to disk until the user has approved the final design summary in
Phase 3. Drafting the skill file "to save time" before approval is a
violation.
</HARD-GATE>

## Phase 1 — Reconstruction

Scan the conversation and present the workflow you observed as **numbered
steps**, naming the tools/commands used at each step. Then let the user
correct it before asking anything else.

- If the session contains **more than one** candidate workflow (e.g., the main
  flow plus an unrelated side-fix), list them and ask which to capture.
- If the session contains **no coherent repeatable workflow**, say exactly
  that and stop. Do not fabricate a workflow to have something to capture.

## Phase 2 — Interview

One question per message. Multiple choice preferred. Ask **only** questions
whose answers change the resulting file — skip anything the reconstruction or
the conversation already settled. Cover, in order:

1. **Generalization** — which steps were one-off vs. essential. Every value
   that varies per use becomes a named parameter in the skill. Secrets and
   user-/machine-specific paths are ALWAYS parametrized (env-var reference or
   placeholder), never hardcoded — even if the user doesn't mention them.
   If you decide to bake in a one-off session value as fixed (e.g., a
   threshold, a label, a format) rather than parametrize it, you MUST surface
   that decision explicitly in the reconstruction or the Phase 3 design
   summary so the user can veto it. Hardcoding a session value silently is a
   violation.
2. **Trigger** — when should future-Claude invoke this skill; collect 2–4
   concrete trigger phrases.
3. **Scope & destination** —
   - general (useful in any project) → `~/.claude/skills/<name>/SKILL.md`
   - project-specific → `<project>/.claude/skills/<name>/SKILL.md`
   Do not assume a dotfiles/claude-config repo exists; write to the real
   destination directly.
4. **Name** — propose one kebab-case name; user confirms or renames.

Trigger and Name need not be standalone questions: proposing them in the
Phase 3 design summary with explicit veto rights is an acceptable way to
cover those topics. They must still appear there for confirmation.

## Phase 3 — Confirmation gate

Present the final design in chat: name, trigger description, destination
path, numbered step outline, parameters. Ask for explicit approval.
Revisions loop back to this gate. Nothing is written until approval.

## Phase 4 — Write

After approval:

1. Check the destination for an existing `<name>/` — on collision, offer
   update vs. rename before touching anything.
2. Create the destination directory if missing.
3. Write the SKILL.md following `superpowers:writing-skills` principles:
   - frontmatter: kebab-case `name`, rich third-person `description` opening
     with when to invoke and including the trigger phrases from Phase 2
   - an Overview stating purpose in 1–3 sentences
   - a concrete numbered procedure with real commands/tool calls,
     parameters clearly marked
   - known failure modes and their fixes, if the session surfaced any
     (e.g., an auth token expiring mid-flow and how it was recovered)
4. Report the written path. If the destination is inside a git repo, note
   the file is uncommitted; do not commit unless asked.

This is a light capture: do NOT run the TDD-for-skills baseline-test loop on
the generated skill — the session itself is the evidence the workflow works.
