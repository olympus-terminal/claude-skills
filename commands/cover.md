---
description: Draft, revise, and audit cover letters for scientific journal submissions (primary research, reviews, opinion pieces). Not for employment or general application cover letters.
argument-hint: <manuscript path> [--journal <name>] [--audit]
---

# Scientific Journal Cover Letters

Create a concise, evidence-grounded letter that helps an editor understand the manuscript's advance, significance, timeliness, readership, and fit without reusing the abstract or inflating the claims.

## Relationship to Science Writing

This skill owns submission strategy, letter architecture, journal fit, declarations, reviewer information, and final detail checks. Apply the claim-calibration and prose rules from `/science-writing`; read `~/.claude/commands/science-writing.md` (its Section 5, Claim calibration, and the Section 3 waste list are the parts most relevant to a letter).

For a normal `/cover` request, apply the science-writing passes internally and return one submission-ready letter. Show separate waste-cut and calibrated passes only when the user requests line-edit history or tutor mode.

## Workflow

1. Determine whether the user needs a new draft, a revision, or a submission-readiness audit.
2. Identify the journal, exact manuscript title, article type, scientific advance, principal conclusion, intended readership, corresponding contact, and required declarations. Classify the manuscript as primary research, review, or opinion.
3. For a journal-specific or submission-ready letter, verify current author instructions, journal scope, article-type terminology, and editor details on the journal's official site. Do not guess a name, title, salutation, pronoun, or submission requirement.
4. Apply the Cover-Letter Guide at the end of this command before drafting or auditing the letter.
5. Build the pitch from manuscript-supported facts. Do not invent results, novelty, priority, journal fit, reviewer expertise, conflicts, declarations, prior editorial discussions, or author approval. Mark missing essentials as `[NEEDED: ...]`.
6. Apply the relevant manuscript mode:
   - **Primary research:** state the specific advance over prior experimental knowledge and the main evidence-backed conclusion.
   - **Review:** state the timely synthesis, the conceptual reorganization it provides, and why the recent literature now warrants it.
   - **Opinion:** state the defensible position, what it changes, and the forward-looking implications.
7. Keep the letter to one page unless the journal directs otherwise. Prefer a direct three-to-five-paragraph narrative over headings or a restated abstract.
8. Run a final proper-noun and consistency check against the manuscript and current journal information.

## Content Requirements

Include, when supported and applicable:

- exact manuscript title and article type;
- concise field context and the unresolved problem or motivation;
- conceptual advance, main conclusion, and what the work enables or changes;
- a concrete explanation of timeliness, readership, and journal fit;
- originality/not-under-consideration and author-approval statements only when confirmed or required;
- corresponding or lead contact and affiliation;
- suggested reviewers with expertise when the user supplies or requests them;
- no more than three opposed reviewers by default, each with a specific professional conflict rationale.

Do not copy the abstract, oversell priority, cite conference reception as evidence of importance, or use praise in place of scientific consequence. Convey excitement through the result and its implications. Keep the tone sincere, simple, confident, and humble.

## Reviewer Guidance

Do not invent reviewer names or conflicts. If asked to identify candidates, verify current affiliations and relevant expertise from authoritative public sources, then flag any conflict information that the user must check. Do not contact candidates. Never propose excluding broad demographic, institutional, national, or continental groups.

## Output

Return:

1. `Cover Letter` — clean, submission-ready prose or a draft with explicit `[NEEDED: ...]` fields.
2. `Verification Needed` — only unresolved journal, author, declaration, reviewer, or factual details; omit when none remain.
3. `Strategic Notes` — at most a few concise points explaining consequential choices; omit routine copyedits.

For an audit-only request, return prioritized findings under `Blocking`, `Material`, and `Polish`, followed by a corrected letter only if the user requested revision.

## Cover-Letter Guide

Adapted from Catarina Sacristán, “Submitting your manuscript: Write the right cover letter,” published January 24, 2017, and organized here as an operational checklist rather than a transcription.

### Editorial Purpose

The cover letter is the journal's first formal introduction to the submission. It should let an editor answer quickly:

1. What was known, and what problem remained?
2. Why did the authors undertake this work or synthesis?
3. What is the specific conceptual advance?
4. Why is the submission timely?
5. What distinguishes it from previous work?
6. What does it change or enable?
7. Why will the journal's readership care?

