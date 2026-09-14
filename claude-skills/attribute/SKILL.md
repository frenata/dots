---
name: ai-attribution-trailer
description: Derive and attach an AI-attribution tuple to git commit messages, recording how much of a change was AI-produced, what the model was used for, who was steering, and whether a human reviewed it. Use this skill whenever the user asks to tag, annotate, or record AI attribution or provenance on a commit; whenever they mention attribution tuples, facets, or notation like |F2|G4|E3|I3|C2|T3|; and whenever they ask to set up or configure AI disclosure for a repo. Also use it proactively at the end of an agentic coding session in a repo that already uses these trailers — the value of this record comes from it being continuous, and a gap is indistinguishable from a concealment.
---

# AI attribution trailer

Attach a six-facet provenance annotation to commits, as a git trailer.

The notation comes from Geraldo Xexéo, *A Faceted Proposal for Transparent Attribution of AI-Assisted Text Production*, arXiv:2604.25346 (COPPE/UFRJ, April 2026), <https://arxiv.org/abs/2604.25346>. Its argument is that a single label like "AI-generated" collapses cases that differ on entirely different axes: code can be human-written but AI-refactored, AI-generated but carefully reviewed, or AI-generated and never read. Six facets, scored independently:

```
AI-Attribution: |F2|G4|E?|I3|C2|T3|
AI-Attribution-Harness: claude-code
AI-Attribution-Session: 0f3a91c4-7b22-4e8d-9a01-5c6f2e8d4b13
AI-Attribution-Spec: arXiv:2604.25346
```

| Facet | Question |
|---|---|
| **F** Form | What did AI do to code that already existed? |
| **G** Generation | How did new code come into existence? |
| **E** Evaluation | Did a human review the result? |
| **I** Intent | What was the model used for? |
| **C** Control | Who was steering? |
| **T** Traceability | What survives of the process? |

Full rung definitions, including the adaptations made for code, are in `references/facets.md`. Read that file before scoring anything — the rungs do not mean what their names suggest, and several have a specific boundary rule that determines the whole score.

## The two rules that matter most

**Never derive E.** Every other facet is inferred from the session and the diff. E is not, ever, under any circumstance, including when tests pass, when linters are clean, when CI is green, when branch protection requires review, or when the human seems obviously careful. E records a human's claim about their own review, and a claim nobody made is not a claim. If the human does not assert a value, write `E?`.

The reason is not pedantry. Every other facet describes the model's contribution, and a model scoring its own review coverage is a machine writing a favourable account of its own work — precisely the conflict of interest that disclosure exists to counter. Automated signals about code quality are real and useful, but they belong in CI, not in a provenance record. `E?` is an honest and informative value. A derived `E3` is worse than no annotation at all, because it looks like accountability while containing none.

**Score from evidence, and break ties against yourself.** You are scoring your own contribution, which is the structural reason these annotations drift generous. The defence is the evidence: G and C both have countable signals — which decisions had alternatives, who made each one, which interventions the human initiated versus which ones you elicited — and applied properly those usually settle the score without a judgment call. Where the evidence genuinely balances, take the reading that credits the model more and the human less.

That tiebreak points different directions for different facets, so don't apply it by reflex: it means C3 over C2, because C measures how much the human steered, but I3 over I4, because I4 credits the human with having sought conceptual help. The test is always which rung claims less for the human, not which number is higher.

## `?` means no claim

`?` is valid in any slot and means the value could not be derived or was not asserted. It is not zero. `E0` is a human stating they reviewed nothing; `E?` is nobody having spoken. `C0` is a human stating they steered entirely; `C?` is a lost transcript. If `?` ever gets read as "probably fine," the annotation has stopped working.

Use `?` freely rather than guessing. An underivable facet is common and unembarrassing: backfilled commits, a session spanning repos, a transcript that isn't available. A confident wrong rung is much worse than an honest blank.

## Workflow

### 1. Gather signals

Read the change itself — `git diff --stat`, `jj diff --stat`, or whatever the repo uses — to establish which paths were touched and how much. This grounds F, but only partly: what settles F is which *lines* were transformed and whether AI or a human transformed them, and no diff shows the second half. The transcript does.

If `git-ai` is installed, its data is stronger than anything inferable, because agents report which lines they wrote rather than the score being guessed at:

```bash
git ai stats --json 2>/dev/null
```

The `ai_additions`, `ai_accepted` and human-override figures map almost directly onto C — with the caveat that they count lines, not decisions. Use them when present, and don't wait for them when absent; the transcript carries most of what the scoring needs.

### 2. Score five facets

Read `references/facets.md`, then score F, G, I, C, T from the session transcript and the signals above. Leave E unscored.

Scoring is a judgment, so record why. Keep a one-line justification per facet for step 3 — not in the commit, just available if the human asks why you proposed C3.

Be strict about what counts as evidence. G and C measure what the *human* did: self-correction, tool retries, and the model's own deliberation are invisible to both, and answering a question the model raised is weaker evidence of steering than an unprompted redirection. A justification that reads well while resting on the model's own activity is the easiest way to arrive at a flattering score honestly.

