# vault-brainstorming — Design

**Date:** 2026-05-17
**Status:** Draft (awaiting user review)
**Scope:** A new personal skill that brainstorms a topic with the user, grounded in *active, multi-pass* reads of their Obsidian vault.

## 1. Motivation

`superpowers:brainstorming` is excellent at turning a software idea into a code-shaped spec. It does not, however, *use the user's personal knowledge*. The user keeps an Obsidian vault (1100+ notes, 640+ links, hybrid-search indexed) and wants brainstorming sessions that are pulled toward — and provoked by — what already lives in that vault.

The gap: an ad-hoc brainstorm with the model produces ideas the model could produce for anyone. A vault-grounded brainstorm produces ideas that *connect to the user's own prior thinking* — recent notes, adjacent threads, half-finished ideas, recurring concepts. That connection is the value.

## 2. Goals

- **G1.** When the user invokes the skill on a topic, the model performs an aggressive, multi-pass read of the vault before saying anything substantive about the topic.
- **G2.** The model surfaces three categories the user can't easily see at a glance: (a) what the vault already says about the topic; (b) creatively-adjacent concepts the vault touches on but doesn't directly tie to the topic; (c) recent notes that may bear on the topic.
- **G3.** The model then runs a brainstorm-style dialog (one question at a time, propose 2–3 angles, refine) *grounded in those findings*, not in generic priors.
- **G4.** The vault stays read-only by default. Writing a synthesis note happens only on explicit user instruction.

## 3. Non-goals (v1)

- Not an auto-fire skill. Trigger is explicit user invocation only.
- Not a replacement for `superpowers:brainstorming`. The two skills coexist and serve different terminal states (code spec vs. vault-grounded exploration).
- Does not terminate by invoking `writing-plans`. The terminal state is conversational, with optional vault note creation.
- No vault writes without explicit user instruction (no "I'll just append a note as I go").
- No reindexing or vault mutation as a side effect of search.
- No project-specific scoping in v1 (the skill always searches the full vault). Per-folder scoping is a future iteration if needed.

## 4. When the skill fires

User-invoked, via the Skill tool. Typical phrasing the description must catch:

- "brainstorm with me on X"
- "explore X using my vault / notes / obsidian"
- "what does my vault say about X"
- "ideate on X drawing from my notes"

The description **must not** claim coverage of generic "brainstorm" requests — `superpowers:brainstorming` handles those. The trigger is the *combination* of brainstorming intent **and** vault/notes/obsidian context.

## 5. Core principle (load-bearing)

**Search the vault before forming the brainstorm. Search creatively, not minimally.**

A single hybrid-search query is **not** a sufficient search pass. The skill mandates three structured passes — discovery, creative, and recency — before any substantive ideation is offered to the user. "I searched once and here's what I found" is the central failure mode and is treated as a violation in the same way `followup-tracking` treats a prose mention as not-capture.

## 6. Procedure

The skill runs in five phases. Phases 1–3 are mandatory. Phase 4 is the brainstorming dialog. Phase 5 is optional and user-triggered.

### Phase 1 — Topic capture

Take the topic from the invocation. If the topic is genuinely ambiguous (two distinct readings, not just "could use more detail"), ask **one** short clarifying question. Otherwise proceed directly to Phase 2 — the vault itself is the primary clarifying instrument.

### Phase 2 — Discovery pass (mandatory)

Run `mcp__obsidian-hybrid-search__search` with the `queries[]` multi-query fan-out parameter. Provide **3–4 reformulations** of the topic, deliberately varying vocabulary (the user's notes may use different terms than the user's prompt):

- The topic as stated.
- A more specific / narrower phrasing.
- A more abstract / categorical phrasing.
- An adjacent or sibling concept the topic implies.

Defaults: `mode: "hybrid"`, `limit: 10`, `rerank: true`, `threshold: 0.2`.

Read the **full content** of the top 3–5 results (`mcp__obsidian-hybrid-search__read` with `related: true`) so the model has the actual prose, tags, and link structure — not just snippets.

### Phase 3 — Creative pass (mandatory)

This is the pass that distinguishes the skill from a search-and-summarize tool. For the top 2–3 notes from Phase 2:

- **Semantic neighbours.** Call `search` with `path: <note_path>` (no `query`) to surface notes the vault considers similar but which did not match the original query vocabulary. These are the "creatively adjacent" ideas.
- **Graph traversal.** Call `search` with `path: <note_path>`, `related: true`, `direction: "both"`, `depth: 1` to follow outgoing links and backlinks one hop out. Backlinks are especially valuable — they show where the user has invoked the concept *from elsewhere*.
- **Tag fan-out.** If the top notes share a non-trivial tag (anything other than a top-level category), run one additional `search` filtered by that tag to surface other notes in the same conceptual neighbourhood.

The goal of this pass is to find notes the user wouldn't have thought to mention but that bear on the topic.

### Phase 4 — Synthesis and brainstorm dialog

Present findings in four labelled sections, scaled to what's actually there (omit a section entirely if it would be empty):

