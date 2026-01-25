---
description: Create a well-formatted pull request
---

Create a pull request for the current branch.

Steps:
1. Run `git log main..HEAD --oneline` to see commits to be included
2. Run `git diff main...HEAD --stat` to see files changed
3. Analyze the changes to determine:
   - Type of change (feature, bugfix, refactor, docs, etc.)
   - Impact and scope
   - Testing status
4. Generate a PR with:
   - Clear, descriptive title following conventional commits
   - Summary section with bullet points
   - Test plan section
   - Any breaking changes noted
5. Use `gh pr create` with the generated title and body
6. Report the PR URL to the user
