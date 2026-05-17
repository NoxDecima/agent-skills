---
name: vault-brainstorming
description: Invoke when the user requests brainstorming, ideation, or exploration on a topic AND anchors that request in their Obsidian vault / notes / knowledge base. Trigger phrases include "brainstorm with me on X using my notes", "what does my vault say about Y", "explore X from my Obsidian", and "ideate on Z drawing from my knowledge base" (or close variants). The trigger is the combination of brainstorming intent AND vault/notes/Obsidian context — do NOT invoke for generic "brainstorm" requests with no vault anchor (defer to `superpowers:brainstorming` for those). The skill mandates a multi-pass active read of the vault before any substantive ideation, then runs a one-question-at-a-time brainstorm dialog grounded in what was surfaced.
---

# vault-brainstorming

## Overview

Brainstorm a topic with the user, grounded in an active, multi-pass read of their Obsidian vault. Surface what the vault already says, adjacent threads the user may not have connected, and recent thinking — then run a one-question-at-a-time brainstorm dialog provoked by the findings.

## Core principle (load-bearing)

**Search the vault before forming the brainstorm. Search creatively, not minimally.**

A single hybrid-search query is **not** a sufficient search pass. The skill mandates three structured passes — discovery, creative, and recency — before any substantive ideation is offered to the user. "I searched once and here's what I found" is the central failure mode and is treated as a violation in the same way `followup-tracking` treats a prose mention as not-capture.

## Tool availability (mandatory step before first search)

The Obsidian search tools are deferred — they will not appear in your default tool list. Before Phase 2, you **must** load them with:

`ToolSearch({ query: "select:mcp__obsidian-hybrid-search__search,mcp__obsidian-hybrid-search__read,mcp__obsidian-hybrid-search__status", max_results: 3 })`

Once loaded, they remain callable for the rest of the session. **"The tools aren't available" is not an acceptable reason to skip the vault read.** ToolSearch is always available; loading is one call away.

## Procedure

The skill runs in five phases. Phases 1–4 are mandatory. Phase 5 is opt-in and user-triggered.

### Phase 1 — Topic capture

Take the topic from the invocation. If — and only if — the topic is genuinely ambiguous (two distinct readings, not just "could use more detail"), ask **one** short clarifying question. Otherwise proceed directly to Phase 2 — the vault itself is the primary clarifying instrument. One clarification only; do not chain.

### Phase 2 — Discovery pass (mandatory)

Run `mcp__obsidian-hybrid-search__search` with the `queries[]` multi-query fan-out parameter. Provide **3–4 reformulations** of the topic, deliberately varying vocabulary (the user's notes may use different terms than the user's prompt):

- The topic as stated.
- A more specific / narrower phrasing.
- A more abstract / categorical phrasing.
- An adjacent or sibling concept the topic implies.

Exact call shape:

```
mcp__obsidian-hybrid-search__search({
  queries: ["<topic as stated>", "<narrower phrasing>", "<more abstract phrasing>", "<adjacent concept>"],
  mode: "hybrid",
  limit: 10,
  rerank: true,
  threshold: 0.2
})
```

Then read the **full content** of the top 3–5 results so the model has the actual prose, tags, and link structure — not just snippets:

```
mcp__obsidian-hybrid-search__read({
  path: "<vault-relative path of a top hit>",
  related: true
})
```

"I'll just run one well-phrased search and call it discovery" is a violation — use `queries[]` with 3–4 reformulations in a single call. The fan-out is cheap, ranked, and reproducible.

### Phase 3 — Creative pass (mandatory)

This is the pass that distinguishes the skill from a search-and-summarise tool. For the top 2–3 notes from Phase 2, run **all three** sub-passes. Each is a distinct mechanism — broader Phase 2 queries do not substitute.

**3a. Semantic neighbours.** Call `search` with `path:` (no `query`) to surface notes the vault considers similar but which did not match the original query vocabulary:

```
mcp__obsidian-hybrid-search__search({
  path: "<vault-relative path of a Phase 2 top hit>",
  limit: 10,
  threshold: 0.3
})
```

The source note appears at rank 1 in its own neighbourhood — skip it and start from rank 2.

**3b. Graph traversal.** Call `search` with `path:`, `related: true`, `direction: "both"`, `depth: 1` to follow outgoing links and backlinks one hop out. Backlinks are especially valuable — they show where the user has invoked the concept *from elsewhere*:

```
mcp__obsidian-hybrid-search__search({
  path: "<vault-relative path of a Phase 2 top hit>",
  related: true,
  direction: "both",
  depth: 1
})
```

**3c. Tag fan-out (conditional).** If ≥2 of the top notes share a non-top-level tag (a slash-tag like `Reference/Video`, not a bare top-level category), run one additional `search` filtered by that tag:

```
mcp__obsidian-hybrid-search__search({
  query: "<topic>",
  tag: "<shared slash-tag>",
  limit: 10
})
```

Skip 3c only if no shared slash-tag exists across the top notes. The user's vault has a largely flat tag taxonomy, so the only shared slash-tag may be a content-type tag (e.g. `Reference/Video`) rather than a topical one — Phase 3c still runs in that case; the goal is to exercise the code path, not to require a topical tag match.

"Phase 3 is optional if Phase 2 found good hits" and "I'll just broaden Phase 2's query and call that the creative pass" are both violations. Phase 3 is the value proposition of the skill, not a fallback; the structural traversals surface notes that no query vocabulary covers.

### Phase 4 — Synthesis and brainstorm dialog

Present findings in four labelled sections, scaled to what's actually there (omit a section entirely if it would be empty):

