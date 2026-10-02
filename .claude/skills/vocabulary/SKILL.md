---
name: vocabulary
description: Record, amend, or retire a project term in docs/vocabulary.md so the same word means the same thing in every conversation, file, and commit.
when_to_use: Use when a term is agreed or redefined in conversation, when the user says "let's call this X" or "from now on X means Y", when a word is being used two different ways, or when asked what a project term means. Also use when the user invokes /vocabulary.
argument-hint: "[term]"
---

# Vocabulary

`docs/vocabulary.md` is the shared language for this project. A term that lives only in a
conversation is lost when the session ends; a term recorded there survives into every future
session as loaded context.

## When a term is agreed

1. **Check it is not already there.** `grep -in "<term>" docs/vocabulary.md`. If present with
   a different meaning, that is a redefinition — go to *When a term changes*.
2. **Write the entry** in the table, alphabetically within its section:

   | Term | Definition | Notes |

   - **Definition** — one sentence, stating what the thing *is*, not what it is for.
   - **Notes** — the distinction that makes the term necessary: what it is commonly confused
     with, or the ADR that established it.
3. **Confirm the wording with the user** before committing if the term encodes a decision
   rather than a naming convention.

## When a term changes

Never edit a definition in place and move on. Either:

- **Amend** — the meaning was always this, the wording was wrong. Edit and say so.
- **Supersede** — the meaning genuinely changed. Update the definition, add the old meaning to
  the Notes column prefixed `Formerly:`, and grep the repo for uses of the old sense:

  ```bash
  grep -rn "<term>" --include="*.md" --include="*.json" . | grep -v "^./docs/vocabulary.md"
  ```

  Fix each hit, or list them for the user. A redefinition that leaves stale uses behind is
  worse than no definition.

## When a term is retired

Move it to the **Retired** section at the bottom with a one-line reason and what replaced it.
Do not delete it — someone will find the old word in an old commit and need to know.

## Rules

- **Terms, not glossary filler.** Define a word only when it is used in a specific way here.
  If `docs/vocabulary.md` would define it the same way a dictionary does, leave it out.
- **One definition per term.** If a word is genuinely used two ways, that is the finding —
  raise it and pick two words.
- **Match the repo.** After writing an entry, the word must be used that way everywhere. The
  document describes the repo; it does not aspire.
- **Use the terms.** Once defined, use the exact term in prose, file names, skill names, and
  commit messages, including in this conversation.
