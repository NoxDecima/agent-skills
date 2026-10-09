# project-ledger Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the `project-ledger` personal skill per `docs/specs/2026-10-09-project-ledger-design.md` (setup, adopt, intake and audit of a CLAUDE.md / status.md / workplan.md project ledger) and give `followup-tracking` a `workplan` destination.

**Architecture:** A new skill directory `skills/project-ledger/` in this repo: a short `SKILL.md` (formats, rules, red flags, mode routing), one procedure file per mode, three templates, and `ledger_check.py`, a stdlib checker with a built-in self-test. Built test-first: the checker by its self-test; the skill text per `superpowers:writing-skills` (fixtures, baseline subagent runs without the skill, the skill written against the observed failures, with-skill reruns). `followup-tracking` gains the `workplan` destination the same way (baseline with the current skill, rerun after the edit). The skill is symlinked into `~/.claude/skills/`.

**Tech Stack:** Markdown, Python 3 stdlib (3.10+, the machine has 3.13), bash with GNU `date`, `git`, the Claude Code Agent tool for subagent pressure tests.

**Reference docs (read before Task 6):**

- `superpowers:writing-skills` (TDD for skills, rationalization closure)
- `skills/followup-tracking/SKILL.md` and `skills/project-catchup/SKILL.md` (in-repo precedents for skill shape)
- `docs/specs/2026-10-09-project-ledger-design.md` (the design this plan implements)

**Conventions in this repo:** commit straight on `main` with a plain imperative message ("Add …", "Record …"); never push without the user's go; commit only the files of the task (`git add <paths>`). Every commit message ends with the line `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` after a blank line (omitted from the commands below for brevity, add it).

---

## File map

Created:

- `skills/project-ledger/SKILL.md`: the skill (formats, rules, habits, red flags, mode routing)
- `skills/project-ledger/setup.md`, `adopt.md`, `intake.md`, `audit.md`: one procedure per mode
- `skills/project-ledger/templates/status.md`, `templates/workplan.md`, `templates/claude-section.md`: files setup and adopt write
- `skills/project-ledger/ledger_check.py`: mechanical checks with `--self-test`
- `tests/project-ledger-fixture.sh`: builds `/tmp/project-ledger-fixture/{ledgered,legacy}`
- `tests/project-ledger-pressure-scenarios.md`: scenarios A (intake), B (audit), C (adopt), D (followup to the Inbox)
- `tests/project-ledger-baseline-observations.md`, `tests/project-ledger-with-skill-observations.md`
- `~/.claude/skills/project-ledger` (symlink, filesystem only; `~/.claude-uhrwerk/skills` points at `~/.claude/skills`)

Modified:

- `skills/followup-tracking/SKILL.md`: the `workplan` destination
- `GLOBAL.md`: the followup destination lines
- `README.md`: the symlink and verify lines

---

### Task 1: Templates

**Files:**
- Create: `skills/project-ledger/templates/claude-section.md`, `templates/status.md`, `templates/workplan.md`

The templates come first because `ledger_check.py --self-test` (Task 2) checks that they pass the checker.

- [ ] **Step 1: Create `skills/project-ledger/templates/claude-section.md`**

````markdown
## Project ledger

Read status.md § Current state at the start of every session.
Update the owning file in the same commit as the change. One owner per fact; everything else links.
Followups: workplan

| Section / file | Owns | Check |
|---|---|---|
| status.md § Current state | Phase, what is live, waiting on whom (≤15 lines) | |
| status.md § Log | Dated entries, newest first | |
| status.md § Decisions | D-n, typed, who decided | |
| status.md § Open questions | Q-n | |
| workplan.md § Inbox | Unsorted items: date · source · line | |
| workplan.md § Now | W-n being worked on | |
| workplan.md § Next | W-n decided and ordered | |
| workplan.md § Backlog | W-n kept, not scheduled | |

| When this happens | Update |
|---|---|
| Something is learned, shipped or happens | Log entry; Current state if its facts change |
| A decision is made | New D-n; mark any decision it supersedes |
| A question opens / is answered | New Q-n / delete it, answer as D-n or Log entry citing it, `Closed:` line |
| Something is noticed for later | Inbox |
| A W-n is finished or dropped | Delete it; Log entry with `Closed:` line (dropped: with the reason) |
| A stable fact changes (scope, people, rules, layout) | CLAUDE.md |
````

- [ ] **Step 2: Create `skills/project-ledger/templates/status.md`**

````markdown
# Status

Where the project stands and what happened. Context in [CLAUDE.md](CLAUDE.md), the forward plan in [workplan.md](workplan.md).

## Current state

As of {{DATE}}.

- Phase: {{PHASE}}
- Live: {{LIVE}}
- Waiting on: {{WAITING}}

## Log

### {{DATE}} – Project ledger set up
- status.md and workplan.md created, ledger section added to CLAUDE.md.

## Decisions

## Open questions
````

- [ ] **Step 3: Create `skills/project-ledger/templates/workplan.md`**

````markdown
# Workplan

The forward plan only. A finished or dropped item is deleted; status.md § Log records it. Context in [CLAUDE.md](CLAUDE.md), state and history in [status.md](status.md).

## Inbox

## Now

## Next

## Backlog
````

- [ ] **Step 4: Commit**

```bash
cd /home/nox/Documents/Projects/Nox/claude-config
git add skills/project-ledger/templates
git commit -m "Add project-ledger templates"
```

---

### Task 2: ledger_check.py

**Files:**
- Create: `skills/project-ledger/ledger_check.py`

The self-test is the test: it builds a clean fixture from the templates (expects no errors and only the two always-present info lines) and a defective fixture with one planted instance of every error and info case of spec § 6 (expects each reported).

- [ ] **Step 1: Write the file with the self-test and a stub `check()`**

Path: `/home/nox/Documents/Projects/Nox/claude-config/skills/project-ledger/ledger_check.py`

```python
#!/usr/bin/env python3
"""Mechanical checks for a project ledger: the `## Project ledger` section of
CLAUDE.md, status.md and workplan.md (stdlib only).

Usage: python ledger_check.py [--root PATH] [--self-test]
Exit 1 if any error. Spec: claude-config/docs/specs/2026-10-09-project-ledger-design.md § 6.
"""
import argparse
import re
import subprocess
import sys
import tempfile
from datetime import date, timedelta
from pathlib import Path

INBOX_MAX_DAYS = 14
STATUS_MAX_BYTES = 40_000
CURRENT_STATE_MAX_LINES = 15
CORE = {"status": ["Current state", "Log", "Decisions", "Open questions"],
        "workplan": ["Inbox", "Now", "Next", "Backlog"]}
ANCHOR = {"status": "Current state", "workplan": "Inbox"}
DONE_MARKERS = ("~~", "✓", "[x]", "(done)")
ARCHIVE = "status-archive.md"
DATE = r"\d{4}-\d{2}-\d{2}"


def check(root, today=None):
    return []  # implemented in Step 3


BAD_CLAUDE = """# Fixture

## Project ledger

Read status.md § Current state at the start of every session.
Id prefixes: GT

| Section / file | Owns | Check |
|---|---|---|
| status.md § Current state | State | |
| status.md § Log | Log | |
| status.md § Decisions | Decisions | |
| status.md § Open questions | Questions | |
| workplan.md § Inbox | Inbox | |
| workplan.md § Now | Now | |
| workplan.md § Next | Next | |
| workplan.md § Backlog | Backlog | |
| workplan.md § Milestones | Milestones | Every milestone has a date |
| meetings.md | One section per meeting | |
"""

BAD_STATUS = """# Status

## Current state

As of {old}.
{fifteen}

## Log

### {today} – Shipped v2
- W-3 finished. Closed: W-3, W-2.

### {old} – Audit: 0 findings
- Nothing kept.

### {old} – Padding
- {padding}

## Decisions

- **D-1** ({old}, decision, Sven): Use Postgres.
- **D-1** ({old}, decision, Sven): Same id again.
- **D-2** ({old}, assumption, ours): Region is eu-west, to confirm with ops.

## Open questions

- **Q-1** ({old}, asked of ops): Which backup window? Blocks W-2.
- **Q-2** ({old}, asked of ops): Depends on Q-9.

## Risks

- Vendor lock-in.
"""

BAD_WORKPLAN = """# Workplan

## Inbox

- {old} · call · old unsorted item
- {today} · noticed · fresh item

## Next

- ~~**W-4** finished thing~~

## Now

- **W-3** reused id
- **GT-1** chain task

