---
description: Get comprehensive git repository status summary
---

Provide a comprehensive summary of the current git repository state.

Steps:
1. Run `git status` to show working tree status
2. Run `git log --oneline -10` to show recent commits
3. Run `git branch -vv` to show branches and tracking info
4. Run `git stash list` to check for any stashed changes
5. If there are uncommitted changes, run `git diff --stat` for a summary
6. Present a clear, organized summary to the user including:
   - Current branch and tracking status
   - Uncommitted changes (staged and unstaged)
   - Recent commit history
   - Any stashed work
   - Suggestions for next steps if applicable
