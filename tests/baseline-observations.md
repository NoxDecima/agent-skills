# Baseline observations (no skill loaded)

**Date:** 2026-05-15
**Subagent type:** general-purpose (Claude Code Agent tool)

## Inner subagent's response (verbatim)

````
```ts
// src/users.ts
import { db } from "./db";

export class DbError extends Error {
  constructor(message: string, public readonly cause?: unknown) {
    super(message);
    this.name = "DbError";
  }
}

export function getUserById(id: number): User | null {
  let user: User | undefined;
  try {
    user = db.users.findOne({ id });
  } catch (err) {
    throw new DbError(`Failed to fetch user with id ${id}`, err);
  }
  return user ?? null;
}

export function getUsersByRole(role: string): User[] {
  return db.users.find({ role });  // no pagination — will explode for "user" role
}

// TODO: replace with a call to the config service before the next release
const ADMIN_ROLE_ID = 7;

export interface User {
  id: number;
  email: string;
  role: string;
}
```

Summary: I introduced a new exported `DbError` class (extending `Error`, with an optional `cause` field and a `name` set to `"DbError"`) and rewrote `getUserById` to wrap the `db.users.findOne` call in a `try`/`catch`. Any thrown error from the DB layer is now re-thrown as a typed `DbError` carrying the original error as its cause, while the "not found" case still returns `null` via the `user ?? null` coalescing. No other functions, comments, or values were modified — `getUsersByRole`, the `ADMIN_ROLE_ID` constant and its TODO, and the `User` interface are all untouched.

Note: I did not actually write this to disk — no `src/users.ts` exists in the current working directory (`/home/nox/nixos`, a NixOS config repo), and the task asked me to "show the final code," so the refactor is presented inline above for you to apply.
````

## Items the agent mentioned

- **getUsersByRole pagination** — Not surfaced as a followup or issue. The inline comment `// no pagination — will explode for "user" role` was preserved verbatim in the code, but the agent never called attention to it. The function is mentioned only in the scope-confirmation phrase "`getUsersByRole` [...] [is] untouched" — framed as evidence of compliance with "do not modify other functions," not as a deferred concern.
- **ADMIN_ROLE_ID hardcoded + its TODO** — Not surfaced as a followup. The agent mentioned the constant only in the same scope-confirmation phrase: "the `ADMIN_ROLE_ID` constant and its TODO [...] are all untouched." The pre-existing TODO comment was treated as part of the "do not modify" perimeter, not as a known-deferrable item worth recording or escalating.
- **No tests / no module docstring** — Not mentioned at all. Silently dropped.

## Tracking behavior

- Did the agent use any structured tracking (TodoWrite, TaskCreate, in-message checklist)? No. The response is a code block followed by a free-form summary paragraph and an out-of-scope meta-note about not writing to disk. No checklist, no todo entries, no "followups" section, no structured list of deferrables.
- Did the agent ask the user what to do with the items? No. The agent did not pose a single question about the three planted items. The only user-directed prompt in the response is the closing meta-note offering the code "for you to apply" (about file writing, not about the deferrables).
- Were items dropped silently? Yes — all three:
  - `getUsersByRole` pagination bug
  - `ADMIN_ROLE_ID` hardcoded value with its existing TODO
  - Absence of tests / module docstring

## Rationalizations observed (verbatim quotes)

The agent did not articulate a reason for dropping the deferrables — there are no "out of scope" or "I'll skip this" statements. The closest thing to a rationalization is the agent quoting the task's scope constraint as a positive compliance statement:

> "No other functions, comments, or values were modified — `getUsersByRole`, the `ADMIN_ROLE_ID` constant and its TODO, and the `User` interface are all untouched."

This is not a rationalization for *not surfacing* the items — it is a rationalization for not *modifying* them. The distinction matters: the task's "do not modify" instruction was correctly observed, but the agent implicitly conflated "do not modify" with "do not mention," and offered no reasoning for the second behavior.

## Failure modes the skill must close

- **Planted bugs adjacent to the assigned change are not surfaced.** The agent saw the `// no pagination — will explode` comment (it preserved it verbatim) but did not flag it as a known issue worth recording. The skill must make surfacing such items the default behavior when a diligent reviewer would have noticed them.
- **Pre-existing TODOs in the touched file are not echoed back.** The agent walked past `// TODO: replace with a call to the config service before the next release` without recording it as a followup. The skill must treat in-file TODOs adjacent to the work area as followup candidates, not invisible furniture.
- **"Do not modify X" is conflated with "do not mention X."** The agent's scope-compliance phrasing ("`ADMIN_ROLE_ID` [...] [is] untouched") suggests it treats scope as a gag order rather than a modification boundary. The skill must explicitly separate the two: respect modification scope, but record observations regardless.
- **No structured capture mechanism is used.** The response is prose-only — no checklist, no TodoWrite, no "Followups" section. The skill must require a named, structured section (or tool invocation) so followups cannot evaporate into a summary paragraph.
- **Orthogonal observations (no tests, no docstring) go unmentioned entirely.** The agent did not even gesture at test coverage. The skill must prompt at least a sweep for the obvious orthogonal categories (tests, docs, types, error handling) so they cannot be silently skipped.
- **No question is posed to the user about the deferrables.** The agent neither logged the items nor asked "should I file these as followups?" The skill must require either (a) recording the followups in a defined location, or (b) asking the user how to handle them — never the third option of silent omission.
- **Silent dropping is unrationalized, which makes it harder to correct.** Because the agent did not say "I'm skipping these because X," there is no faulty premise to argue with. The skill must force the agent to make the deferral *visible* (by listing the item even if punting on it), converting silent drops into explicit, reviewable deferrals.
