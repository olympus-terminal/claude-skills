# Security & Performance

## Security Scan

Scan the codebase for common security vulnerabilities:

1. Search for patterns indicating potential vulnerabilities:
   - SQL injection: string concatenation in queries
   - XSS: unescaped user input in HTML
   - Command injection: shell commands with user input
   - Path traversal: file operations with user input
   - Hardcoded secrets: API keys, passwords, tokens
   - Insecure deserialization
   - Missing authentication/authorization checks
   - Insecure cryptography
2. For each finding, provide: severity rating (critical/high/medium/low), file and line location, explanation, exploitation scenario, recommended fix with code example
3. Generate a summary organized by severity
4. Suggest additional security tools to run (semgrep, bandit, etc.)

---

## Performance Check

Analyze the codebase or specified file for performance issues:

1. If a file is specified, focus there; otherwise scan recent changes
2. Look for common anti-patterns:
   - N+1 queries in database code
   - Unnecessary loops or nested iterations
   - Memory leaks (unclosed resources, growing collections)
   - Synchronous operations that could be async
   - Missing caching opportunities
   - Inefficient data structures
   - Regex compilation in loops
3. For each issue: explain the impact, show problematic code, provide an optimized alternative
4. Prioritize by impact (high/medium/low)
