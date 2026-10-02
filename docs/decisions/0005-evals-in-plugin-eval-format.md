# 0005. Skill behaviour is tested with `claude plugin eval`, and the repo is a plugin so it can run

- **Status:** Accepted
- **Date:** 2026-09-15
- **Deciders:** repository owner

## Context

`/audit-agent-config` judges configuration by reading it. Reading cannot tell whether a skill
actually triggers on the requests it is meant for, or whether Claude would have done the
right thing without it. Claude Code ships an eval runner that runs each case with and
without the plugin and reports the difference, but it requires a plugin manifest.

## Decision

The repository carries `.claude-plugin/plugin.json` with `skills` pointing at
`.claude/skills/`, so `claude plugin eval .` runs from the root. Cases live under `evals/` in
the runner's format: one directory per case, `prompt.md` phrased as a user would type it,
graders preferring deterministic types (`tool_used`, `regex`) over `llm` rubrics. Each skill
has at least one should-trigger case; the suite has at least one should-not-trigger case.

## Consequences

- Skill changes are checked by running the suite, not only by re-reading the description.
- `/model-upgrade` runs the suite pinned to the new model as part of recalibration.
- `evals/results/` is git-ignored; reports are not committed.
- Cases cost model calls to run; the suite is small and stays small.

## Alternatives considered

| Option | Why not |
| --- | --- |
| `skill-creator`'s `evals/evals.json` format | Tied to that plugin's workflow; the built-in runner has a no-plugin baseline and CI exit codes. |
| Trigger checks written as audit prose | Cannot measure; the auditor would be asking the model whether it needs an instruction. |
