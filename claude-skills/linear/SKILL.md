---
name: linear-issue
description: >
  Write and post well-crafted Linear issues. Use this skill any time the user wants to file, draft, create, or write a Linear ticket, issue, bug report, feature request, or task. Also trigger when the user says things like "open a ticket", "log this in Linear", "create a task for", or "write up this bug". Assumes the Linear MCP is available. Always preview before posting.
---

# Linear Issue Skill

Write clear, complete Linear issues. Omit needless words. One touch of whimsy per issue — maximum.

## Defaults

| Field | Default |
|---|---|
| Team | PLAT |
| Status | Backlog |
| Priority | (unset — don't guess) |
| Estimate | (unset — don't guess) |
| Project | assign to a real project or an evergreen: "Technical Support" or "Business as Usual" |

Never set priority or effort. Let the team decide.

---

## Issue Anatomy

### Title
Verb-first. Specific. ≤10 words.

```
✓ Fix race condition in session token refresh
✓ Add pagination to /v1/orgs endpoint  
✗ Bug with login
✗ Improvements to the API
```

### Description structure

Use this template, omitting sections that don't apply:

```markdown
## Context
[Why this matters. One or two sentences max.]

## Problem / Goal
[What's broken or what needs to exist.]

## Repro  ← required for bugs/failures
1. Step one
2. Step two
3. Observe 🔥

**Expected:** ...  
**Actual:** ...

## Relevant Code
[Link directly to GitHub. Prefer line-anchored permalinks.]

## Prior Art
[Link to a PR or issue this resembles.]

## Definition of Done
- [ ] ...
- [ ] ...

## Open Questions
> ❓ **Needs input from [SME name/team]:** [the question]
```

---

## Rules

### Bugs and failures → always include a repro
No repro, no ticket. If the reporter didn't provide steps, ask before filing. A bug without a repro is a wish, not an issue.

### Touching existing code → link to it on GitHub
Use line-anchored permalinks (`#L42` or `#L42-L67`). Don't just name the file — link it. If you don't have the repo URL, ask.

```
✓ https://github.com/acme/api/blob/main/src/auth/session.ts#L112-L134
✗ "See session.ts around line 112"
```

### Similar to prior work → cite the PR
Link the PR. One sentence on what's the same and what's different.

```
Similar to #1847 (added rate limiting to /v1/users). Same middleware pattern applies; 
the wrinkle here is that /v1/orgs has two codepaths depending on org type.
```

### Definition of Done
Be explicit. Each checkbox is a concrete, testable condition. Avoid "it works."

```
✓ - [ ] Unit tests cover the null-org edge case
✓ - [ ] Endpoint returns 429 with Retry-After header
✗ - [ ] Feature is complete
```

### Ambiguity → surface it, name the SME
Don't silently paper over unknowns. Put open questions in their own section. If you know who owns the area, say so.

```
> ❓ **Needs input from @maya (auth team):** Should token refresh failures 
> silently re-authenticate, or surface the error to the client?
```

---

## Labels

Pull real labels from Linear before filing. Prefer:

- **type/** sub-labels — `type/bug`, `type/feature`, `type/chore`, etc.
- **security** — any issue touching auth, data access, or PII
- **good first issue** — well-scoped, self-contained, good docs

Don't invent labels.

---

## Project Assignment

Always assign a project. Check real projects first (use `linear_searchProjects` or similar). Fall back to evergreens:

- **Technical Support** — reactive work, external-triggered
- **Business as Usual** — maintenance, internal tooling, housekeeping

---

## Workflow (Claude Code)

1. **Gather info.** Ask for anything missing: repro steps, GitHub repo URL, relevant PR, SME name.
2. **Draft the issue** in the conversation. Show it fully formatted.
3. **Ask for approval.** "Should I post this to Linear?"
4. **Post only after confirmation.** Use `linear_createIssue` (or equivalent MCP tool).
5. **Return the issue URL.**

Never post without an explicit go-ahead.

---

## Examples

### Bug report

**Title:** Fix null pointer in org invite when invitee has no email

```markdown
## Context
Org invites crash for SSO users who authenticated without storing an email address. 
Affects ~3% of enterprise customers.

## Repro
1. Create an org with SSO enabled (Okta)
2. Invite a user who logged in via SAML (no email on record)
3. Observe 500 in the API and a very sad Sentry alert

**Expected:** Invite queued; user notified via SSO provider  
**Actual:** `TypeError: Cannot read properties of null (reading 'toLowerCase')` at [org/invite.ts#L88](https://github.com/acme/api/blob/main/src/org/invite.ts#L88)

## Relevant Code
- [invite.ts#L82-L95](https://github.com/acme/api/blob/main/src/org/invite.ts#L82-L95) — email normalization without null guard
- [user.model.ts#L34](https://github.com/acme/api/blob/main/src/models/user.model.ts#L34) — `email` field is nullable

## Definition of Done
- [ ] Null guard added before `toLowerCase` call
- [ ] Invite succeeds for SSO users with no stored email
- [ ] Regression test: invite SSO user → no 500
- [ ] Sentry alert resolves

## Open Questions
> ❓ **Needs input from @priya (identity team):** For SSO users without email, 
> should we fall back to their SSO `nameID`, or require orgs to configure 
> an email attribute in their IdP mapping?
```

---

### Feature request

**Title:** Add cursor-based pagination to GET /v1/orgs

```markdown
## Context
/v1/orgs uses offset pagination. Customers with >1k orgs report stale results 
during enumeration. Cursor-based pagination fixes this.

## Prior Art
Implemented for /v1/users in [#1847](https://github.com/acme/api/pull/1847). 
Same approach applies; note that orgs have two list codepaths (owned vs. member) 
that both need updating.

## Relevant Code
- [orgs.controller.ts#L45-L78](https://github.com/acme/api/blob/main/src/orgs/orgs.controller.ts#L45-L78) — current offset logic
- [pagination.ts](https://github.com/acme/api/blob/main/src/lib/pagination.ts) — shared cursor utility from #1847, reuse this

## Definition of Done
- [ ] `GET /v1/orgs` accepts `cursor` and `limit` params
- [ ] Offset params (`page`, `per_page`) deprecated but not removed
- [ ] Both owned and member codepaths paginated
- [ ] API docs updated
- [ ] Integration test: paginate 500 orgs, assert no duplicates or gaps
```
