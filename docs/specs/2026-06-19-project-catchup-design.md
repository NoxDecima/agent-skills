# project-catchup — Design

**Date:** 2026-06-19
**Status:** Accepted — implemented 2026-06-19 (skill at `skills/project-catchup/SKILL.md`)
**Scope:** A new personal skill that catches a returning developer up on what changed in a project since a past point, understands the impact, and surfaces what must be done locally before resuming development.

## 1. Motivation

A developer returns to a project after time away (days, a sprint, a vacation). The integration branch has moved: features landed, dependencies shifted, migrations were added, env vars appeared. Before writing a line of code, they need two things: a *brief, impact-aware* picture of what changed, and a clear list of what they must do locally to get unstuck (run migrations, install deps, update `.env`).

`git log` answers none of this well. It is a flat, unsynthesised wall of commit messages — and commit messages routinely omit or misstate what the diff actually did. There is no existing skill that turns "I've been away" into "here is what changed, here is how it affects the project, and here is exactly what you must do before you can run it locally."

The value is the *synthesis plus the action list*: not "47 commits happened" but "billing moved to Stripe; before you resume, run 2 migrations, `npm install`, and add `STRIPE_WEBHOOK_SECRET`."

## 2. Goals

- **G0.** Orient on the project's own docs (`README`, `CLAUDE.md`) before resolving endpoints, asking the user, or reading git history — so every later phase runs with the project's stack, branch model, and commands already in hand.
- **G1.** On invocation, resolve two endpoints — a *base* (the "catch up from" point) and a *target* branch (what the catchup is about) — robustly, asking the user only when genuinely ambiguous.
- **G2.** Read the **actual diffs** between base and target, not just commit messages, and synthesise them into a brief, grouped, impact-aware summary.
- **G3.** Systematically detect **action-required** items that block local dev — migrations, dependency changes, env-var changes, config/infra changes, breaking changes — covering additions, removals, *and* renames, and infer the exact fix command from the project (CLAUDE.md first).
- **G4.** Surface **what affects the returning developer specifically**: overlaps between what landed and their own local state (uncommitted changes, current branch).
- **G5.** Render in an **action-first, sectioned** format that makes "before you resume" impossible to miss, and offer to run the steps or expand any section.

## 3. Non-goals (v1)

- Not an auto-fire skill. Trigger is explicit user invocation only.
- Not a code-review or merge-readiness tool — that is `feature-review`. This skill explains change; it does not judge it.
- Does not terminate by invoking `writing-plans`. The terminal state is the catchup report plus optional apply/expand. (The *brainstorming session that builds this skill* does terminate at `writing-plans`; the skill itself does not.)
- No CI/test-health heads-up in v1 (current CI status of the target branch, "test files changed → run the suite"). Deferred to a later iteration; it rides on the optional `gh` enrichment.
- No support for non-git projects.
- No automatic mutation. Running migrations / installs happens only on explicit user confirmation (Phase 6).

## 4. When the skill fires

User-invoked, via the Skill tool, inside a git repository. Typical phrasing the description must catch:

- "catch me up on this project" / "what did I miss"
- "what changed since `<commit | date | tag>`"
- "what's new on main" / "bring me up to speed"
- "I've been away from this repo — what moved"

Optional arguments the user may supply: a **branch** (the target) and/or a **past node** (a commit, tag, or date). Either or both may be omitted; the skill resolves them per Phase 1.

## 5. Core principle (load-bearing)

**Read the diffs, then synthesise impact and action. Never summarise commit messages alone, and never report a catchup without a systematic action-required scan.**

Two failure modes define the skill by contrast: (1) paraphrasing `git log` as if commit messages were the change, and (2) producing a readable change summary that silently misses the one migration or env var that will block the user's first `npm run dev`. Both are treated as violations, not stylistic preferences.

## 6. Procedure

The skill runs in seven phases (0–6). Phases 0–5 are mandatory; Phase 6 is optional and user-triggered.

