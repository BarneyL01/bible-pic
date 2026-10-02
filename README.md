# agent-base

Reusable Claude Code configuration for Flutter applications targeting **web** and **Android**.

This repository holds agent configuration only — no Flutter code. Application repositories
adopt it by copying `templates/flutter-app/` into themselves.

## Skills

| Command | Does |
| --- | --- |
| `/audit-agent-config` | Audits every `CLAUDE.md` and skill for stale paths, vagueness, duplication, broken references, and weak triggers. `--fix` applies the safe findings. |
| `/adopt-base` | Installs or updates the base in a Flutter app repo, reconciling anything the app has customised. |
| `/flutter-stack-decide` | Closes a `TBD` stack placeholder: presents options, takes the decision, writes an ADR and a checkable instruction. |
| `/vocabulary` | Records, amends, or retires a term in `docs/vocabulary.md`. |
| `/model-upgrade` | Recalibrates the configuration for a new model generation: re-tests every compensation, proposes additions, runs the evals, updates the baseline. |

## Layout

```
CLAUDE.md                     instructions for working on the base itself
.claude-plugin/plugin.json    makes the repo a plugin so `claude plugin eval .` runs
.claude/
  settings.json               permission defaults
  skills/                     the five skills above
docs/
  vocabulary.md               agreed terms — the shared language
  model-baseline.md           which model generation the config is tuned for
  asking-for-improvements.md  the prompts that make this repo better
  adoption.md                 how an app repo consumes the base
  decisions/                  ADRs, numbered and immutable once accepted
evals/                        behavioural tests for the skills
templates/
  flutter-app/                what gets copied into an app repo
```

## Getting started

- **Setting up a new Flutter app:** see [docs/adoption.md](docs/adoption.md).
- **Changing the base:** read [CLAUDE.md](CLAUDE.md) first, then run `/audit-agent-config`
  before committing.
- **Unsure what a term means:** [docs/vocabulary.md](docs/vocabulary.md).
- **A new model shipped:** run `/model-upgrade <model-id>`; see
  [docs/asking-for-improvements.md](docs/asking-for-improvements.md) for the other prompts
  that keep this repo effective.
- **Testing the skills:** `claude plugin eval . --no-publish`; see [evals/README.md](evals/README.md).

## Status

The Flutter stack is deliberately undecided — every choice in
`templates/flutter-app/CLAUDE.md` is marked `TBD` and closed explicitly rather than assumed.
See [ADR 0002](docs/decisions/0002-stack-choices-stay-open-until-decided.md).
