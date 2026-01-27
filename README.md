# Claude Skills

A collection of custom Claude Code commands and skills for enhanced productivity.

## Structure

```
claude-skills/
├── commands/       # Slash commands (.md files)
├── scripts/        # Supporting Python scripts
├── skills/         # Skill definitions (auto-loaded reference knowledge)
│   └── jubail/     # NYU Abu Dhabi Jubail HPC cluster
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

For skills (auto-loaded reference knowledge), copy to `~/.claude/skills/`:

```bash
# Copy the Jubail HPC skill
cp -r skills/jubail ~/.claude/skills/
```

## Available Commands

### Utility Commands

| Command | Description |
|---------|-------------|
| `/screenshot` | View and analyze the most recent screenshot |
| `/cleanup-figs` | Clean up old timestamped figure versions |
| `/log` | Export current session to readable .log file |

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

### HPC Commands (Jubail - NYU Abu Dhabi)

| Command | Description |
|---------|-------------|
| `/jubail-slurm` | Generate a SLURM batch script for Jubail HPC |
| `/jubail-script` | Create a Python script with HPC environment detection |
| `/jubail-deploy` | Prepare and transfer files to/from Jubail HPC |
| `/jubail-debug` | Debug a failed Jubail HPC job |

**Auto-loaded skill:** The `jubail` skill (`skills/jubail/`) is reference knowledge that Claude loads automatically when working on HPC-related tasks. It enforces the `/scratch/drn2/` path conventions, SLURM template rules, and known pitfalls.

## Command Details

### `/screenshot`
View and analyze the most recent screenshot from ~/Pictures/Screenshots/.

### `/cleanup-figs`
Clean up old versions of timestamped figures using dry-run first for safety.

### `/log`
Export the current Claude Code session to a readable `.log` file. Creates a timestamped file with all user/assistant messages. Requires `scripts/export_session.py` to be installed at `~/.claude/commands/`.

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

### `/jubail-slurm <description>`
Generate a SLURM batch script for Jubail HPC. Supports CPU (`compute`), GPU (`nvidia`), and array jobs. Automatically includes all required environment setup (HOME override, conda activation, NetworkX workaround).

### `/jubail-script <description>`
Create a Python script with automatic environment detection that works on both the local workstation (`/media/drn2/External/`) and Jubail HPC (`/scratch/drn2/PROJECTS/`). Uses hostname-based detection via `get_base_dir()`.

### `/jubail-deploy <project>`
Generate rsync commands to transfer files between local machine and Jubail HPC. Supports upload, download, selective sync, and dry-run mode. Includes pre-submission checklist.

### `/jubail-debug <error or job ID>`
Diagnose failed HPC jobs against a known-issues database (wrong HOME, hardcoded paths, missing modules, NetworkX bug, NumPy conflicts, etc.). Provides step-by-step debugging and fix suggestions.

## Skills

Skills are auto-loaded reference knowledge that Claude uses when relevant. They are not invoked as slash commands.

### `jubail`
Comprehensive reference for the NYU Abu Dhabi Jubail HPC cluster. Covers:
- Path conventions (`/scratch/drn2/` instead of `/home/drn2/`)
- Python environment detection pattern
- SLURM template requirements
- Partition selection (`compute` vs `nvidia`)
- Conda environment management
- Known package issues and workarounds

Install: `cp -r skills/jubail ~/.claude/skills/`

## Contributing

Feel free to add new commands! Each command should:
1. Have a clear, descriptive filename (kebab-case)
2. Include YAML frontmatter with `description`
3. Provide step-by-step instructions for Claude
4. Handle edge cases gracefully

## License

MIT
