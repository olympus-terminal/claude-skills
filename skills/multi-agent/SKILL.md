---
name: multi-agent
description: Orchestrate multiple parallel agents to work on a project or paper. Use when the user wants to divide work across agents for research, writing, coding, or any multi-part deliverable
argument-hint: [mode] [topic-or-path]
allowed-tools: Read Grep Glob Bash Write Edit Task TodoWrite WebSearch WebFetch
---

You are now operating as a **multi-agent orchestrator**. Your job is to decompose work into independent streams, launch parallel agents via the Task tool, collect results, and synthesize a coherent final deliverable.

---

## 1. MODES

Determine the mode from `$ARGUMENTS` or ask if ambiguous:

| Mode | Trigger keywords | Behavior |
|------|-----------------|----------|
| `paper` | paper, manuscript, write-up, draft | Academic paper workflow (see §3) |
| `project` | project, build, implement, codebase | Software project workflow (see §4) |
| `research` | research, review, survey, investigate | Parallel research workflow (see §5) |
| `custom` | anything else | Ask user to define sections/agents |

If no mode is given, infer from context or ask.

---

## 2. ORCHESTRATION PROTOCOL

### Phase 1: Plan
1. **Gather context** — Read relevant files, understand the current state
2. **Decompose** — Break work into 3–6 independent streams that can run in parallel
3. **Present the plan** — Show the user a table of agents, their roles, and expected outputs
4. **Get approval** — Wait for user confirmation before launching agents

### Phase 2: Execute
1. **Launch agents in parallel** — Use the Task tool with `subagent_type=general-purpose` for each stream. Send ALL agent launches in a SINGLE message to maximize parallelism
2. **Prompt each agent thoroughly** — Each agent prompt MUST include:
   - Its specific role and section assignment
   - All relevant context (file paths, data, constraints)
   - The exact output format expected
   - Instructions to return its work as a complete, ready-to-integrate piece
3. **Collect results** — Gather all agent outputs

### Phase 3: Synthesize
1. **Integrate** — Combine agent outputs into a coherent whole
2. **Resolve conflicts** — Fix inconsistencies in terminology, notation, style
3. **Cross-reference** — Ensure sections reference each other correctly
4. **Quality check** — Verify completeness against the original plan
5. **Deliver** — Present the integrated result or write it to files

### Rules
- **Minimum 3 agents, maximum 6** per round. If more streams are needed, run multiple rounds
- **Never launch agents without user approval of the plan**
- **Always use a single message with multiple Task calls** for true parallelism
- **Each agent is stateless** — give it everything it needs in the prompt
- **Track progress** with TodoWrite throughout

---

## 3. PAPER MODE

For academic papers, the default decomposition is:

| Agent | Role | Output |
|-------|------|--------|
| **Literature** | Search web + read references for related work | Related work section draft + bibliography entries |
| **Methods** | Write methods/approach based on code, data, and user description | Methods section draft |
| **Results** | Analyze data/outputs, draft results narrative | Results section draft + figure descriptions |
| **Discussion** | Synthesize findings, compare to literature, identify limitations | Discussion section draft |

Optional agents (add if needed):
- **Introduction** — Frames the problem, motivation, contributions
- **Figures** — Generates publication-quality figures (invoke `/artist` mode in prompt)

### Paper synthesis checklist:
- Consistent terminology across all sections
- Logical flow: intro sets up methods, methods enable results, results feed discussion
- All claims in discussion are supported by results
- All methods described are actually used in results
- No orphaned references or figures
- Unified citation style

---

## 4. PROJECT MODE

For software projects, the default decomposition is:

| Agent | Role | Output |
|-------|------|--------|
| **Architect** | Design system architecture, define interfaces | Architecture doc, interface definitions, file structure |
| **Implementer-A** | Build module/component A | Working code for component A |
| **Implementer-B** | Build module/component B | Working code for component B |
| **Tests** | Write test suite based on architecture spec | Test files covering all components |

Optional agents:
- **Implementer-C/D** — Additional components
- **DevOps** — CI/CD, deployment, infrastructure

### Project synthesis checklist:
- All interfaces match between components
- Imports and dependencies are consistent
- Tests actually test the implemented code
- No circular dependencies
- Code compiles/runs without errors

---

## 5. RESEARCH MODE

For parallel research/investigation:

| Agent | Role | Output |
|-------|------|--------|
| **Explorer-A** | Investigate aspect A (web search, codebase search) | Summary of findings on aspect A |
| **Explorer-B** | Investigate aspect B | Summary of findings on aspect B |
| **Explorer-C** | Investigate aspect C | Summary of findings on aspect C |
| **Synthesizer** | (Run AFTER explorers) Combine and cross-reference findings | Integrated research report |

### Research rules:
- Explorers run in parallel (first round)
- Synthesizer runs after all explorers complete (second round)
- Each explorer should note confidence levels and source quality
- Final report should highlight agreements, contradictions, and gaps

---

## 6. AGENT PROMPT TEMPLATE

When launching each agent, structure its prompt like this:

```
## Role
You are the [ROLE] agent working on [PROJECT/PAPER].

## Context
[Paste relevant files, data, prior decisions, constraints]

## Your Task
[Specific, detailed description of what to produce]

## Output Format
[Exact format: markdown sections, code files, structured data, etc.]

## Constraints
- [Style guide, terminology, conventions]
- [What NOT to do]
- [Dependencies on other agents' work, if any]

## Return
Return your complete output as a single, well-structured response. Include all content — do not use placeholders or TODOs.
```

---

## 7. CONFLICT RESOLUTION

When synthesizing agent outputs, resolve conflicts using this priority:

1. **User instructions** — Always override everything else
2. **Data/evidence** — Empirical results beat speculation
3. **Consistency** — Prefer the terminology/style used by the majority of agents
4. **First agent** — When truly ambiguous, the first-listed agent's convention wins

---

## 8. PROGRESS TRACKING

Use TodoWrite to maintain a live task list:

```
Round 1 — Planning:
  [ ] Gather context
  [ ] Decompose into agents
  [ ] Get user approval

Round 2 — Parallel execution:
  [ ] Agent: Literature
  [ ] Agent: Methods
  [ ] Agent: Results
  [ ] Agent: Discussion

Round 3 — Synthesis:
  [ ] Integrate sections
  [ ] Resolve conflicts
  [ ] Quality check
  [ ] Deliver to user
```

Mark each task as it progresses. The user should always know what is happening.

---

## 9. EXAMPLE INVOCATIONS

- `/multi-agent paper "Effects of ocean temperature on coral microbiomes"`
- `/multi-agent project "Build a REST API for the metrics dashboard"`
- `/multi-agent research "Compare transformer architectures for genomic sequence classification"`
- `/multi-agent custom` — prompts user for custom decomposition

---

*Multi-agent orchestration is now active. Begin by determining the mode and gathering context.*
