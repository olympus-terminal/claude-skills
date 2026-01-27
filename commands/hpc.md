---
description: Load Jubail HPC best practices into this session
---

You are now working with the **NYU Abu Dhabi Jubail HPC cluster** for user **drn2**. Apply ALL of the following rules for the rest of this session whenever you generate SLURM scripts, Python code, rsync commands, or any HPC-related work.

---

## Golden Rules

1. **NEVER use `/home/drn2/`** -- quota is ~10 GB. Always use `/scratch/drn2/newhome/` as HOME.
2. **ALWAYS detect environment** in Python scripts so they work on both local and HPC.

## Paths

| What | Path |
|------|------|
| Effective HOME | `/scratch/drn2/newhome/` |
| Conda install | `/scratch/drn2/newhome/miniconda3/` |
| Main conda env | `/scratch/drn2/software/conda-mamba_1` |
| TMPDIR | `/scratch/drn2/tmp/` |
| Projects | `/scratch/drn2/PROJECTS/<NAME>/` |
| Local mirror | `/media/drn2/External/<NAME>/` |
| SSH host | `drn2@jubail.abudhabi.nyu.edu` |

## Python Environment Detection (include in every script)

```python
import socket
from pathlib import Path

def get_base_dir(project_name: str) -> Path:
    hostname = socket.gethostname()
    if "cn" in hostname or "gpu" in hostname or "jubail" in hostname:
        return Path(f"/scratch/drn2/PROJECTS/{project_name}")
    return Path(f"/media/drn2/External/{project_name}")
```

Derive ALL file paths from `get_base_dir()`. Never hardcode `/media/drn2/` or `/scratch/drn2/` outside that function.

## SLURM -- Mandatory Environment Block

Every `.sbatch` script MUST have this before any module/conda lines:

```bash
export HOME=/scratch/drn2/newhome
export TMPDIR=/scratch/drn2/tmp
export PYTHONUSERBASE=/scratch/drn2/newhome/.local
mkdir -p $TMPDIR
unset NETWORKX_BACKEND_CONFIG
unset NX_BACKEND_CONFIG
```

Then load modules and conda:

```bash
module load gcc/13.2.0
# module load cuda/12.2.0  # only for nvidia partition
source /scratch/drn2/newhome/miniconda3/etc/profile.d/conda.sh
conda activate /scratch/drn2/software/conda-mamba_1
```

## Partitions

| Partition | Use | Key flags |
|-----------|-----|-----------|
| `compute` | CPU work | `--cpus-per-task=28 --mem=90G` |
| `nvidia` | GPU work (V100/A100/H100) | add `--gres=gpu:N`, load `cuda/12.2.0` |

**GPU partition is `nvidia`, NOT `gpu`.** Max wall time 48h.

## SLURM Defaults

```
--nodes=1 --ntasks=1 --cpus-per-task=28 --mem=90G --time=48:00:00
--output=logs/slurm_%j.out --error=logs/slurm_%j.err
```

Array jobs use `%A_%a` for log names. Always `mkdir -p logs` before submitting.

## File Transfer

```bash
# local -> HPC
rsync -Pvrt /media/drn2/External/PROJECT/ drn2@jubail.abudhabi.nyu.edu:/scratch/drn2/PROJECTS/PROJECT/
# HPC -> local
rsync -Pvrt drn2@jubail.abudhabi.nyu.edu:/scratch/drn2/PROJECTS/PROJECT/ /media/drn2/External/PROJECT/
```

## Job Commands

```bash
sbatch script.sbatch            # submit
squeue -u drn2                  # check jobs
scancel JOBID                   # cancel
sacct -j JOBID                  # accounting
tail -f logs/slurm_JOBID.out   # watch output
```

## Job Dependencies (pipelines)

```bash
JOB1=$(sbatch --parsable step1.sbatch)
JOB2=$(sbatch --parsable --dependency=afterok:$JOB1 step2.sbatch)
```

## Known Pitfalls

- `/home/drn2` paths silently fail or hit quota
- `conda` is NOT on PATH in batch; must `source conda.sh` first
- NetworkX >= 3.6.1 has `nx-loopback` bug -- always unset the env vars
- NumPy >= 2.1 breaks numba/shap -- pin `numpy<2.1` if needed
- Log dirs must exist before submission
- GPU partition is `nvidia` not `gpu`

## Interactive Testing

```bash
srun --pty --partition=compute --cpus-per-task=4 --mem=16G --time=1:00:00 bash
export HOME=/scratch/drn2/newhome
source /scratch/drn2/newhome/miniconda3/etc/profile.d/conda.sh
conda activate /scratch/drn2/software/conda-mamba_1
```

## Login Node Aliases

```bash
ho      # export HOME=/scratch/drn2/newhome
mamba   # load modules + activate ML conda env
```

---

Confirm you have loaded Jubail HPC best practices and briefly summarize what the user should know. Then proceed with whatever task they need.
