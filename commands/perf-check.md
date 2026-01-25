---
description: Analyze code for performance issues
---

Analyze the codebase or specified file for performance issues.

Steps:
1. If a file is specified, focus on that file; otherwise scan recent changes
2. Look for common performance anti-patterns:
   - N+1 queries in database code
   - Unnecessary loops or nested iterations
   - Memory leaks (unclosed resources, growing collections)
   - Synchronous operations that could be async
   - Missing caching opportunities
   - Inefficient data structures
   - Regex compilation in loops
3. For each issue found:
   - Explain the performance impact
   - Show the problematic code
   - Provide an optimized alternative
4. Prioritize by impact (high/medium/low)
