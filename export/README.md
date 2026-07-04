# Portable Agent Skills

Agent-agnostic instructions extracted from [claude-skills](https://github.com/olympus-terminal/claude-skills). These work with any coding agent that reads markdown instructions: Claude Code, OpenCode, Codex, Cursor, Aider, etc.

## Usage

**Option 1: Drop one combined file into your project**
```bash
cp AGENTS.md /path/to/your/project/
```
Any agent that reads project-root markdown files (CLAUDE.md, AGENTS.md, .cursorrules, CODEX.md, etc.) will absorb these instructions automatically.

**Option 2: Include specific modules**
Copy only the files you need from this directory. Reference them from your agent config.

## Files

| File | What it does |
|------|-------------|
| `AGENTS.md` | Combined file — all modules below in one document |
| `policies.md` | Data integrity rules, shell command formatting |
| `science-writing.md` | Line editor for scientific prose (Nature, Cell, eLife level) |
| `publication-figures.md` | Publication-quality figure standards (matplotlib, TikZ, seaborn, SVG) |
| `reviewer.md` | In silico peer reviewer — 3-pass manuscript review |
| `repo-audit.md` | 4-pass audit to make repos publication-ready |
| `security.md` | Security vulnerability scan + performance analysis |
| `dev-workflow.md` | 13 dev procedures: debug, review, commit, PR, refactor, tests, etc. |
| `multi-agent-templates.md` | Templates for parallelizing paper/project work across agents |

## Agent Compatibility

These are pure markdown instructions. No YAML frontmatter, no tool-specific syntax, no slash commands. To use with a specific agent:

| Agent | How to load |
|-------|------------|
| Claude Code | Copy `AGENTS.md` to project root (auto-loaded as CLAUDE.md) or `~/.claude/CLAUDE.md` for global |
| OpenCode | Copy to project root as `AGENTS.md` or reference in config |
| Codex | Copy as `CODEX.md` or include in system prompt |
| Cursor | Copy content into `.cursorrules` |
| Aider | Reference in `.aider.conf.yml` or paste into chat |
| Any LLM | Paste into system prompt or provide as context document |
