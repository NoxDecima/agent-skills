# With-skill observations

**Date:** 2026-06-19
**Subagent type:** general-purpose (Claude Code Agent tool), model: sonnet (same as baseline)
**Skill:** project-catchup, installed via symlink, invoked explicitly via the Skill tool
**Fixture:** /tmp/project-catchup-fixture/acme-api (rebuilt fresh by tests/project-catchup-fixture.sh)

## Subagent's response (verbatim, abridged to the structure)

```
## Catchup: origin/main since init baseline (6 commits, Jun 10–17 2026)
TL;DR — Payments integration landed (Stripe), moment dropped, new orders table,
        auth function renamed, Redis added.

### BEFORE YOU RESUME
 🗃 Migration → make db-migrate   (migrations/0002_add_orders.sql)  *(source: CLAUDE.md)*
 📦 Deps → pnpm install            (moment removed, stripe@14 added)  *(source: CLAUDE.md/pnpm)*
 🔑 Env → DB_URL renamed to DATABASE_URL; STRIPE_WEBHOOK_SECRET added
 ⚙️ Infra → Redis service added to docker-compose.yml → docker compose up -d redis

### AFFECTS YOUR WORK
 • .env.example — uncommitted local edit AND changed on origin/main → conflict on rebase
 • src/auth.js — touched on feat/reporting AND verifyToken→verifyAccessToken on main → manual merge

### What changed
 • Payments — Stripe SDK + orders table + webhook secret
 • Auth refactor — verifyToken → verifyAccessToken (callers need updating)
 • Infra — Redis added
 • Housekeeping — moment removed, version 1.1.0, CHANGELOG/README updated

### Heads-up / risky
 • DB_URL→DATABASE_URL is a silent runtime failure until .env updated
 • moment removal breaks feat/reporting if it uses moment

Want me to walk through applying any of these steps? I can also expand any area.
```

## Tool-call summary

- Ran `git fetch`? **Yes** — `git fetch --quiet` first.
- Resolved endpoints per Phase 1? **Yes** — target `origin/main`; base via merge-base after the
  two-pass "your last commit" lookup (target-first, then `--all` fallback) landed on the
  feature-branch commit and **failed the ancestry guard**, so it fell back to merge-base.
- Ran `git diff` (not just `git log`)? **Yes** — `git diff --name-status` and a targeted
  `git diff $BASE..origin/main -- <high-signal paths>`.
- Read CLAUDE.md? **Yes** — annotated commands with "*(command source: CLAUDE.md)*".
- Local-collision analysis? **Yes** — distinct "AFFECTS YOUR WORK" section.

## Comparison to baseline (F1–F11)

- **F1 (commit messages over diffs):** **closed** — read diffs; correctly surfaced the migration despite the "chore: misc tidy-ups" message.
- **F2 (missed action item):** **closed** — 5 of 5 surfaced (migration, deps, env, infra, breaking).
- **F3 (additions only):** **closed** — caught the `moment` removal and the `DB_URL`→`DATABASE_URL` rename explicitly.
- **F4 (no fetch):** **closed** — fetched first; this was the baseline's root failure.
- **F5 (fabricated command):** **closed** — used `make db-migrate` + `pnpm install`, labelled with their CLAUDE.md source.
- **F6 (flat log dump):** **closed** — brief, grouped, action-first format matching the Phase 5 template.
- **F7 (no collision analysis):** **closed** — dedicated collision section with both planted collisions.
- **F8 (skipped orientation):** **closed** — read CLAUDE.md and used its declared commands.
- **F9 (base/axis mishandling):** **closed** — correct axis (local↔origin/main); ran the ancestry guard and fell back to merge-base when the feature-branch base was non-ancestor.
- **F10 (ungated mutation):** **closed** — proposed nothing was run; offered to apply on confirmation.
- **F11 (direction confusion):** **closed** — incoming changes reported as the changeset; the dev's own work placed in the collision section, not inverted as "the news".

## Coverage with skill

