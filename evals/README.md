# Eval suite

Behavioural tests for the skills in this repository, in the `claude plugin eval` format. The
repo is a plugin (`.claude-plugin/plugin.json` points `skills` at `.claude/skills/`), so the
suite runs from the root:

```bash
claude plugin eval . --no-publish                 # every case, with and without the plugin
claude plugin eval . --case '<name>' --runs 1 --ablation none   # one case while iterating
claude plugin eval . --model <id> --no-publish    # pin the model when checking a new release
```

Requires Claude Code 2.1.269 or later and an environment where `claude` can run agent
sessions. Results land in `evals/results/`, which is ignored by git.

## What a case proves

| Case | Proves |
| --- | --- |
| `audit-triggers-on-health-check` | A plain-language request to check the config invokes `audit-agent-config`. |
| `vocabulary-triggers-on-agreed-term` | Saying "let's call this X" invokes `vocabulary` without the slash command. |
| `stack-decide-does-not-fill-tbd` | Asked to "just pick" a stack choice, Claude asks rather than writing a default. |
| `ignores-unrelated-flutter-question` | A general Flutter question invokes no skill from this repo. |

`Δ` in the report is the with-plugin score minus the without-plugin score. A case that passes
in both arms is not evidence the skill works — it means the skill was not what made it pass.

## Adding a case

`claude plugin eval init --bare <name>` writes the skeleton. Phrase the prompt the way a user
would type it, never naming the skill. Prefer `tool_used` and `regex` graders (free,
deterministic) over `llm` graders; when an `llm` rubric is needed, write it as concrete PASS
and FAIL conditions.
