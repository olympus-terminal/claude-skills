---
description: Suggest and apply refactoring improvements
---

Analyze and refactor the specified code: $ARGUMENTS

Steps:
1. Read and understand the specified file or function
2. Identify refactoring opportunities:
   - Extract method/function for repeated code
   - Rename for clarity
   - Simplify conditionals
   - Remove dead code
   - Apply design patterns where appropriate
   - Reduce cyclomatic complexity
   - Improve separation of concerns
3. For each suggested refactoring:
   - Explain the benefit
   - Show before/after comparison
   - Note any risks or considerations
4. Ask user which refactorings to apply
5. Apply selected refactorings carefully, ensuring:
   - No functionality changes
   - Tests still pass
   - Code style consistency