**Covering several commits at once.** A session usually produces a stack, and most facets are properties of the session rather than of any one commit — G, I, C and T will normally be identical across all of them. F is the exception, since it depends on what each commit touched. Score the shared facets once, vary F per commit, and present it that way: shared values stated once, then a line per commit for F with its own justification. One judgment, several annotations.

### 3. Propose, get agreement, don't interrogate

Show the proposed tuple with a one-line justification per facet, and ask the human to correct anything wrong and assert E:

```
Proposed: |F2|G4|E_|I3|C2|T3|

F2  edits within existing functions in parser.rs, structure preserved
G4  eleven turns, three corrections, one rejected approach
I3  new behaviour: added the retry path
C2  you specified the backoff strategy and rejected the first design
T3  session logged with model identity; session id 0f3a91c4 recorded in the trailer

Does that match? Correct anything that's off — and how much did you review?
  E0  none          E3  all of it
  E2  parts of it   E4  all of it, plus review by someone else
  E?  skip
```

The justifications are the point. A tuple shown without them can only be accepted or ignored, because the human has no way to tell whether C2 was reasoned or guessed. Shown with them, a wrong score is visible at a glance — *you specified the backoff strategy* is either true or it isn't. That's what makes agreement meaningful rather than a rubber stamp.

Keep it to one exchange. Recognition is cheaper than recall, so correcting a proposal is sustainable where a six-question form is not. Ask once per session, not once per commit — a prompt on every commit gets dismissed reflexively within days, and a reflexively dismissed assertion is worth less than `?`.

Accept corrections without argument. The human was there; you are inferring from a transcript. Don't re-derive, don't defend the original score, don't ask them to justify the correction. If they change C3 to C1, write C1.

If they don't respond at all, the derived facets stand — they were never claims by the human — but E is `?`. Never let silence become an E value.

### 4. Write the trailer

Append to the commit message, blank line before the trailer block:

```
AI-Attribution: |F2|G4|E3|I3|C2|T3|
AI-Attribution-Harness: claude-code
AI-Attribution-Session: 0f3a91c4-7b22-4e8d-9a01-5c6f2e8d4b13
AI-Attribution-Spec: arXiv:2604.25346
```

The session trailer is what earns T3. Without it the annotation claims logs exist while giving no way to reach them, which is T2. Write it when the harness exposes a stable session identifier at runtime; omit it and score T2 when it doesn't. Never fabricate one — a pointer that resolves to nothing is worse than no pointer, because it looks checkable.

**If the commits are already pushed,** say so before touching anything. Adding a trailer rewrites the message, which means a force-push on a branch someone may already be reviewing. Offer the choice — amend locally and let the human push, or leave the pushed commits alone and start the convention on the next ones — rather than deciding for them.

The spec trailer makes the annotation self-describing. Someone reading `git log` cold, years from now, with no access to this skill, can resolve the notation from the commit alone — which matters more than the third line costs, since a provenance record that outlives its own documentation isn't one.

It points at the source of the notation, not at a certificate of conformance. This skill departs from the paper in three documented ways, so if anyone treats the trailer as a conformance claim, correct them: it's a citation. Where that distinction needs to be visible in the record itself, write `AI-Attribution-Spec: arXiv:2604.25346 (adapted)` and let `references/rationale.md` carry the detail.

The harness is a separate trailer because it's a constant property of the environment, not a variable of the commit. Every agentic session structurally satisfies the paper's G5 — multi-step, tool-using, staged rewriting — so recording it in G would saturate the facet and destroy the variance that makes it worth recording. G scores interaction depth; the harness is noted once and forgotten.

Under `jj`, amending a trailer later is a routine operation rather than a history rewrite, so a merge-time correction of E by a reviewer is cheap. Under git, prefer getting E right at commit time.

## Scope and honesty about the notation

The segment is the commit. The paper is multi-scale and supports annotating a file or a function, but per-commit is the granularity that fits how the work is already chunked. Don't annotate finer without being asked.

This follows the paper's notation with three deliberate departures: E is never derived, only asserted; G5 is moved to a separate harness trailer; and F is read as covering AI-applied changes specifically. Say so if anyone asks — a departure you can name is different from a departure you made by accident. `references/rationale.md` has the reasoning for each.

If asked what the annotation proves, the answer is: nothing. Traceability is not truthfulness. A complete record makes a claim inspectable and contestable; it does not make it true. That limit is worth stating plainly rather than letting the notation's precision imply more than it carries.

## Citation

This skill implements, with the departures noted above and in `references/rationale.md`:

> Xexéo, G. (2026). *A Faceted Proposal for Transparent Attribution of AI-Assisted Text Production.* arXiv:2604.25346. <https://arxiv.org/abs/2604.25346>

The facet names, rung structure, and pipe-delimited notation are the author's. The adaptation of the rungs to source code, the removal of G5 to a separate harness field, and the refusal to derive E are not — treat them as this skill's departures, not as the paper's position, whenever the difference could matter to a reader.

The paper describes itself as a position paper and a call to action rather than a finished standard, and notes its facets remain untested for whether different annotators apply them consistently. Represent it that way rather than as an adopted convention.

## Reference files

- `references/facets.md` — rung definitions for all six facets with code adaptations and boundary rules. Read before scoring.
- `references/rationale.md` — why the design departs from the paper where it does; citation; what to say when someone challenges the scheme.
