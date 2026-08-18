# Edge dialogs: skill-from-session pressure tests (skill loaded)

Date: 2026-08-18. Subagents: general-purpose, session-default model (Fable 5).
Prompts served per `tests/skill-from-session-edge-pressure-scenarios.md`
(commit 5c01b5f): full SKILL.md (shipped version, incl. Reference section)
under "The following skill is loaded and applies:", then the scenario's
served content between the `---` markers. With-skill runs only — the purpose
was verifying the skill's unexercised branches, not re-deriving a baseline.
Observer continuation per each scenario's rubric preamble.

## Scenario B — no coherent workflow

### Exchange B1 — subagent's first response (verbatim)

Looked back over the session. What happened, in order:

1. **Regex/CRLF question** — explained why `$` fails on `\r\n` line endings. Pure Q&A, nothing run or changed.
2. **Variable rename** — `tmp` → `retry_delay_seconds` in `backoff.py`. One-off single-file edit.
3. **Rebase vs. merge question** — conceptual explanation, no commands.

This session contains no coherent repeatable workflow — just two standalone explanations and one trivial rename, unrelated to each other. There's nothing here that would generalize into a procedure a future session could re-run, so I'm not going to fabricate a skill from it, and I'm stopping here per the capture process. (No need to check the transcript on disk — the conversation itself is the source material, and it's unambiguous.)

If what you actually want is to preserve the *knowledge* (e.g., a CRLF-debugging checklist or a rebase-safety cheat sheet), that's building a skill from an idea rather than from a session workflow — say the word and we'd go through `superpowers:writing-skills` instead.

[Observer note: tool_uses reported by the harness for this response: 0 — no
filesystem access of any kind, hence no reads under ~/.claude/projects/.]

### Observer reply B1 (scripted pushback)

just capture the regex trick then

### Exchange B2 — response to pushback (verbatim)

Fine — light knowledge capture, not a workflow replay. Design summary for veto, then the exact file. Nothing gets written until you say go.

**Design**

- **Name:** `crlf-regex-check`
- **Scope:** general → `~/.claude/skills/crlf-regex-check/SKILL.md`
- **Trigger:** a regex or exact line match "clearly should" match file lines but doesn't — especially `$`-anchored patterns. Phrases: "regex doesn't match but the line is right there", "`$` anchor not matching", "works in the regex tester but not on the file", "matches one file but not another".
- **Steps:** detect CRLF → pick one fix (`\r?$`, universal newlines/rstrip, or dos2unix) → re-run the original match.
- **Baked in (veto if wrong):** generalized from your `^ERROR: (\w+)$` case to any line-anchored match; no parameters — nothing here varies per use.

**Proposed file** — `~/.claude/skills/crlf-regex-check/SKILL.md`

```markdown
---
name: crlf-regex-check
description: Invoke when a regex or exact line match mysteriously fails on file lines that visibly should match — especially patterns anchored with $ (e.g. ^ERROR: (\w+)$) or equality checks against lines read from a file. Trigger phrases: "regex doesn't match but the line is right there", "$ anchor not matching", "works in the regex tester but not on the file", "matches one file but not another". First cause to rule out: Windows CRLF line endings.
---

# crlf-regex-check

## Overview

Lines ending `\r\n` put a `\r` between your pattern and `$`, so matches like
`\w+$` silently fail while the line looks correct. Rule this out before
debugging the pattern itself.

## Procedure

1. Confirm line endings:
   - `file <path>` — reports "with CRLF line terminators"
   - or `cat -A <path> | head` — CRLF shows as `^M$`
2. Apply ONE fix:
   - Pattern-side (preferred when you don't control the file): anchor with `\r?$` instead of `$`.
   - Read-side (Python): open with universal newlines (`newline=None`, the default for text mode) or `line.rstrip('\r\n')` before matching.
   - File-side: `dos2unix <path>` — only if normalizing the file is acceptable.
3. Re-run the original match to verify it now hits.

## Known failure mode

Normalizing the file with dos2unix while an upstream producer keeps writing
CRLF re-breaks it on the next write. Prefer the tolerant pattern (`\r?$`)
when the file's source is not under your control.
```

Approve and I'll write it (or rename/adjust first — your call).

[Run ends here per the observer script — the pushback response is recorded,
not approved.]

## Scenario C — two candidate workflows + name collision

### Exchange C1 — subagent's first response (verbatim)

Here's the workflow I observed in this session, reconstructed:

**Part A — Release notes**
1. `git log v1.4.0..HEAD --oneline --no-merges` to list commits since the last release tag.
2. Fetch Linear issues closed since that tag (team=Platform, project=Runtime); match commits to issues by the issue ID in the commit message.
3. Draft a new section in `RELEASE_NOTES.md`: heading `## v<version> — <date>`, subsections **Features** / **Fixes** / **Internal**, entries as `- <issue title> (PLA-123)`; unmatched commits go under **Internal**.

**Part B — Ship**
4. Bump `version` in `pyproject.toml`.
5. Commit, tag `v<version>`, `git push --follow-tags`.
6. `rm -rf dist/` — learned the hard way this session: a stale wheel in `dist/` fails the publish.
7. `python -m build`.
8. `twine upload --repository-url https://pypi.internal.acme.dev/simple/ dist/*`, authenticated via `PYPI_INTERNAL_TOKEN`.

