# Facet rungs

Six facets, scored independently. `?` is valid in any slot and means no claim.

The rungs below are adapted from Xexéo (arXiv:2604.25346), whose definitions are written for prose. The adaptation to code is by analogy, not by definition — where a mapping is strained, that's noted rather than papered over.

**Contents**
- [F — Form](#f--form)
- [G — Generation](#g--generation)
- [E — Evaluation](#e--evaluation)
- [I — Intent](#i--intent)
- [C — Control](#c--control)
- [T — Traceability](#t--traceability)
- [Worked examples](#worked-examples)

---

## F — Form

*What did AI do to code that already existed?*

| | |
|---|---|
| **F0** | AI transformed no pre-existing lines. Includes purely additive changes to existing files — a new function appended to a module, a new test added to a suite — and cases where all editing of generated code was done by hand. |
| **F1** | Mechanical, meaning-preserving: formatting, whitespace, import ordering, lint autofix. |
| **F2** | Local edits preserving structure: renames, signature changes, bug fixes inside a function. |
| **F3** | Restructuring within a module: extracting functions, reorganising control flow, changing how logic is arranged. |
| **F4** | Architectural: responsibilities moved across modules, interfaces or data models changed. |

**Two independent conditions. Both must hold for F to be non-zero.**

*The change was applied by AI.* Human editing of AI-generated code is not Form — it's review, and it belongs in E and C. This produces a result that looks wrong until you see why: a session where the model generates a large amount of code and the human then revises all of it by hand scores `F0|G4|…` with a high E. F records the model's transformations, and the model made none.

*A retained version already existed.* Not "existed before this session" — session boundaries are an artifact of the harness, and anchoring to them would mean the same work scores differently depending on whether someone restarted their agent. The anchor is whether there was a version you were keeping.

**Score lines, not files.** Touching an existing file is not the test; transforming lines within it is. Appending a function to an existing module, or a test to an existing suite, changes nothing that was there before — that's F0, even though the diff lists a pre-existing path. A `--stat` summary cannot distinguish the two cases; read the hunks, or the transcript.

**Where that line falls in practice.** Discarded intermediates inside an iteration loop are Generation: the model proposes an approach, you say use a queue instead, it rewrites wholesale, and nothing in between was ever a version you held onto. That's G4 producing a first version, and F stays 0. But once a version exists that you'd have been willing to ship, a later instruction to restructure it is Form — F3 or F4 — and it makes no difference whether that instruction came ten minutes later in the same session or next Tuesday in a fresh one.

The practical test: *would you have been content to stop at the earlier version?* If yes, transforming it is Form. If it was scrapped en route to something you'd accept, it's Generation.

**The facets are independent, and one commit can score both.** Generating a new module while restructuring an existing one is `F3|G4` — the two questions are about different code, not competing readings of the same code.

**F3/F4 is the boundary that matters.** F3 changes how logic is arranged inside a unit; F4 changes what the units are. F4 carries much stronger implications about who designed the system.

**Honest limit:** these rungs are analogies. The paper's F1–F4 are orthographic, grammatical, local-stylistic, and global-rhetorical. Mapping those onto formatting, local edit, refactor, and architecture is reasonable and is not what the author defined.

---

## G — Generation

*How did new code come into existence?*

| | |
|---|---|
| **G0** | No AI-generated lines. |
| **G1** | Inline completions only — autocomplete-scale suggestions, accepted or rejected as they appeared. |
| **G2** | Single prompt; output used substantially as returned. |
| **G3** | The approach was fixed in advance and largely executed as specified; little redirection during. |
| **G4** | Multi-turn: the human questioned, corrected, redirected, or rejected outputs across the session. |

**Only human-initiated redirection counts toward G4.** A model that hits a type error, fixes it, and moves on has told you nothing about interaction depth. Neither has a model that answers its own question, retries a failing test, or reconsiders an approach unprompted. G measures how much the human shaped the production, so self-correction, tool retries and internal deliberation are all invisible to it. Count what the human did.

**Steering can be front-loaded, and that shows up here as G3.** A spec detailed enough to fix the approach — interfaces named, structure described, decisions already made — produces a session that largely executes rather than negotiates. Few turns, little redirection, G3. The work can still be substantial; what's low is the amount of steering that had to happen *during*.

**But specificity about outcomes is not specificity about approach, and they pull opposite ways.** A ticket with rich context and a thorough definition of done, silent on how to build it, leaves every approach decision open. Those decisions surface during the work, which produces *more* turns, not fewer — often G4, and with the model making the calls. So a well-written outcome spec tends toward high G and high C together, which is the opposite of what intuition suggests.

**G5 is deliberately absent.** The paper's G5 — a designed workflow with multiple prompts, retrieval, tool use, staged rewriting — is satisfied structurally by every agentic coding session on turn one. Recording it would make G a constant and destroy the variance worth capturing. The harness goes in `AI-Attribution-Harness:` instead, and G scores interaction depth.

This is a departure from the paper. It exists because G4 describes the human interaction and G5 describes the tooling; they are two axes, not two rungs. Say so if challenged.

**G and C must not collapse into each other.** G counts exchanges; C attributes decisions. They come apart in both directions: a single prompt specifying the exact code shape is `G2|C1`, and a long session against an outcome-only spec is `G4|C3`. If they start tracking each other across a repo's history, one of them has stopped doing work.

---

## E — Evaluation

*Did a human review the result?*

**Never derive this facet. Not from tests, not from linters, not from CI, not from branch protection, not from the human seeming careful.** If the human does not assert a value, write `E?`.

| | |
|---|---|
| **E0** | Asserted: no human reviewed the output. |
| **E1** | Asserted: automated checks only. Available for a human to claim; never assigned by the skill. |
| **E2** | Asserted: a human reviewed part of it. |
| **E3** | Asserted: a human reviewed all of it. |
| **E4** | Asserted: review by another person, or a documented review stage — a merged PR with an approval qualifies. |
| **E?** | No assertion made. |

**E4 is about process structure, not diligence.** An approval click satisfies it. That's correct rather than a weakness: a scale attempting to measure care taken would be unfalsifiable.

**Where automated signals go: not here.** Test results, coverage, lint tier and type strictness are real evidence about the artifact, and they belong in CI where they already live. The tuple records provenance about the process. Keeping them separate is more accurate than compressing them into E, and a green pipeline never establishes that the change does the right thing — only that it is well-formed and doesn't regress known behaviour.

---

## I — Intent

*What was the model used for?*

| | |
|---|---|
| **I0** | No AI use. |
| **I1** | Mechanical correction: formatting, syntax, lint fixes. |
| **I2** | Transformation of existing code: refactor, port, translate, restructure — without new behaviour. |
| **I3** | Generation of new content: new functions, modules, tests, implementations. |
| **I4** | Conceptual support: weighing designs, proposing architecture, identifying gaps, questioning the approach. |

**Don't smuggle delegation into I.** A one-shot "build me a thing" prompt hands over all the architectural decisions, which is tempting to score I4. Resist it: that's Control, and scoring it in both double-counts. I asks what role the model played in the workflow; C asks who decided. A prompt that delegates heavily but asks only for an implementation is I3 with a high C.

**I4 is more common in careful work than in careless work.** Asking a model to sketch two approaches, or to find what you haven't considered, is genuinely conceptual. Firing one prompt at it and shipping the output usually isn't.

**But the conceptual work has to be something the human asked for.** A model that surfaces a design question mid-task, poses the options, and implements whichever the human picks has done conceptual work the human didn't request — that belongs in C, as evidence of the model setting the agenda, not in I as evidence of the human reaching for conceptual help. I4 needs the human to have gone looking for it. When torn between I3 and I4, take I3 unless there's a human-initiated request for design input.

---

## C — Control

*Who was steering?*

| | |
|---|---|
| **C0** | Human-controlled throughout; AI shaped no content. |
| **C1** | Narrowly bounded tasks; the human determined the approach in advance. |
| **C2** | Guided interaction: human set goals, imposed constraints, corrected across turns. |
| **C3** | AI-dominant: AI produced most content and made most of the decisions; human selected, approved, or lightly modified. |
| **C4** | Autonomous: the human did not review during production. |

**Score by attributing decisions, not by counting turns.** List the choices in the session that had real alternatives — how to chunk the work, whether to add a helper or inline the logic, the shape of an interface, the test strategy, whether to rebase — and mark who made each. A session where the human made one of six such decisions is C3 regardless of how long it ran or how pleasant the collaboration felt. This is the most mechanically checkable facet; use the evidence rather than an impression.

**Human-initiated interventions outweigh model-elicited ones.** Answering a question the model raised is weaker evidence of steering than redirecting unprompted, because the model set that agenda — it chose what was worth asking about and framed the options. A session with one unprompted rejection and two answers to model-posed questions has one piece of strong evidence, not three. C2's "imposed constraints across turns" does not survive that count.

**Steering that happened before the session still counts.** A spec that fixes the approach is control, exercised in advance: C1, even if the session itself was quiet. But note what kind of specificity it is. Detail about *outcomes* — context, acceptance criteria, a definition of done — constrains what "done" means and leaves every approach decision to the model. That is C3 territory despite looking thorough. Detail about *approach* is what moves C down.

**With `git ai stats --json`,** `ai_additions` versus `ai_accepted` and the human-override count are close to a direct measurement of the content half. Prefer them over inference, but remember they measure lines, not decisions — a small human edit can encode a large decision, and a large accepted block can encode none.

**When the evidence is genuinely balanced, prefer the reading that credits the model more.** This is a tiebreak, not a starting position: applied properly the decision count usually settles it. The reason for the tiebreak is that the model is scoring its own autonomy, and "the human steered carefully throughout" is both pleasing and unfalsifiable.

---

## T — Traceability

*What survives of the process?*

Score the **post-state** — the state after this skill writes its trailer, not the state before.

| | |
|---|---|
| **T0** | No record. |
| **T1** | Informal notes; not enough to reconstruct. |
| **T2** | Prompts or partial interaction records available. |
| **T3** | Full logs, model identification, and intermediate versions. |
| **T4** | Independently verifiable provenance: signed metadata or third-party attestation. |

**Artifact history is not process history.** A repository preserving every intermediate version — as `jj`'s auto-commit of working edits does — shows what the code became at every instant and still cannot recover what was asked, what was rejected, or which model answered. That is maximum resolution on outcome and none on cause. Version history alone is not T3; T3 needs prompts and model identity too.

**Running inside a logging harness is T2, not T3, unless the record is addressable.** Every agentic session produces a transcript somewhere, so treating that alone as T3 would make the facet constant and meaningless. The question is whether a reader of the commit can get from the annotation to the record. If nothing identifies which session produced this change, the honest score is T2: a partial record exists and someone determined could probably find it.

Write `AI-Attribution-Session:` with the harness's session identifier when one is available at runtime, and score T3. That converts "logs exist" into "here is the key to the log." It does not make the record public — the transcript stays wherever the harness put it, usually local — but it makes the claim checkable by anyone who has access, which is the difference the facet is measuring. If the harness exposes no stable identifier, omit the trailer and score T2 rather than inventing one.

**Self-reported attribution is T3, not T4.** Tools like `git-ai` record which lines an agent wrote because the agent says so. That's attestation, not verification: anyone editing outside an instrumented agent produces a clean human attribution. T4 requires provenance a third party can check.

**Prompts stored outside the repo** — as `git-ai` does, in a redacted external store — mean the repo carries a pointer, not the evidence. Score what a reader of the repo can actually reach.

---

## Worked examples

**One-shot generation, shipped unread.** A single prompt produces a new script; it's committed without being read. New file, so nothing pre-existing was transformed. One turn, no correction. The model determined the structure. Chat closed, nothing kept.
`|F0|G2|E0|I3|C3|T0|` — E0 only because the human said so; otherwise `E?`.

**Careful feature work in a mature repo.** Twelve turns adding a retry path to an existing module, several corrections, one approach rejected; the human specified the backoff strategy; merged through a required PR review; the harness session id is recorded in the trailer.
`|F2|G4|E4|I3|C2|T3|` — T3 because the session is addressable, not merely logged.

**Well-specified ticket, model made the approach calls.** An issue with rich context and a three-item definition of done, silent on how to build it. The model chose the chunking, the helper-versus-inline call, the interface and the test strategy; the human answered one design question the model raised, rejected one edit, and asked one question that changed nothing. Long session, many turns — but one human-initiated redirection across eighty minutes, and one human decision out of six.
`|F2|G3|E2|I3|C3|T2|` — G3 because the turns were the model's own working, not the human's steering; C3 on the decision count; T2 with no session identifier recorded.

**AI generated it, the human rewrote it by hand.** The model produced a first implementation across several turns; the human then edited essentially all of it themselves, with no further model involvement. F stays 0 because the model transformed nothing — every change to the generated code was human. The revision shows up where it belongs, in E. The harness logged the session but exposed no identifier to record.
`|F0|G4|E3|I3|C2|T2|` — T2, since nothing in the commit points at the transcript.

**A refactor the human designed and the model executed.** The human described the target structure in detail; the model moved code across three modules without adding behaviour; the human read the whole diff; session id recorded.
`|F4|G3|E3|I2|C1|T3|`

**Backfilled commit, no transcript.** The diff is available; nothing else is.
`|F2|G?|E?|I?|C?|T0|` — most of the tuple is unknowable after the fact, and the honest annotation says so. This is why backfilling is mostly not worth doing: the facets that carry the signal are exactly the ones that don't survive.
