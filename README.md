# Claude Skills

A collection of custom Claude Code [Anthropic] commands and skills for enhanced productivity.

## Structure

```
claude-skills/
├── commands/              # Slash commands (.md files → ~/.claude/commands/)
├── skills/                # Skill directories (→ ~/.claude/skills/)
│   ├── caveman/           #   /caveman — toggle caveman-speak
│   └── multi-agent/       #   /multi-agent — parallel agent orchestration
├── scripts/               # Supporting Python scripts
├── install.sh             # Symlink installer (--clone, --update, --uninstall)
└── examples/              # Example configurations
```

## Installation

```bash
# Bootstrap on a new machine (clones repo + symlinks everything)
./install.sh --clone

# Update after pulling new changes
./install.sh --update

# Or just re-link from an existing checkout
./install.sh
```

Commands are symlinked into `~/.claude/commands/`, skills into `~/.claude/skills/`. Existing files are backed up before replacement.

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

### Scientific Writing & Review

| Command | Description |
|---------|-------------|
| `/science-writing` | Line-edit prose for high-impact journals (Nature, Cell, eLife) |
| `/reviewer` | In silico manuscript reviewer in David R. Nelson's voice |
| `/repo` | Audit repos for publication readiness (GitHub, HuggingFace, Zenodo) |
| `/speak` | Extract text from media and convert to TTS audio (MP3) |

### Session Management

| Command | Description |
|---------|-------------|
| `/signoff` | Write structured handoff note for the next agent/session |

### HPC Commands

| Command | Description |
|---------|-------------|
| `/hpc` | Load Jubail HPC best practices into the session |

## Available Skills

Skills are richer than commands — they have their own directories with supporting files (templates, state, etc.) and are installed into `~/.claude/skills/`.

| Skill | Description |
|-------|-------------|
| `/caveman` | Toggle caveman-speak mode. Prose goes caveman, code stays untouched. |
| `/multi-agent` | Orchestrate 3-6 parallel agents for papers, projects, or research. Modes: `paper`, `project`, `research`, `custom`. |

### `/multi-agent` details

Includes two planning templates:
- `paper-template.md` — Decompose academic papers into Literature/Methods/Results/Discussion agents
- `project-template.md` — Decompose software projects into Architect/Implementer/Tests agents

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

### `/hpc`
Load NYU Abu Dhabi Jubail HPC best practices into the current session. Teaches Claude the `/scratch/drn2/` path conventions, SLURM template requirements, Python environment detection patterns, partition selection, and known pitfalls. Run this at the start of any HPC-related session.

## Contributing

### Adding a command
1. Create `commands/your-command.md` with YAML frontmatter (`description` required)
2. Run `./install.sh` to symlink it
3. Commit and push — other machines pick it up via `./install.sh --update`

### Adding a skill
1. Create `skills/your-skill/SKILL.md` with YAML frontmatter (`name`, `description`, `allowed-tools`)
2. Add any supporting files (templates, state trackers) in the same directory
3. Run `./install.sh` to symlink the directory
4. Commit and push

## License

MIT
