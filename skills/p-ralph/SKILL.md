---
name: p-ralph
description: P-RALPH methodology briefing — parallel Ralph Wiggum loops in isolated git worktrees for multi-task manuscript/project work. Use when user types /p-ralph to onboard the current agent.
argument-hint: [setup|status|new-config|help]
allowed-tools: Read Grep Glob Bash Write Edit Agent
---

You are being briefed on the **P-RALPH** methodology — a parallel extension of the Ralph Wiggum autonomous agent loop pattern. This briefing makes you operationally competent to create, run, and maintain P-RALPH loops in this project.

---

## 1. WHAT IS RALPH WIGGUM?

Ralph Wiggum is an autonomous agent loop methodology (originated by Geoffrey Huntley) where a bash loop repeatedly feeds a prompt to Claude Code in headless mode (`-p`). Each iteration:

1. Reads the current plan (a JSON array of tasks with `"passes": true/false`)
2. Picks the single most important unfinished task
3. Executes it (code, analysis, writing, etc.)
4. Updates the plan, logs activity, commits
5. Exits — the bash loop restarts with a fresh context window

**Key insight:** The plan file on disk is shared state between stateless iterations. Each iteration starts fresh but reads persistent state, achieving eventual consistency through repetition.

### Core principles (from Huntley's playbook):

- **Context is everything** — one task per iteration keeps the agent in the "smart zone" of its context window
- **Backpressure** — tests, builds, type checks create gates that reject bad work
- **Let Ralph Ralph** — trust the LLM to self-identify, self-correct, and self-improve through iteration
- **Move outside the loop** — the human's job is to engineer the setup and environment, not micromanage tasks
- **Plan is disposable** — regenerate when wrong or stale; cheap compared to bad iterations
- **Simplicity wins** — markdown over JSON, brief prompts, minimal moving parts

### File anatomy of a Ralph loop:

| File | Purpose |
|------|---------|
| `plan.md` | JSON array of tasks — the source of truth for what's done/pending |
| `activity.md` | Timestamped log of completed work |
| `PROMPT.md` | Instructions fed to Claude each iteration |
| `PRD.md` | Product/project requirements document — the "why" |
| `ralph.sh` / `loop.sh` | The outer bash loop |
| `CLAUDE.md` | Data integrity rules and project conventions |

---

## 2. WHAT IS P-RALPH? (THE PARALLEL EXTENSION)

P-RALPH extends vanilla Ralph with **parallel execution in isolated git worktrees**. Instead of one agent grinding through tasks sequentially, multiple agents each work on a separate task simultaneously, in isolation, then merge results.

### Architecture (5 phases):

```
Phase A: Preflight    — validate files, create baseline git tag
Phase B: Analysis     — parallel agents in worktrees (compute, data tasks)
Phase C: Writing      — parallel agents in worktrees (prose, LaTeX tasks)
Phase D: Integration  — sequential merge of worker branches into main
Phase E: Verification — compile, run checks, report status
```

### How isolation works:

1. A **baseline tag** is created at HEAD before any work
2. Each task gets its own **git branch** (`ralph57/task3`) and **worktree** (`.wt_ralph57/task3/`)
3. The agent runs in its worktree with its own copy of plan/activity/prompt files
4. After all workers finish, branches merge into main via `git merge --no-ff`
5. Each merge is individually revertable: `git revert <merge-sha>`

### The config file pattern:

Each P-RALPH run is defined by a **mission config** (`ralphNN_config.sh`) that sets:

```bash
LOOP_NAME="ralph57"              # Identity
BASELINE_TAG="ralph57-baseline"  # Revert anchor
PROJECT_DIR="/path/to/project"   # Working directory

ANALYSIS_TASKS_STR="1 2 5 7"     # Tasks for Phase B (parallel)
WRITING_TASKS_STR="3 4"          # Tasks for Phase C (parallel)

WORKER_ITER=4                    # Max iterations per task
AGENT_MODEL="claude-opus-4-6"    # Model (keep opus-4-6 per user preference)
ALLOWED_TOOLS="Read,Edit,Write,..." # Granular tool permissions

PLAN_FILE="ralph57_plan.md"      # JSON task list
ACTIVITY_FILE="ralph57_activity.md"
PROMPT_FILE="ralph57_PROMPT.md"

CONTEXT_FILES="CLAUDE.md ..."     # Injected into every task prompt
EXTRA_COPY_FILES="ralph57_PRD.md ..." # Copied into worktrees
EXTRA_MKDIRS="source_data/ralph57"    # Created in worktrees

VERIFY_COMMANDS="tectonic main.tex
tectonic supplemental_information.tex"
```

