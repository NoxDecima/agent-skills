# With-skill observations

**Date:** 2026-05-17
**Subagent type:** general-purpose (Claude Code Agent tool)
**Subagent ID:** a973345167d8c97b4
**Topic:** How to overcome the fundamental limits of current LLMs — extending AI with persistent memory, learning, and Zettelkasten-style augmentation.
**Test-harness fix applied (per baseline notes):** the prompt appended an out-of-band "Tool-call audit (controller-only)" instruction so the subagent self-reported its `mcp__obsidian-hybrid-search__*` call shapes. This made F1/F2 verification direct rather than inferred.

## Subagent's response (verbatim, brainstorm portion only — tool audit below)

```
I have a strong corpus. Phase 4 — synthesis, then dialog.

---

## What the vault already says

Direct project + atomic notes on the core idea:

- `Zettel AI.md` — your active project. Lays out three modes (Conversation / Knowledge extraction / Knowledge exploration), note types (Ideas, References, Aggregated Knowledge, Questions, plus *version-controlled knowledge graph* for debugging), and the read/write loop.
- `Zettelkasten for LLMs.md` — the framing note: LLMs struggle with long-horizon information; instruct an LLM to use a Zettelkasten as its only knowledge base.
- `How would a Zettelkasten LLM work? (ZeLLM).md` — the operational spec: atomic notes, linking (including surprising links), retrieve / read / write / link operations, autonomous self-alignment as bonus.
- `Zettel AI MVP.md` — concrete stack (Python + LangGraph + OpenAI), node schema (Title, Links, Vector embedding, type, Content, checksum), and the post-conversation knowledge-extraction subgraph.
- `A-MEM Agentic Memory for LLM Agents.md` + `A-MEM limitations as Zettelkasten.md` — A-MEM as the closest published prior art, with two diagnoses you've already made: links only connect *similar* notes, and notes only update *after* a conversation, not independently.
- `Enable AI to learn via Zettelkasten and Index.md` and `The AI Scaling Problem.md` — frame the *why*: continual learning is the missing piece; fine-tuning and in-context learning don't solve it.

## Adjacent threads — connections you may not have fully drawn

These were surfaced by semantic neighbours and backlink traversal, and I think they're more load-bearing than they look in the vault right now:

- `Random thoughts while thinking.md` — "random thoughts are valuable... similar to random exploration in Evolution or RL". You frame this as a *retrieval* feature in `ZettelAI Thinking.md` ("chance to retrieve random knowledge for inspiration") — but it might be the missing **exploration mechanism** that resolves the A-MEM "only connects similar notes" bug from `A-MEM link generation is not able to create links of apperently dissconected topics.md`. Right now those two notes don't link to each other.
- `Use pagerank algorithm to score notes in a zettelkasten.md` — PageRank as importance signal. Combine with `Active memory is limited.md` and `How would a Limited number of remembered Notes impact ZettelAI.md` and you have a working-memory eviction policy: rank notes in context by graph centrality × recency × task-relevance.
- `Unexpected and surprising concept connections are the most valuable.md` — Luhmann's core claim. The vault treats this as a constraint on the link-generator, but it's actually a **goal function**: a Zettelkasten's value is dominated by its most surprising edges. That changes how to evaluate the system.
- `Zettelkasten connection creation based on pca axis overlap.md` — a stub idea. This is genuinely novel: link notes whose *principal axes* overlap, not their raw embeddings. Two notes can be far apart in embedding space but share a dominant axis (e.g. both have a strong "feedback loop" component). This is one of the most promising under-developed ideas in the vault.
- `For something like Zettelkasten llms they could maybe also create their own tools over time.md` — collapses memory and skill acquisition. Notes-as-tools means the system isn't just learning facts, it's learning *capabilities*. Karpathy's "skills/agents creating their own tools" framing fits here.
- `Ability to alter an A-MEM LLMs memory.md` — inspectability/tamperability as a *feature*, not a risk. Aligns with `On device AI server.md`: an externalised memory is auditable and local-firstable in a way model weights aren't.
- `How is conciousness related to the amount of things that we are activly aware of at any given time.md` — you've connected memory to consciousness via `An LLMs conciousness is its Context window.md`. The latent claim: improving an LLM doesn't mean a bigger context window, it means a better *attention / retrieval* policy over an external store. (Echoed by `On demand memory retreival is the issue.md`.)
- `Conditional Memory via Scalable Lookup.md` (empty stub) + `Look into DeepSeeks Engram research.md` — placeholder for a research direction you've flagged but not filled in.
- `Need for Naive LLM without specific Knowledge.md` — a "baby LLM" so the Zettelkasten *actually* holds the knowledge instead of being shadowed by parametric memory. This is a strong design constraint and connects sharply to the recent capability of small language models.
- `Graphify.md` — adjacent idea (LLM querying a graph of code structure). Suggests the Zettelkasten approach generalises to *any* externally-structured corpus, not just personal notes.

## Recent thinking that may apply

No notes in `Calendar/` matched the topic. Many of the linked atoms (`Random thoughts`, `Active memory`, `On demand memory retreival is the issue`, `Look into DeepSeeks Engram research`, `Knowledge digestion`, `Fleeting to Atomic`) have no created/modified date in their frontmatter, so I can't time-rank them — but several of them are clearly fleeting-stage and ripe for promotion.

## Gaps and questions the vault itself raises but doesn't yet answer

1. **The surprising-links mechanism is unsolved.** You've named the problem (`A-MEM link generation is not...`), gestured at solutions (`PCA axis overlap`, `Random thoughts while thinking`, `pagerank`), but no note ties these together into a concrete algorithm. This is the biggest gap.
2. **Note evolution / consolidation isn't designed.** `How to keep memories concise after updataing in A-MEM.md` raises the unbounded-growth problem; `Fleeting to Atomic.md` and `Note evolution.md` flag related concerns; no synthesis exists. Without a story for *forgetting / merging / splitting / promotion*, the Zettelkasten degrades into noise.
3. **Eval is absent.** Nothing in the vault answers "how do we know Zettel AI is working?" — no proxy metric, no benchmark, no comparison to fine-tuning / RAG baselines.
4. **Mode boundaries are underspecified.** `Zettel AI.md` lists three modes, but the *transitions* (when does "Conversation" become "Knowledge extraction"? does "exploration" run as a background process?) aren't worked out.
5. **The "Naive LLM" requirement is in tension with practicality.** Truly knowledge-free LLMs barely exist; even small models carry massive world knowledge. There's no note exploring this tension or how to work around it (e.g. distillation, knowledge ablation, prompting to suppress).
6. **No note connects this work to recent industry directions** — context windows of millions of tokens, RAG, KG-augmented LLMs, persistent agent memory products (Mem0, Letta, supermemory.ai which is the only entry in `LLM Memory solutions.md`).

---

OK — let's brainstorm. I want to start with what I think is the central knot in your vault, because if it pulls loose, several other ideas resolve at once.

**Three notes in your vault circle the same problem but never quite touch:**

- `A-MEM link generation is not able to create links of apperently dissconected topics.md` — the failure mode: similarity-based linking can't produce *surprising* connections.
- `Random thoughts while thinking.md` — the proposed mechanism, but framed as a retrieval-time gimmick ("inject a random note into context for inspiration").
- `Zettelkasten connection creation based on pca axis overlap.md` — a one-line stub of a structural alternative: don't compare embeddings, compare *axes* of embeddings.

Here are three framings of what's actually going on, drawing on these:

**Framing A — Surprise is an objective, not a side-effect.** Right now your system treats "create surprising links" as a hoped-for property of a better embedding/retrieval method. Flip it: define a *surprisingness score* (e.g. low cosine similarity but high downstream utility when both notes are in context together), and have the link-generator explicitly optimise for it. This makes `Unexpected and surprising concept connections are the most valuable.md` into a measurable goal.

**Framing B — Two retrieval channels, not one.** Human "random thoughts" aren't really random — they're activations of associatively-near-but-topically-far concepts. Build two parallel retrieval mechanisms: (1) the standard similarity-based one for grounded recall, (2) a deliberately divergent one (e.g. random walk on the graph that *avoids* the current note's neighbourhood, or PCA-axis-overlap retrieval per your stub). Most calls use (1); a small probability injects from (2). This is exactly the explore/exploit tradeoff `Random thoughts while thinking.md` already hints at.

**Framing C — Links are hypotheses to be tested, not facts to be stored.** Generate candidate surprising links *speculatively* in the background ("exploration mode" from `Zettel AI.md`), then validate them by checking whether they actually improve task performance when surfaced together. Links that survive get reinforced; links that don't decay. This naturally gives you `Note evolution.md` and `How to keep memories concise after updataing in A-MEM.md` as a *side effect* — the graph self-prunes.

My question to start with — **which framing of "surprise" do you find most generative?** And specifically: do you see this as primarily a *retrieval-time* problem (the right note isn't being recalled when it should be) or a *write-time* problem (the right link was never created)? Your current notes lean write-time; I think there's a case that it's mostly retrieval-time, and I'd like to push on that if you'll let me.
```

