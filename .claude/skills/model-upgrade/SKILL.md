---
name: model-upgrade
description: Recalibrate this repository's agent configuration for a newly released model generation, by re-testing every instruction that compensates for a prior model's behaviour, checking for platform features the configuration does not yet use, running the eval suite, and recording the result in docs/model-baseline.md.
when_to_use: Use when a new Claude model or Claude Code version has shipped, when the user asks whether the configuration is still tuned for the current model, asks what has changed in LLMs that this repo should exploit, or asks to remove outdated prompting patterns. Also use when the user invokes /model-upgrade.
argument-hint: "[target-model-id]"
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Bash(git log:*), Bash(git blame:*), Bash(grep:*), Bash(claude plugin eval:*), WebFetch(domain:docs.claude.com), WebFetch(domain:code.claude.com), WebFetch(domain:platform.claude.com)
---

# Model upgrade

An instruction written for one model generation is either still needed, dead weight, or
actively harmful on the next. Nobody owns removal by default, so configurations accumulate
the union of every generation's workarounds. This skill makes removal owned: every
compensation is re-tested against the new model, and the outcome is recorded.

Read `docs/model-baseline.md` first — it says what the current calibration assumed.

## Outcome

Three deliverables, all of them, in this order:

1. **A report** — every instruction tagged `compensation` in this repo, with the re-test
   result on the target model: `still needed`, `no longer needed`, or `untested` with the
   reason. Plus new platform features the configuration could use, and the eval results.
2. **A proposed diff** — one hunk per finding. Propose; apply only when the user says so.
3. **An updated `docs/model-baseline.md`** and a new ADR recording what changed and why.

## Establishing the target

The target model is `$ARGUMENTS` if given; otherwise the model serving this session (ask
`get_session` if available, else `claude --version` and the session banner). State it at the
top of the report.

Read the target's migration notes before forming any opinion. In order of authority:

- the `claude-api` skill's `shared/model-migration.md` (section for the target) and
  `shared/prompt-audit.md`, when that skill is available in the session;
- `https://docs.claude.com` model migration and prompting pages for the target;
- `https://code.claude.com/docs/en/changelog` for Claude Code features shipped since the
  baseline's calibration date.

Where none of these documents a behaviour, say so — do not infer it from the model's name.

## Re-testing compensations

Every instruction with a provenance tag of `compensation` carries a `retest:` probe. Run
the probe, or describe exactly why it cannot be run here (no Flutter SDK, no app repo
checked out). A probe you did not run is `untested`, never `still needed` by default.

```bash
grep -rn "provenance: compensation" --include="CLAUDE.md" --include="SKILL.md" .
```

An instruction whose tagged model is two or more generations behind the target, with no
retest recorded since, is presumptively removable — but removal is a hypothesis: propose the
removal in the diff and name the probe that would confirm it.

Instructions tagged `environment`, `preference`, or `contract` are not re-tested by a model
change. Leave them alone unless the migration notes say the platform mechanism they rely on
changed.

## Finding missing text, not only dead text

Recalibration adds guidance as often as it removes it. For the target, check the migration
notes' "behavioural shifts" against `templates/flutter-app/CLAUDE.md` and this repo's
`CLAUDE.md`: a documented failure mode of the new model with no instruction addressing it is
a finding with action `add`, and the fix is the migration notes' own recommended wording,
cited.

Check the platform side the same way: a Claude Code feature shipped since the calibration date
that would replace prose with mechanism (a frontmatter field, a hook event, a settings key)
goes in the report under *Platform features*, with a proposed use or a stated reason to skip.
Record both outcomes in the baseline's feature tables.

## Running the evals

```bash
claude plugin eval . --model <target-model-id> --no-publish
```

Pin `--model` to the target so a rollout is not mistaken for a configuration regression. A
case that passes with the plugin and without it (`Δ` of zero) means the skill is not what
made it pass — report that; it is evidence the skill's trigger or body is not earning its
place on this model. If `claude plugin eval` is unavailable in the environment, say so and
mark the eval row in the baseline as not run.

## Recording the result

- `docs/model-baseline.md`: update the calibration table, rewrite the behaviours table to
  match what the target's notes document, and move any compensation found unnecessary out of
  the "instructions that depend on it" column.
- `docs/decisions/NNNN-recalibrate-for-<model>.md`: what was removed, what was added, what
  stayed untested and why. One ADR per upgrade.
- Terms the new generation introduces (a new effort level, a new tool) go through
  `/vocabulary`.

## Boundaries

- Do not remove an instruction tagged `preference` on the grounds that the model no longer
  needs it. Preferences are the owner's; only the owner retires them.
- Do not apply the diff without the user's say-so. The report and the proposed diff are the
  deliverable of an unattended run.
- A retest that regresses is re-added in its minimal form, not restored verbatim.