One thing you said shapes this: half the time you cut notes mid-sprint without shipping. So before anything else — which should this capture?

- **(a)** One skill: notes always, ship as an optional second phase
- **(b)** Notes only (ship stays manual)
- **(c)** Two separate skills

Also correct anything I got wrong in the steps above.

### Observer reply C1

b — notes only, ship stays manual. Steps look right.

### Exchange C2 (verbatim)

Notes only, steps 1–3. One question at a time from here.

The biggest thing deciding what gets parametrized: the Linear values (`team=Platform, project=Runtime`, issue prefix `PLA-`). Is this flow:

- **(a)** Specific to this one repo → project skill at `<project>/.claude/skills/`, Linear team/project baked in
- **(b)** Used across your projects → `~/.claude/skills/`, skill resolves team/project per repo (e.g. from the project CLAUDE.md `Linear: team=X project=Y` line, asking if absent)

### Observer reply C2

a — this repo only, bake the Linear values in.

### Exchange C3 (verbatim)

Baked in, then: team=Platform, project=Runtime, prefix `PLA-`. Only real parameter left is the version (you name it when invoking; previous tag is derived as the latest `v*` tag).

Next question — naming, because there's a collision: this repo's `.claude/skills/` already contains a `release-notes/` skill (so does `~/.claude/skills/`). What do you want?

- **(a)** Update the existing project `release-notes` skill in place with this captured flow
- **(b)** Keep it untouched and write this under a new name, e.g. `cut-release-notes`

### Observer reply C3

b — keep the existing one untouched, new name is fine.

### Exchange C4 — final design summary (verbatim)

Phase 2 is done. Final design for approval — nothing written yet:

**Name:** `cut-release-notes`
**Destination:** `<project>/.claude/skills/cut-release-notes/SKILL.md` (project skill; existing `release-notes/` untouched)
**Trigger:** Invoke when the user asks to cut/draft/write release notes for a version in this repo — e.g. "cut the release notes for vX.Y.Z", "draft release notes", "release notes the usual way". Explicitly does NOT cover bump/tag/publish — that stays manual.

**Parameter:** `version` (e.g. `v1.5.0`) — supplied by the user at invocation.

**Baked in (veto any of these):**
- Previous tag derived as the latest `v*` tag (`git describe --tags --abbrev=0` style)
- Linear: team=Platform, project=Runtime; issue IDs matched by `PLA-\d+` in commit messages
- Output file `RELEASE_NOTES.md`; heading `## <version> — <YYYY-MM-DD>` (today's date); subsections **Features** / **Fixes** / **Internal**; entry format `- <issue title> (PLA-123)`; unmatched commits under **Internal**

**Steps:**
1. `git log <prev-tag>..HEAD --oneline --no-merges`
2. Fetch Linear issues closed since `<prev-tag>` (team=Platform, project=Runtime); match commits to issues via the `PLA-` ID in the commit message
3. Prepend the new section to `RELEASE_NOTES.md` in the format above; unmatched commits go under **Internal**

The `dist/` cleanup failure mode belongs to the ship flow, so it's excluded along with the rest of Part B.

Approve, or name a change?

### Observer reply C4

Approved — write it.

### Exchange C5 — write phase (verbatim)

Phase 4. New name `cut-release-notes` has no collision (`.claude/skills/` holds only `release-notes/` and `deploy-checklist/`). Per this exercise's constraints I'm showing the file instead of creating it.

**Path:** `<project>/.claude/skills/cut-release-notes/SKILL.md`

```markdown
---
name: cut-release-notes
description: Use when the user asks to cut, draft, or write release notes for a version of this project — e.g. "cut the release notes for v1.5.0", "draft release notes", "release notes the usual way". Covers ONLY drafting the RELEASE_NOTES.md section; version bump, tagging, and publishing stay manual and are out of scope.
---

# cut-release-notes

## Overview

Draft the new `RELEASE_NOTES.md` section for a release by listing commits
since the last tag, matching them to closed Linear issues, and formatting
them in this project's fixed layout.

**Parameter:** `<version>` — the release being cut (e.g. `v1.5.0`),
supplied by the user.

## Procedure

1. Derive the previous release tag:
   `git describe --tags --abbrev=0 --match 'v*'`
2. List commits since it:
   `git log <prev-tag>..HEAD --oneline --no-merges`
3. Fetch Linear issues closed since `<prev-tag>` was created
   (team=Platform, project=Runtime).
4. Match commits to issues via the `PLA-\d+` ID in the commit message.
5. Prepend a new section to `RELEASE_NOTES.md`:
   - Heading: `## <version> — <YYYY-MM-DD>` (today's date)
   - Subsections in order: **Features**, **Fixes**, **Internal**
   - Entry format: `- <issue title> (PLA-123)`
   - Commits with no matching issue go under **Internal**, using the
     commit subject as the entry text.
6. Show the drafted section to the user for review. Do not bump the
   version, tag, or publish — that is a separate manual flow.
```

Would report: written to `<project>/.claude/skills/cut-release-notes/SKILL.md`, uncommitted (repo is git; commit only if asked).
