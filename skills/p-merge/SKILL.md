---
name: p-merge
description: Working in a shared tree while other agents (Claude, Codex, the user) commit in parallel. Sync before editing, build on the latest version of every shared file, stage only your own paths, and report the merged state as fact. Use when the user types /p-merge, or whenever git shows commits or file changes you did not make.
argument-hint: [check|commit|help]
allowed-tools: Read Grep Glob Bash Edit Write
---

# P-MERGE: co-working with parallel agents

Parallel agents are the NORM in this user's projects, not an anomaly. Other sessions commit to the same branch
in the same working tree while you work. Your job is to fold their work and yours into one consistent state
without stopping, without reverting anything, and without reporting their commits as caveats.
(For orchestrated worktree loops, see /p-ralph. This skill is for ad hoc parallel sessions on one tree.)

## 1. Sync at three moments
At the start of a task, before editing any shared file, and before every commit:
```bash
git log --oneline -8 && git status --short -- <paths you will touch>
git log --oneline <last-sha-you-saw>..HEAD --stat     # what others committed since you last looked
```
Read every foreign commit that touches a file you are about to edit, or an artifact you derive from. A
foreign change is new input, not a problem. Never revert it, overwrite it, or redo it.

## 2. Build on the latest version, never on your memory of it
- **Shared text** (main.tex, SI, cover letter, bib): Re-read the region right before an Edit. Use narrow, unique
  `old_string` so a stale edit fails instead of clobbering. Never Write a whole shared file from a cached copy.
- **Versioned artifacts** (figure scripts `make_fig_X_<stamp>.py`, tables, package manifests): derive the next
  version from the NEWEST stamp on disk and in the .tex, not from the last one you wrote. Find it with
  `grep includegraphics main.tex`, `ls -t`, and the manifest.
- **Check the newest version still carries your earlier change.** Diff the foreign script against yours (e.g.
  `diff make_fig_X_<old>.py make_fig_X_<new>.py`). If your change was dropped, re-apply it on top of theirs as a new
  stamped version.
- **Derived binaries** (main.pdf, compressed portal PDFs) are never merged. Rebuild them from the current
  sources, which already contain everyone's work.
- **Manifests and indexes:** read the current file, then update rows in place. A row you did not touch stays as
  it is, even if it points to a version you did not make.

## 3. Prove the commit contains only your work
1. Before the first edit of a shared file, keep a timestamped copy. Before committing, confirm that the copy
   equals `git show HEAD:<path>`, or that it differs only by foreign commits you have read. If someone left
   UNCOMMITTED edits in the same file, commit only your hunks: write a patch of them and `git apply --cached`.
   Leave their hunks unstaged.
2. Stage named paths only: `git add <file> <file>`. Never `git add` an untracked directory wholesale. Never
   `git add -A` or `git add .`.
3. Read `git diff --cached --stat` before committing. Every line must be a file you changed on purpose.
4. To unstage, use `git restore --staged <path>`. **Never use `git rm -r --cached <dir>`**: it also untracks
   files other agents committed in that directory. (This happened: two tracked plan files were untracked while
   backing out an accidental package add.)
5. If a mistaken commit is still unpushed, fix it with `--amend`, then re-check `git show --stat HEAD`.

## 4. When intents genuinely collide
If two agents changed the same lines, merge by meaning, keeping both intents (e.g. their capitalization pass
plus your new sentence). Ask the user only when the intents contradict each other (one deletes what the other
expands), and then show both versions side by side.

## 5. Running jobs and outputs
Do not touch HPC jobs, background processes, or output folders that another agent created. New outputs get new
timestamps, so they never overwrite a parallel agent's file.

## 6. Reporting
State the merged state as fact, in one line if at all: "Built on <sha> (<what it changed>); verified it
keeps <your earlier change>." Do not frame other agents' commits as surprises, warnings, or "things you should
know". Mention a foreign change only if it alters a number, a decision, or something the user must act on.

## /p-merge check
Run §1 and list foreign commits since your last known SHA, with the files they touched that overlap yours.
Confirm that the newest version of each shared artifact carries your changes (§2), and that nothing is
half-staged (§3).