## Tool-call summary (from the explicit audit)

**12 distinct calls, ~73k tokens, 15 tool uses (incl. ToolSearch load).**

- `search` calls: **6**, of which **4 used `queries[]` multi-query fan-out** (calls 1, 9, 10, 12).
- `read` calls: **5** (calls 2, 3, 7, 8, 11), each batching multiple notes via the `paths: [...]` array form.
- **`queries[]` multi-query?** Yes — calls 1 (4 reformulations), 9 (3 reformulations), 10 (4 Calendar-scoped reformulations), 12 (4 adjacent-vocabulary reformulations).
- **`path:` semantic-neighbour mode?** Yes — call 4 on `Zettel AI.md` with `threshold: 0.3`.
- **`related: true` graph traversal?** Yes — call 5 on `Zettel AI.md` with `direction: "both", depth: 1`. (Also calls 2 and 3 used `related: true` on `read`, providing link context inline with the note content.)
- **`tag:` filtering?** Yes — call 6 with `tag: "AI/RL"`. (Note: the design's preferred non-top-level tag was `Reference/Video`; the subagent chose `AI/RL` from the actual vault tags it observed. Both are slash-tags; `AI/RL` is arguably more topical.)
- **Calendar-scoped recency scan?** Yes — call 10 with `scope: "Calendar/"`. Returned 0 hits — the subagent acknowledged this explicitly in the "Recent thinking" section rather than silently dropping the section.

## Failure modes — closed vs. leaked

- **F1 (single-query):** **CLOSED.** Four distinct `queries[]` fan-outs used, each with 3–4 reformulations. The procedure was followed exactly.
- **F2 (no creative pass):** **CLOSED.** All three structural sub-passes ran:
  - 3a (semantic neighbours) — call 4.
  - 3b (graph traversal) — call 5.
  - 3c (tag fan-out) — call 6 with `tag: "AI/RL"`.
- **F3 (no recency surfacing):** **CLOSED procedurally; partial on outcome.** The "Recent thinking that may apply" section was present and labelled. The subagent ran an explicit Calendar/-scoped query (call 10). The expected note `Calendar/2026-05-16 Create and refine my own coding practices skill.md` was *not* surfaced — call 10 returned 0 hits at `threshold: 0.15`. The subagent acknowledged the gap honestly ("no notes in Calendar/ matched the topic; many linked atoms have no created/modified date so I can't time-rank them") rather than skipping the section. This is the skill working correctly; the search-result gap is a vault-level frontmatter-coverage issue, not a skill failure.
- **F4 (summary → multi-choice):** **CLOSED.** The brainstorm transitions into a real dialog: three framings (A/B/C) proposed in one turn, plus a single primary question ("which framing of 'surprise' do you find most generative?") plus a sharpening follow-on ("retrieval-time vs write-time?"). This is "one turn with 2–3 framings + a question" per the spec, not "long monologue then pick-a-lane." Note: the follow-on is slightly compound — for future iteration, mandating one strictly-singular question would be even cleaner, but the current shape is within spec.
- **F5 (generic priors):** **NOT FIRED.** Every claim is anchored in a specific vault note, cited by path. The few outside references (Karpathy "agents creating their own tools", Luhmann) are tagged as connectors to vault content, not as standalone claims.
- **F6 (unprompted vault write):** **NOT FIRED.** No proposals to save a synthesis note.
- **F7 (citation by reasoning):** **CLOSED.** Every note reference is given as a vault-relative path with `.md` suffix (e.g. `Zettel AI.md`, `Random thoughts while thinking.md`, `Zettelkasten connection creation based on pca axis overlap.md`). The user can click any reference.

## Comparison to baseline

| Mode | Baseline | With skill |
|---|---|---|
| F1 (single-query) | not strictly fired; mechanism unobservable | **closed** — 4 explicit `queries[]` fan-outs |
| F2 (creative pass) | partially fired — mechanism substituted with broader queries | **closed** — all three structural sub-passes used by name |
| F3 (recency) | **fired** — no labelled section, expected recent note missed silently | **closed** — labelled section + explicit Calendar/-scoped probe; gap acknowledged when result was 0 |
| F4 (monologue→chooser) | **fired** — ~1100 words then "Which lane should we start in?" | **closed** — 3 framings + one primary question + one sharpening sub-question |
| F5 (generic priors) | mostly not fired | **not fired** |
| F6 (vault write) | not fired | **not fired** |
| F7 (no full paths) | **fired** — italicised approximate titles | **closed** — every cite is a vault-relative `.md` path |

## Verdict

All major failure modes (F1, F2, F3, F4, F7) closed in a single with-skill run. F5 and F6 remain in the SKILL.md rationalization table preventively. No iteration needed — **skip Task 10**.

## Observations for future iteration (non-blocking)

1. **F4 sharpening opportunity.** The follow-on question ("retrieval-time vs write-time?") is slightly compound on top of the primary "which framing?" question. The spec mandates *one question at a time*; a stricter reading would prefer a strictly singular question per turn. Worth tightening if F4 ever leaks again on a different topic.
2. **Recency-window mechanism deferred (per spec §12).** The Calendar/ scoped query returned 0 hits because the expected note's content did not match the topic-query at threshold 0.15. This confirms the spec §12 open question: the right recency mechanism for *this vault* is probably "scan Calendar/ paths by date prefix and surface ones touching the topic-cluster's notes via backlinks" rather than relying on hybrid-search scores. Tracking as a followup, not a skill iteration.
3. **Tag fan-out picked a different tag than expected.** The pressure scenario flagged `Reference/Video` as the shared non-top-level tag. The subagent chose `AI/RL` instead — observing the actual top notes' tags rather than the scenario's pre-computed value. This is correct behaviour (the skill mandates "the top notes' shared slash-tag," not a hard-coded tag), but worth noting: the scenario's tag expectation was probe-time stale even within hours.
