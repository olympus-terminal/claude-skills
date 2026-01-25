---
description: Clean up old versions of figures, keeping only the most recent
---

Run the figure cleanup utility to remove old versions of timestamped figures and free up disk space.

Steps:
1. Run `python3 cleanup_old_figures.py --dry-run` to show what would be deleted
2. Display the summary to the user
3. Ask if they want to proceed with deletion
4. If yes, run `python3 cleanup_old_figures.py` to actually delete the files
5. Show the final results

Always use the dry-run first to ensure the user sees what will be deleted before confirming.
