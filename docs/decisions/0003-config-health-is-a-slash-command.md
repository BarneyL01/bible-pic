# 0003. Configuration health checks run as an on-demand slash command

- **Status:** Accepted
- **Date:** 2026-09-15
- **Deciders:** repository owner

## Context

Agent configuration decays as paths move and instructions accumulate. The check can run on
demand, on pull requests via CI, on a schedule, or from a local hook after edits. CI and
scheduled runs catch decay without being asked but produce output nobody reads when the
findings are mostly nits, and both need infrastructure this repository does not yet have.

## Decision

The health check is `/audit-agent-config`, invoked explicitly. No GitHub Actions workflow, no
scheduled routine, and no post-edit hook at this stage.

## Consequences

- Decay is caught only when someone runs the command; the root `CLAUDE.md` names it so it is
  discoverable.
- No CI configuration to maintain while the repository has no build.
- Adding a PR-triggered or scheduled run later is additive — the skill already produces a
  severity-ranked table suitable for posting.

## Alternatives considered

| Option | Why not |
| --- | --- |
| PR-triggered GitHub Action | Needs CI setup before there is anything to build; comment noise on low-severity findings. |
| Scheduled routine opening PRs | Generates unreviewed PRs against a repository with no established review rhythm. |
| Post-edit hook | Fires on every edit including work-in-progress; interrupts rather than reviews. |
