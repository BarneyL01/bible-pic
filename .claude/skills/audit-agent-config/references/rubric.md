# Rubric: what good agent configuration looks like

Used by `/audit-agent-config`. Also the authoring standard — write new instructions so they
would pass this on the first run.

## Part 1 — CLAUDE.md files

### C1. Accuracy (blocking when violated)
Every path, command, file name, and cross-reference resolves. A stale path is worse than no
path: it sends the agent to the wrong place with confidence.

### C2. Specificity
An instruction must be checkable. A reviewer reading the diff should be able to say "followed"
or "not followed" without interpretation.

| Fails | Passes |
| --- | --- |
| "Write clean, maintainable code." | "Keep widget build methods under 50 lines; extract sub-widgets beyond that." |
| "Test thoroughly." | "Every new public function in `lib/` gets a unit test in the mirrored path under `test/`." |
| "Follow Flutter best practices." | "Prefer `const` constructors; `flutter analyze` must report zero issues." |

Flag any instruction containing *properly*, *appropriately*, *as needed*, *best practices*,
*clean*, *robust*, or *where relevant* unless the surrounding sentence makes the criterion
concrete.

### C3. No duplication
The same rule stated in two places will drift. Each rule lives in exactly one file. If
`CLAUDE.md` and a skill both cover it, the skill wins and `CLAUDE.md` drops it.

### C4. No contradictions
Two instructions that cannot both be satisfied is a blocking finding. Check especially across
the root `CLAUDE.md` and `templates/flutter-app/CLAUDE.md`, which are edited at different
times for different audiences.

### C5. Length discipline
`CLAUDE.md` is loaded on every turn. Budget:

| Lines | Verdict |
| --- | --- |
| under 100 | healthy |
| 100-200 | justify each section; look for content that should be a skill |
| over 200 | should-fix — move task-specific guidance into skills |

Length alone is not a finding; length plus content that only matters for one task type is.

### C6. Earns its place
Would a competent engineer unfamiliar with this repo do the wrong thing without this line? If
no, the line is noise. Restating language defaults, generic advice, or things the tooling
already enforces all fail this test.

### C7. Placeholders are honest
A `TBD` must say what is undecided and who decides it. A `TBD` silently replaced by an
assumed default is a blocking finding — it converts an open question into a fake decision.

## Part 2 — Skills

### S1. Frontmatter validity (blocking)
- `name` present, kebab-case, and identical to the containing directory name.
- `description` present and non-empty.
- No unrecognised keys.

### S2. Description quality
The description is the only thing that decides whether the skill ever loads. It must contain
both halves:

1. **What it does** — third person, one clause.
2. **When to use it** — the concrete phrases and situations that should trigger it, including
   `Also use when the user invokes /skill-name.` for slash-invocable skills.

| Fails | Passes |
| --- | --- |
| "Helps with Flutter stuff." | "Scaffold a new Flutter feature module with its route, state, and test files. Use when the user asks to add a feature, screen, or page to the app. Also use when the user invokes /new-feature." |

Flag a description under 20 words, or one with no trigger clause, as should-fix.

### S3. Trigger distinctness
No two skills should match the same request. Compare descriptions pairwise; overlapping
triggers mean the wrong skill loads roughly half the time. Overlap is a should-fix with the
fix being a narrowed description on one of them, not a deletion.

### S4. Body is procedure, not preamble
The body tells the agent what to do, in order. Flag:
- Motivational framing longer than two sentences.
- Explanations of what the skill is for, already in the description.
- Lists of what the skill will not do, beyond one short scope section.

### S5. Referenced files exist (blocking)
Every `references/*`, `scripts/*`, or asset the body mentions is present in the skill
directory, and every script is executable.

### S6. Progressive disclosure
Keep `SKILL.md` under about 150 lines. Detail that is only needed sometimes goes in
`references/` and is loaded on demand. A skill body that has to be read in full every time it
loads is paying its full cost on every trigger.

### S7. Evidence of use
A skill that has never been invoked and whose triggers no longer describe real work is a
candidate for deletion — report it, ask before removing.

## Part 3 — Repository-level

### R1. Vocabulary coverage
Project-specific terms used in instructions are defined in `docs/vocabulary.md`. Terms defined
there but used nowhere are also a finding — either the term is dead or the instructions are
missing it.

### R2. Decision traceability
Instructions that encode a choice (a library, a layout, a workflow) cite an ADR in
`docs/decisions/`. An instruction with no recorded reasoning cannot be revisited safely.