1. **What the vault already says** — direct hits from Phase 2, summarised with note titles and a one-line takeaway each.
2. **Adjacent threads** — Phase 3 results: semantic neighbours, backlink contexts, shared-tag notes. Lead with the *unexpected* connections.
3. **Recent thinking that may apply** — notes from either pass whose modification or index time is within the recent window (last ~30 days, derived from frontmatter or index metadata where available). Surface these even if their relevance score is moderate — recency is its own signal.
4. **Gaps and questions** — concepts the user's notes *imply* but don't directly address; tensions between notes; unanswered questions the notes themselves raise.

After the synthesis, transition into a brainstorm-style dialog: one question at a time, propose 2–3 framings/angles drawing on the surfaced notes (not generic priors), refine iteratively. This mirrors the *shape* of `superpowers:brainstorming` without its software-design terminal state.

Cite specific notes by title when an idea is provoked by them — this lets the user open the note and follow the thread.

### Phase 5 — Optional synthesis note (user-triggered only)

If — and only if — the user explicitly asks for a written-back artifact ("write this up", "save a synthesis note", "add this to the vault"), the skill drafts a note and asks where to save it. The user confirms path and tags before any write. Default behaviour is read-only.

## 7. Anti-patterns to close (rationalizations)

Captured directly as rationalization rows in SKILL.md, in the same style as `followup-tracking`:

| Rationalization | Reality |
|---|---|
| "I searched once with the topic verbatim — that's the discovery pass." | Multi-query fan-out (3–4 reformulations) is required. Single-query search is a violation. |
| "Phase 3 (creative pass) is optional if Phase 2 already returned good hits." | Phase 3 is the value proposition of the skill, not a fallback. It runs every time. |
| "I'll summarise the vault hits and let the user take it from there." | Summary is not brainstorming. Use the findings to provoke divergent thinking and ask questions. |
| "The user's prompt didn't mention the vault explicitly — I'll just brainstorm normally." | If the user invoked this skill, vault grounding is the contract. Do not silently degrade. |
| "I'll write a synthesis note as I go so I don't lose the thread." | Vault writes require explicit user instruction. Phase 5 is opt-in only. |
| "I'll cite my reasoning without naming specific notes." | Cite by note title. The user navigates by note. |
| "Recency doesn't matter — the relevance score is what counts." | Recent notes get their own surfacing channel even at moderate relevance. Recency is signal. |

## 8. Red flags — stop and re-read the skill

- About to answer substantively without having run Phase 2 + Phase 3 searches.
- About to run only one `search` call and proceed.
- About to write to the vault without an explicit user request.
- About to summarise vault hits without transitioning into a brainstorm dialog.
- About to invoke `writing-plans` at the end of the session — wrong skill; this one does not terminate there.

## 9. Relationship to other skills

- **`superpowers:brainstorming`**: distinct skill, distinct terminal state. Both can fire in a session if the work calls for it (e.g., vault-brainstorm a concept, then `superpowers:brainstorming` if the concept turns into a software project).
- **`superpowers:writing-skills`**: required reading for editing this skill (TDD-for-skills, rationalization closure). Per project `CLAUDE.md`.
- **`followup-tracking`**: if vault gaps or open questions surface during the session and the user wants any tracked beyond the conversation, `followup-tracking` is the right channel — not vault writes.

## 10. Repo and filesystem layout

New skill directory:

```
skills/
  vault-brainstorming/
    SKILL.md
```

Symlink (added to `README.md`'s symlink list):

- `~/.claude/skills/vault-brainstorming` → `<repo>/skills/vault-brainstorming`

No other repo changes. The skill depends only on the existing `mcp__obsidian-hybrid-search__*` MCP tools, which are already configured at the user level.

## 11. TDD-for-skills (build discipline)

Per project `CLAUDE.md`, skill edits must follow the `superpowers:writing-skills` TDD discipline. The implementation plan must include:

1. Author a baseline pressure scenario in `tests/` (`vault-brainstorming-baseline-pressure-scenario.md`) — a realistic topic for which a vault-grounded brainstorm is the right answer, and which a no-skill subagent will fail in predictable ways.
2. Run the scenario against a subagent **without** the skill installed. Record observations in `tests/vault-brainstorming-baseline-observations.md`. Expected failure modes (to be confirmed empirically): single-query search, no creative pass, immediate summary without brainstorm dialog, missed recency.
3. Write `skills/vault-brainstorming/SKILL.md` against the observed failure modes — each rationalization row in §7 must trace to a specific baseline failure.
4. Run the scenario again *with* the skill installed and record `tests/vault-brainstorming-with-skill-observations.md`.
5. Iterate on SKILL.md until every baseline failure is closed by a rule the model actually follows under pressure.

The plan (next step) will sequence these as discrete tasks.

## 12. Open questions deferred to plan

- Exact wording of the SKILL.md `description` field (it must reliably trigger on "brainstorm + vault/notes/obsidian" intent without over-firing).
- Whether Phase 3's tag fan-out should be unconditional or gated on a shared-tag heuristic.
- Whether to set a hard cap on the number of `search`/`read` calls per session to prevent runaway exploration.

These are implementation details, not design questions, and belong in the plan.
