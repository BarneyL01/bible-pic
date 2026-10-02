# 0004. Every compensating instruction carries its provenance, and a new model triggers recalibration

- **Status:** Accepted
- **Date:** 2026-09-15
- **Deciders:** repository owner

## Context

Instructions in a `CLAUDE.md` or skill exist for different reasons: some compensate for a
behaviour of the model generation they were written against, some record facts about the
environment, some are the owner's preferences, some describe how a tool works. Only the
first kind becomes wrong when a new model ships — but without a record of which kind each
instruction is, a reviewer cannot tell a load-bearing rule from a fossil, and the safe move
is always to keep everything. Configurations therefore accumulate the union of every
generation's workarounds, and the prompt-audit guidance for current models documents that
this accumulated text degrades output rather than merely wasting tokens.

Claude Code strips block-level HTML comments from `CLAUDE.md` before injection, so a tag
placed in a comment costs no context.

## Decision

Every instruction is tagged with an HTML comment of the form
`<!-- provenance: <category>[@<model-id>] | retest: <probe> -->`, where the category is one
of `compensation`, `environment`, `preference`, or `contract`. A `compensation` names the
model generation it was written against and a one-line probe that would show whether it is
still needed.

A new model generation triggers `/model-upgrade`, which re-tests every `compensation`,
proposes additions for the new model's documented failure modes, runs the eval suite pinned
to the new model, and records the result in `docs/model-baseline.md` and an ADR. It proposes
a diff; it does not apply one without the owner's say-so.

## Consequences

- A compensation with no tag is a blocking audit finding (rubric M4).
- `preference` instructions are never removed by a model change; only the owner retires them.
- The baseline file is the single place that says which model the configuration is tuned
  for; disagreement between it and the tags is drift.
- Tags in `SKILL.md` files are not stripped and cost a few tokens per invocation; accepted for
  uniformity of the convention.

## Alternatives considered

| Option | Why not |
| --- | --- |
| A separate register file mapping instructions to provenance | Drifts from the instructions it describes; nothing keeps them in step. |
| Frontmatter `metadata` on skills only | Leaves `CLAUDE.md` instructions untagged, which is where most compensations live. |
| Re-audit the whole configuration on every model release | Cannot distinguish a preference from a compensation; produces a length contest instead of a fit check. |
