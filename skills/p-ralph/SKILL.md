---
name: p-ralph
description: P-RALPH methodology briefing — parallel Ralph Wiggum loops in isolated git worktrees for multi-task manuscript/project work. Use when user types /p-ralph to onboard the current agent.
argument-hint: [setup|status|new-config|help]
allowed-tools: Read Grep Glob Bash Write Edit Agent
---

You are being briefed on the **P-RALPH** methodology — a parallel extension of the Ralph Wiggum autonomous agent loop pattern. This briefing makes you operationally competent to create, run, and maintain P-RALPH loops in this project.

---

## 0. ORIENT BEFORE YOU ACT (read this first)

New Claudes repeatedly trip on the same five things. Internalize these before
doing anything; each is expanded later with the why.

1. **Nothing lives where you assume — `find` first.** The orchestrator
   (`ralph.sh`), prior configs, and the guides get swept into `archive/` during
   repo re-orgs. Never trust a hardcoded path. See §7.
2. **Count missions across ALL homes** (root + `archive/ralph_configs/` +
   `source_data/ralph*`) before picking the next number. Root alone undercounts
   because finished missions are archived. When unsure, ASK. See §8 step 0.
3. **`integrate` merges EVERY worker branch in one pass.** Two tasks touching
   the same file → conflict → stranded work. To truly serialize, interleave
   `analysis`+`integrate` per task; don't just split waves. See §5.
4. **Visual tasks require visual proof.** Regenerate → render to PNG → crop to
   the panel → Read it → iterate. Summaries lie; a shrunk thumbnail hides
   overlaps. See §5.
5. **One command for the user.** Generate `ralphNN_run.sh` and hand over
   `./ralphNN_run.sh` — not a 5-line staged sequence. See §Execution and §8.

When the work is done: push edits through to the COMPILED artifact (e.g.
`supplemental_information.pdf`), open only that, and report what you verified —
not "should be fixed."

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

**DEFAULT = ONE SHOT.** Every mission ships a generated `ralphNN_run.sh` launcher
(see §8) that resolves the orchestrator + config by path and runs the full
mission. The user should only ever need ONE command:

```bash
./ralphNN_run.sh                 # full mission: preflight -> analysis -> writing -> integrate -> verify -> cleanup
```

`ralph.sh all` already chains every phase, so a single invocation is the norm.
Do NOT hand the user a 3-5 line staged sequence as the primary instruction —
that is friction. The launcher hides the orchestrator path (which may live in
`archive/ralph_configs/ralph.sh` after a re-org, not project root).

Staged / single-phase runs are an ESCAPE HATCH only — surface them only if the
user asks, or if tasks edit the same shared file and you flag a merge risk:

