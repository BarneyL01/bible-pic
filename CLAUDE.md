# agent-base

Reusable Claude Code configuration for Flutter applications targeting **web** and **Android**.

This repository ships agent configuration, not application code. Its output is copied into
Flutter app repositories via the `/adopt-base` skill. `README.md` has the file layout;
`docs/vocabulary.md` has the terms; `docs/model-baseline.md` says which model generation the
configuration is tuned for.

<!-- Provenance tags in this file are HTML comments: Claude Code strips them before injection,
     so they cost no context. Format and categories: rubric criterion M4. -->

## What lives here — and what does not

<!-- provenance: preference | ADR 0001 -->

| Belongs in this repo | Does not belong here |
| --- | --- |
| Base instructions (`templates/flutter-app/CLAUDE.md`) | `lib/`, `pubspec.yaml`, `android/`, `web/` |
| Skills under `.claude/skills/` | Application widgets, tests, or assets |
| Shared permission defaults (`.claude/settings.json`) | App secrets, keystores, signing config |
| Vocabulary, decisions, baseline under `docs/` | Per-app build output |
| Eval cases under `evals/` | |

If a change only makes sense for one app, it belongs in that app's repo, not here.

## Working rules

### Vocabulary is binding
<!-- provenance: preference | the owner's stated requirement -->
`docs/vocabulary.md` defines the terms used across this repo. Use those terms exactly — in
prose, file names, skill names, and commit messages. When a new term is agreed in
conversation, record it with the `/vocabulary` skill before the session ends. When a term
in `docs/vocabulary.md` no longer matches reality, fix the document rather than working
around it.

### Placeholders stay visible
<!-- provenance: preference | ADR 0002 -->
`templates/flutter-app/CLAUDE.md` deliberately contains `TBD` markers for undecided stack
choices. Do not fill them with defaults. An undecided choice is resolved by
`/flutter-stack-decide`, which asks the user and records an ADR. If you encounter a `TBD`
while doing other work, stop and ask rather than assuming.

### Instructions must be checkable
<!-- provenance: contract | rubric C2; the Claude Code memory docs give the same rule -->
Every instruction written into a `CLAUDE.md` or a skill must be specific enough that a
reviewer can tell whether it was followed. Prefer "run `dart format --set-exit-if-changed .`
before committing" over "keep formatting tidy". Vague guidance is a finding for
`/audit-agent-config`.

### Every compensation carries its provenance
<!-- provenance: contract | ADR 0004; rubric M4 -->
An instruction that exists because a model generation misbehaved is tagged with an HTML
comment naming the category, the model, and a retest probe:

```
<!-- provenance: compensation@claude-fable-5-1 | retest: <one-line probe> -->
```

Categories are `compensation`, `environment`, `preference`, and `contract`; the rubric
defines them. Tag new instructions when you write them. `/model-upgrade` re-tests every
`compensation` when a new model ships; an untagged one is invisible to it.

### Skills over prose
<!-- provenance: contract | CLAUDE.md loads every turn; skills load on trigger -->
When guidance is only needed for one kind of task, write it as a skill, not as a paragraph
here. See `.claude/skills/audit-agent-config/references/rubric.md` for the authoring rules
that apply to both. Task skills that should run only when the user asks set
`disable-model-invocation: true`; trigger phrasing goes in `when_to_use`, not `description`.

### Changes to the base are versioned decisions
<!-- provenance: preference -->
A change to `templates/flutter-app/` alters the instructions every downstream app receives.
Record the reasoning as an ADR in `docs/decisions/` when the change is a choice rather than
a correction.

### Verify before claiming
<!-- provenance: compensation@claude-fable-5-1 | retest: ask for a status summary mid-task and
     check each claim against a tool result; the migration notes say keep this on 5.1 -->
Report only work you can point to a tool result for. The Flutter SDK is **not** installed in
Claude Code cloud containers, so `flutter` and `dart` commands fail there; in a cloud session
a Flutter check is **unverified**, and the summary says so.

## Commands

| Task | Command |
| --- | --- |
| Audit agent config | `/audit-agent-config [--fix] [path]` |
| Recalibrate for a new model | `/model-upgrade [model-id]` |
| Run the eval suite | `claude plugin eval . --no-publish` |
| Record an agreed term | `/vocabulary` |
| Install the base into an app repo | `/adopt-base` |
| Resolve TBD stack choices | `/flutter-stack-decide` |
