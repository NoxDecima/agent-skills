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
