---
description: Write a structured handoff note for the next agent/session to resume work
---

Create a handoff note so the next agent or session can resume where this one left off. The note goes in the project root as `HANDOFF.md` (overwrite if one exists).

## What to include

Analyze the full conversation and produce a structured handoff with these sections:

### 1. PROJECT STATE
One paragraph. What is this project, what stage is it at right now. No history — just current state as if the reader walked in cold.

### 2. WHAT WAS DONE THIS SESSION
Bulleted list of concrete actions taken (files created, code written, decisions made, repos set up). Include file paths. No vague summaries — if it can't be verified by reading a file, it doesn't belong here.

### 3. DECISIONS MADE
Bulleted list of design/strategy decisions that were agreed on but may not be obvious from the code alone. Include the *why* for each. These are the things that would be lost if the next agent only read the codebase.

### 4. OPEN QUESTIONS
Anything unresolved, ambiguous, or explicitly deferred. If there were options discussed but not chosen, note them.

### 5. NEXT STEPS (PRIORITIZED)
Numbered list, most important first. Each item should be actionable — a next agent should be able to pick up item #1 and start working immediately. Include:
- What to do
- Which files/directories are relevant
- Any gotchas or prerequisites

### 6. KEY FILES
Table of the most important files the next agent should read first, with one-line descriptions.

## Rules

- Be specific. Paths, filenames, function names, line numbers.
- No boilerplate. No "this project aims to..." filler.
- Write for a capable agent who has never seen this conversation but can read code.
- If there's a CLAUDE.md in the project, reference it but don't duplicate its contents.
- If `git log` shows recent commits from this session, reference the commit hashes.
- Keep total length under 200 lines.
- After writing HANDOFF.md, report its location to the user.
