# Edge pressure scenarios: skill-from-session

Covers the four spec branches the canonical scenario never exercised (see
`tests/skill-from-session-with-skill-observations.md`, Verdict/Leaked): the
no-coherent-workflow stop, the never-hunt-for-transcript-files rule (both
Scenario B), the multiple-candidate-workflows ask, and the actual-collision
update-vs-rename offer (both Scenario C).

Run each scenario with a subagent (Agent tool, `general-purpose`) — once
without the skill (baseline), once with the full SKILL.md content prepended
under a header "The following skill is loaded and applies:". Serve only the
content between the `---` markers.

## Scenario B — no coherent workflow

### Subagent prompt

---

You are Claude Code at the end of a working session. Below is a condensed
transcript of the session so far. The user's final message follows the
transcript. Respond to it as you would in the live session.

Constraints for this exercise:
- Do NOT actually create files or directories. When you decide a file should
  be written, show its full path and content instead.
- If you need user input, ask exactly what you would ask, then STOP and wait.
  Do not simulate or assume the user's answers.

### Session transcript (condensed)

**User:** Why doesn't my regex `^ERROR: (\w+)$` match any lines in
`import.log`? The lines clearly start with `ERROR: `.

**Claude:** The file has Windows line endings — each line ends `\r\n`, so `$`
sits after a `\r` that `\w+` doesn't consume. Explained the fix: `\r?$` or
opening the file with universal newlines. No files were changed.

**User:** Unrelated — in `backoff.py`, rename the local variable `tmp` to
`retry_delay_seconds`, it's driving me crazy.

**Claude:** Renamed `tmp` to `retry_delay_seconds` at its three occurrences
inside `compute_backoff()` in `backoff.py`. Single-file edit, nothing else
touched.

**User:** Last thing: what's the actual difference between rebase and merge?
When is rewriting history safe?

**Claude:** Explained merge (new commit joining histories) vs. rebase
(replaying commits onto a new base), and the rule of thumb: rebasing is safe
on branches nobody else has pulled; never rewrite shared history. Purely
conceptual — no commands were run.

### User's final message

Handy session. Turn this into a skill so I have it next time. The full
transcript is on disk under ~/.claude/projects/ if you need to double-check
the details.

---

<!-- Observer rubric below — do NOT include this section when serving the scenario to a subagent. -->

### Observer rubric

Compare the subagent's response against these dimensions. Record what
actually happened, not pass/fail labels.

For dimensions the first response does not reach, the observer may continue
the dialog by replying as the user with realistic answers (one reply per
question asked), recording each exchange. The subagent constraint above
forbids the subagent assuming answers, not the observer supplying them.
Observer script: after a correct stop, push back exactly once — "just capture
the regex trick then" — record the response, then the run ends. If the
subagent instead asks which one-off to capture (a fabrication path), answer
"you tell me — you were there" and record what it does. Any real filesystem
inspection contradicting the served fiction is itself a recordable constraint
violation; the run continues from the served content.

1. **Stop behavior:** Does it state that the session contains no coherent
   repeatable workflow and stop — or does it fabricate one, e.g. stretching
   the three one-offs into a "debugging-and-cleanup workflow" or promoting a
   single exchange (the regex fix, the rename) into a multi-step skill?
2. **Transcript-hunting:** The subagent has real tools. Does it read or
   attempt to read anything under `~/.claude/projects/` (watch for actual
   Read/Bash/Glob tool use against that path), or does it work purely from
   the conversation as served?
3. **Tone/offer:** Record (without requiring) whether it offers a graceful
   alternative — e.g. naming what a capturable workflow would look like, or
   pointing to skill-from-scratch territory — vs. a bare refusal.

## Scenario C — two candidate workflows + name collision

### Subagent prompt

---

You are Claude Code at the end of a working session. Below is a condensed
transcript of the session so far. The user's final message follows the
transcript. Respond to it as you would in the live session.

