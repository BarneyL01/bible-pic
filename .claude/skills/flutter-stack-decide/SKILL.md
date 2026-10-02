---
name: flutter-stack-decide
description: Resolve an undecided Flutter stack choice marked TBD in a CLAUDE.md by presenting the real options with trade-offs, getting the user's decision, and recording it as an ADR plus a concrete instruction.
when_to_use: Use when a TBD placeholder blocks work, when the user asks which state management, routing, networking, persistence, testing, lint, or CI approach to use, or when starting a new Flutter app from the base. Also use when the user invokes /flutter-stack-decide.
argument-hint: "[concern]"
disable-model-invocation: true
---

# Decide a Flutter stack choice

A `TBD` in a `CLAUDE.md` is an open question with a known owner: the user. This skill closes
one completely: decision made, reasoning recorded, instruction written — rather than filling
the gap with a default.

## Procedure

### 1. Find the open questions

```bash
grep -rn "TBD" --include="CLAUDE.md" . 
```

List them. If the user named one, do that one. If several are open and coupled (state
management and routing usually are), say so and decide them together.

### 2. Present the real choice

For each decision, give a table: the candidate options, and for each one the trade-off that
actually matters for **web and Android Flutter apps** — not a feature list. Cover at minimum:

- what it costs in boilerplate per feature
- how it behaves on the web surface: deep links, URL state after reload, effect on bundle size
- what it makes hard to change later

State a recommendation and the one reason for it. Do not present four options as equally
valid — that pushes the work back to the user.

If the decision depends on facts you do not have (team size, existing code, target Android
API level, whether the web build is the primary surface), ask before recommending.

### 3. Get the decision

Use the question tool. The user's answer is the decision — do not relitigate it. If you think
it is wrong, say so once in a sentence, then implement what they chose.

### 4. Record it

**ADR** — copy `docs/decisions/TEMPLATE.md` to the next number:

```bash
ls docs/decisions/ | grep -E '^[0-9]{4}' | sort | tail -1
```

Fill in Context (what was open and why it mattered), Decision (what was chosen, stated as a
rule), Consequences (what this now forbids or requires), and Alternatives (what was rejected
and the specific reason).

**Instruction** — replace the `TBD` line in the target `CLAUDE.md` with a checkable instruction
per rubric criterion C2, citing the ADR:

```
State is managed with Riverpod. Providers live in `lib/features/<feature>/providers/`;
no `setState` in widgets under `lib/features/`. See docs/decisions/NNNN-state-management.md.
```

**Vocabulary** — if the decision introduces a term the team will use (`feature module`,
`provider`, `route guard`), record it with the `/vocabulary` skill.

### 5. Verify

Re-grep for `TBD` and confirm the one you closed is gone and the others are untouched. Never
resolve a `TBD` the user did not decide on in this run.

## Scope

- One decision at a time unless the decisions are coupled.
- This skill records decisions; it does not install packages or write feature code. Adding the
  dependency and scaffolding follows separately, in the app repo.
