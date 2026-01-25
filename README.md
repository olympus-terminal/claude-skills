# Claude Skills

A collection of custom Claude Code commands and skills for enhanced productivity.

## Structure

```
claude-skills/
├── commands/       # Slash commands (.md files)
├── skills/         # Skill definitions
└── examples/       # Example configurations
```

## Installation

Copy the desired commands to your `.claude/commands/` directory:

```bash
# Copy a specific command
cp commands/screenshot.md ~/.claude/commands/

# Or copy all commands
cp commands/*.md ~/.claude/commands/
```

## Available Commands

### Utility Commands

| Command | Description |
|---------|-------------|
| `/screenshot` | View and analyze the most recent screenshot |
| `/cleanup-figs` | Clean up old timestamped figure versions |

### Git Workflow Commands

| Command | Description |
|---------|-------------|
| `/git-summary` | Comprehensive git status, commits, and branch info |
| `/new-feature` | Start a new feature branch with proper workflow |
| `/quick-commit` | Stage and commit with auto-generated message |
| `/make-pr` | Create a well-formatted pull request |
| `/review-changes` | Review uncommitted changes with suggestions |

### Code Analysis Commands

| Command | Description |
|---------|-------------|
| `/search-code` | Deep search with context-aware results |
| `/todo-scan` | Find all TODO, FIXME, HACK comments |
| `/perf-check` | Analyze code for performance issues |
| `/security-scan` | Scan for common security vulnerabilities |
| `/refactor` | Suggest and apply refactoring improvements |

### Development Commands

| Command | Description |
|---------|-------------|
| `/run-tests` | Run tests and analyze failures |
| `/explain-error` | Explain error messages and suggest fixes |
| `/debug-help` | Systematic debugging assistance |
| `/doc-gen` | Generate documentation for code |
| `/deps-check` | Check dependencies for issues and updates |

## Command Details

### `/screenshot`
View and analyze the most recent screenshot from ~/Pictures/Screenshots/.

### `/cleanup-figs`
Clean up old versions of timestamped figures using dry-run first for safety.

### `/git-summary`
Get a complete view of your repository including status, recent commits, branches, and stashes.

### `/new-feature <description>`
Start a new feature branch from main with a proper naming convention and implementation plan.

### `/quick-commit`
Automatically generate a conventional commit message based on your changes.

### `/make-pr`
Create a pull request with auto-generated title, summary, and test plan.

### `/review-changes`
Get a code review of uncommitted changes with quality, security, and performance feedback.

### `/search-code <pattern>`
Thorough codebase search that finds definitions, usages, and related patterns.

### `/todo-scan`
Find and categorize all TODO/FIXME/HACK comments, prioritized by importance.

### `/perf-check`
Identify N+1 queries, memory leaks, inefficient loops, and other performance issues.

### `/security-scan`
Scan for SQL injection, XSS, hardcoded secrets, and other OWASP vulnerabilities.

### `/refactor <file or function>`
Get refactoring suggestions with before/after comparisons and apply selected changes.

### `/run-tests`
Auto-detect test framework, run tests, and provide detailed failure analysis with fixes.

### `/explain-error <error message>`
Get a clear explanation of any error with specific fix suggestions.

### `/debug-help <issue description>`
Systematic debugging with hypothesis generation and investigation steps.

### `/doc-gen <file or function>`
Generate language-appropriate documentation (docstrings, JSDoc, etc.).

### `/deps-check`
Check for outdated packages, security vulnerabilities, and dependency issues.

## Contributing

Feel free to add new commands! Each command should:
1. Have a clear, descriptive filename (kebab-case)
2. Include YAML frontmatter with `description`
3. Provide step-by-step instructions for Claude
4. Handle edge cases gracefully

## License

MIT