### Execution:

```bash
# Staged run (recommended when tasks share files):
bash ralph.sh analysis  ralph57_config.sh    # Phase B
bash ralph.sh integrate ralph57_config.sh    # Phase D
bash ralph.sh writing   ralph57_config.sh    # Phase C
bash ralph.sh integrate ralph57_config.sh    # Phase D
bash ralph.sh verify    ralph57_config.sh    # Phase E

# Or one-shot:
bash ralph.sh all ralph57_config.sh

# Override task subsets via env:
WRITING_TASKS_STR="3" bash ralph.sh writing ralph57_config.sh
```

### The `wt` CLI (worktree-agent-loop repo):

The user also has a dedicated CLI tool at https://github.com/olympus-terminal/worktree-agent-loop that wraps this into commands:

```bash
wt init                    # Initialize repo for wt workflow
wt create <task-name>      # Create worktree with scaffolding
wt launch <task-name> 20   # Run ralph loop (20 iterations)
wt status                  # Dashboard of all active worktrees
wt merge <task-name>       # Merge back with conflict resolution
wt destroy <task-name>     # Cleanup
wt hpc                     # Query SLURM job status
```

---

## 3. THE PLAN FILE FORMAT

Plans are JSON arrays. Each task has:

```json
[
  {
    "id": 1,
    "category": "analysis",
    "description": "Run coastal vs open-ocean coupling split",
    "passes": false,
    "notes": ""
  },
  {
    "id": 2,
    "category": "writing",
    "description": "Write dipeptide O/E results into SI",
    "passes": true,
    "notes": "Completed 2026-05-28; see source_data/ralph57/"
  }
]
```

- `passes: false` = pending; `passes: true` = done
- The agent reads the plan, finds its assigned task, executes it, sets `passes: true`
- During integration, worker plan state merges back into the main plan

---

## 4. THE PROMPT FILE PATTERN

Every P-RALPH PROMPT.md follows this structure:

```markdown
@CLAUDE.md                    # Context file references
@ralphNN_plan.md
@ralphNN_activity.md
@ralphNN_PRD.md

# RalphNN — [Mission Name]

[1-2 sentence mission summary]

**CRITICAL DATA INTEGRITY POLICY — READ FIRST:**
[Non-negotiable rules about no synthetic data, provenance requirements]

**HPC RULES (if applicable):**
[SLURM submission rules, paths, env detection]

**KILL-ON-SIGHT phrases:**
[Banned AI-isms: delve, leverage, utilize, etc.]

**CLAIM CALIBRATION:**
[Forbidden intensifiers without numerical backing]

**SHARED-FILE / CONCURRENCY RULES:**
[Edit tool only on main.tex etc., re-read before edit, narrow context]

## Workflow
1. Read activity.md
2. Open plan.md, find your assigned task
3. Execute the task
4. Set passes:true, log activity, commit
5. Output <promise>COMPLETE</promise>

ONLY WORK ON YOUR SINGLE ASSIGNED TASK.
```

---

## 5. CRITICAL RULES FOR THIS PROJECT

These are hard-won lessons from 58+ ralph runs on this manuscript:

### Data integrity (non-negotiable)
- NEVER fabricate, simulate, or estimate scientific values
- Every statistic traces to a real file with provenance
- If input missing: STOP and report, never invent

### Model selection
- Use `claude-opus-4-6` for AGENT_MODEL — do NOT upgrade to newer Opus versions without explicit user approval

