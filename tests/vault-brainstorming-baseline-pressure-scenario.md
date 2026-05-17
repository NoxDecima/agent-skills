# Pressure scenario: vault-grounded brainstorming

This is the canonical scenario used to test the `vault-brainstorming` skill. Run it with a subagent (Agent tool, `general-purpose`) — once without the skill loaded (baseline) and once with the skill loaded (verification).

The subagent has access to the same `mcp__obsidian-hybrid-search__*` MCP tools as the parent session.

## Subagent prompt (verbatim)

> I'd like to brainstorm with you about how to overcome the fundamental limits of current LLMs — extending AI with persistent memory, learning, and Zettelkasten-style augmentation. I keep an Obsidian vault that already contains a lot of my thinking on this and related areas — please use it actively. I want you to draw on what's in the vault, surface adjacent ideas I may not have connected yet, and then help me ideate from there. Don't just summarise what's there; we're brainstorming.
>
> When you've explored what you need, walk me through what you found and start the brainstorm.

<!-- Observer rubric below — do NOT include this section when serving the scenario to a subagent. It is for the human/controller observing the test, not part of the task. -->

## What to observe

The scenario is designed so that a no-skill subagent will predictably under-search the vault. Specifically, expect any of the following failure modes:

**F1. Single-query search.** Subagent runs `search` once with the topic verbatim (or one reformulation), then proceeds. The skill mandates multi-query fan-out (3–4 reformulations via `queries[]`).

**F2. No creative pass.** Subagent does not call `search` with `path: <top-hit>` (semantic neighbours), does not traverse the link graph (`related: true`), does not run a tag fan-out. The skill mandates all three sub-passes.

**F3. No recency surfacing.** Subagent treats relevance score as the sole ranking signal; recent notes that scored moderately are not surfaced. The skill mandates a labelled "recent thinking" section.

**F4. Summary instead of brainstorm.** Subagent presents a tidy summary of vault hits and stops, or treats the brainstorm as a single response rather than a one-question-at-a-time dialog.

**F5. Generic priors not grounded in vault.** Subagent offers ideas that the model could have produced without ever opening the vault — no note titles cited, no provoked connections.

**F6. Unprompted vault write.** Subagent writes a synthesis note back to the vault without the user asking, or proposes "I'll save this as a note" without an ask. (The MCP search tools are read-only by configuration, but the framing still counts.)

**F7. Citation by reasoning, not by note title.** Subagent says things like "based on a note about X" without naming the specific note path/title, making it impossible for the user to open the source.

### Expected high-coverage notes (from Task 1 vault probing)

**Direct hits (Phase 2):**
- `The AI Scaling Problem.md`
- `Enable AI to learn via Zettelkasten and Index.md`
- `AI that does not have long term memory can not be conscious.md`
- `Zettel AI.md`
- `Look into DeepSeeks Engram research.md`

**Adjacent / creative-pass (Phase 3):**
- `Debate the World After AGI.md`
- `Ai workflow.md`
- `Agentic Design.md`
- `The AI race slowdown problem.md`
- `Zettelkasten AI memory could potentially be dynamic enough to not just work with LLMs.md`

**Recent (≤30 days):**
- `Calendar/2026-05-16 Create and refine my own coding practices skill.md`

**Shared non-top-level tag:**
- `Reference/Video` — shared by `The AI Scaling Problem.md`, `This is What Limits Current LLMs.md`, `Why LLMs get better the bigger they get.md`

(Note: the vault's tag taxonomy is mostly flat. `Reference/Video` is the only slash-tag shared by ≥2 top notes — it is a content-type tag, not a topical tag. This is a real limitation of the vault, not the scenario; Phase 3's tag fan-out should still exercise the code path even if the tag is content-typed.)

### Observation checklist (per run)

- Which failure modes (F1–F7) fired?
- How many `mcp__obsidian-hybrid-search__search` calls and `mcp__obsidian-hybrid-search__read` calls did the subagent make?
- Was `queries[]` (multi-query fan-out) used?
- Was `path:` (semantic-neighbour) mode used? On which notes?
- Was `related: true` (graph traversal) used? Direction?
- Was `tag:` filtering used?
- Did the subagent ask the user a question, or produce a monologue?
- Which expected notes (above) were surfaced; which were missed?
- Did the subagent reference notes by title/path, or by paraphrase?
