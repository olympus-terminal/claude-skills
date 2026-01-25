---
description: Scan codebase for TODO, FIXME, and HACK comments
---

Scan the codebase for TODO, FIXME, HACK, and XXX comments.

Steps:
1. Use Grep to search for TODO, FIXME, HACK, and XXX patterns
2. For each match, capture the surrounding context
3. Categorize findings by:
   - Priority (FIXME > HACK > TODO)
   - File/component
   - Age if determinable from git blame
4. Present an organized report:
   - Summary counts by category
   - Detailed list with file, line, and context
   - Suggestions for which items to address first
   - Option to create GitHub issues for critical items