The letter is a selective pitch, not a second abstract. Its value comes from synthesis, consequence, and fit.

### Recommended Architecture

#### Opening

- Address the correct editor or use a neutral salutation when an individual editor cannot be verified.
- Give the exact manuscript title and the journal's exact article-type label.
- State that the manuscript is being submitted for consideration.
- Mention an invitation or prior editorial agreement only when it occurred and the wording is verified.

#### Context and motivation

- Establish the minimum prior knowledge needed to understand the gap.
- Name the unresolved problem or reason the synthesis is needed.
- Move quickly; this is usually one compact paragraph.

#### Advance and conclusion

- State the key advance in relation to prior work, not merely the topic studied.
- Give the central evidence-backed conclusion in plain scientific language.
- Select only the results needed to understand the advance. Do not enumerate every result or mirror the abstract's order.

#### Significance, timeliness, and fit

- Explain the next scientific consequence: what can now be understood, tested, built, or reconsidered?
- Identify the relevant readership concretely.
- Connect the manuscript to the journal's scope or active conversations without flattering the journal.
- Replace generic breadth claims with named communities or questions.

#### Administrative close

- Include originality, exclusive consideration, author approval, conflicts, preprint status, or related-manuscript disclosures when confirmed and required.
- Identify the corresponding or lead contact and affiliation.
- Add reviewer suggestions or opposed reviewers only when appropriate.
- Close directly and professionally.

### Manuscript Modes

#### Primary research

Emphasize the advance relative to prior experimental findings. State what the design or data allow the authors to conclude, using verbs calibrated to the evidence. The editor should understand both the result and why it changes the field's position.

#### Review

Emphasize the synthesis and conceptual advance, especially what has changed in roughly the last one to five years. Explain why the literature now needs organization, reconciliation, or a new framework. Do not describe the article as merely “comprehensive.”

#### Opinion or perspective

State the position early. Explain why it is novel, defensible, and consequential, then project the concrete questions, experiments, or decisions that follow from it. Distinguish the authors' argument from established consensus.

### Reviewer Information

For suggested reviewers, provide the information requested by the journal, commonly:

- name and current affiliation;
- institutional email or identifier when required;
- relevant expertise in one short phrase;
- a user-verified absence of disqualifying conflicts.

Keep opposed reviewers to three by default unless journal policy says otherwise. Give a specific professional reason, such as a close collaboration, direct competition on unpublished work, or a personal conflict. Do not oppose people by geography, identity, institution class, or an entire field.

### Style and Length

- One page is normally sufficient; approximately 250–450 words is a useful range when the journal gives no limit.
- Lead with the point. Delete manuscript-history narration and textbook background.
- Use short paragraphs and concrete verbs.
- Generate energy through a clear advance and consequence, not intensifiers.
- Be confident without claims of unsupported priority.
- Avoid florid language, ostentation, sales slogans, and generic claims of “broad interest.”
- Do not mention conference counts or enthusiastic reception as a substitute for evidence.
- Do not paste or lightly paraphrase the abstract.

### Missing-Information Policy

Never silently manufacture submission facts. Use precise placeholders:

- `[NEEDED: exact journal article type]`
- `[NEEDED: corresponding author and affiliation]`
- `[NEEDED: confirm all authors approved submission]`
- `[NEEDED: confirm manuscript is not under consideration elsewhere]`
- `[NEEDED: journal-specific preprint or related-manuscript disclosure]`
- `[NEEDED: reviewer conflict check]`

Ask a question only when the answer changes the letter materially and cannot be recovered from the supplied manuscript or authoritative journal information.

### Final Submission Audit

Check every item against the manuscript and current journal site:

- journal name;
- editor name, role, and salutation;
- manuscript title, capitalization, and punctuation;
- article type;
- author and affiliation details;
- corresponding/lead contact;
- claims, numbers, terminology, and organism/model names;
- journal fit and readership statement;
- originality, exclusivity, approval, conflicts, preprint, and related-work declarations;
- reviewer names, affiliations, expertise, and conflicts;
- spelling, grammar, syntax, and one-page length.

Wrong-journal or wrong-editor residue is a blocking defect, not a minor typo.

User request: $ARGUMENTS