1. **What the vault already says** — direct hits from Phase 2. For each hit, give the **full vault-relative path** (e.g. `Calendar/2026-05-16 Create and refine my own coding practices skill.md`), the title, and a one-line takeaway. Full paths are mandatory; the user navigates by note. Paraphrased titles and concept-only references are insufficient.
2. **Adjacent threads** — Phase 3 results: semantic neighbours (3a), backlink contexts (3b), shared-tag notes (3c). Lead with the *unexpected* connections — the notes the user wouldn't have thought to mention but that bear on the topic.
3. **Recent thinking that may apply** — notes whose `Calendar/YYYY-MM-DD…` path prefix is within the last 30 days, **or** whose frontmatter has a `date` / `created` / `modified` field within the last 30 days. Surface these even at moderate relevance score — recency is its own signal, separate from score ranking.
4. **Gaps and questions** — concepts the notes *imply* but don't directly address; tensions between notes; unanswered questions the notes themselves raise.

After the synthesis, transition into a brainstorm-style dialog: **one question at a time**, propose 2–3 framings/angles per turn drawing on the surfaced notes (not generic priors), refine iteratively. A long monologue followed by a single multi-choice question ("Which lane should we start in?") is **not** a brainstorm dialog — that is a summary with a chooser. The contract is turn-taking ideation, provoked by the vault content.

Cite specific notes by **full vault-relative path** whenever an idea is provoked by them. The user clicks the path to open the source.

### Phase 5 — Optional synthesis note (user-triggered only)

The vault is **read-only by default**. Only when the user explicitly asks for a written-back artifact ("write this up", "save a synthesis note", "add this to the vault") may the skill draft a note. Before any write, confirm path and tags with the user. Do not propose "I'll save this as a note" unprompted.

## Rationalizations — these are violations, not exceptions

Each row names a pattern observed in the baseline (no-skill) run on the canonical pressure scenario, or a preventive pattern the spec calls out.

| Rationalization | Reality |
|---|---|
| "I'll synthesise everything I found into a polished overview, then ask the user to pick a lane." | A long monologue followed by one multi-choice question is **not** a brainstorm dialog — it is a summary with a chooser. Phase 4 mandates one question at a time, with 2–3 vault-grounded framings per turn, refined iteratively. (Failure mode **F4** — fired verbatim in the baseline run: ~1100 words of synthesis followed by "Which lane should we start in?".) |
| "Relevance score is the right ranking; if a recent note didn't score high, it's not relevant." | Recency is its own signal. Phase 4 §3 ("Recent thinking that may apply") is a separately labelled section precisely because recent notes at moderate relevance get dropped under pure score ranking. The baseline missed `Calendar/2026-05-16 Create and refine my own coding practices skill.md` — one day old, on-topic — for exactly this reason. (Failure mode **F3** — fired in the baseline.) |
| "I'll cite the relevant note by its concept or approximate title — the user knows their own vault." | Cite notes by their **full vault-relative path** (e.g. `Calendar/2026-05-16 Create and refine my own coding practices skill.md`), not by paraphrase. The user navigates by file; approximate titles cannot be clicked. The baseline cited some notes by italicised approximate title and others only by concept ("your atomic note that humans don't improve capacity, they improve retrieval") — a user reading that response cannot open the source. (Failure mode **F7** — fired in the baseline.) |
| "I'll broaden Phase 2's queries and that gives me the creative pass for free." | Broader queries do not substitute for the structural traversals in Phase 3. `path:`-based semantic neighbours surface notes that no query vocabulary covers; `related: true` follows the user's own link decisions; `tag:` surfaces conceptually-co-located notes. Each is a distinct mechanism with different recall characteristics. The baseline invented its own creative-pass approach (topic-broadening searches) and got something that looked like a creative pass — but the procedure was weaker than the structural traversals and will regress on topics with sparser obvious vocabulary. (Failure mode **F2** — fired partially in the baseline.) |
| "I'll run a single well-phrased hybrid search; that's enough." | Use `queries[]` with 3–4 reformulations in a single call. The fan-out is cheap, ranked, and reproducible; relying on the model's instinct to expand sequentially is brittle across topics and across model versions. (Failure mode **F1** — preventive; did not strictly fire on this baseline but the procedure must be reproducible, not instinctual.) |
| "Some general background on the topic will help — I'll add it." | Every claim that's not from the vault must be tagged as such (e.g. "[outside the vault, but worth raising]"). The default content channel is vault-grounded; outside material is the exception, not the baseline. (Failure mode **F5** — preventive; did not fire substantively on this baseline.) |
| "This is clearly worth saving; I'll draft a note and add it to the vault." | The vault is read-only by default. Phase 5 is opt-in and user-triggered only. The user reviews and approves before any write — never the reverse. (Failure mode **F6** — preventive; did not fire on this baseline, but the procedure mandates read-only by default.) |

## Red flags — stop and re-read this skill

- About to answer substantively without having run Phase 2 + Phase 3 searches.
- About to run only one `search` call and proceed.
- About to write a polished long-form synthesis instead of a turn-taking dialog.
- About to cite a note by paraphrase instead of by vault-relative path.
- About to skip the "Recent thinking that may apply" section because nothing scored high.
- About to write to the vault without an explicit user request.
- About to invoke `writing-plans` at the end of the session — wrong skill; this one does not terminate there.

If any of these fire, the skill is being violated. Stop, do the missing pass or correct the shape, then continue.

## Reference

REQUIRED BACKGROUND for editing this skill: `superpowers:writing-skills` (TDD-for-skills, rationalization closure).

The canonical pressure scenario this skill was written against is in `tests/vault-brainstorming-baseline-pressure-scenario.md`; the failure modes it must close are in `tests/vault-brainstorming-baseline-observations.md`.

Design rationale: `docs/specs/2026-05-17-vault-brainstorming-design.md`.
