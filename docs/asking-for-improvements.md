# Asking this repo to get better

The configuration does not improve on its own. These are the requests that move it, grouped by
what triggers them. Each is a prompt to type as written; the skill or command it maps to is
named so you can call that directly instead.

## When a new model ships

| Ask | What happens | Maps to |
| --- | --- | --- |
| "A new model is out — recalibrate the base for `<model-id>`." | Every `compensation` instruction is re-tested, missing guidance for the new model's documented failure modes is proposed, evals run pinned to the new model, `docs/model-baseline.md` and an ADR are updated. | `/model-upgrade <model-id>` |
| "Which of our instructions only exist because an older model misbehaved?" | Lists every `compensation`-tagged instruction with its model and retest probe. | `grep -rn "provenance: compensation"` or `/model-upgrade` step 1 |
| "What has changed in Claude Code since we last calibrated that we're not using?" | Reads the changelog since the baseline date, reports each feature with a proposed use or a reason to skip, records the decision in the baseline. | `/model-upgrade` (platform features section) |
| "Audit our prompts for patterns written for older models." | The prompt-audit guide from the `claude-api` skill is run over every `CLAUDE.md` and `SKILL.md`: report plus proposed diff, nothing applied. | `/claude-api prompt-audit` when that skill is installed; otherwise `/audit-agent-config` Part 4 |
| "Run the evals against `<model-id>` and tell me what regressed." | Suite runs with `--model` pinned; the report shows with/without scores per case. | `claude plugin eval . --model <model-id> --no-publish` |

## When the configuration feels stale or is being ignored

| Ask | What happens | Maps to |
| --- | --- | --- |
| "Is the config still accurate?" / "Health-check the agent setup." | Paths, commands, and cross-references are verified; vagueness, duplication, and model-fit findings are tabled with severities and fixes. | `/audit-agent-config` |
| "Fix the safe findings." | Applies broken-reference, contradiction, and duplication fixes; asks before anything that touches a `TBD`, an accepted ADR, or a skill's existence. | `/audit-agent-config --fix` |
| "Claude keeps ignoring rule X." | Check whether X is checkable (rubric C2); if it must fire at a fixed point, it is a hook candidate (rubric M6). Ask for the hook to be proposed as a diff. | `/audit-agent-config` then `/update-config` |
| "Trim CLAUDE.md." | Claude Code's own doctor proposes cuts of content derivable from the codebase. | `/doctor` |
| "Which skill never fires?" | The eval suite's `Δ` column: a skill whose cases pass without the plugin is not earning its trigger. | `claude plugin eval .` |

## When a skill is added or changed

| Ask | What happens | Maps to |
| --- | --- | --- |
| "Write a skill for `<task>`." | Author against the rubric: description says what, `when_to_use` says when, task skills set `disable-model-invocation: true`, detail goes under `references/`. | rubric Part 2; `anthropic-skills:skill-creator` for evals and description tuning |
| "Does `<skill>` trigger when it should?" | Add should-trigger and should-not-trigger cases, run them, tune `when_to_use` against the result rather than against intuition. | `claude plugin eval init`, then `claude plugin eval . --case <name>` |
| "Two skills overlap." | Rubric S3: narrow one description; never delete to resolve overlap. | `/audit-agent-config` |

## When a decision is made or a word is agreed

| Ask | What happens | Maps to |
| --- | --- | --- |
| "Let's call this X." / "From now on X means Y." | Entry written to `docs/vocabulary.md`; a redefinition greps the repo for stale uses. | `/vocabulary` (fires without the slash) |
| "Pick the state management / router / …" | Options with trade-offs, your decision, an ADR, and a checkable instruction replacing the `TBD`. | `/flutter-stack-decide <concern>` |
| "Why did we decide X?" | The ADR in `docs/decisions/`; if there is none, that is a finding under rubric R2. | `ls docs/decisions/` |

## When something went wrong in a session

| Ask | What happens | Maps to |
| --- | --- | --- |
| "Remember that `<correction>`." | In an app repo, goes to `docs/lessons.md` (travels with the repo) and to auto memory (machine-local). In this repo, a correction that is really a rule goes to `CLAUDE.md` with a provenance tag. | template `Lessons` rule; `/memory` |
| "Turn that lesson into a rule." | Rubric's recency-trap check first: would it have helped most recent sessions, or only the one that wrote it? If the former, it becomes a tagged instruction; if the latter, it stays a lesson. | `/audit-agent-config` |

## What to expect back

Every one of these produces a report before any change, and a proposed diff you can take hunk
by hunk. A run that finds nothing says so in one line and changes nothing.
