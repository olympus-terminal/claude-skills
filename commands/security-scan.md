---
description: Scan code for security vulnerabilities
---

Scan the codebase for common security vulnerabilities.

Steps:
1. Search for patterns indicating potential vulnerabilities:
   - SQL injection: string concatenation in queries
   - XSS: unescaped user input in HTML
   - Command injection: shell commands with user input
   - Path traversal: file operations with user input
   - Hardcoded secrets: API keys, passwords, tokens
   - Insecure deserialization
   - Missing authentication/authorization checks
   - Insecure cryptography
2. For each finding:
   - Severity rating (critical/high/medium/low)
   - File and line location
   - Explanation of the vulnerability
   - Exploitation scenario
   - Recommended fix with code example
3. Generate a summary report organized by severity
4. Suggest additional security tools to run (semgrep, bandit, etc.)