```bash
./ralphNN_run.sh analysis        # one phase (analysis|writing|integrate|verify|continue)
WRITING_TASKS_STR="3" bash <orchestrator> writing ralphNN_config.sh   # task subset
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

## 5. CRITICAL RULES

These are hard-won lessons from 58+ ralph runs:

### Data integrity (non-negotiable)
- NEVER fabricate, simulate, or estimate scientific values
- Every statistic traces to a real file with provenance
- If input missing: STOP and report, never invent

### Model selection
- Default `claude-opus-4-6` for AGENT_MODEL — do NOT silently upgrade.
- EXCEPTION: when the user explicitly asks (e.g. "use opus-4-8 for graphics"),
  set the model they named in the config and note it. The user's instruction
  in the session always wins over this default.

### Concurrency safety — and how `integrate` ACTUALLY works
- Shared files (main.tex, supplemental_information.tex, references.bib): Edit
  tool ONLY, never Write. Re-read immediately before each edit. Use narrow
  unique `old_string` context so edits fail-safe.
- **CRITICAL — the integrate phase merges ALL branches in ONE pass.** A single
  `bash ralph.sh integrate` builds `merge_order = (all analysis tasks + all
  writing tasks)` and merges every worker branch sequentially into main. So if
  TWO tasks both edited `supplemental_information.tex` (even different lines)
  and you call `integrate` once at the end, git raises add/add conflicts and
  the orchestrator bails with "No resolver script found" — the work is stranded
  on the worker branches and never reaches main. This bit a real session.
- **To genuinely serialize same-file tasks, INTERLEAVE per task** — do NOT just
  split the analysis waves and integrate once at the end:
  ```bash
  ralph.sh preflight                       # baseline tag, ONCE
  ANALYSIS_TASKS_STR="1" ralph.sh analysis # task 1 only
  ANALYSIS_TASKS_STR="1" ralph.sh integrate# merge task 1 on a clean tree
  ANALYSIS_TASKS_STR="2" ralph.sh analysis # task 2 only
  ANALYSIS_TASKS_STR="2" ralph.sh integrate# merge task 2 on a clean tree
  ralph.sh verify
  ```
  The generated `ralphNN_run.sh` (see §8) should encode exactly this interleave
  when same-file conflict risk exists — that is the whole point of the launcher.
- `analysis`/`integrate`/`verify` phases do NOT re-run preflight, so calling
  preflight once up front is safe and wave 1's merge survives into wave 2.

### Recovering a failed integrate (stranded branches)
If integrate conflicted and left work on `ralphNN/taskN` branches:
1. `git status` — confirm main is clean (no half-merge); the work is safe on
   the branches, not lost.
2. Merge branches ONE AT A TIME: `git merge --no-ff ralphNN/task1`, resolve,
   then `ralphNN/task2`. For two figures editing different `\includegraphics`
   lines the `.tex` merges cleanly; for the binary PDF, just recompile fresh
   (`tectonic ...`) and `git add` the rebuilt PDF to resolve.
3. Untracked `ralphNN_activity.md` / `_run.sh` in the tree can block a merge
   ("would be overwritten") — move them aside, merge, restore.

### Visual / figure-task verification (MANDATORY for any figure work)
A figure fix is NOT done until you have SEEN it fixed. Summary text lies.
- Regenerate the figure, then render the PDF to PNG: `pdftoppm -png -r 220
  <fig>.pdf <out>`, and **Read the PNG**.
- For dense multi-panel figures, the full-figure render is too small to judge —
  **crop to the affected panel/region** (PIL) and Read that. Today a legend
  overlap survived TWO "fixed" claims because it was judged from a shrunk
  full-figure thumbnail. Crop and zoom.
- Iterate: if the render still shows the defect, adjust and re-render. Only set
  `passes:true` after the cropped, high-res view confirms the fix AND nothing
  else regressed.
- After all figure edits: update the `\includegraphics` filename, recompile the
  document, and open ONLY the final compiled PDF (e.g.
  `supplemental_information.pdf`) — not each standalone figure file, unless the
  user asks. "Push through to the compiled artifact, then open that."

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
1. Find the most recent `ralph*_plan.md` and report task completion (count
   `passes:true` / total).
2. Check for active worktrees (`git worktree list`) and leftover worker
   branches (`git branch | grep ralphNN/`) — leftover branches with commits
   mean a previous integrate FAILED and work is stranded (see §5 recovery).
3. Check for uncommitted changes and `ralphNN_logs/pending_conflicts_*.txt`.
4. Report any pending conflicts and whether main is clean.

### `run` (if user asks to execute)
The user runs the loop from the terminal — do NOT run it from within Claude Code
(it would spawn nested Claude instances). Instead:
1. Verify the config, plan, and `ralphNN_run.sh` launcher exist.
2. Print ONE command: `./ralphNN_run.sh` (the launcher hides the orchestrator
   path and encodes any required serialization). Do not hand over a multi-line
   staged sequence as the default.
3. Offer to watch logs / help resolve conflicts if integrate fails.

---

## 7. KEY REFERENCES

**Locations drift after repo re-orgs — ALWAYS `find` before assuming.** In this
project the orchestrator and guides were swept into `archive/` and are NOT in
project root. Do not trust a hardcoded path; search first.

| Item | Where to look (search, don't assume) |
|------|----------|
| Framework repo | `https://github.com/olympus-terminal/worktree-agent-loop` |
| Ralph orchestrator | `find <project> -name ralph.sh` — commonly `archive/ralph_configs/ralph.sh`, NOT project root after a re-org |
| Active mission files | project root while a mission runs (`ralphNN_*`) |
| Archived missions | `archive/ralph_configs/` — completed configs/plans/PRDs/prompts land here |
| Mission outputs (committed) | `source_data/ralphNN/` |
| Run logs | `archive/ralph_loops_archive/` and/or `ralphNN_logs/` |
| Master guide | `archive/ralph_configs/RALPH_WIGGUM_MASTER_GUIDE.md` (canonical copy) |
| Huntley's original | `saved_logs/RALPH_original_guide_huntley.txt` |