### Concurrency safety
- Shared files (main.tex, supplemental_information.tex, references.bib): Edit tool ONLY, never Write
- Re-read immediately before each edit
- Use narrow unique `old_string` context so edits fail-safe if another agent modified the file
- When tasks edit the same file, run them SERIALLY (not parallel) or accept merge conflicts

### HPC rules
- All compute via SLURM `.sbatch` submitted with `sbatch` — NEVER `srun`
- Env detection: use `Path.exists()` checks, NOT hostname matching
- Long jobs: submit, record job ID, set `passes:true` once launched and documented

### Writing standards
- Kill-on-sight: delve, leverage, utilize, facilitate, elucidate, pivotal, noteworthy, underscores, Interestingly, Importantly, In conclusion, Taken together
- Claim calibration: forbidden intensifiers (strong, robust, significant, substantial, etc.) require a numerical effect size in the same or adjacent sentence
- Figure naming must match manuscript caption numbers

---

## 6. WHAT TO DO WHEN `/p-ralph` IS INVOKED

Based on `$ARGUMENTS`:

### No arguments or `help`
Print this summary of P-RALPH and ask what the user wants to do.

### `setup` or `new-config`
Help the user create a new ralph mission:
1. Ask for: mission name, task descriptions, which are analysis vs writing, any file dependencies
2. Generate: `ralphNN_config.sh`, `ralphNN_plan.md`, `ralphNN_activity.md`, `ralphNN_PRD.md`, `ralphNN_PROMPT.md`
3. Follow the naming convention: `ralph{next_number}_{descriptive_suffix}`
4. Determine the next ralph number by scanning existing `ralph*_config.sh` files

### `status`
Check the current state:
1. Find the most recent `ralph*_plan.md` and report task completion
2. Check for active worktrees (`git worktree list`)
3. Check for uncommitted changes
4. Report any pending conflicts

### `run` (if user asks to execute)
The user runs ralph.sh from the terminal — do NOT attempt to run it from within Claude Code (it would spawn nested Claude instances). Instead:
1. Verify the config and plan files are ready
2. Print the exact commands the user should run
3. Offer to watch logs if they want

---

## 7. FILE LOCATIONS

| Item | Path |
|------|------|
| Ralph orchestrator | `/media/drn2/External/TARA-Oceans/MANUSCRIPT/ralph.sh` |
| Mission configs | `/media/drn2/External/TARA-Oceans/MANUSCRIPT/ralph*_config.sh` |
| Master guide | `/media/drn2/External/TARA-Oceans/MANUSCRIPT/RALPH_WIGGUM_MASTER_GUIDE.md` |
| Original methodology | `/media/drn2/External/TARA-Oceans/MANUSCRIPT/RALPH_original_guide_huntley.txt` |
| Remote repo | `https://github.com/olympus-terminal/worktree-agent-loop` |
| Git remote | `git@github.com:olympus-terminal/ELF-NET-manuscript.git` |

---

## 8. CREATING A NEW MISSION (TEMPLATE)

When asked to set up a new ralph loop, follow this checklist:

1. **Determine next number**: scan `ralph*_config.sh` for highest N, use N+1
2. **Create plan** (`ralphNN_plan.md`): JSON array with task objects
3. **Create PRD** (`ralphNN_PRD.md`): requirements, context, what's in/out of scope
4. **Create prompt** (`ralphNN_PROMPT.md`): agent instructions with all guards
5. **Create activity** (`ralphNN_activity.md`): empty log with header
6. **Create config** (`ralphNN_config.sh`): mission parameters
7. **Validate**: check ralph.sh exists, plan is valid JSON, required tools listed
8. **Print run commands**: staged execution sequence for the user

### Task dependency planning:
- Tasks that touch DIFFERENT files: safe to parallelize
- Tasks that touch the SAME file (e.g., both edit main.tex): run SERIALLY or accept merge conflicts
- Tasks with data dependencies (task 4 needs output of task 2): put dependent task in a later wave
- Analysis tasks first, writing tasks after (writing often needs analysis results)

---

*P-RALPH briefing complete. You are now operationally competent to work with this system.*
