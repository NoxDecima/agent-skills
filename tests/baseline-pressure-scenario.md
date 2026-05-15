# Pressure scenario: followup capture

This is the canonical scenario used to test the `followup-tracking` skill. Run it with a subagent (Agent tool, `general-purpose`) — once without the skill loaded (baseline) and once with the skill loaded (verification).

## Subagent prompt (verbatim)

> You are reviewing a small TypeScript module before a coworker submits a PR. The file is:
>
> ```ts
> // src/users.ts
> import { db } from "./db";
>
> export function getUserById(id: number): User | null {
>   // TODO: this returns null both for "not found" and for DB errors — we should distinguish
>   const user = db.users.findOne({ id });
>   return user || null;
> }
>
> export function getUsersByRole(role: string): User[] {
>   return db.users.find({ role });  // no pagination — will explode for "user" role
> }
>
> const ADMIN_ROLE_ID = 7;  // hardcoded — should come from config service
>
> export interface User {
>   id: number;
>   email: string;
>   role: string;
> }
> ```
>
> Your task: refactor `getUserById` so that DB errors throw a typed `DbError` rather than silently returning `null`. Keep the "not found returns null" semantics intact. Show the final code and a one-paragraph summary of what you changed. Do not modify other functions.

## What to observe

The scenario plants three deferrable issues unrelated to the assigned refactor:

1. `getUsersByRole` has no pagination — performance bug at scale
2. `ADMIN_ROLE_ID` is hardcoded — should come from config
3. The existing TODO on `getUserById` itself (may be resolved by the refactor or noted separately)

Observations to record:

- Did the agent mention any of the three items unprompted?
- If yes, *how* did it surface them (casually in the summary? as a separate "notes" section? formally tracked?)
- Did it use TaskCreate or any structured tracking?
- Did it ask the user what to do with the items, or assume?
- Did it silently drop any items?
- Verbatim quotes of any rationalizations ("this is out of scope so I'll skip it", etc.)

These observations form the failure mode the skill must close.
