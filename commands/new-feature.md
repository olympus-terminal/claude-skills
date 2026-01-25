---
description: Start a new feature with proper git workflow
---

Start a new feature branch for: $ARGUMENTS

Steps:
1. Ensure working directory is clean (`git status`)
2. Fetch latest from origin (`git fetch origin`)
3. Create and checkout a new branch from main:
   - Use kebab-case naming: feature/short-description
   - Example: feature/add-user-authentication
4. Create initial plan:
   - Analyze what files/components will need changes
   - Identify dependencies and potential blockers
   - Create a todo list for implementation steps
5. Report to user:
   - Branch name created
   - Implementation plan
   - First suggested steps