These files are gitignored as session-specific working files (pattern
`ralph*_{plan,PRD,PROMPT}.md`, `ralph*_config.sh`, `ralph*_run.sh`,
`ralph*_activity.md`). Figure PDFs/SVGs under `figures/` are often gitignored
too — use `git add -f` to track a regenerated figure the manuscript references.

---

## 8. CREATING A NEW MISSION (TEMPLATE)

When asked to set up a new ralph loop, follow this checklist:

0. **Orient first — find the highest mission number across ALL homes, not just
   root.** Completed missions get archived, so scanning root configs alone
   UNDERCOUNTS and you'll reuse a number. Check every home:
   ```bash
   ls ralph*_config.sh archive/ralph_configs/ralph*_config.sh \
      archive/ralph_configs/ralph*_plan.md source_data/ralph* 2>/dev/null \
      | grep -oE 'ralph[0-9]+' | grep -oE '[0-9]+' | sort -n | tail -1
   ```
   If unsure whether recent missions ran, ASK the user ("last I see is ralphNN —
   is that right?") rather than guessing. A real session reused a number because
   it only saw a stray plan file in root.
1. **Determine next number**: highest N found in step 0, use N+1.
2. **Create plan** (`ralphNN_plan.md`): JSON array with task objects
3. **Create PRD** (`ralphNN_PRD.md`): requirements, context, what's in/out of scope
4. **Create prompt** (`ralphNN_PROMPT.md`): agent instructions with all guards
5. **Create activity** (`ralphNN_activity.md`): empty log with header
6. **Create config** (`ralphNN_config.sh`): mission parameters
7. **Locate the orchestrator**: `ralph.sh` may NOT be in project root after a
   re-org — search the project (commonly `archive/ralph_configs/ralph.sh`).
   Find it ONCE here so the launcher can hardcode the path.
8. **Create launcher** (`ralphNN_run.sh`): a thin one-shot wrapper that resolves
   the orchestrator + config relative to itself and `exec`s `ralph.sh ${1:-all}`.
   `chmod +x` it. This is the user's single entry point — ALWAYS generate it.
9. **gitignore hygiene**: ensure `ralph*_run.sh` (and the other `ralph*_*`
   working files) are gitignored — they are session-specific, not source.
10. **Validate**: orchestrator found, plan is valid JSON, required tools listed,
    launcher passes `bash -n`.
11. **Print ONE run command**: `./ralphNN_run.sh`. Not a staged sequence —
    one shot is the default (see §Execution). Mention the staged escape hatch
    only if shared-file merge risk warrants it.

The `ralphNN_run.sh` template:
```bash
#!/bin/bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORCH="${HERE}/<path-to>/ralph.sh"     # resolved in step 7
CONFIG="${HERE}/ralphNN_config.sh"
exec bash "$ORCH" "${1:-all}" "$CONFIG"
```

### Task dependency planning:
- Tasks that touch DIFFERENT files: safe to parallelize
- Tasks that touch the SAME file (e.g., both edit main.tex): run SERIALLY or accept merge conflicts
- Tasks with data dependencies (task 4 needs output of task 2): put dependent task in a later wave
- Analysis tasks first, writing tasks after (writing often needs analysis results)

---

*P-RALPH briefing complete. You are now operationally competent to work with this system.*
