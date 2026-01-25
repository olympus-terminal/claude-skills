---
description: Review uncommitted changes with improvement suggestions
---

Review all uncommitted changes in the repository and provide feedback.

Steps:
1. Run `git diff` to get all unstaged changes
2. Run `git diff --cached` to get staged changes
3. For each changed file, analyze:
   - Code quality and style consistency
   - Potential bugs or edge cases
   - Performance implications
   - Security considerations
   - Test coverage needs
4. Provide a structured review with:
   - Summary of changes by file
   - Issues found (critical, warnings, suggestions)
   - Specific improvement recommendations with code examples
   - Suggested commit message if changes look ready
