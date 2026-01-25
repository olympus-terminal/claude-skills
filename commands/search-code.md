---
description: Deep search through codebase with context
---

Perform a thorough search through the codebase for $ARGUMENTS.

Steps:
1. Use Grep to search for the pattern across all relevant file types
2. Use Glob to find files with matching names if applicable
3. For each significant match, read surrounding context
4. Analyze the results to understand:
   - Where the pattern is defined
   - Where it's used/called
   - Related code patterns
5. Present organized results grouped by:
   - Definitions
   - Usages
   - Related patterns
6. Provide insights about the code structure and relationships
