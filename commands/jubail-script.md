---
description: Create a Python script with Jubail HPC environment detection
---

Create a Python script for: $ARGUMENTS

This script must work on BOTH the local workstation and the Jubail HPC cluster.

Steps:

1. Determine the project name and what the script needs to do.

2. Add the environment detection boilerplate at the top of every script:

   ```python
   #!/usr/bin/env python3
   import os
   import socket
   from pathlib import Path

   def get_base_dir(project_name: str) -> Path:
       """Detect if running on Jubail HPC or local workstation."""
       hostname = socket.gethostname()
       if "cn" in hostname or "gpu" in hostname or "jubail" in hostname:
           return Path(f"/scratch/drn2/PROJECTS/{project_name}")
       return Path(f"/media/drn2/External/{project_name}")

   PROJECT = "PROJECT_NAME"
   BASE_DIR = get_base_dir(PROJECT)
   ```

3. Derive ALL file paths from `BASE_DIR`:

   ```python
   data_dir = BASE_DIR / "data"
   results_dir = BASE_DIR / "results"
   figures_dir = BASE_DIR / "figures"
   ```

4. NEVER hardcode absolute paths like `/media/drn2/External/...` directly.
   Always go through `get_base_dir()`.

5. Create output directories if they don't exist:

   ```python
   results_dir.mkdir(parents=True, exist_ok=True)
   figures_dir.mkdir(parents=True, exist_ok=True)
   ```

6. If the script uses multiprocessing or heavy parallelism, detect available CPUs:

   ```python
   import multiprocessing
   n_cpus = int(os.environ.get("SLURM_CPUS_PER_TASK", multiprocessing.cpu_count()))
   ```

7. If the script uses GPU/CUDA, detect GPU availability:

   ```python
   import torch
   device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
   print(f"Using device: {device}")
   if device.type == "cuda":
       print(f"GPU: {torch.cuda.get_device_name(0)}")
   ```

8. Add progress logging with timestamps for long-running jobs:

   ```python
   from datetime import datetime
   def log(msg):
       print(f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] {msg}", flush=True)
   ```

9. Implement the actual task logic using the patterns above.

10. Optionally offer to also generate a matching `.sbatch` script for submission.

CRITICAL VALIDATION before output:
- [ ] `get_base_dir()` function is present and used
- [ ] No hardcoded `/media/drn2/` or `/scratch/drn2/` paths outside the detection function
- [ ] Output directories are created with `mkdir(parents=True, exist_ok=True)`
- [ ] Script has `#!/usr/bin/env python3` shebang