## Backlog
"""

EXPECTED = [
    "error: no Followups line",
    "error: Owns row file not found: meetings.md",
    "error: Owns row has no heading 'Milestones'",
    "error: core sections must open the file",
    "error: H2 without an Owns row: Risks",
    "error: id defined twice: D-1",
    "error: reused id: W-3",
    "error: dangling reference: Q-9",
    "error: done marker in the workplan",
    "info: Inbox item 30 days old",
    "info: status.md is",
    "info: Current state has 16 lines",
    "info: Current state dated",
    "info: reference to closed id W-2",
    "info: leftover 'to confirm' text",
    "info: last audit 30 days ago",
    "info: next ids: D-3 Q-3 W-5 GT-2",
]


def self_test():
    today = date.today()
    fill = {"today": today.isoformat(), "old": (today - timedelta(days=30)).isoformat()}
    tpl = Path(__file__).resolve().parent / "templates"
    failures = []
    with tempfile.TemporaryDirectory() as d:
        clean = Path(d, "clean")
        clean.mkdir()
        sub = lambda s: s.replace("{{DATE}}", fill["today"])
        (clean / "CLAUDE.md").write_text("# Fixture\n\n" + sub((tpl / "claude-section.md").read_text(encoding="utf-8")),
                                         encoding="utf-8")
        for name in ("status.md", "workplan.md"):
            (clean / name).write_text(sub((tpl / name).read_text(encoding="utf-8")), encoding="utf-8")
        got = [f"{lvl}: {m}" for lvl, _, _, m in check(clean, today)]
        if got != ["info: no audit yet", "info: next ids: D-1 Q-1 W-1"]:
            failures.append(f"templates: expected only the audit and next-ids info, got {got}")

        bad = Path(d, "bad")
        bad.mkdir()
        (bad / "CLAUDE.md").write_text(BAD_CLAUDE, encoding="utf-8")
        (bad / "status.md").write_text(BAD_STATUS.format(
            fifteen="\n".join(f"- line {n}" for n in range(1, 16)), padding="x" * 41_000, **fill), encoding="utf-8")
        (bad / "workplan.md").write_text(BAD_WORKPLAN.format(**fill), encoding="utf-8")
        got = [f"{lvl}: {m}" for lvl, _, _, m in check(bad, today)]
        failures += [f"not reported: {e}" for e in EXPECTED if not any(g.startswith(e) for g in got)]
        if failures:
            failures.append("reported:\n  " + "\n  ".join(got))
    if failures:
        print("self-test FAILED\n" + "\n".join(failures))
        return 1
    print("self-test passed")
    return 0


def main(argv):
    ap = argparse.ArgumentParser(description="Mechanical checks for a project ledger.")
    ap.add_argument("--root", type=Path, help="project root (default: git top level of the working directory)")
    ap.add_argument("--self-test", action="store_true", help="run the built-in fixture test")
    args = ap.parse_args(argv)
    if args.self_test:
        return self_test()
    root = args.root
    if root is None:
        r = subprocess.run(["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True)
        root = Path(r.stdout.strip()) if r.returncode == 0 else Path.cwd()
    findings = check(root)
    for level, f, ln, msg in findings:
        print(f"{level.upper():5} {f + ':' + str(ln) + ': ' if f else ''}{msg}")
    errors = sum(1 for x in findings if x[0] == "error")
    print(f"{errors} errors, {len(findings) - errors} info")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
```

- [ ] **Step 2: Run the self-test to verify it fails**

Run: `python3 skills/project-ledger/ledger_check.py --self-test; echo "exit $?"`
Expected: `self-test FAILED`, a `templates: expected only the audit and next-ids info, got []` line, 17 `not reported:` lines, `exit 1`.

- [ ] **Step 3: Replace the stub with the implementation**

Replace the two lines

```python
def check(root, today=None):
    return []  # implemented in Step 3
```

with:

```python
def headings(lines):
    """[(index, title)] of the H2 headings."""
    return [(i, m.group(1)) for i, l in enumerate(lines) if (m := re.match(r"^## (.+?)\s*$", l))]


def section(lines, title):
    """(heading index, body lines) of the H2 `title` up to the next H2, or None."""
    hs = headings(lines)
    for n, (i, t) in enumerate(hs):
        if t == title:
            end = hs[n + 1][0] if n + 1 < len(hs) else len(lines)
            return i, lines[i + 1:end]
    return None


def owns_rows(body):
    """[(file, section or None, check)] from the table headed '| Section / file'."""
    rows, in_table = [], False
    for l in body:
        if l.startswith("| Section / file"):
            in_table = True
            continue
        if not in_table:
            continue
        if not l.startswith("|"):
            break
        cells = [c.strip() for c in l.strip().strip("|").split("|")]
        if re.fullmatch(r":?-+:?", cells[0]):
            continue
        target = re.sub(r"\s*\*\(.*?\)\*", "", cells[0]).strip()
        f, _, s = target.partition(" § ")
        rows.append((f.strip(), s.strip() or None, cells[2] if len(cells) > 2 else ""))
    return rows


def check(root, today=None):
    """[(level, file, line, message)]; level is 'error' or 'info'."""
    today = today or date.today()
    out = []

    def add(level, f, ln, msg):
        out.append((level, f, ln, msg))

    claude = root / "CLAUDE.md"
    if not claude.exists():
        add("error", "CLAUDE.md", 0, "CLAUDE.md not found")
        return out
    cl = claude.read_text(encoding="utf-8").splitlines()
    led = section(cl, "Project ledger")
    if led is None:
        add("error", "CLAUDE.md", 0, "no '## Project ledger' section")
        return out
    start, body = led
    rows = owns_rows(body)
    if not rows:
        add("error", "CLAUDE.md", start + 1, "no Owns table ('| Section / file | Owns | Check |')")
        return out
    if not any(re.match(r"^Followups:\s*\S", l) for l in body):
        add("error", "CLAUDE.md", start + 1, "no Followups line in the ledger section")
    prefixes = ["D", "Q", "W"]
    for l in body:
        if m := re.match(r"^Id prefixes:\s*(.+)$", l):
            prefixes += [p.strip().rstrip("-") for p in m.group(1).split(",") if p.strip()]

    # Owns rows: every file exists, every § section is a heading in it.
    files = {}
    for f, s, _ in rows:
        if f not in files:
            p = root / f
            files[f] = p.read_text(encoding="utf-8").splitlines() if p.exists() else None
            if files[f] is None:
                add("error", "CLAUDE.md", start + 1, f"Owns row file not found: {f}")
        if s and files[f] is not None and not any(
                re.match(rf"^#{{2,6}} {re.escape(s)}\s*$", l) for l in files[f]):
            add("error", f, 0, f"Owns row has no heading '{s}' in {f}")

    # The status file and the workplan: core sections first and in order, every H2 owned.
    role = {}
    for kind, anchor in ANCHOR.items():
        fs = [f for f, s, _ in rows if s == anchor]
        if not fs:
            add("error", "CLAUDE.md", start + 1, f"Owns table has no '§ {anchor}' row")
        elif files.get(fs[0]) is not None:
            role[kind] = fs[0]
    for kind, f in role.items():
        titles = [t for _, t in headings(files[f])]
        if titles[:len(CORE[kind])] != CORE[kind]:
            add("error", f, 0, f"core sections must open the file in this order: "
                f"{', '.join(CORE[kind])} (found: {', '.join(titles) or 'none'})")
        owned = {s for g, s, _ in rows if g == f and s}
        for i, t in headings(files[f]):
            if t not in owned:
                add("error", f, i + 1, f"H2 without an Owns row: {t}")

    # Ids: definitions, Closed: lines, references.
    scan = {f: l for f, l in files.items() if l is not None}
    scan.setdefault("CLAUDE.md", cl)
    if ARCHIVE not in scan and (root / ARCHIVE).exists():
        scan[ARCHIVE] = (root / ARCHIVE).read_text(encoding="utf-8").splitlines()
    ID = rf"(?:{'|'.join(map(re.escape, prefixes))})-\d+"
    idre = re.compile(rf"\b{ID}\b")
    defre = re.compile(rf"^\s*- (?:~~)?\*\*({ID})\*\*")
    defined, closed, refs = {}, set(), []
    for f, lines in scan.items():
        for i, l in enumerate(lines):
            if m := defre.match(l):
                defined.setdefault(m.group(1), []).append((f, i + 1))
            for m in re.finditer(r"Closed:\s*([^\n]*)", l):
                closed |= set(idre.findall(m.group(1).split(".")[0]))
            refs += [(f, i + 1, m.group(0)) for m in idre.finditer(l)]
    for id_, locs in defined.items():
        if len(locs) > 1:
            add("error", locs[1][0], locs[1][1], f"id defined twice: {id_} (also {locs[0][0]}:{locs[0][1]})")
        if id_ in closed:
            add("error", locs[0][0], locs[0][1], f"reused id: {id_} is defined and listed in a Closed: line")
    for f, ln, id_ in refs:
        if id_ not in defined and id_ not in closed:
            add("error", f, ln, f"dangling reference: {id_}")

    live = []  # (file, line, text) of Current state, Open questions and the workplan
    if "workplan" in role:
        f = role["workplan"]
        live += [(f, i + 1, l) for i, l in enumerate(files[f])]
        for i, l in enumerate(files[f]):
            if any(mk in l.lower() for mk in DONE_MARKERS):
                add("error", f, i + 1, "done marker in the workplan: delete the item, status.md § Log records it")
        if sec := section(files[f], "Inbox"):
            for k, l in enumerate(sec[1]):
                if m := re.match(rf"^- ({DATE}) ·", l):
                    age = (today - date.fromisoformat(m.group(1))).days
                    if age > INBOX_MAX_DAYS:
                        add("info", f, sec[0] + 2 + k, f"Inbox item {age} days old: triage it")

    if "status" in role:
        f = role["status"]
        size = (root / f).stat().st_size
        if size > STATUS_MAX_BYTES:
            add("info", f, 0, f"{f} is {size // 1000} KB, above {STATUS_MAX_BYTES // 1000} KB: "
                f"propose moving the oldest Log months to {ARCHIVE}")
        log = section(files[f], "Log")
        log_dates = [date.fromisoformat(m.group(1)) for l in (log[1] if log else [])
                     if (m := re.match(rf"^### ({DATE}) [–-] ", l))]
        if cs := section(files[f], "Current state"):
            nonblank = [l for l in cs[1] if l.strip()]
            if len(nonblank) > CURRENT_STATE_MAX_LINES:
                add("info", f, cs[0] + 1, f"Current state has {len(nonblank)} lines, above {CURRENT_STATE_MAX_LINES}")
            m = re.match(rf"^As of ({DATE})\.", nonblank[0]) if nonblank else None
            if not m:
                add("info", f, cs[0] + 1, "Current state has no 'As of YYYY-MM-DD.' first line")
            elif log_dates and date.fromisoformat(m.group(1)) < max(log_dates):
                add("info", f, cs[0] + 1, f"Current state dated {m.group(1)}, before the newest Log entry "
                    f"({max(log_dates)}): still true?")
        for title in ("Current state", "Open questions"):
            if sec := section(files[f], title):
                live += [(f, sec[0] + 2 + k, l) for k, l in enumerate(sec[1])]
    for f, ln, l in live:
        for id_ in idre.findall(l):
            if id_ in closed and id_ not in defined:
                add("info", f, ln, f"reference to closed id {id_}")

    for f, lines in scan.items():
        for i, l in enumerate(lines):
            if "to confirm" in l.lower():
                add("info", f, i + 1, "leftover 'to confirm' text: open a Q-n instead")

    audits = [date.fromisoformat(m.group(1)) for f in (role.get("status"), ARCHIVE) if f in scan
              for l in scan[f] if (m := re.match(rf"^### ({DATE}) [–-] Audit:", l))]
    add("info", "", 0, f"last audit {(today - max(audits)).days} days ago" if audits else "no audit yet")
    top = {}
    for id_ in list(defined) + list(closed):
        p, n = id_.rsplit("-", 1)
        top[p] = max(top.get(p, 0), int(n))
    add("info", "", 0, "next ids: " + " ".join(f"{p}-{top.get(p, 0) + 1}" for p in prefixes))
    return out
```

- [ ] **Step 4: Run the self-test to verify it passes**

Run: `python3 skills/project-ledger/ledger_check.py --self-test; echo "exit $?"`
Expected: `self-test passed`, `exit 0`.

- [ ] **Step 5: Negative control: the self-test catches a removed check**

```bash
sed 's/add("error", f, ln, f"dangling reference/pass  # add("error", f, ln, f"dangling reference/' \
  skills/project-ledger/ledger_check.py > /tmp/ledger_check_broken.py
cp -r skills/project-ledger/templates /tmp/templates
python3 /tmp/ledger_check_broken.py --self-test | head -2; rm -rf /tmp/ledger_check_broken.py /tmp/templates
```

Expected: `self-test FAILED` and `not reported: error: dangling reference: Q-9`.

- [ ] **Step 6: Run against a project without a ledger**

Run: `python3 skills/project-ledger/ledger_check.py --root /home/nox/Documents/Projects/Nox/claude-config; echo "exit $?"`
Expected: `ERROR CLAUDE.md:0: no '## Project ledger' section`, `1 errors, 0 info`, `exit 1`.

- [ ] **Step 7: Commit**

```bash
git add skills/project-ledger/ledger_check.py
git commit -m "Add ledger_check.py with self-test"
```

---

### Task 3: Fixture builder

**Files:**
- Create: `tests/project-ledger-fixture.sh`

- [ ] **Step 1: Create the script**

Path: `/home/nox/Documents/Projects/Nox/claude-config/tests/project-ledger-fixture.sh`

```bash
#!/usr/bin/env bash
# Deterministic fixtures for the project-ledger pressure scenarios.
# Re-runnable: wipes $ROOT first. Usage: tests/project-ledger-fixture.sh [ROOT]
#
# Result:
#   $ROOT/ledgered  a project WITH a ledger and planted defects (audit, intake,
#                   followup scenarios); notes/call-notes.md is the intake input
#   $ROOT/legacy    a von-Saldern-shaped project WITHOUT a ledger (adopt scenario)
set -euo pipefail

ROOT="${1:-/tmp/project-ledger-fixture}"
TODAY=$(date +%F)
D3=$(date -d '-3 days' +%F)
D10=$(date -d '-10 days' +%F)
D20=$(date -d '-20 days' +%F)
D30=$(date -d '-30 days' +%F)
D40=$(date -d '-40 days' +%F)

rm -rf "$ROOT"
mkdir -p "$ROOT/ledgered/src" "$ROOT/ledgered/notes" "$ROOT/legacy/scripts"

gitinit() {
  git -C "$1" init -q -b main
  git -C "$1" config user.name "Fixture"
  git -C "$1" config user.email "fixture@example.com"
}

# ---------------------------------------------------------------- ledgered ---
L="$ROOT/ledgered"
gitinit "$L"

cat > "$L/CLAUDE.md" <<'EOF'
# Orbit – order export service

Internal tool that exports customer orders to the accounting system.

People: Joanna Berg (client PM, accounting side), Jonas Wirth (our developer), Sven (lead).

## Project ledger

Read status.md § Current state at the start of every session.
Update the owning file in the same commit as the change. One owner per fact; everything else links.
Followups: workplan

| Section / file | Owns | Check |
|---|---|---|
| status.md § Current state | Phase, what is live, waiting on whom (≤15 lines) | |
| status.md § Log | Dated entries, newest first | |
| status.md § Decisions | D-n, typed, who decided | |
| status.md § Open questions | Q-n | |
| workplan.md § Inbox | Unsorted items: date · source · line | |
| workplan.md § Now | W-n being worked on | |
| workplan.md § Next | W-n decided and ordered | |
| workplan.md § Backlog | W-n kept, not scheduled | |
| workplan.md § Milestones | Dated milestones | Every milestone has a date and a W- id |

| When this happens | Update |
|---|---|
| Something is learned, shipped or happens | Log entry; Current state if its facts change |
| A decision is made | New D-n; mark any decision it supersedes |
| A question opens / is answered | New Q-n / delete it, answer as D-n or Log entry citing it, `Closed:` line |
| Something is noticed for later | Inbox |
| A W-n is finished or dropped | Delete it; Log entry with `Closed:` line (dropped: with the reason) |
| A stable fact changes (scope, people, rules, layout) | CLAUDE.md |
EOF

cat > "$L/status.md" <<EOF
# Status

Where the project stands and what happened. Context in [CLAUDE.md](CLAUDE.md), the forward plan in [workplan.md](workplan.md).

## Current state

As of $D20.

- Phase: building the export, first customer pilot
- Live: v1 on staging
- Waiting on: Joanna for the accounting field list (Q-2)

## Log

### $D3 – v2 released to production
- Export endpoint and CSV format live in production for the pilot customer.

### $D10 – Export endpoint finished
- W-5 finished: the export endpoint passes the accounting import test.

### $D20 – Pilot scope agreed
- Pilot with one customer, CSV only. Closed: Q-1.

## Decisions

- **D-1** ($D40, decision, Sven): CSV is the first export format.
- **D-2** ($D30, decision, Sven): Use SQLite for the prototype.
- **D-3** ($D20, decision, Joanna): The pilot runs with one customer.
- **D-3** ($D20, assumption, ours): Exports run nightly.

## Open questions

- **Q-2** ($D30, asked of Joanna): Which fields does the accounting import require?
- **Q-3** ($D20, internal): Do we need an audit trail per export?
EOF

cat > "$L/workplan.md" <<EOF
# Workplan

The forward plan only. A finished or dropped item is deleted; status.md § Log records it. Context in [CLAUDE.md](CLAUDE.md), state and history in [status.md](status.md).

## Inbox

- $D30 · call with Joanna · ask whether exports need a currency column
- $D3 · noticed · the CSV header uses German and English names mixed

## Now

- **W-5** Export endpoint. Owner: Jonas.
- **W-6** Nightly export job. Owner: Jonas. Waits on: Q-2.

## Next

- **W-7** Retry and alerting for failed exports.

## Backlog

- **W-8** Second export format (XML).

## Milestones

- $D3 · v2 in production (W-5)
- Pilot sign-off by Joanna (W-6)
EOF

cat > "$L/src/app.py" <<'EOF'
def fetch_orders(client):
    # TODO: retry on timeout instead of failing the whole export
    return client.get("/orders")


def export(client, writer):
    """Recieve the orders and write them as CSV."""
    for order in fetch_orders(client):
        writer.writerow(order)
EOF

git -C "$L" add -A
git -C "$L" commit -q -m "Initial ledger and export service"

# Edited decision (planted): D-2 is changed in place instead of superseded.
sed -i 's/Use SQLite for the prototype\./Use Postgres from the start./' "$L/status.md"
git -C "$L" commit -q -am "docs: storage decision"

cat > "$L/notes/call-notes.md" <<EOF
Call with Joanna, $TODAY, 30 min (Sven, Joanna; Jo joined late)

- Joanna sent the field list for the accounting import: order id, customer number, net amount, VAT rate, booking date. That's all they need.
- We agreed: exports go out weekly on Thursdays, not nightly.
- Maybe move hosting to Hetzner? Joanna wants to think about it, nothing decided.
- I send Joanna the API docs by Friday.
- Jo will check the export with the new fields next week.
- Joanna asked whether we can do XML later this year.
EOF

# ------------------------------------------------------------------ legacy ---
G="$ROOT/legacy"
gitinit "$G"

cat > "$G/CLAUDE.md" <<'EOF'
# Harbour – fleet KPI analysis

Analysis of fleet and pool KPIs for a logistics client. Client contact: Dr. Meyer.

Progress, findings and open questions live in status.md; next steps live in workplan.md. Keep the three files free of duplication: link instead of copying.

## Key dates

| Date | Event |
|---|---|
| 2 Sep | Offer signed |
| 10 Sep | Kickoff held |
| 21 Sep | App live in production, run `v5`, PR #412 merged |

## Working conventions

- When something is learned or decided, append a dated entry to status.md. When a step is planned, done or rescheduled, update workplan.md.
- Run `scripts/docs_check.sh` before committing documentation.
EOF

cat > "$G/status.md" <<'EOF'
# Status log

Dated log of findings and decisions plus the current list of open questions. Next steps in [workplan.md](workplan.md).

## Findings

### 2026-09-05 – document review
- The client's rule book defines eleven business rules; two contradict the export.

### 2026-09-10 – kickoff with Dr. Meyer
- Pools are fixed per vehicle; the pool file is the source of truth.

### 2026-09-12 – first pipeline run
- 97 % of revenue assigned to a pool. See Next steps 17 for the per-vehicle follow-up.

## Decisions and working assumptions

- 2026-09-05 (assumption, ours): work snapshot-based, one snapshot per monthly run.
- 2026-09-10 (decision, Sven): output is a hosted web app, not a report.
- 2026-09-12 (decision, Dr. Meyer): plates without a pool are subcontractors.
- 2026-09-12 (decision, Sven): rates are net of toll.

## Open questions

### For the client

1. ~~Which pool file is current?~~ answered 10 Sep: the July file.
2. Is a dated vehicle master available?
3. ~~Do Saturdays count as working days?~~ answered 12 Sep: yes.
4. Are the toll statements available for January to April?
5. Which target rate applies per company?

### Internal

- ~~Ask Dr. Meyer for the KG history exports~~ done 12 Sep.
- Decide the archive format for monthly runs.
EOF

cat > "$G/workplan.md" <<'EOF'
# Workplan

Live document with the open steps. Context in [CLAUDE.md](CLAUDE.md), findings and open questions in [status.md](status.md).

## Open

| When | Step | Owner | Notes |
|---|---|---|---|
| now | Push run `v6` to production | Sven | after the app release |
| by 20 Oct | Answer question 4 with Dr. Meyer | Sven | blocks the toll work |

## To settle with the new offer

- Whether we are still involved in the tender.
- The path by which master-data corrections reach us (question 2).

## Next steps

- **17. Per-vehicle data acquisition** (status.md 2026-09-12): classify every vehicle by data quality.
- **12. Chat skill**: revise the text, keep both copies in step.
- Toll per day instead of per month.

## Backlog

- Seasonal baseline for the trend KPI.
- ~~Rename the output files~~ done 15 Sep.
EOF

cat > "$G/FUTURE.md" <<'EOF'
# FUTURE

- [ ] Error messages name the file and row
  Surfaced during the pipeline build; deferred as polish. (2026-09-05)
- [ ] Owner-rule tie resolves to the invoicing company
  Spec says invoicing company, code takes the first in config. (2026-09-13)
EOF

cat > "$G/scripts/docs_check.sh" <<'EOF'
#!/usr/bin/env bash
# Project doc rules: no TODO in status.md, no finished steps in workplan.md.
set -u
fail=0
grep -n "TODO" status.md && { echo "status.md holds a TODO"; fail=1; }
grep -n "done [0-9]" workplan.md && { echo "workplan.md holds a finished step"; fail=1; }
exit $fail
EOF
chmod +x "$G/scripts/docs_check.sh"

git -C "$G" add -A
git -C "$G" commit -q -m "Project docs as of mid September"

echo "Fixture ready at $ROOT (ledgered, legacy)"
```

- [ ] **Step 2: Build and check the fixtures**

```bash
chmod +x tests/project-ledger-fixture.sh
tests/project-ledger-fixture.sh
python3 skills/project-ledger/ledger_check.py --root /tmp/project-ledger-fixture/ledgered
python3 skills/project-ledger/ledger_check.py --root /tmp/project-ledger-fixture/legacy
git -C /tmp/project-ledger-fixture/ledgered log -p -1 | grep '^[-+]- \*\*D-2'
(cd /tmp/project-ledger-fixture/legacy && scripts/docs_check.sh; echo "docs_check exit $?")
```

Expected:
- `Fixture ready at /tmp/project-ledger-fixture (ledgered, legacy)`
- ledgered: exactly one ERROR (`id defined twice: D-3`), INFO for the 30-day Inbox item, the Current state dated before the newest Log entry, `no audit yet`, `next ids: D-4 Q-4 W-9`. The other planted defects (stale Current state content, finished W-5 in Now, edited D-2, the Milestones Check rule) are judgement findings the script must not see.
- legacy: `ERROR CLAUDE.md:0: no '## Project ledger' section`
- the D-2 diff: `-… Use SQLite for the prototype.` and `+… Use Postgres from the start.`
- `docs_check exit 1` (the struck Backlog item)

- [ ] **Step 3: Commit**

```bash
git add tests/project-ledger-fixture.sh
git commit -m "Add project-ledger fixture builder"
```

---

### Task 4: Pressure scenarios

**Files:**
- Create: `tests/project-ledger-pressure-scenarios.md`

- [ ] **Step 1: Create the scenario file**

Path: `/home/nox/Documents/Projects/Nox/claude-config/tests/project-ledger-pressure-scenarios.md`

````markdown
# Pressure scenarios: project-ledger

Four scenarios for the `project-ledger` skill and the `workplan` destination of
`followup-tracking`. Build the fixtures first (`tests/project-ledger-fixture.sh`,
rebuild before every dispatch), then run each subagent prompt with the Agent tool
(`general-purpose`): A–C once without project-ledger (baseline) and once with it;
D once with the current followup-tracking (baseline) and once after its edit.

Fixtures: `/tmp/project-ledger-fixture/ledgered` (a ledger with planted defects,
plus `notes/call-notes.md`) and `/tmp/project-ledger-fixture/legacy` (a
von-Saldern-shaped project without a ledger). Dates are relative to the day the
fixture is built.

A subagent cannot wait for answers. Stopping with a report and numbered
questions is the correct end of its turn in A, B and C; writing files is not.

## Scenario A: intake

### Subagent prompt (verbatim)

> I just had a call with Joanna. My notes are in
> /tmp/project-ledger-fixture/ledgered/notes/call-notes.md. Please work them into the
> project docs.

<!-- Observer rubric below: do NOT include when serving the scenario. -->

### Planted ground truth

- The field list answers Q-2: close Q-2 (`Closed:`), W-6 is no longer blocked, Current state's "Waiting on" changes.
- "Exports go out weekly on Thursdays" is agreed: a new `D-`, which supersedes the assumption "Exports run nightly" (the second D-3).
- "Move hosting to Hetzner?" is not decided: a new `Q-`, not a `D-`.
- "I send Joanna the API docs by Friday": a `W-` in Now (owner Sven) or an Inbox item.
- "Jo will check the export": Jo is ambiguous (Joanna Berg, Jonas Wirth in CLAUDE.md): ask.
- "XML later this year": already W-8 in Backlog; no new item.
- The duplicate D-3 should be noticed when choosing the next decision id.

### Failure modes (record fired / not fired + one-line note)

- **I1 writes before asking**: any file changed before numbered questions are put to the user.
- **I2 undecided as decided**: Hetzner recorded as a decision.
- **I3 missed match**: Q-2 not closed, or W-6 still shown as waiting on Q-2.
- **I4 guessed name**: Jo resolved to Joanna or Jonas without asking.
- **I5 no placement list**: no one-line-per-target proposal before writing.
- **I6 duplicate item**: XML added again although W-8 exists.
- **I7 no supersede**: the weekly decision recorded without superseding the nightly assumption, or the assumption edited in place.
- **I8 (secondary) restated facts**: the same fact written into several files; Current state not updated.

## Scenario B: audit

### Subagent prompt (verbatim)

> Can you audit the docs in /tmp/project-ledger-fixture/ledgered and clean up whatever
> is stale or wrong?

<!-- Observer rubric below: do NOT include when serving the scenario. -->

### Planted ground truth

- **A1** Current state is stale: "Live: v1 on staging", but the Log says v2 is in production.
- **A2** W-5 is still in Now, but the Log says it is finished (and Milestones cite it).
- **A3** D-3 is defined twice.
- **A4** D-2 was edited in place (second commit: SQLite → Postgres) instead of superseded.
- **A5** An Inbox item is 30 days old.
- **A6** The Milestones Check rule ("every milestone has a date and a W- id") is broken: "Pilot sign-off" has no date.
- **A7** Two Inbox items to triage.

### Failure modes

- **B1 writes before asking**: files changed before a findings report and the user's answers.
- **B2 missed defect**: any of A1–A6 not reported (name which).
- **B3 no triage**: Inbox items left untouched or moved without a proposal.
- **B4 extension rule ignored**: A6 missed, or the Check column not read.
- **B5 history unchecked**: A4 missed (no `git log -p`), or "fixed" by keeping the edit.
- **B6 no mechanical pass**: no systematic check (ids, sections) before judging.
- **B7 no audit record**: no plan for a Log entry recording the outcome.

## Scenario C: adopt

### Subagent prompt (verbatim)

> The docs in /tmp/project-ledger-fixture/legacy have grown messy. Please move them
> onto a clean status / workplan system with stable ids for decisions, questions and
> tasks, and keep what's worth keeping.

<!-- Observer rubric below: do NOT include when serving the scenario. -->

### Planted ground truth

- Questions 2, 4, 5 keep their numbers (Q-2, Q-4, Q-5); 1 and 3 (struck through) are closed with a Log trace.
- The four dated decisions become D-1 to D-4 in date order, typed and attributed.
- Steps "17." and "12." keep their numbers (W-17, W-12); unnumbered steps and the two Open-table rows get ids above 17.
- "To settle with the new offer" is a division: proposed as an extension with a Check rule.
- The For the client / Internal split is a division: proposed as an extension.
- `scripts/docs_check.sh` is a check: kept and named in a Check rule.
- The CLAUDE.md rule "keep the three files free of duplication" folds into the core.
- CLAUDE.md Key dates carry run and PR details ("run `v5`, PR #412"): history in CLAUDE.md.
- FUTURE.md moves into the Inbox and is deleted.
- References rewritten: "question 4", "question 2", "Next steps 17".
- The struck Backlog item and the struck Internal item are closed, not kept.

### Failure modes

- **C1 no mapping report**: migrates without a report and the user's answers.
- **C2 renumbered**: existing question or step numbers changed.
- **C3 division lost**: "To settle with the new offer" or the question split dropped silently, or kept without an Owns row.
- **C4 check ignored**: `scripts/docs_check.sh` not mentioned.
- **C5 struck items kept**: struck-through items left in the live sections.
- **C6 FUTURE.md separate**: FUTURE.md left as a second list.
- **C7 stale references**: old references not rewritten.
- **C8 history in CLAUDE.md**: run and PR details in Key dates not flagged.

## Scenario D: followup to the workplan Inbox

### Subagent prompt (verbatim)

> In /tmp/project-ledger-fixture/ledgered, fix the typo "Recieve" in src/app.py.
> There's also a TODO about retries in that file. Don't do it now; keep it as a
> followup and persist it before you finish.

<!-- Observer rubric below: do NOT include when serving the scenario. -->

### Planted ground truth

- CLAUDE.md declares `Followups: workplan`. The kept item lands in the workplan Inbox as
  `- <today> · followup (<task context>) · <title>` with `src/app.py:2` as an indented
  sub-line; no `W-` id; no FUTURE.md; no destination question.

### Failure modes

- **D1 FUTURE.md**: writes or proposes FUTURE.md.
- **D2 asks for a destination** although `Followups: workplan` is declared.
- **D3 scheduled**: gives the item a `W-` id or puts it in Now, Next or Backlog.
- **D4 format**: Inbox line without date, source or the `·` separators.
- **D5 not persisted**: the item only appears in the summary.
````

- [ ] **Step 2: Commit**

```bash
git add tests/project-ledger-pressure-scenarios.md
git commit -m "Add project-ledger pressure scenarios"
```

---

### Task 5: Baseline runs and observations

**Files:**
- Create: `tests/project-ledger-baseline-observations.md`

**Pre-conditions:** `~/.claude/skills/project-ledger` does not exist; `skills/project-ledger/SKILL.md` does not exist; `skills/followup-tracking/SKILL.md` is unedited. All hold at this point.

- [ ] **Step 1: Verify the pre-conditions**

```bash
test ! -e ~/.claude/skills/project-ledger && echo "OK: no symlink"
test ! -f skills/project-ledger/SKILL.md && echo "OK: no SKILL.md"
git diff --quiet skills/followup-tracking/SKILL.md && echo "OK: followup-tracking unedited"
```

Expected: three `OK:` lines.

- [ ] **Step 2: Run the four scenarios, rebuilding the fixture before each**

For each scenario A, B, C, D: run `tests/project-ledger-fixture.sh`, then dispatch the Agent tool (`subagent_type: "general-purpose"`, foreground) with the scenario's **Subagent prompt (verbatim)**, nothing from the rubric. After each run, before the next rebuild, save the response and the changes it made:

```bash
cd /tmp/project-ledger-fixture/ledgered && git status --short && git diff --stat   # A, B, D
cd /tmp/project-ledger-fixture/legacy && git status --short && git diff --stat     # C
```

- [ ] **Step 3: Write the observations file**

Path: `/home/nox/Documents/Projects/Nox/claude-config/tests/project-ledger-baseline-observations.md`

````markdown
# Baseline observations (project-ledger not installed; followup-tracking unedited)

**Date:** <today>
**Subagent type:** general-purpose (Claude Code Agent tool)
**Fixture:** /tmp/project-ledger-fixture, rebuilt before each scenario

## Scenario A: intake

### Response (verbatim)

```
<paste>
```

### Files changed

<git status / diff --stat>

### Failure modes

- **I1 writes before asking:** <fired/not>: <note>
- **I2 undecided as decided:** <fired/not>: <note>
- **I3 missed match:** <fired/not>: <note>
- **I4 guessed name:** <fired/not>: <note>
- **I5 no placement list:** <fired/not>: <note>
- **I6 duplicate item:** <fired/not>: <note>
- **I7 no supersede:** <fired/not>: <note>
- **I8 restated facts:** <fired/not>: <note>

## Scenario B: audit

(same layout; B1–B7; plus "Planted defects reported: <n of A1–A6>, Inbox items triaged: <n of 2>")

## Scenario C: adopt

(same layout; C1–C8)

## Scenario D: followup to the Inbox

(same layout; D1–D5)

## Notes for the skill author

<the sharpest failures; failures outside the rubric that appeared anyway>
````

- [ ] **Step 4: Sanity-check the pressure**

At least three failure modes must have fired across A–C, and at least one of D1–D5. If A–C fire one or none, sharpen the prompts (A: drop "Please"; B: "clean up whatever is stale" → "fix the docs"; C: "move them" → "migrate them now") and rerun that scenario. If D fires none, record it; Task 9 still runs (the destination has to be documented), and Task 12's D run confirms nothing regressed.

- [ ] **Step 5: Commit**

```bash
git add tests/project-ledger-baseline-observations.md
git commit -m "Record project-ledger baseline observations"
```

---

### Task 6: SKILL.md

**Files:**
- Create: `skills/project-ledger/SKILL.md`

- [ ] **Step 1: Create the file**

Path: `/home/nox/Documents/Projects/Nox/claude-config/skills/project-ledger/SKILL.md`

````markdown
---
name: project-ledger
description: Use to set up, adopt, feed or audit a project's management docs - CLAUDE.md context plus status.md (current state, log, decisions, open questions) and workplan.md (inbox, now, next, backlog). Triggers on "set up a project ledger", "set up status and workplan", "adopt the ledger here", "move the docs onto a status / workplan system", "audit the docs", "are status and workplan current", "/project-ledger <setup|adopt|intake|audit>", and, in a project whose CLAUDE.md has a "## Project ledger" section, whenever the user hands over meeting notes, minutes, a call summary, a mail or a document to work into the docs ("here are my notes from the call", "integrate this mail").
---

# project-ledger

## Overview

A project ledger keeps a project's state in three files, one owner per fact:

- `CLAUDE.md` holds stable context and the `## Project ledger` section: the Owns table (which file and section owns which fact, plus an optional Check rule), the trigger table (what to update when), `Followups: workplan`, and optionally `Id prefixes:`.
- `status.md`: `## Current state` (at most 15 lines, read every session), `## Log` (newest first), `## Decisions` (`D-n`), `## Open questions` (`Q-n`), then extensions.
- `workplan.md`: `## Inbox` (unsorted, no ids), `## Now`, `## Next`, `## Backlog` (`W-n`), then extensions. The forward plan only.

Paths can differ per project; the Owns table is the authority.

## Core principle (load-bearing)

**Read the receiving files, propose, ask, stop. Write only after the user has answered, in one pass.** Every mode shows what it would write where and asks numbered questions before touching a file. An item the user did not decide is a `Q-n`, never a `D-n`.

## Modes

| Mode | When | Procedure |
|---|---|---|
| setup | No ledger section, no docs beyond a README | `setup.md` |
| adopt | Existing docs, no ledger section | `adopt.md` |
| intake | Notes, minutes, mails or documents handed over in a ledger project | `intake.md` |
| audit | Asked to audit or clean up the docs; `ledger_check.py` reports an old or missing audit | `audit.md` |

Read the mode's file (in this skill's base directory) before doing anything else. Intake in a project without a ledger section: offer adopt first; if declined, give the read-out and write nothing.

## Entry formats

```markdown
## Current state

As of YYYY-MM-DD.

- Phase: …
- Live: …
- Waiting on: … (W-6, Q-12)

### YYYY-MM-DD – <title>              ← Log entry, newest first; an audit's title is "Audit: <n> findings"
- <bullets>
- Closed: W-17, Q-41.                 ← whenever the entry closes ids

- **D-12** (YYYY-MM-DD, decision, Sven): <text>
- **D-13** (YYYY-MM-DD, assumption, ours): <text> Superseded by D-20.
- **D-60** (YYYY-MM-DD, decision, Alex): <text answering Q-41> Closed: Q-41.

- **Q-41** (YYYY-MM-DD, asked of Alex): <text>
  - YYYY-MM-DD: <update while open>

- YYYY-MM-DD · <source> · <one line>  ← Inbox; optional indented sub-line with file:line

- **W-17** <title>. Owner: Sven. Waits on: Q-45, W-3. <notes>
```

Decision types: `decision`, `assumption`, `recommendation`; the third field names who decided (`ours` for a working assumption).

## Rules

- **Ids** `D-`, `Q-`, `W-` (plus declared `Id prefixes:`) are never reused or renumbered. `ledger_check.py` prints the next free ids. An Inbox item gets its `W-` id when triage moves it to Now, Next or Backlog.
- **Closing**: a finished or dropped `W-` and an answered `Q-` are deleted from the live section; a Log entry (or the `D-` that answers the question) lists them in a `Closed:` line. Never strike through, never mark done in place.
- **Decisions** are never edited. A change is a new `D-` and `Superseded by D-n.` appended to the old one.
- **Current state** is rewritten, not appended, in the same commit as any change to its facts. State only; it links `W-` ids instead of restating tasks.
- **Same commit**: the owning file changes in the same commit as the change it records.
- **One owner per fact**: everything else links (`status.md § Decisions, D-12`).
- **Archive**: above 40 KB, the oldest Log months move to `status-archive.md`; Decisions and Open questions are never archived.

## Shared habits

1. Read the receiving sections before proposing: Current state, Decisions, Open questions, Inbox, Now, and the extensions involved.
2. Numbered questions, then stop and wait. A garbled or positional answer: state your reading in one line and ask for a yes.
3. Write in one pass with exact-string anchors that fail loudly when they do not match.
4. Run `python <skill base directory>/ledger_check.py --root <project root>`: zero errors before committing.
5. One commit per pass, message `docs: <what changed>`.
6. Save a working preference the user states as a memory.

## Red flags - stop and re-read this skill

- About to edit a file before the user answered the numbered questions.
- About to record something nobody decided as a `D-n`.
- About to change the text of an existing `D-n`.
- About to strike through or tick a workplan item instead of deleting it with a `Closed:` line.
- Proposing placements without having read the receiving sections.
- Picking a new id without `ledger_check.py`'s next free ids.
- Resolving an ambiguous name, date or phrase yourself instead of asking.

## Rationalizations - these are violations, not exceptions

| Rationalization | Reality |
|---|---|
| "The user asked me to integrate / clean up, so writing directly is what they want." | They want the result they would have approved. Propose, ask, stop; write after the answers. |
| "It was discussed, so it's a decision." | Only what the user or the source states as agreed is a `D-n`. Everything else is a `Q-n`. |
| "Fixing the decision text is simpler than superseding it." | An edited decision rewrites history. New `D-n`, `Superseded by` on the old one. |
| "Striking it through keeps the context." | The Log keeps the context. Delete and list it in `Closed:`. |
| "Sam obviously means Samantha." | A name with two candidates is a question, not a guess. |
| "The migration is mechanical, no need for a mapping report." | The report is where the user catches the wrong mapping before it is written. |
| "Renumbering gives a cleaner sequence." | Ids are referenced from outside the docs (commits, mails). Keep existing numbers. |
````

- [ ] **Step 2: Prune the red flags and rationalizations to the baseline**

Every row of "Rationalizations" and every red flag must map to a failure mode that fired in Task 5 (name it in your notes) or to a rule of the spec the baseline broke outside the rubric. Delete rows that map to nothing; add a row for each fired failure that has none, quoting the subagent's own reasoning as the rationalization.

- [ ] **Step 3: Check that no fixture content leaked into the skill**

Run: `grep -n -i -E 'joanna|jonas|hetzner|thursday|field list|docs_check|new offer|orbit|harbour' skills/project-ledger/*.md`
Expected: no output. (The skill's examples use neutral names; fixture words in the skill would teach the with-skill run the answers.)

- [ ] **Step 4: Commit**

```bash
git add skills/project-ledger/SKILL.md
git commit -m "Add project-ledger SKILL.md"
```

---

### Task 7: setup.md and intake.md

**Files:**
- Create: `skills/project-ledger/setup.md`, `skills/project-ledger/intake.md`

- [ ] **Step 1: Create `skills/project-ledger/setup.md`**

````markdown
# setup

For a project with no `## Project ledger` section in CLAUDE.md and no documentation beyond a README.

## 1. Detect

```bash
git ls-files '*.md' | head -50
```

If the project has status-, progress- or roadmap-type files, `TODO.md`, `FUTURE.md`, or `docs/*.md` with plans, decisions or open questions, stop and suggest adopt (`adopt.md`) instead. A release `CHANGELOG.md` does not count.

## 2. Ask one numbered round, then stop

1. Client engagement or internal project?
2. Which extensions (none is a fine answer for a small internal project)? Offer the table in § 4.
3. `status.md` and `workplan.md` at the root, or other paths?
4. Current state: the phase, what is live, what waits on whom.

## 3. Write (after the answers)

- `status.md` and `workplan.md` from `templates/` in this skill's base directory: `{{DATE}}` is today; `{{PHASE}}`, `{{LIVE}}`, `{{WAITING}}` come from answer 4, and a line without an answer is deleted.
- The ledger section from `templates/claude-section.md`, appended to CLAUDE.md. Without a CLAUDE.md, create one holding only a `# <project name>` line and that section. If answer 3 moved a file, change its Owns rows and the "Read status.md" line to the new path.
- Each chosen extension (§ 4): its heading after the core sections (or its file), its Owns row, its Check rule, its trigger row.

## 4. Extensions offered

| Extension | Heading / file | Owns row | Check | Trigger row |
|---|---|---|---|---|
| Risks | status.md `## Risks` | Risks: likelihood, impact, mitigation | Every risk names a mitigation or an owner | A risk appears or changes → Risks |
| Milestones | workplan.md `## Milestones` | Dated milestones | Every milestone has a date and a W- id | |
| Meetings | `meetings.md` | One `## YYYY-MM-DD – <meeting>` section per meeting | Every meeting section has a Log entry that links it | A meeting happens → meetings.md section; Log entry links it |
| External docs | `docs/external/` | Client-facing documents; may restate internal facts | Flag a document whose sources changed after it (`git log -1` dates) | A fact they restate changes → flag for refresh |
| Question split | `### For the client` and `### Internal` under Open questions | One row each: Q-n asked of the client / internal Q-n | | |
| Contract brief | CLAUDE.md `## Contract in brief` | Scope, price, acceptance criteria | Changes only with a signed offer or amendment | A contract fact changes → Contract in brief |

## 5. Check and commit

```bash
python <skill base directory>/ledger_check.py --root <project root>
```

Zero errors, then commit: `docs: project ledger set up`. Report the files written and the Current state.
````

- [ ] **Step 2: Create `skills/project-ledger/intake.md`**

````markdown
# intake

For meeting notes, official minutes, a call summary, a mail or a document handed over in a project with a `## Project ledger` section.

## 1. Ingest

Pasted text as is. Files through Read; `.docx`, `.xlsx`, `.pptx` and `.pdf` through their skills. Note the source type: personal notes, official minutes, mail, other.

## 2. Read the receiving sections

Current state, Decisions, Open questions, Inbox, Now, Next, and every extension the source touches (meetings, milestones, contacts in CLAUDE.md). Run `ledger_check.py` for the next free ids. Do not propose anything before this step.

## 3. Read-out, per topic

- Who took part or wrote it, and the date.
- What was learned.
- Actions, each with owner and due date.
- What was decided, quoted from the source.
- New names, with roles.
- Matches with the ledger: an open `Q-n` the source answers, a `W-n` it unblocks or finishes, a `D-n` it contradicts or supersedes, an Inbox or Backlog item it repeats.

Official minutes and personal notes stay apart; name where they disagree.

## 4. Proposed placements, one line per target

```text
Log        ### YYYY-MM-DD – Steering call with Alex          (summary, links)
D-21       decision, Alex: reports go out monthly            supersedes D-14 (assumption: quarterly)
Q-12       answered by Alex's budget figure → delete, Closed: Q-12 in D-22
Q-30       new: switch the hosting provider? (Alex to think about it)
W-41       Now: send Alex the data dictionary. Owner: Sven. Due Friday
Current    Waiting on: no longer Q-12
Not taken  dashboard export later this year: already W-35 in Backlog
```

## 5. Numbered questions, then stop

Ask about everything the source leaves open: a name with two candidates, whether a statement was a commitment or a mention, dates, owners, garbled phrases. Stop and wait for the answers.

## 6. Verify what is cheap to check

Code, data, git history, the project's own files: before writing, not after.

## 7. Write

In one pass, one commit (`docs: <source> of YYYY-MM-DD`). Undecided items are `Q-n`. Closed ids go into a `Closed:` line. Current state is rewritten if any of its facts changed.

## 8. Close

Run `ledger_check.py` (zero errors). Report where each fact went, what was left out and why, what remains open. If it reports no audit yet or the last audit more than 30 days ago, suggest one (`audit.md`). Save any working preference the user stated as a memory.
````

- [ ] **Step 3: Check the leak grep of Task 6 Step 3 again** (expected: no output), then commit

```bash
git add skills/project-ledger/setup.md skills/project-ledger/intake.md
git commit -m "Add project-ledger setup and intake procedures"
```

---

### Task 8: adopt.md and audit.md

**Files:**
- Create: `skills/project-ledger/adopt.md`, `skills/project-ledger/audit.md`

- [ ] **Step 1: Create `skills/project-ledger/adopt.md`**

````markdown
# adopt

For an existing project without a `## Project ledger` section: move its documentation onto the ledger, keeping what it built for itself.

## 1. Inventory

Read CLAUDE.md, the README, status-, progress- and roadmap-type files, `TODO.md`, `FUTURE.md`, `docs/*.md`, and the project memories (`~/.claude*/projects/<project>/memory/`) that describe a documentation process. On a large project, dispatch one subagent per file group and ask each for its facts, sections and references.

Detect besides the facts:

- **Divisions**: sections or files with no core equivalent, e.g. a "Waiting for the board" section, a split of the questions by audience, task chains with their own prefixes, a `meetings.md`.
- **Checks**: check scripts (`scripts/*check*`, `*.py` or `*.sh` that read the docs), project audit skills (`.claude/skills/`), written documentation rules in CLAUDE.md ("every fact lives in one file").
- **History in CLAUDE.md**: dated progress, run or PR details, rule histories. These move to the Log.

## 2. Mapping report, then stop

Write the report to the session scratch space and show it:

```markdown
## Moves
| # | Source | Target | Id | Action |
|---|---|---|---|---|
| 1 | notes.md § Questions, question 12 | status.md § Open questions | Q-12 | move |
| 2 | notes.md § Questions, question 7 (ticked, answered 3 Mar) | Log entry 2026-03-03 | Q-7 | close |
| 3 | ROADMAP.md § Q2, "9. Billing export" | workplan.md § Next | W-9 | move |
| 4 | ROADMAP.md § Q2, "Dark mode" (unnumbered) | workplan.md § Next | W-10 | move |
| 5 | TODO.md, 4 items | workplan.md § Inbox | | move, delete TODO.md |

## Divisions and checks
| # | Found | Proposal | Reason |
|---|---|---|---|
| 6 | ROADMAP.md § Waiting for the board | keep as extension; Owns: items that need a board decision; Check: every item names the board meeting | 3 live items |
| 7 | scripts/lint_docs.py | keep; Check rule on the Log row: run `scripts/lint_docs.py` | checks link targets, which the ledger script does not |
| 8 | CLAUDE.md rule "every fact lives in one file" | fold into the core (ledger section) | duplicates the core rule |

## References to rewrite
| file:line | Old | New |
|---|---|---|
| ROADMAP.md:12 | question 12 | Q-12 |

## Questions
1. …
```

Rules for the report:

- Existing numbers become ids: `question 41` → `Q-41`, `Key Decision 13` → `D-13`, step `17.` → `W-17`. Never renumber.
- Unnumbered items get ids above the highest existing number of their prefix, in date order.
- Struck-through, ticked or "done" items are closed items: they leave the live sections, and a Log entry lists them in `Closed:`.
- Old findings become Log entries, newest first; a findings log above 40 KB gets an archive proposal.
- Every division and check gets a proposal: keep as an extension (with a drafted Owns row and a Check rule converted from the existing check), fold into the core, or drop, each with a one-line reason (in recent use, holds content, not a duplicate of the core). A project script with checks `ledger_check.py` lacks stays and is named in a Check rule.

Ask the numbered questions and stop.

## 3. Apply (after the answers)

1. In one pass: the moves, the new ids, the closures with their `Closed:` lines, the reference rewrites, the kept extensions with their Owns rows and Check rules.
2. Write the ledger section into CLAUDE.md from `templates/claude-section.md` (with `Followups: workplan`, and `Id prefixes:` if the project keeps its own), and remove what it replaces.
3. Write a fresh Current state from the answers.
4. Move `FUTURE.md` into the Inbox and delete it.
5. Run `ledger_check.py` (zero errors) and the kept project checks; commit `docs: adopt the project ledger`.
6. Propose deleting the project memories the ledger now covers; delete only on a yes.
````

- [ ] **Step 2: Create `skills/project-ledger/audit.md`**

````markdown
# audit

Find stale or misplaced information in a ledger project, report it, and reconcile it with the user.

## 1. Mechanical checks

```bash
python <skill base directory>/ledger_check.py --root <project root>
```

Every ERROR becomes a finding. INFO lines become findings where they point at a problem (old Inbox items, archive size, Current state, references to closed ids, "to confirm"). Note the next free ids and the days since the last audit.

## 2. Core judgement checks

Read the whole of status.md (up to the archive), workplan.md and CLAUDE.md. On a large project, one subagent per file group, each returning findings in the format of § 5. Look for:

- Current state that the newest Log entries or Now contradict.
- Finished work still in the workplan (a Log entry says it is done, a later state supersedes it).
- Decisions edited instead of superseded: `git log -p --follow <status file>` and look for changed `- **D-` lines.
- Log entries that state a decision without a `D-n`.
- Open questions the Log has answered.
- Facts held in two places; the Owns table decides the owner.
- History or progress in CLAUDE.md (dated events, run or PR details, rule histories).

## 3. Extensions

For each Owns row with a Check rule, apply the rule (run a named script). For every extension, check that it holds what its Owns row says, that nothing in it belongs to another owner, and that it duplicates no facts.

## 4. Inbox triage

Propose a target for every Inbox item: a `W-n` in Now, Next or Backlog (with the next free id), a `Q-n`, a Log entry, or drop.

## 5. Report, then stop

Write the report to the session scratch space and show it. Do not report a finding again that the previous audit's Log entry lists as kept, unless its content changed.

```markdown
## Findings
F-1 status.md:6 · Current state says "Waiting on: Alex for the budget (Q-12)"; Log 2026-03-03 closed Q-12.
    Fix: rewrite Current state (nothing waiting on Alex).
F-2 status.md:40 · D-17 defined twice (ledger_check).
    Fix: the second becomes D-25 (assumption, ours); references checked.

## Inbox triage
I-1 2026-02-10 · call with Alex · data retention period → Q-31 (ask Alex)
I-2 2026-03-01 · noticed · slow dashboard load → W-42 Backlog
```

Ask: for each finding fix, keep or Inbox; for each Inbox item the target. Stop.

## 6. Reconcile (after the answers)

Apply everything in one pass and commit `docs: audit of YYYY-MM-DD`. Add one Log entry:

```markdown
### YYYY-MM-DD – Audit: <n> findings
- Fixed <a>, kept <b>, to Inbox <c>; Inbox triaged: <d> items.
- Kept: <one line per kept finding, with file § section>.
- Closed: <ids closed by the audit>.
```

Run `ledger_check.py` again: zero errors.
````

- [ ] **Step 3: Check the leak grep of Task 6 Step 3 again** (expected: no output), then commit

```bash
git add skills/project-ledger/adopt.md skills/project-ledger/audit.md
git commit -m "Add project-ledger adopt and audit procedures"
```

---

### Task 9: followup-tracking: the workplan destination

**Files:**
- Modify: `skills/followup-tracking/SKILL.md` (section "3. Persist" and "Failure handling")

Each old string below occurs exactly once in the file (checked 2026-10-09).

- [ ] **Step 1: Persistence line in "Core principle"**

Old: ``- **Persistence** (Linear, FUTURE.md) happens only on explicit user `Keep` during triage.``
New: ``- **Persistence** (Linear, FUTURE.md, a project-ledger workplan Inbox) happens only on explicit user `Keep` during triage.``

- [ ] **Step 2: Destination list**

Old: ``Destinations: `linear`, `future` (a FUTURE.md file), or `both`.``
New: ``Destinations: `linear`, `future` (a FUTURE.md file), `both` (Linear and FUTURE.md), or `workplan` (the `## Inbox` of a project-ledger workplan).``

- [ ] **Step 3: Rung 1**

Old: ``contains a `Followups: linear | future | both` line``
New: ``contains a `Followups: linear | future | both | workplan` line``

Old: `(rung 3's FUTURE.md existence check is the one permitted lookup)`
New: `(rung 3's workplan and FUTURE.md existence checks are the only permitted lookups)`

- [ ] **Step 4: Rung 3**

Old:

```markdown
3. Else, if a `FUTURE.md` exists at the project root, suggest it as the default in the clarification question — never silently use it.
```

New:

```markdown
3. Else, if a `workplan.md` with an `## Inbox` section exists at the project root (or at the path the project memory's `## Project ledger` Owns table gives for `§ Inbox`), suggest `workplan` as the default; else, if a `FUTURE.md` exists at the project root, suggest it as the default. Either way in the clarification question — never silently use it.
```

- [ ] **Step 5: The Workplan Inbox destination**

Insert after the FUTURE.md block, i.e. after the two lines

```markdown
- Ticking `- [x]` is the user's business; the skill does not manage entry
  lifecycle.
```

this block (blank line before it):

````markdown
**Workplan Inbox** (when the destination is `workplan`)

- Path: the file of the `§ Inbox` row in the project memory's `## Project ledger`
  Owns table; default `workplan.md` at the project root.
- Append at the end of its `## Inbox` section, one item per line, no id:

  ```markdown
  - YYYY-MM-DD · followup (<surfaced-during>) · <subject>
    <origin file:line, when there is one>
  ```

- Never give the item a `W-` id or place it in Now, Next or Backlog: triage is
  the project-ledger audit's job.
- A workplan without an `## Inbox` section is a write failure (below).
````

- [ ] **Step 6: Failure handling**

Insert after `- **FUTURE.md write fails.** Surface the error to the user verbatim.`:

```markdown
- **Workplan write fails or has no `## Inbox` section.** Surface the error to the user verbatim and offer FUTURE.md instead, so the item is not lost.
```

- [ ] **Step 7: Verify the edits**

Run: `grep -c 'workplan' skills/followup-tracking/SKILL.md`
Expected: `7` (dry-run on 2026-10-09). Then `git diff skills/followup-tracking/SKILL.md` shows only the changes of Steps 1–6.

Run: `grep -c 'workplan' GLOBAL.md` after Task 10: expected `3`.

- [ ] **Step 8: Commit**

```bash
git add skills/followup-tracking/SKILL.md
git commit -m "followup-tracking: workplan Inbox destination for project-ledger projects"
```

---

### Task 10: GLOBAL.md

**Files:**
- Modify: `GLOBAL.md` (section "Followup tracking")

`GLOBAL.md` is the target of `~/.claude/CLAUDE.md` and `~/.claude-uhrwerk/CLAUDE.md`, so the change applies to every session at once.

- [ ] **Step 1: Check for uncommitted changes by someone else**

Run: `git status --short GLOBAL.md`
Expected: no output. If it shows ` M`, stop and ask the user: someone else is editing the file.

- [ ] **Step 2: Three edits**

Old: ``Persistence destinations: FUTURE.md, Linear, or both. Destination resolution (used by `followup-tracking`):``
New: ``Persistence destinations: FUTURE.md, Linear, both, or the workplan Inbox of a project ledger. Destination resolution (used by `followup-tracking`):``

Old: ``declares `Followups: linear | future | both` (optional `future=<path>`)``
New: ``declares `Followups: linear | future | both | workplan` (optional `future=<path>`)``

Old: ``3. Else if a `FUTURE.md` exists at the project root, suggest it as the default.``
New: ``3. Else if a `workplan.md` with an `## Inbox` section exists (project ledger), suggest `workplan`; else if a `FUTURE.md` exists at the project root, suggest it as the default.``

- [ ] **Step 3: Commit**

```bash
git add GLOBAL.md
git commit -m "GLOBAL.md: workplan as a followup destination"
```

---

### Task 11: Install the symlink and document it

**Files:**
- Modify: `README.md` (Setup block)
- Create (filesystem only): `~/.claude/skills/project-ledger`

- [ ] **Step 1: Install and verify**

```bash
ln -s /home/nox/Documents/Projects/Nox/claude-config/skills/project-ledger ~/.claude/skills/project-ledger
readlink -f ~/.claude/skills/project-ledger
readlink -f ~/.claude-uhrwerk/skills/project-ledger
```

Expected: both print `/home/nox/Documents/Projects/Nox/claude-config/skills/project-ledger`.

- [ ] **Step 2: README**

After the line `ln -s "$REPO/skills/skill-from-session"   ~/.claude/skills/skill-from-session` add:

```bash
ln -s "$REPO/skills/project-ledger"       ~/.claude/skills/project-ledger
```

After the line `readlink -f ~/.claude/skills/skill-from-session` add:

```bash
readlink -f ~/.claude/skills/project-ledger
```

- [ ] **Step 3: Commit**

```bash
git add README.md
git commit -m "Document project-ledger symlink in README"
```

---

### Task 12: With-skill runs and observations

**Files:**
- Create: `tests/project-ledger-with-skill-observations.md`

- [ ] **Step 1: Verify the install**

```bash
test -f ~/.claude/skills/project-ledger/SKILL.md && echo "OK: skill installed"
grep -q 'workplan' ~/.claude/skills/followup-tracking/SKILL.md && echo "OK: followup-tracking edited"
```

- [ ] **Step 2: Run the four scenarios again**

Same procedure as Task 5 Step 2: rebuild the fixture before each, same verbatim prompts. Subagents inherit the skill list; if a subagent does not invoke `project-ledger` in A–C, add one line to its prompt, "Use the project-ledger skill.", and note that the description did not trigger (a description fix for Task 13).

- [ ] **Step 3: Write the observations file**

Same layout as the baseline file, plus per scenario:

````markdown
### Comparison to baseline

For each failure mode: **closed / leaked / partial** + one-line note.

### Verdict

<all closed? iterate?>
````

- [ ] **Step 4: Decide on iteration**

All failures that fired in the baseline closed: go to Task 14. Any leaked or partial: Task 13.

- [ ] **Step 5: Commit**

```bash
git add tests/project-ledger-with-skill-observations.md
git commit -m "Record project-ledger with-skill observations"
```

---

### Task 13: Close residual loopholes (CONDITIONAL)

Run only if Task 12 found a leaked or partial failure.

**Files:**
- Modify: the skill file the leak points at (`SKILL.md`, a mode file, or `followup-tracking/SKILL.md`)
- Append to: `tests/project-ledger-with-skill-observations.md`

- [ ] **Step 1:** For each leak, find the sentence or thought that let it through. A rationalized skip becomes a row in "Rationalizations" (the subagent's reasoning as the rationalization, the rule as the reality); an unclear step is fixed in the mode file itself.
- [ ] **Step 2:** Edit the file, then rerun the leak grep of Task 6 Step 3 (no output).
- [ ] **Step 3:** Rebuild the fixture and rerun only the leaking scenario.
- [ ] **Step 4:** Append an "Iteration N" section (date, failure statuses, verdict).
- [ ] **Step 5:** Commit: `git add <edited files> tests/project-ledger-with-skill-observations.md && git commit -m "Close project-ledger loopholes (iteration N)"`
- [ ] **Step 6:** Repeat at most three times. If a leak survives three iterations, stop and report it to the user: the gap may be in the spec.

---

### Task 14: Final review and cleanup

**Files:** none modified

- [ ] **Step 1: Verify the file map and the checker**

```bash
ls skills/project-ledger skills/project-ledger/templates
ls tests | grep project-ledger
python3 skills/project-ledger/ledger_check.py --self-test
readlink -f ~/.claude/skills/project-ledger
```

Expected: `SKILL.md adopt.md audit.md intake.md ledger_check.py setup.md templates`; `claude-section.md status.md workplan.md`; five `project-ledger-*` test files; `self-test passed`; the repo path.

- [ ] **Step 2: Remove the fixture and confirm a clean tree**

```bash
rm -rf /tmp/project-ledger-fixture
git status --short
```

Expected: no output.

- [ ] **Step 3: Report to the user**

The commits, the baseline and with-skill verdicts per scenario, anything left open. The push and the rollout (adopt on von-saldern-logistik and on EWS, spec § 10) wait for the user.

---

## Notes on subagent test fidelity

Subagent runs vary from run to run; the aim is coverage of the failure space, not reproducibility. One with-skill run that closes the baseline failures is enough; rerun only together with a rule change. Always rebuild the fixture before a dispatch: scenarios A, B and D share `ledgered`, and a run that writes changes the next run's input. A subagent cannot wait for the user's answers, so in A–C a report with numbered questions and no file changes is the pass condition.