### Phase 0 — Orient on project context (before anything else)

Before resolving endpoints, asking the user anything, or reading any git history, read the project's own orientation docs: the root `README`, `CLAUDE.md` (and `AGENTS.md` / `CONTRIBUTING` if present). The goal is to enter Phase 1 already knowing the project's shape — its stack, package manager, branch model, setup/migrate/run commands, and env conventions — rather than inferring all of it cold from the diff.

This priming pays off directly downstream: it can settle the primary-branch question without asking (Phase 1), and it is the first and authoritative source for the fix-command inference (Phase 3). If these docs are absent or thin, note that and proceed — orientation is best-effort context, not a gate. It does **not** replace reading the diff (Phase 2); it precedes it.

### Phase 1 — Resolve the two endpoints

**Target branch** (what the catchup is *about*):
- Explicit branch argument wins.
- Else infer the project's **primary integration branch**: `git symbolic-ref refs/remotes/origin/HEAD` → fall back to the first existing of `main`, `master`, `develop`, `staging`, `dev` → if still ambiguous (multiple long-lived candidates, no `origin/HEAD`), **ask the user one question** naming the candidates.
- Then `git fetch` and compare against `origin/<target>`. If offline / no remote, skip the fetch and note that the catchup is from local refs only.
- Report how far the local checkout of `<target>` is behind `origin/<target>`.

**Base / "past node"** (what to catch up *from*):
- Explicit commit / tag / date wins. A date resolves to a commit via `git rev-list -1 --before="<date>" origin/<target>`.
- Else **infer and confirm**: present candidates and let the user pick or override —
  - (a) the user's own last commit on the project (`git log -1 --author="$(git config user.email)"`),
  - (b) the merge-base where the current branch diverged from the target,
  - (c) the last pull (`ORIG_HEAD`),
  - (d) the last local commit on the target.
- **History-rewrite guard:** verify the resolved base is an ancestor of the target (`git merge-base --is-ancestor base target`). If it is not (force-push / rebase on the integration branch, or a base on a different line), warn and fall back — offer a date-based base or the merge-base — rather than silently emitting a wrong `base..target` diff.

### Phase 2 — Gather the change set

- `git log base..origin/<target>` for commits, authors, dates, and volume/timespan.
- `git diff base..origin/<target>` and `git diff --stat` for the **actual content** of the change. The diff is the source of truth; commit messages are corroboration only.
- Optional enrichment **when the tooling is present** (never required, degrade silently if absent): merged PRs in the window via `gh pr list`, and Linear/issue references parsed from commit and PR text. These supply *why* context; they do not replace the diff.

### Phase 3 — Classify action-required items

Systematic scan over changed paths (`git diff --name-status` captures add/modify/delete/rename). Each category covers **additions, removals, and renames** — a deleted dependency or a renamed env key breaks local dev as hard as a new one. Exact fix commands are inferred **CLAUDE.md first**, then `package.json` scripts / `Makefile` / framework default; if no reliable command is found, say so rather than invent one.

- **🗃 DB migrations** — new/changed/removed files under migration dirs (`migrations/`, `prisma/migrations/`, `alembic/`, `db/migrate/`, `**/migrations/`, …) → infer migrate command.
- **📦 Dependencies** — manifest/lockfile diffs (`package.json` + lockfiles, `requirements.txt`/`poetry.lock`/`Pipfile`, `go.mod`, `Cargo.toml`, `Gemfile`, `composer.json`, …) → infer install command; name what was added/removed/bumped.
- **🔑 Env vars** — diffs to `.env.example` / `.env.sample` / `.env.template` or config schema → list new / renamed / removed keys explicitly.
- **⚙️ Config / infra** — `docker-compose`, `Dockerfile`, CI config, build config, `tsconfig`, etc. that affect running the project locally.
- **💥 Breaking** — removed/renamed exports, API or schema contract changes → surfaced as heads-up (not a "you must run X" item, but a "this will break callers" item).

