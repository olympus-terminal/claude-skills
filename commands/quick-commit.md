---
description: Quickly stage and commit changes with auto-generated message
---

Stage all changes and create a commit with an appropriate message.

Steps:
1. Run `git status` to see what will be committed
2. Run `git diff` to analyze the actual changes
3. Generate a commit message that:
   - Follows conventional commit format (feat:, fix:, docs:, etc.)
   - Summarizes the what and why concisely
   - Is under 72 characters for the first line
4. Show the user:
   - Files to be committed
   - Proposed commit message
5. Ask for confirmation before committing
6. If confirmed, run `git add -A && git commit -m "message"`
7. Show the result
