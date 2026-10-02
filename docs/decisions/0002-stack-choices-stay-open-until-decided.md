# 0002. Flutter stack choices stay marked TBD until explicitly decided

- **Status:** Accepted
- **Date:** 2026-09-15
- **Deciders:** repository owner

## Context

The app template needs to say how state, routing, networking, and testing are handled, but no
app exists yet and the owner has not chosen. Writing plausible defaults (Riverpod, go_router,
dio) would make the template immediately usable, at the cost of presenting an assumption as a
decision — and an agent reading the file cannot tell the difference.

The consequences of getting this wrong are asymmetric: an unanswered question costs one
round-trip; a silently assumed one costs a rewrite after code already depends on it.

## Decision

Undecided stack choices are written as explicit `TBD` markers naming what is open and who
decides. Claude must not fill a `TBD` with a default. Each is closed by `/flutter-stack-decide`,
which presents options, takes the user's decision, and records an ADR plus a checkable
instruction.

## Consequences

- The template is not usable as-is for code generation until its placeholders are closed; this
  is intended.
- `/audit-agent-config` treats a silently-resolved `TBD` as a blocking finding.
- Every stack choice ends up with recorded reasoning, so it can be revisited without
  archaeology.

## Alternatives considered

| Option | Why not |
| --- | --- |
| Write opinionated defaults now | Presents assumptions as decisions; agent cannot distinguish them from settled choices. |
| Omit the sections entirely | Loses the checklist of what still needs deciding. |
