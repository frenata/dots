# JFDI

A lightweight, exploratory workflow for solo engineers. Think out loud, record decisions, move fast.

No sprints. No specs. No ceremony. Just: explore → decide → record.

## Install

```bash
# Global (all projects)
cp -r jfdi/ ~/.claude/skills/

# Local (this project only)
cp -r jfdi/ .claude/skills/
```

Restart Claude Code. Run `/jfdi init` to set up a project.

## Commands

| Command | What it does |
|---|---|
| `/jfdi init` | Set up `.dev/` structure and wire up `CLAUDE.md` |
| `/jfdi think <topic>` | Explore a problem before deciding anything |
| `/jfdi adr <title>` | Record an architecture decision |
| `/jfdi status` | Quick snapshot of where things stand |

## Structure

```
.dev/
  adr/          # architecture decisions
  context.md    # current focus, open questions, next actions
  log.md        # append-only work log
```

## Guiding principles

1. **The human is the architect** — Claude surfaces tradeoffs. The human makes calls.
2. **One question at a time** — conversations, not forms.
3. **Decisions over documentation** — the ADR is a record, not a deliverable.
4. **Name real tradeoffs** — not theoretical ones.
5. **Flag contradictions, don't resolve them** — surface conflicts with existing ADRs and let the human decide.
6. **Plain files** — never suggest a tool where a markdown file works.
