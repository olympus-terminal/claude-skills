# Multi-Agent Templates

Templates for decomposing work across parallel agents.

---

## Paper Plan Template

Use when decomposing a paper into agent assignments.

### Metadata
- **Title**: [working title]
- **Target journal**: [if known]
- **Authors**: [if known]
- **Status**: [new draft / revision / rewrite]

### Agent Assignments

**Agent 1: Literature**
- Search terms: [key phrases for web/literature search]
- Scope: [how far back, which databases, which subfields]
- Output: Related work section (500-1000 words) + key references

**Agent 2: Methods**
- Source material: [code paths, notebooks, experimental protocols]
- Level of detail: [reproducibility-grade / overview]
- Output: Methods section (500-1500 words) + equations or pseudocode

**Agent 3: Results**
- Data location: [paths to results, tables, figures]
- Key findings: [bullet points of what to highlight]
- Output: Results section (500-1500 words) + figure/table descriptions

**Agent 4: Discussion**
- Key comparisons: [what prior work to compare against]
- Limitations: [known weaknesses]
- Output: Discussion section (500-1000 words) including limitations and future work

### Integration Notes
- Citation style: [APA / Vancouver / journal-specific]
- Terminology conventions: [terms that must be consistent]
- Abbreviations: [define once in intro, use throughout]

---

## Project Plan Template

Use when decomposing a software project into agent assignments.

### Metadata
- **Project name**: [name]
- **Language/stack**: [Python, TypeScript, etc.]
- **Status**: [greenfield / extension / refactor]

### Agent Assignments

**Agent 1: Architect**
- Scope: define modules, interfaces, data flow, file structure
- Constraints: [existing conventions, dependencies]
- Output: architecture document with interface definitions

**Agent 2: Implementer-A** -- [Component Name]
- Scope: [specific module or feature]
- Interfaces: [what it exposes, what it consumes]
- Output: working code files

**Agent 3: Implementer-B** -- [Component Name]
- Scope: [specific module or feature]
- Interfaces: [what it exposes, what it consumes]
- Output: working code files

**Agent 4: Tests**
- Framework: [pytest / jest / etc.]
- Coverage targets: [which components, which edge cases]
- Output: test files with passing tests

### Integration Notes
- Shared types/interfaces: [path to shared definitions]
- Error handling: [exceptions / result types / etc.]
- Import style: [absolute / relative]
