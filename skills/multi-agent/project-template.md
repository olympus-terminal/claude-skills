# Project Plan Template

Use this template when decomposing a software project into agent assignments.

## Metadata
- **Project name**: [name]
- **Language/stack**: [Python, TypeScript, etc.]
- **Status**: [greenfield / extension / refactor]

## Agent Assignments

### Agent 1: Architect
- **Scope**: Define modules, interfaces, data flow, file structure
- **Constraints**: [existing codebase conventions, dependencies]
- **Output**: Architecture document with interface definitions

### Agent 2: Implementer-A — [Component Name]
- **Scope**: [specific module or feature]
- **Interfaces**: [what it exposes, what it consumes]
- **Output**: Working code files for this component

### Agent 3: Implementer-B — [Component Name]
- **Scope**: [specific module or feature]
- **Interfaces**: [what it exposes, what it consumes]
- **Output**: Working code files for this component

### Agent 4: Tests
- **Framework**: [pytest / jest / etc.]
- **Coverage targets**: [which components, which edge cases]
- **Output**: Test files with passing tests

## Integration Notes
- Shared types/interfaces: [path to shared definitions]
- Error handling convention: [exceptions / result types / etc.]
- Import style: [absolute / relative]