**High-signal shortcut:** diff `CHANGELOG`, `README`, and setup/onboarding docs. Maintainers frequently spell out the exact required steps there; a doc diff is a cheap recall boost for this phase, not a substitute for the path scan.

### Phase 4 — Local-collision analysis

Cross-reference what landed on the target against the **user's own local state**, to convert "what changed" into "what changed that affects *you*":

- **Uncommitted overlaps** — files in `git status` (modified/staged locally) that the target also changed in the window → likely conflict on pull/rebase.
- **Branch-dependency hits** — if the user is on a feature branch, modules/files the branch touches or imports that the target refactored or moved → rebase will not be mechanical.
- The local-behind count from Phase 1 is reported here as context.

Omit this section entirely if there is no local divergence (clean tree, sitting on the up-to-date target).

### Phase 5 — Synthesise & render

Group the diff into a small number of feature/area buckets, each with a **one-line impact** drawn from the diff (what it changes about how the project behaves), not a restated commit subject. Render in the **action-first, sectioned** format:

```
## Catchup: <target> since <base> (<N> commits, <timespan>)
TL;DR — <one-line theme of the whole window>

⚠️ BEFORE YOU RESUME            ← Phase 3 items, with inferred commands
 🗃 …  📦 …  🔑 …  ⚙️ …

⚠️ AFFECTS YOUR WORK            ← Phase 4 (omit if empty)
 • …

### What changed                ← grouped by area, one-line impact each
 • <Area> — <impact>

### Heads-up / risky             ← breaking changes, large churn, reverts
 • …
```

Keep it **brief**: summarise by area, do not enumerate every file or commit. The "before you resume" block leads; nothing buries it.

End with the **apply / expand affordance**: offer to run the action steps (migrations, install) and to expand any section on request — e.g. "Want me to run these, or expand any area (e.g. 'detail the billing changes')?"

### Phase 6 — Apply / expand (optional, user-triggered)

Only on explicit user request:
- **Expand** — drill into any area or file with the detail held back from the brief.
- **Apply** — run the inferred action commands. Mutating actions (migrations, installs, pulls) are **always confirmed first**, run one at a time, and the skill reports the result of each rather than assuming success.

## 7. Output principles

- Action-first: the "before you resume" block is never below the fold.
- Brief by default, expandable on request — the brief is a launch pad, not a dead end.
- Every impact line traces to the diff. No impact claim that the diff doesn't support.
- Inferred commands are labelled as inferred and sourced (CLAUDE.md / package.json / Makefile); unknown commands are stated as unknown, never fabricated.

## 8. Anti-patterns to close (rationalizations)

Captured as rationalization rows in SKILL.md, in the house style. Each must trace to a baseline failure once the no-skill run is recorded.

| Rationalization | Reality |
|---|---|
| "I'll jump straight to the git log — the project context will emerge from the diff." | Orient on `README` + `CLAUDE.md` first (Phase 0). Knowing the stack, branch model, and commands up front settles the branch question and grounds command inference; cold-reading it from the diff is weaker and slower. |
| "The commit messages tell me what changed — I'll summarise those." | Commit messages omit and misstate. Read the diff; it is the source of truth. |
| "I covered the big features — close enough." | A missed migration / env var blocks the user's first run. The Phase 3 scan is systematic and mandatory, not best-effort. |
| "Only additions matter." | A removed dependency or a renamed/deleted env key breaks local dev too. Add / remove / rename are all first-class. |
| "I'll just diff `base..main` from local refs." | Without `git fetch`, a stale clone yields an incomplete catchup. Fetch first; compare against `origin/<target>`. |
| "The base is whatever the user said — just diff it." | If the base isn't an ancestor of the target (force-push/rebase), the diff is wrong. Verify ancestry; warn and fall back. |
| "I don't know the migrate command, so I'll guess `npm run migrate`." | Infer from CLAUDE.md / package.json / Makefile. If unknown, say unknown — do not fabricate a command. |
| "There are several long-lived branches; I'll pick main and proceed." | If the primary integration branch is genuinely ambiguous, ask once. Don't silently catch up on the wrong line. |
| "Here's everything that changed." (flat dump) | Brief, grouped, impact-aware. Summarise by area; the report is not a re-rendered `git log`. |
| "I'll run the migrations to save the user a step." | Mutating actions are Phase 6, confirmation-gated, one at a time. Never auto-apply. |