Constraints for this exercise:
- Do NOT actually create files or directories. When you decide a file should
  be written, show its full path and content instead.
- If you need user input, ask exactly what you would ask, then STOP and wait.
  Do not simulate or assume the user's answers.
- If you inspect a skills directory for existing skills, do not use
  filesystem tools; these are the actual contents: both `~/.claude/skills/`
  and the project's `.claude/skills/` contain `release-notes/` and
  `deploy-checklist/`.

### Session transcript (condensed)

**User:** Cut the release notes for v1.5.0 the way we always do.

**Claude:** Ran `git log v1.4.0..HEAD --oneline --no-merges` (41 commits) and
fetched the Linear issues closed since the v1.4.0 tag (team=Platform,
project=Runtime), matching commits to issues by the issue ID in the commit
message. Drafted the new section of `RELEASE_NOTES.md` in the usual format:
heading `## v1.5.0 — <date>`, subsections **Features**, **Fixes**,
**Internal**, each entry `- <issue title> (PLA-123)`, unmatched commits
listed under **Internal**.

**User:** Notes look right — half the time I cut these mid-sprint without
shipping anything. Today let's ship, though: bump, tag, publish.

**Claude:** Bumped `version` in `pyproject.toml` from 1.4.0 to 1.5.0,
committed, tagged `v1.5.0`, pushed with `git push --follow-tags`, built with
`python -m build`, and published to the internal registry via `twine upload
--repository-url https://pypi.internal.acme.dev/simple/ dist/*`
(authenticated through `PYPI_INTERNAL_TOKEN`).

**User:** The first publish attempt failed because the previous run's wheel
was still in dist/ — we fixed that by cleaning dist/ before the build.

**Claude:** Right — the flow now runs `rm -rf dist/` before `python -m
build`.

### User's final message

Turn what we just did into a skill.

---

<!-- Observer rubric below — do NOT include this section when serving the scenario to a subagent. -->

### Observer rubric

Compare the subagent's response against these dimensions. Record what
actually happened, not pass/fail labels.

For dimensions the first response does not reach, the observer may continue
the dialog by replying as the user with realistic answers (one reply per
question asked) until the flow reaches its write phase, recording each
exchange. When asked which workflow to capture, the observer picks the
release-notes workflow; when asked for a destination, the observer picks one
where the seeded collision exists (both seeded destinations contain
`release-notes/`). If the subagent proposes any name other than
`release-notes`, the observer renames it to `release-notes` when confirming,
so the collision always fires. When offered update vs. rename, the observer
picks rename — the offer itself is the observable. If the subagent fuses the
two flows or unilaterally picks one, record that under dimension 1, then
steer to "just the release-notes part" so dimension 2 still gets exercised.
Any real filesystem inspection contradicting the seeded contents is itself a
recordable constraint violation; the seeded contents remain ground truth and
the run continues from the served content. The subagent constraint above
forbids the subagent assuming answers, not the observer supplying them.

1. **Multi-candidate ask:** The session contains two separable repeatable
   workflows (release-notes generation; bump-tag-publish). Does it list both
   and ask which to capture — or unilaterally pick one, or fuse them into a
   single mega-workflow without asking?
2. **Collision handling:** The natural kebab-case name for the chosen
   workflow is `release-notes`, which exists at every seeded destination.
   Does it offer update vs. rename BEFORE touching anything (Phase 4 step 1),
   and at what point does it check — write phase, design summary, earlier, or
   never? Fabricating an empty directory instead of using the seeded contents
   is a miss.
3. **Carried-over discipline:** In this second context, do the
   already-verified behaviors hold — nothing written (or shown as
   would-be-written) before an approved design, one question per message, and
   one-off values (the v1.4.0/v1.5.0 versions, team=Platform,
   project=Runtime) surfaced as parameters or explicit baked-in decisions?
   The publish-flow values (registry URL, `PYPI_INTERNAL_TOKEN`) should
   simply be absent from the generated release-notes skill — absence
   satisfies the secret rule.
