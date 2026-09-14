# Rationale

## Source

Geraldo Xexéo, *A Faceted Proposal for Transparent Attribution of AI-Assisted Text Production*, arXiv:2604.25346 (April 2026). Section 7 annotates the paper itself, which is the quickest way to see the notation in use.

The paper is explicitly a position paper and calls itself a call to action rather than a finished standard; the facets are untested for whether different annotators apply them consistently. Cite it as the most articulate version of the idea, not as something anyone has adopted.

Adjacent work worth knowing if someone asks what else exists:
- **STM Association**, *Recommendations for a Classification of AI Use in Academic Manuscript Preparation* (September 2025) — nine task categories, publisher-facing, the most institutionally weighty thing in this space.
- **International Science Council**, Global Reporting Standard for AI Disclosure in Research — the actual standards process, still in consultation.
- **Git AI** (`git-ai-project/git-ai`) — a Git Notes convention linking each AI-written line to agent, model and prompt, with multi-vendor agent support. Complementary rather than competing: it produces the provenance record, this produces the interpretive summary.

## Deliberate departures from the paper

**E is never derived.** The paper's E1 is "automated review only", with grammar checkers as the reference case. In software the automated tier spans from a formatter to a borrow checker to a full regression suite, which makes a single rung meaningless — but the deeper reason for refusing is structural. A model scoring its own review coverage produces a favourable account of its own work. E is the one facet where a human must speak, and `?` records their silence honestly.

A consequence worth accepting rather than working around: this loses the ability to reward a strong automated pipeline in the annotation. That's fine. CI already reports it, and a disclosure record was never where anyone would look for a build status.

**G5 is folded into a separate harness trailer.** The paper's G4 describes human interaction depth; G5 describes tooling. Every agentic session satisfies G5 structurally, so keeping it would make G constant. Splitting them preserves the variance.

**F is scoped to AI-applied changes to code that already existed.** The paper leaves ambiguous whether F means transformations in which AI participated or transformations present in the text regardless of origin. Since the model's purpose is attributing AI involvement, the first reading is the only one that keeps F meaningful — which has the consequence that heavy human revision of AI-generated code leaves F at 0 and registers in E instead.

The second condition, that a version already existed, is anchored on whether the version was retained rather than on when the session started. Session boundaries are a property of the harness; scoring identical work differently because someone restarted their agent would be incoherent.

## The recurring structural problem

Three facets turn out to have two axes crammed into one ordinal:

- **E** conflates *coverage* (how much was reviewed) with *who* (the reviewer's independence). E3 and E4 are not cleanly ordered, and an AI verification pass has nowhere to go at all.
- **T** conflates *artifact* provenance with *process* provenance. A repo with complete version history and no prompts scores the same as saved prompts with no version control.
- **G** conflates *interaction depth* with *harness structure*.

The top-level facets were split carefully and then each quietly re-merged distinct questions inside itself. This is the most substantive available critique of the framework and is worth stating if the user is writing about it.

## What to say when challenged

**"Doesn't this just let people claim whatever they want?"** Yes, for E, by design — it's an assertion, and assertions can be false. The other facets are derived from the session and the diff, and `git-ai` data where available. Traceability makes a claim contestable, not true. Nothing here proves anything, and the notation's precision shouldn't be allowed to imply otherwise.

**"Why not a percentage?"** Percentages of AI-written lines are available from `git ai stats` and answer a different question. A high percentage carefully steered and fully reviewed is a different artifact from the same percentage shipped unread. That difference is the entire point of having facets.

**"Isn't version control already enough?"** It's strong on artifact history and silent on cause. See the T section in `facets.md`.