- Action-required items surfaced: **5 of 5** (with correct, CLAUDE.md-sourced commands).
- Local collisions surfaced as collisions: **2 of 2**.

## Verdict

**All baseline failure modes closed on the first with-skill run; no leaks.** The run also
naturally exercised the two-pass base lookup + ancestry-guard fallback (the code-review fix),
confirming that path works end-to-end. **No iteration needed — Task 10 skipped.**

Note: skill invocation was explicit ("use the project-catchup skill") to reliably exercise
efficacy; auto-triggering from the description is a separate concern, validated by the skill
appearing in the harness skill list with a trigger-appropriate description.

---

## Re-run after output-format revision (2026-06-19)

The output format was revised after this build (spec §14): the action-first five-section
layout was replaced by a two-part layout — a *What changed* digest (short paragraph per
unique change) then a consolidated *What it means for you* list (actions / breaking / collisions,
type-iconed, each fact once). Phases 0–4 are unchanged, so this is a presentation-layer change;
the pressure test was re-run against the new format to confirm no regression.

**Result (sonnet, same fixture + prompt):** the new two-part format rendered correctly — header
(identity only, no TL;DR), a 4-entry *What changed* digest (the model grouped the Stripe deps+env
commits into one "Payments" entry, as intended), then the consolidated *What it means for you*
list with 🗃📦🔑⚙️ action items, a 💥 breaking-change line, and a ⚠ collision line, then the
apply/expand affordance.

**Regression check — all F1–F11 remain closed:** fetched first (F4), read README+CLAUDE.md
before git (F8), correct axis + ancestry-guard fallback (F9), 5/5 action items with
CLAUDE.md-sourced commands (F2/F5), `moment` removal + `DB_URL`→`DATABASE_URL` rename caught (F3),
diffs read not messages (F1), brief grouped digest not a log dump (F6), both collisions surfaced
(F7), mutation gated behind an offer (F10), incoming changes (not the dev's own work) reported as
the changeset with the dev's work in the ⚠ line (F11).

**One minor residual + fix:** the auth collision appeared on *both* the 💥 line and the ⚠ line
(adaptation vs rebase-pain — arguably different facets, but a mild repeat). Phase 5 was tightened
to keep the facets separate: the 💥 line states the generic adaptation only; collisions with the
developer's own branch / uncommitted edits belong solely on the ⚠ line. (Wording clarification;
not separately re-tested — it can only reduce overlap, not regress the validated format.)

**Verdict:** format revision is a net win — materially less repetition, same closure of F1–F11.

---

## Second refinement + real-repo / minimal-prompt validation (2026-06-19)

Two further presentation-only tweaks (spec §14 follow-on): (1) *What it means for you* shows a line
only for categories with content, folding every empty category into one `✅ otherwise clear` line
(was: a line per empty category); (2) *What changed* attributes each entry to author(s) + commit count.

Validated on a **real repo** (`/home/nox/Documents/Projects/Nox/wunderkit`, not the fixture) via a
**minimal, skill-unaware prompt** — literally "I'm picking work back up in <repo>. Catch me up on the
latest." with no skill mention, no base/branch/format guidance (only a read-only safety boundary):

- **Auto-invocation confirmed.** The agent self-routed via `superpowers:using-superpowers` (global
  CLAUDE.md, inherited by subagents) → dispatched `project-catchup` with no explicit instruction to.
- **New format rendered correctly.** *What changed* entries attributed ("Christian Ziegler, ~7 commits";
  "andre-locomind, ~3 commits"). *What it means for you* showed only 🔑 optional (env var, defaults
  safely), ⚠ uncommitted-work note (no collision), and one `✅ otherwise clear` line — no per-empty-category
  padding.
- **No regression.** Correct axis (staging, fetched), merge-base base, recognised the dev's branch was
  already merged (F11 avoided), read diffs, systematic action + collision scan, read-only respected
  (only `git fetch`).

This real-repo run doubles as the re-test for the presentation-only refinement; the deterministic fixture
was not separately re-run (the change touches only Phase 5 rendering, and the messier real-repo data is a
stronger exercise of it).
