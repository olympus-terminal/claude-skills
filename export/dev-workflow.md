# Dev Workflow

Procedures for common development tasks. Each section is a self-contained instruction set.

---

## Debug

When debugging an issue:

1. Gather information: error messages, log output, reproduction steps
2. Form hypotheses about potential causes
3. Investigate systematically:
   - Read relevant source files
   - Check recent changes with git log/diff
   - Search for similar issues and error patterns in the codebase
4. For each hypothesis: explain the theory, suggest how to verify it, provide debugging steps or code
5. Propose solutions in order of likelihood
6. Offer to implement the most likely fix

---

## Review Changes

Review all uncommitted changes in the repository:

1. Run `git diff` for unstaged changes and `git diff --cached` for staged changes
2. For each changed file, analyze: code quality, potential bugs or edge cases, performance implications, security considerations, test coverage needs
3. Provide a structured review: summary by file, issues found (critical/warnings/suggestions), improvement recommendations with code examples, suggested commit message

---

## Quick Commit

Stage all changes and create a commit:

1. Run `git status` and `git diff` to analyze changes
2. Generate a commit message following conventional commit format (feat:, fix:, docs:, etc.) — under 72 characters for the first line, summarizing what and why
3. Show the user files to be committed and proposed message
4. Ask for confirmation before committing

---

## Make PR

Create a pull request for the current branch:

1. Run `git log main..HEAD --oneline` and `git diff main...HEAD --stat`
2. Analyze changes for type (feature, bugfix, refactor, docs), impact, scope, and testing status
3. Generate a PR with: clear title (conventional commits), summary bullets, test plan, breaking changes
4. Use `gh pr create` and report the URL

---

## New Feature

Start a new feature branch:

1. Ensure working directory is clean
2. Fetch latest from origin
3. Create and checkout a branch from main using kebab-case: `feature/short-description`
4. Analyze what files/components need changes, identify dependencies and blockers
5. Report branch name and implementation plan

---

## Refactor

Analyze and refactor specified code:

1. Read and understand the target file or function
2. Identify opportunities: extract method, rename for clarity, simplify conditionals, remove dead code, reduce cyclomatic complexity, improve separation of concerns
3. For each suggestion: explain the benefit, show before/after, note risks
4. Ask which refactorings to apply
5. Apply selected changes, ensuring no functionality changes and tests still pass

---

## Run Tests

Run the project's test suite:

1. Detect project type and test framework (pytest, jest, vitest, go test, cargo test, etc.)
2. Run with verbose output
3. If tests fail: parse output, read failing test and source code, analyze root cause, suggest specific fixes
4. If tests pass: report coverage if available, note slow tests, suggest additional test cases for gaps

---

## Git Summary

Provide a comprehensive repository status:

1. `git status` for working tree state
2. `git log --oneline -10` for recent commits
3. `git branch -vv` for branches and tracking info
4. `git stash list` for stashed changes
5. `git diff --stat` if uncommitted changes exist
6. Present organized summary with current branch, changes, history, stashes, and next-step suggestions

---

## Dependency Check

Analyze project dependencies:

1. Identify package managers: npm/yarn (package.json), pip (requirements.txt, pyproject.toml), cargo (Cargo.toml), go (go.mod)
2. Check for: outdated packages, security vulnerabilities (npm audit, pip-audit), unused dependencies, version conflicts
3. Report: critical security issues, major version updates, minor/patch updates, cleanup recommendations

---

## TODO Scan

Scan the codebase for TODO, FIXME, HACK, and XXX comments:

1. Search for these patterns across all files
2. Capture surrounding context for each match
3. Categorize by priority (FIXME > HACK > TODO) and file/component
4. Check age via git blame if possible
5. Present organized report with counts, detailed list, and suggestions for which to address first

---

## Explain Error

Analyze and explain an error:

1. Parse the error message for type, file/line, and stack trace
2. Read relevant source files at indicated locations
3. Analyze the code context
4. Explain in plain language: what the error means, why it occurred here, common causes
5. Provide fixes: minimal immediate fix, better patterns to prevent recurrence, related best practices

---

## Generate Docs

Generate documentation for specified code:

1. Read the code and analyze purpose, parameters, return values, side effects, dependencies, usage patterns
2. Generate language-appropriate documentation: Google-style docstrings (Python), JSDoc (JS/TS), Godoc (Go), Rustdoc (Rust)
3. Include: description, parameter types, return values, example usage, important notes

---

## Search Code

Perform a thorough codebase search:

1. Search for the pattern across all relevant file types
2. Search for files with matching names
3. Read surrounding context for significant matches
4. Analyze results for: definitions, usages, related patterns
5. Present organized results grouped by definitions/usages/related, with structural insights

---

## Handoff Note

Write a structured handoff (`HANDOFF.md`) so the next agent or session can resume work:

1. **Project State** — one paragraph, current state as if the reader walked in cold
2. **What Was Done** — bulleted list of concrete actions with file paths
3. **Decisions Made** — design/strategy decisions with the *why* for each
4. **Open Questions** — anything unresolved or deferred
5. **Next Steps** — numbered, prioritized, each actionable with relevant files and gotchas
6. **Key Files** — table of important files with one-line descriptions

Rules: be specific (paths, function names, line numbers). No boilerplate. Write for a capable agent who has never seen the conversation. Keep under 200 lines.