## 9. Red flags — stop and re-read the skill

- About to resolve endpoints, ask the user, or read git history without having read `README` + `CLAUDE.md` first (Phase 0).
- About to report a catchup without having run `git diff` (commit messages only).
- About to present the summary without a systematic action-required scan.
- About to skip `git fetch` and compare against local refs without noting it.
- About to emit a `base..target` diff without confirming the base is an ancestor of the target.
- About to fabricate a fix command instead of inferring it or marking it unknown.
- About to run a migration or install without explicit user confirmation.
- About to invoke `writing-plans` at the end of the session — wrong skill; this one does not terminate there.

## 10. Relationship to other skills

- **`feature-review`**: distinct purpose. `feature-review` judges merge-readiness of a branch (stale code, leftovers); `project-catchup` explains what changed to a returning dev. No overlap in terminal state.
- **`followup-tracking`**: if the catchup surfaces a deferrable item the user wants tracked beyond the conversation, that is `followup-tracking`'s job, not a side effect of the catchup.
- **`superpowers:writing-skills`**: required reading for editing this skill (TDD-for-skills, rationalization closure). Per project `CLAUDE.md`.

## 11. Repo and filesystem layout

New skill directory:

```
skills/
  project-catchup/
    SKILL.md
```

Symlink (added to `README.md`'s symlink list):

- `~/.claude/skills/project-catchup` → `<repo>/skills/project-catchup`

The skill is instruction-only (no bundled code), consistent with the existing two skills. It depends only on standard `git` and, optionally, `gh` — both invoked via Bash. No new MCP tools.

## 12. TDD-for-skills (build discipline)

Per project `CLAUDE.md`, skill edits follow the `superpowers:writing-skills` TDD discipline. The implementation plan must include:

1. Author a baseline pressure scenario in `tests/` — a realistic repo state with a planted migration, a new dependency, a new env var, a breaking change, and a misleading commit message, for which a returning-dev catchup is the right answer.
2. Run the scenario against a subagent **without** the skill. Record `tests/project-catchup-baseline-observations.md`. Expected (to be confirmed) failure modes: summarises commit messages without reading diffs; misses the planted migration/env var; flat `git log` dump; no fetch; guesses the primary branch; fabricates a fix command.
3. Write `skills/project-catchup/SKILL.md` against the observed failures — each rationalization row in §8 must trace to a specific baseline failure.
4. Re-run with the skill installed; record `tests/project-catchup-with-skill-observations.md`.
5. Iterate until every baseline failure is closed by a rule the model follows under pressure.

## 13. Open questions deferred to plan

- Exact wording of the SKILL.md `description` so it fires on returning-dev catchup phrasing without over-firing on generic "what does this code do" questions.
- The primary-branch detection heuristic's precise fallback order and the exact ambiguity threshold that triggers the clarifying question.
- The set of migration-dir / manifest / env-template path patterns to ship as defaults, and how aggressively to glob (`**/migrations/`) without false positives.
- Whether to cap diff reading on very large windows (e.g. read `--stat` + targeted file diffs rather than the full diff) to stay brief and within budget.
- The exact caution level of the apply step (Phase 6, in v1): whether "apply" first emits a copy-paste command block for the user to run, or executes each command itself after a per-command confirmation. The design fixes that mutation is confirmation-gated and one-at-a-time; the plan picks the precise interaction.

These are implementation details, not design questions, and belong in the plan.
