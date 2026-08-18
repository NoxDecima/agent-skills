# skill-from-session — Design

Date: 2026-08-18
Status: approved

## Purpose

A skill invoked at the end of a session that turns the workflow that just happened into a persistent skill. It reconstructs the workflow from the conversation, refines it through a one-question-at-a-time interview (akin to `superpowers:brainstorming`), confirms the final design, and only then writes the SKILL.md.

## Constraints

- **Same-session only.** Invoked as the last act of the session whose workflow it captures. The conversation is in context; no transcript-file discovery or parsing.
- **Portable.** Must not assume a claude-config-style dotfiles repo exists. General skills are written directly to `~/.claude/skills/<name>/SKILL.md`; project-specific skills to `<project>/.claude/skills/<name>/SKILL.md`.
- **Light capture.** The generated skill follows `writing-skills` principles (trigger description, concrete steps) but skips the TDD-for-skills baseline-test loop. The session itself is the evidence the workflow works.

## Identity & trigger

- Location in this repo: `skills/skill-from-session/SKILL.md`, symlinked into `~/.claude/skills/` like the other personal skills.
- Frontmatter description triggers on end-of-session requests to persist the just-completed workflow: "turn this into a skill", "make a skill from what we just did", "capture this workflow", "skillify this session" (and close variants).
- Explicit non-trigger: creating a skill from scratch or from a spec — that remains `superpowers:writing-skills` territory. The trigger is the presence of a completed workflow in the current conversation.

## Procedure (four phases)

### Phase 1 — Reconstruction

Scan the current conversation and present a numbered reconstruction of the observed workflow: the steps, the tools/commands used, the order. If the session contains more than one candidate workflow, list them and ask which to capture. If no coherent repeatable workflow exists, say so instead of fabricating one. The user corrects or confirms the reconstruction before any interviewing starts.

### Phase 2 — Interview

Brainstorming-style: one question per message, multiple choice preferred. Only ask questions whose answers change the resulting file — no ritual questions about things the reconstruction already settled. Topics:

1. **Generalization** — which steps were one-off vs. essential; anything that varies per use becomes a parameter. Secrets and user-specific paths are always parametrized, never hardcoded.
2. **Trigger** — when future-Claude should invoke the skill; concrete trigger phrases.
3. **Scope & destination** — general → `~/.claude/skills/<name>/`; project-specific → `<project>/.claude/skills/<name>/`. No dotfiles-repo assumption.
4. **Name** — the skill proposes a kebab-case name; the user confirms.

### Phase 3 — Confirmation gate

Present the final design in chat: name, trigger description, destination path, step outline, parameters. **Hard gate: nothing is written to disk before explicit approval.** Revisions loop back to this gate.

### Phase 4 — Write

Write the SKILL.md following `writing-skills` principles: frontmatter with kebab-case name and a rich third-person trigger description ("Use when…"), an overview, a concrete numbered procedure, and known failure modes if the session surfaced any. Before writing, check the destination for a name collision; if one exists, offer update vs. rename. End by reporting the written path, noting the file is uncommitted if the destination is inside a git repo.

## Error handling

- No coherent workflow in session → report that, do not fabricate.
- Name collision at destination → offer update vs. rename before writing.
- Destination directory missing (e.g. `<project>/.claude/skills/`) → create it.

## Building this skill (process note)

Constructing `skill-from-session` itself follows this repo's TDD-for-skills rule: author a baseline pressure scenario in `tests/` (a mock session ending in "turn this into a skill"), run it without the skill, document the failure modes, then write the minimal skill that closes them. This applies only to building the skill — not to the skills it generates.
