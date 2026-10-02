---
name: audit-agent-config
description: Audit every CLAUDE.md and skill in this repository for staleness, vagueness, duplication, broken references, weak trigger descriptions, and text written for an older model, then report findings and optionally fix them.
when_to_use: Use when the user asks to review, audit, health-check, or clean up the agent configuration, asks whether CLAUDE.md or the skills are still accurate or effective, or after a batch of changes to .claude/ or docs/. Also use when the user invokes /audit-agent-config.
argument-hint: "[--fix] [path]"
disable-model-invocation: true
allowed-tools: Read, Glob, Grep, Bash(find:*), Bash(ls:*), Bash(grep:*), Bash(wc:*), Bash(git log:*), Bash(git blame:*)
---

# Audit agent configuration

Agent configuration decays silently. Paths move, commands get renamed, instructions
accumulate, and a skill that never triggers costs nothing to keep and everything to rely on.
This skill finds that decay and reports it as a fixable list.

Read `references/rubric.md` before auditing. It is the checklist; this file is the procedure.

## Arguments

| Argument | Effect |
| --- | --- |
| *(none)* | Audit everything, report only. |
| `--fix` | Apply the findings you are confident about, then re-report with outcomes. |
| a path | Audit only that file or directory. |

## Procedure

### 1. Inventory

Collect the full set of targets before reading any of them:

```bash
find . -path ./.git -prune -o -name "CLAUDE.md" -print -o -name "SKILL.md" -print | sort
ls docs/ docs/decisions/ 2>/dev/null
```

Include `templates/` — those files become live instructions in downstream app repos, so
they are audited to the same standard as the ones governing this repo.

### 2. Verify claims against reality

This is the part that cannot be done by reading alone. For each file, extract the concrete
claims and check them:

- **File and directory paths** mentioned in prose — does each one exist? Flag every path that
  does not resolve.
- **Commands** presented as runnable — is the binary available, and does the command shape
  match the tool's actual interface? If the toolchain is absent (see *Environment
  constraints* in the root `CLAUDE.md`), say the claim is **unverified**, not that it passes.
- **Skill cross-references** — does `/some-skill` exist as a directory under `.claude/skills/`?
- **Links** to files in this repo — do they resolve?
- **Terms** used in `CLAUDE.md` or any `SKILL.md` — is each defined in `docs/vocabulary.md`?
  Undefined project-specific terms are a finding; general software English is not.
- **ADR references** — does every cited `docs/decisions/NNNN-*.md` exist, and does its status
  still match how the instruction talks about it?

Paths inside fenced code blocks that illustrate a format, and paths containing `NNNN`, `<`,
or `>`, are placeholders — do not report them as broken. Paths inside `templates/` resolve
against the app repo that adopts the template, not against this one. A placeholder that does not follow
one of those conventions is itself a finding: make it obviously a placeholder.

### 3. Grade against the rubric

Apply `references/rubric.md` to each file. Record every finding with:

- severity — **blocking**, **should-fix**, or **nit**
- `file:line`
- the specific defect, quoted
- the concrete fix

Do not report a finding you cannot state a fix for. "This section feels long" is not a
finding; "lines 40-58 restate the Flutter test command already given at line 12 — delete the
second copy" is.

### 4. Report

Output one table, blocking first:

| Severity | Location | Finding | Fix |
| --- | --- | --- | --- |

Then a short verdict paragraph: what is healthy, what is the single most valuable change.

If there are no findings, say so plainly in one line and stop. Do not manufacture findings
to justify the run.

### 5. Fix (only with `--fix`)

Apply findings in this order: broken references, then contradictions, then duplication, then
vagueness. After each edit, re-run the relevant verification from step 2 to confirm the fix
holds.

**Never apply without asking:**
- Deleting a skill outright.
- Resolving a `TBD` placeholder — that is `/flutter-stack-decide`'s job and needs the user.
- Changing an ADR whose status is `Accepted` — supersede it with a new ADR instead.
- Rewording an instruction where you cannot tell which of two readings the user intended.

Re-report the table afterwards with an outcome column: `fixed`, `skipped`, or `needs-user`.

## Scope boundaries

- This skill audits configuration, not application code. Flutter source quality belongs to
  `/code-review`.
- Findings about a downstream app's own `CLAUDE.md` are reported, not fixed, unless that app
  repo is the working directory.