### R3. Template parity
`templates/flutter-app/` is audited as live instructions, not as inert examples. A defect
there propagates to every downstream app.

### R4. Permission hygiene
`.claude/settings.json` allow-rules cover the commands the instructions actually tell the
agent to run — otherwise every run generates prompts. Deny-rules cover destructive and
secret-reading operations. Flag an allow-rule for a command no instruction uses.

## Severity assignment

| Severity | Meaning |
| --- | --- |
| **blocking** | The agent will do the wrong thing: broken path, contradiction, invalid frontmatter, missing referenced file, fake decision. |
| **should-fix** | The agent will do worse work or waste context: vagueness, duplication, weak description, overlong file. |
| **nit** | Style, ordering, or wording with no behavioural effect. |

## Part 4 — Model fit

Instructions are per-model artifacts. These criteria catch text written for a model that is
no longer the one reading it. They are grounded in the prompt-audit guidance shipped with the
`claude-api` skill and the Claude Fable 5.1 migration notes; when either updates, this part is
re-derived by `/model-upgrade`.

### M1. Pressure language
Density of `MUST`, `NEVER`, `ALWAYS`, `CRITICAL`, `IMPORTANT` in capitals, `!!`, or emphasis
with no adjacent reason. Current models follow instructions closely; inflated emphasis causes
over-triggering and a hedging register. One scoped, reasoned emphasis is fine; a pattern of
them is a should-fix. Trigger text (`description`, `when_to_use`) is exempt — routing text
may carry calibrated urgency.

### M2. Dated scaffolds
"Think step by step", `<scratchpad>` or `<thinking>` tag instructions, "plan before acting",
"summarise progress every N tool calls", numeric output caps (`at most N words`) — techniques
now native to the model or replaced by configuration (`effort`). Should-fix; the fix is
deletion or an `effort` setting in the skill's frontmatter.

### M3. Over-prescription
Numbered `STEP 1 … STEP N` choreography for work that needs judgment, prohibition lists with
no reason beside each line, strategy coaching ("it is usually best to…"). Current models plan
better than a hand-written script for open-ended work. Keep exact sequences only where
exactly one order is safe (destructive commands, auth, migrations). Otherwise state the goal,
the constraints, and how to verify.

### M4. Provenance present (blocking when absent on a compensation)
Every instruction that exists because a model misbehaved carries a provenance tag naming the
category, the model generation, and a retest probe:

```
<!-- provenance: compensation@claude-fable-5-1 | retest: <one-line probe> -->
```

Categories: `compensation` (model behaviour — re-tested every generation), `environment`
(fact about the world — re-checked when the environment changes), `preference` (owner's
choice — retired only by the owner), `contract` (tool or skill mechanics — changes with the
tool). An instruction with no tag is graded by the auditor as one of the four and the tag
proposed. HTML comments are stripped from `CLAUDE.md` before injection, so tags cost no
context there.

### M5. Fossils
Retired model names, migration-relative phrasing ("now works differently", "no longer",
"instead of"), anti-formatting rules ("never use bullets"), update suppressors ("don't
narrate", "hold findings for the end"), reminders re-inserted on a cadence. Each of these
was tuned against a behaviour a current model does not have, and several invert on Claude
Fable 5.1 (which under-formats and under-narrates). Should-fix: remove, or replace with a
rule that says when the behaviour is wanted.

### M6. Enforceable in code, written as prose
A rule that must fire at a fixed point ("before every commit run X", "never write to
`android/key.properties`") is more reliable as a hook, a permission deny-rule, or a schema
check than as an instruction. Nit unless the rule is observed being skipped, then should-fix
with the mechanism named. Owner's infrastructure choices (ADR 0003) decide whether to act.

### M7. Platform features unused
A frontmatter field, settings key, or hook event that would replace prose in this repo and
that shipped after the baseline's calibration date. Reported by `/model-upgrade`; the audit
only checks that `docs/model-baseline.md` lists a decision for each one it names.

## What not to flag under Part 4

Context is never cruft: audience, environment facts, quality bar, and the reasons behind
constraints stay however long they are. A verification instruction ("do not report a test
as passing unless you ran it") stays on Claude Fable 5.1 — the migration notes say so
explicitly. Working redundancy that does not disagree with itself is a refactoring
preference, not a finding. An audit that finds nothing changes nothing.
