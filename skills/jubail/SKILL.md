---
name: jubail
description: >
  Reference knowledge for NYU Abu Dhabi Jubail HPC cluster. Auto-loads when
  working on SLURM scripts, HPC batch jobs, Python scripts that need to run on
  the cluster, or any task involving /scratch/drn2/ paths. Provides environment
  conventions, path mappings, SLURM templates, and known pitfalls.
user-invocable: false
---

# Jubail HPC -- Reference Knowledge

You are assisting user **drn2** on the **NYU Abu Dhabi Jubail HPC** cluster.
Always apply the rules and conventions below when generating SLURM scripts,
Python code destined for HPC, rsync commands, or any HPC-related advice.

For full details, read `skills/jubail/reference.md` in this skill directory.

---

## Golden Rules

1. **NEVER use `/home/drn2/`** -- the home quota is ~10 GB.
   Always use `/scratch/drn2/newhome/` as the effective HOME.
2. **ALWAYS add environment detection** to any Python script that may run on
   both the local workstation and the cluster.

---

## Path Mapping

| Context | Path |
|---------|------|
| Effective HOME on HPC | `/scratch/drn2/newhome/` |
| Conda install | `/scratch/drn2/newhome/miniconda3/` |
| Main conda env | `/scratch/drn2/software/conda-mamba_1` |
| TMPDIR for jobs | `/scratch/drn2/tmp/` |
| All projects | `/scratch/drn2/PROJECTS/<PROJECT_NAME>/` |
| Local project mirror | `/media/drn2/External/<PROJECT_NAME>/` |

---

## Python Environment Detection (always include)

```python
import socket
from pathlib import Path

def get_base_dir(project_name: str) -> Path:
    hostname = socket.gethostname()
    if "cn" in hostname or "gpu" in hostname or "jubail" in hostname:
        return Path(f"/scratch/drn2/PROJECTS/{project_name}")
    return Path(f"/media/drn2/External/{project_name}")
```

---

## SLURM Script Requirements

Every `*.sbatch` file MUST contain these environment lines before any
`module load` or `conda activate`:

```bash
export HOME=/scratch/drn2/newhome
export TMPDIR=/scratch/drn2/tmp
export PYTHONUSERBASE=/scratch/drn2/newhome/.local
mkdir -p $TMPDIR
unset NETWORKX_BACKEND_CONFIG
unset NX_BACKEND_CONFIG
```

Then load modules and activate conda:

```bash
module load gcc/13.2.0
# module load cuda/12.2.0   # uncomment for GPU partition
source /scratch/drn2/newhome/miniconda3/etc/profile.d/conda.sh
conda activate /scratch/drn2/software/conda-mamba_1
```

---

## Partition Selection

| Partition | Use case | Notes |
|-----------|----------|-------|
| `compute` | CPU-parallel work | `--cpus-per-task=28 --mem=90G` |
| `nvidia`  | GPU work (V100/A100/H100) | add `--gres=gpu:N`, load `cuda/12.2.0` |

**The GPU partition is called `nvidia`, NOT `gpu`.** Max wall time is 48 h.

---

## File Transfer

```bash
# Local -> HPC
rsync -Pvrt /media/drn2/External/PROJECT/ drn2@jubail.abudhabi.nyu.edu:/scratch/drn2/PROJECTS/PROJECT/

# HPC -> Local
rsync -Pvrt drn2@jubail.abudhabi.nyu.edu:/scratch/drn2/PROJECTS/PROJECT/ /media/drn2/External/PROJECT/
```

---

## Common Pitfalls

- Paths referencing `/home/drn2` will silently fail or hit quota.
- `conda` is not on PATH in batch jobs; you MUST `source conda.sh` first.
- NetworkX >= 3.6.1 has an `nx-loopback` bug; unset the env vars (see above).
- NumPy >= 2.1 breaks numba/shap; pin `numpy<2.1` if needed.
- Log directories (`logs/`) must exist before submission: `mkdir -p logs`.
- The partition for GPUs is `nvidia` not `gpu`.
