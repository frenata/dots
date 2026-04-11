---
name: jj
description: Use this skill whenever working in a repository that uses jj (Jujutsu) for version control, or when the user asks to commit, branch, split, or manage changes with jj. Triggers on any mention of "jj", "jujutsu", "workspace", "bookmark", "change set", or when the user wants to organize work into logical units. Use this skill to drive all VCS operations — do not fall back to raw git commands unless explicitly asked. Apply it proactively when the user describes a multi-phase plan, asks to separate concerns in their changes, or wants to isolate work on different features.
---

# jj (Jujutsu) Skill

Use `jj` for all VCS operations in repos managed by Jujutsu. Never reach for `git` unless the user explicitly asks.

## Core Mental Model

In jj, the **working copy is always a change**. There's no staging area. Every edit is automatically part of the current change. Key concepts:

- **Change**: The atomic unit of work (like a commit, but always mutable)
- **Bookmark**: Named pointer to a change (jj's equivalent of a git branch)
- **Workspace**: Independent working copy sharing the same repo — use for parallel workstreams

---

## Daily Workflow

### Starting work

```bash
# See current state — always orient here first
jj log

# Start a new change on top of the current one
jj new -m "feat: add login page"

# Or start from a specific bookmark
jj new main -m "feat: add login page"
```

### Describing changes

```bash
# Set/update the description of the current change
jj describe -m "feat: implement user auth"

# View what's in the current change
jj diff
jj status
```

### Bookmarks (branches)

```bash
# Create a bookmark at the current change
jj bookmark create feat/my-feature

# Move a bookmark to the current change
jj bookmark set feat/my-feature

# List bookmarks
jj bookmark list

# Push to remote — always push by bookmark name, never by change id
jj git push --bookmark feat/my-feature
```

**Rule: never push without a named bookmark.** Always create or move a bookmark before pushing. `jj git push --change @` is off-limits — it creates anonymous remote refs and makes history hard to navigate.

---

## Change Descriptions (Commit Message Style)

All change descriptions follow **conventional commits** prefix plus the **seven rules**:

```
<type>: <imperative subject>
```

Common types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `perf`

The seven rules, adapted for conventional commits:

1. **Separate subject from body with a blank line**
2. **Limit the subject line to 50 characters** (72 hard ceiling; prefix counts toward the limit)
3. **Prefix lowercase; subject after the colon lowercase** — `feat: add login page`, not `feat: Add login page`
4. **No period at the end**
5. **Imperative mood** — "add", not "added" or "adds". Test: "If applied, this commit will ___"
6. **Wrap the body at 72 characters**
7. **Body explains what and why, not how** — the code explains how

Simple change — subject only:

```
fix: null check in auth middleware
```

Change needing context:

```bash
jj describe -m "perf: lazy-validate JWT tokens

Previously decoded on every request, including unauthenticated routes.
Now validation runs only when a protected route is matched.

Cuts p99 latency on public endpoints by ~40ms."
```

When stubbing a change chain upfront, concise subjects alone are fine. Fill in bodies with `jj describe` once the work is done and the reasoning is clear.

---

## Multi-Phase Work

When a task has a clear plan with phases (e.g., "first refactor X, then add feature Y, then update tests"):

1. **Map each phase to a change** using `jj new -m "..."` between phases
2. **Name the series** with a bookmark at the final change
3. **Keep changes focused** — one logical concern per change

Example workflow for "refactor auth, then add OAuth, then add tests":

```bash
jj new main -m "refactor: extract auth middleware"
# ... make refactor changes ...

jj new -m "feat: add OAuth provider"
# ... add OAuth ...

jj new -m "test: cover auth and OAuth flows"
# ... write tests ...

jj bookmark create feat/oauth
```

The `jj log` will show a clean, readable chain of intent.

---

## Splitting a Change

When a change has grown to cover multiple concerns, split it.

**Non-interactive split by file/path:**
```bash
# Put specific files into a new child change, keep rest in current
jj split -r @ -- path/to/file.ts path/to/other.ts
```

**Interactive split (choose hunks):**
```bash
jj split -r @
```

**Split strategy:**
- Group by concern, not by file type
- Ask: "would reviewing these together confuse a reader?" — if yes, split
- After splitting, use `jj describe` to give each part a crisp message

---

## Rebase and Squash

### Rebase

```bash
# Rebase current change onto a different target
jj rebase -r @ -d main

# Rebase a whole branch (change + descendants)
jj rebase -s <change-id> -d main
```

### Squash

```bash
# Squash current change into its parent
jj squash

# Squash a specific change into its parent
jj squash -r <change-id>

# Squash specific files only (leave rest in child)
jj squash --into <parent-id> -- path/to/file.ts
```

---

## Workspaces

Use workspaces to work on multiple bookmarks simultaneously without stashing or context-switching.

```bash
# Create a new workspace for a parallel workstream
jj workspace add ../my-repo-hotfix

# Switch to it (in your shell)
cd ../my-repo-hotfix

# List workspaces
jj workspace list

# Forget a workspace when done
jj workspace forget hotfix
```

**When to use workspaces:**
- Hotfix needed while mid-feature
- Long-running feature + quick exploratory spike
- Reviewer asks for changes while you've already moved on

Each workspace has its own working-copy change. They share the same underlying repo — no duplication.

---

## Useful Inspection Commands

```bash
jj log                          # Visual change graph
jj log -r 'bookmarks()'         # Show only bookmarked changes
jj show                         # Full diff of current change
jj show <change-id>             # Diff of specific change
jj diff -r <id1>..<id2>         # Diff between two changes
jj op log                       # Operation history (undo with jj op undo)
```

---

## Git Interop

```bash
jj git fetch                    # Fetch from remote
jj git push --bookmark <n>      # Push a bookmark
jj git push --all               # Push all bookmarks
```

---

## Key Principles for Claude

1. **Describe before coding.** When given a plan, stub the change chain with `jj new -m "..."` calls first, then implement.
2. **One concern per change.** If implementation drifts into multiple concerns, split proactively.
3. **Bookmark at feature boundaries.** Every reviewable unit of work gets a named bookmark.
4. **Never leave the working copy undescribed.** Always run `jj describe` before moving on.
5. **Use `jj log` to narrate progress** — the log should read like a clean story of the work done.

---

## Undoing and Exploring Alternatives

Never undo work by manually reverting edits. Use jj's history instead.

**Dead end — abandon the current approach:**
```bash
jj undo        # Undo the last jj operation (repeatable)
jj op log      # See full operation history if you need to undo further back
```

**Diverging approaches — fork from a known-good change:**
```bash
# Go back to the good change, start a new branch of exploration
jj new <change-id> -m "feat: try alternate approach"
```

This leaves the abandoned chain intact and visible in `jj log`. You can return to it, compare it, or discard it later. Prefer this over `jj undo` when you want to keep both attempts in view.

**Rule:** if you catch yourself deleting code to "undo" something, stop. Use `jj undo` or fork with `jj new`.
