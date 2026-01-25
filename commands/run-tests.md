---
description: Run tests and analyze failures in detail
---

Run the project's test suite and provide detailed analysis.

Steps:
1. Detect the project type and test framework:
   - Python: pytest, unittest
   - JavaScript/TypeScript: jest, mocha, vitest
   - Go: go test
   - Rust: cargo test
2. Run the appropriate test command with verbose output
3. If tests fail:
   - Parse the failure output
   - Read the failing test files
   - Read the relevant source code
   - Analyze the root cause
   - Provide specific fix suggestions with code examples
4. If tests pass:
   - Report coverage if available
   - Note any slow tests
   - Suggest additional test cases if gaps are apparent
