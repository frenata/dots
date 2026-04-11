---
name: jfdi
description: Lightweight exploratory workflow for solo engineers. Subcommands: init, think, adr, status.
argument-hint: <init|think|adr|status> [args]
disable-model-invocation: true
allowed-tools: Read Write Bash(mkdir *) Bash(ls *) Bash(date *) Bash(wc *) Bash(jj *)
---

Route to the appropriate subcommand based on `$0`.

---

## init

Set up JFDI in this project.

1. Create `.dev/adr/`, `.dev/log.md`, `.dev/context.md`

2. Seed `.dev/log.md`:
```
# Work Log

## !`date +%Y-%m-%d`

```

3. Seed `.dev/context.md`:
```markdown
# Current Focus

_What are you working on right now?_

## Open Questions

_Things you haven't decided yet._

## Constraints

_Hard limits: technical, time, scope._

## Next Actions

_Concrete next steps, max 5._
```

4. Append to `.claude/CLAUDE.md` (create if missing):
```markdown
## Project Context

This project uses JFDI for decision tracking.

- `.dev/context.md` — current focus, open questions, next actions
- `.dev/adr/` — architecture decisions and their rationale
- `.dev/log.md` — append-only work log

Read `.dev/context.md` at the start of any work session. When making implementation choices that touch recorded decisions, cite the relevant ADR.
```

5. Confirm what was created.

---

## think

Argument: `$1` — topic or question to explore.

Exploratory reasoning session before any decision is locked.

1. Read `.dev/context.md` and any relevant ADRs in `.dev/adr/`
2. Ask 1–3 pointed questions to understand the problem space — conversational, not a form. Pick the most important unknown first.
3. Present 2–3 concrete approaches with honest tradeoffs.
4. Flag any assumptions being made.
5. End with: "Want to record this as an ADR, or keep exploring?"

**Role: thinking partner, not decision-maker.**
- Present tradeoffs without steering toward one
- Surface consequences framed as "worth knowing" — not "therefore do X"
- Name real gotchas without using them to make the choice
- Do not recommend a specific option unless explicitly asked

Do not generate code, write a spec, or ask for acceptance criteria.

---

## adr

Argument: `$1` — short title for the decision.

Record an Architecture Decision.

1. If a `think` session just happened in this conversation, offer to pre-fill from that context.
2. Auto-number: `ls .dev/adr/ 2>/dev/null | wc -l`, zero-pad to 3 digits.
3. Create `.dev/adr/NNN-slugified-title.md` using the template below.
4. Append a one-line entry to `.dev/log.md`: `- ADR-NNN: [title]`
5. If this resolves an open question in `.dev/context.md`, remove it.

**Template:**
```markdown
# ADR-NNN: [Title]

**Date:** YYYY-MM-DD
**Status:** accepted

## Context

What situation or problem prompted this decision?

## Decision

What did we decide to do?

## Rationale

Why this over the alternatives? What made this the right call right now?

## Tradeoffs

What are we giving up? What could bite us later?

## Alternatives Considered

- **[Option A]:** why rejected
- **[Option B]:** why rejected
```

Status options: `accepted` | `superseded by ADR-NNN` | `deprecated` | `experimental`

**Example:**
```markdown
# ADR-001: Use SQLite

**Date:** 2025-04-11
**Status:** accepted

## Context

Need persistent storage. Single server, one user, no concurrent writes.

## Decision

SQLite via the stdlib `sqlite3` module.

## Rationale

Zero ops overhead. No separate process. Fits in the repo for local dev.
Migration story is simple: just ship the file.

## Tradeoffs

Can't scale horizontally. Fine — this isn't that.

## Alternatives Considered

- **Postgres:** operational overhead not justified at this scale
- **JSON files:** no query capability, integrity risks
```

---

## status

Quick project snapshot.

**Current repo state:**
```!
jj log --limit 10 2>/dev/null || echo "no jj history"
jj status 2>/dev/null
```

Read `.dev/context.md` and the last 10 entries from `.dev/log.md`.

Output a brief summary (under 20 lines):
- Current focus
- What was done recently
- Open questions
- Next actions

Then ask: "Does `context.md` need updating?"
