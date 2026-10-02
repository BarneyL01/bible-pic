# Model baseline

The model generation this configuration was last calibrated against, and what that
calibration assumed. `/model-upgrade` updates this file; nothing else should.

| Field | Value |
| --- | --- |
| Calibrated against | `claude-fable-5-1` (Claude Fable 5.1) |
| Calibration date | 2026-09-15 |
| Claude Code version at calibration | 2.1.272 |
| Calibrated by | `/model-upgrade` initial run, from the Claude Fable 5.1 migration notes |
| Evals last run | never — see `evals/README.md` |

## Documented behaviours this configuration relies on

Each row is a behaviour of the calibrated model that an instruction in this repo either
compensates for or depends on. When a new model ships, these are the claims to re-test —
not the whole configuration.

| Behaviour | Source | Instructions that depend on it |
| --- | --- | --- |
| Reports progress it cannot point to evidence for, on long runs, unless told to audit claims against tool results | Fable 5.1 migration notes, "Ground progress claims" | `Verify before claiming` in both `CLAUDE.md` files |
| At higher effort, adds unrequested refactors, extra tests, and adjacent fixes | Fable 5.1 notes, "Scope and test coverage" | `Scope` in `templates/flutter-app/CLAUDE.md` |
| Answers from memory about named tools and packages it recognises, even when its knowledge is stale — more so at low effort | Fable 5.1 notes, "Search triggering at low effort" | `Packages and APIs` in `templates/flutter-app/CLAUDE.md` |
| Can end a turn by describing the next step instead of doing it, deep into long sessions | Fable 5.1 notes, "Maximizing long-horizon execution" | `Finish the turn` in `templates/flutter-app/CLAUDE.md` |
| Performs better with a place to write lessons for future sessions | Fable 5.1 notes, "Give it a memory surface" | `Lessons` in `templates/flutter-app/CLAUDE.md` |
| Follows explicit instructions closely; emphasis markers and repetition cause over-triggering | Prompt-audit guide, group 1a | Rubric criterion M1 |
| Plans without being told; step-by-step scripts for judgment work reduce output quality | Prompt-audit guide, group 1c; Fable 5.1 "De-prescribe migrated prompts" | Rubric criterion M3 |
| Under-formats and under-narrates relative to prior generations | Fable 5.1 notes, "Formatting", "User-facing progress updates" | No anti-formatting or no-narration rules anywhere in this repo (M5 checks this stays true) |
| Parallel sub-agents are dependable; suppressing delegation is a prior-generation guardrail | Fable 5.1 notes, "Let it delegate" | No delegation-suppressing rule anywhere in this repo |

## Platform features in use

| Feature | Where | Since |
| --- | --- | --- |
| Skill `when_to_use` frontmatter (trigger text separated from description) | every `SKILL.md` | 2026-09-15 |
| Skill `disable-model-invocation` (task skills load only on `/name`) | audit, adopt, stack-decide, model-upgrade | 2026-09-15 |
| HTML comments in `CLAUDE.md` stripped before injection (zero-cost provenance tags) | both `CLAUDE.md` files | 2026-09-15 |
| `claude plugin eval` suite | `evals/` | 2026-09-15 |
| Auto memory (`~/.claude/projects/<project>/memory/`) | relied on, not configured | default |

## Platform features considered and not adopted

| Feature | Why not yet | Revisit when |
| --- | --- | --- |
| `.claude/rules/` with `paths:` scoping | No app code exists to scope rules to | First app adopts the base |
| `PreToolUse` hook enforcing the pre-commit checks | Owner chose settings-only infrastructure (ADR 0003) | Prose rule is observed to be skipped |
| `context: fork` for the audit skill | Audit needs the conversation's context to know what changed | Audit runs get long enough to pollute the main context |
