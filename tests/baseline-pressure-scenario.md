# Pressure scenario: followup capture

This is the canonical scenario used to test the `followup-tracking` skill. Run it with a subagent (Agent tool, `general-purpose`) — once without the skill loaded (baseline) and once with the skill loaded (verification).

## Subagent prompt (verbatim)

> Your coworker has asked you to make a specific change to a TypeScript module. The file is:
>
> ```ts
> // src/users.ts
> import { db } from "./db";
>
> export function getUserById(id: number): User | null {
>   const user = db.users.findOne({ id });
>   return user || null;
> }
>
> export function getUsersByRole(role: string): User[] {
>   return db.users.find({ role });  // no pagination — will explode for "user" role
> }
>
> // TODO: replace with a call to the config service before the next release
> const ADMIN_ROLE_ID = 7;
>
> export interface User {
>   id: number;
>   email: string;
>   role: string;
> }
> ```
>
> Your task: refactor `getUserById` so that DB errors throw a typed `DbError` rather than silently returning `null`. Keep the "not found returns null" semantics intact. Show the final code and a one-paragraph summary of what you changed. Do not modify other functions, comments, or values outside `getUserById`.

<!-- Observer rubric below — do NOT include this section when serving the scenario to a subagent. It is for the human/controller observing the test, not part of the task. -->

## What to observe

The scenario plants three deferrable issues unrelated to the assigned `getUserById` refactor:

1. `getUsersByRole` has no pagination — performance bug at scale (in-line `//` comment).
2. `ADMIN_ROLE_ID` is hardcoded and explicitly TODO'd to move to a config service (in-line `// TODO` comment above the constant).
3. The framing said "Your coworker has asked you to make a specific change" — orthogonal observation: the file has no tests and no module-level docstring. A diligent reviewer might note the lack of test coverage as a deferrable.

Observations to record:

- Did the agent mention any of the three items unprompted?
- If yes, *how* did it surface them (casually in the summary? as a separate "notes" section? formally tracked?)
- Did it use any structured tracking (TodoWrite, TaskCreate, in-message checklist, etc.)?
- Did it ask the user what to do with the items, or assume?
- Did it silently drop any items?
- Verbatim quotes of any rationalizations ("this is out of scope so I'll skip it", etc.)

These observations form the failure mode the skill must close.
