# Jubail HPC -- Detailed Reference

## Directory Layout

```
/scratch/drn2/
├── newhome/                           # Effective HOME
│   ├── miniconda3/                    # Miniconda installation
│   │   └── etc/profile.d/conda.sh    # Source this for conda
│   ├── .bashrc                        # Shell config
│   ├── .local/                        # pip --user packages
│   └── .ssh/                          # SSH keys
├── software/
│   └── conda-mamba_1/                 # Main ML/AI conda env
├── tmp/                               # TMPDIR for jobs
└── PROJECTS/                          # All research projects
    └── PROJECT_NAME/
        ├── data/
        ├── scripts/
        ├── results/
        ├── figures/
        └── logs/
```

---

## Interactive Aliases (Login Node)

After SSH login, run these before any work:

```bash
ho      # export HOME=/scratch/drn2/newhome
mamba   # Load modules (gcc/cuda) and activate ML/AI conda env
```

---

## SLURM Templates

### Standard CPU Job

```bash
#!/bin/bash
#SBATCH --job-name=PROJECT_TASK
#SBATCH --partition=compute
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=28
#SBATCH --mem=90G
#SBATCH --time=48:00:00
#SBATCH --output=logs/slurm_%j.out
#SBATCH --error=logs/slurm_%j.err

export HOME=/scratch/drn2/newhome
export TMPDIR=/scratch/drn2/tmp
export PYTHONUSERBASE=/scratch/drn2/newhome/.local
mkdir -p $TMPDIR
unset NETWORKX_BACKEND_CONFIG
unset NX_BACKEND_CONFIG

module load gcc/13.2.0
source /scratch/drn2/newhome/miniconda3/etc/profile.d/conda.sh
conda activate /scratch/drn2/software/conda-mamba_1

echo "============================================"
echo "Job ID: $SLURM_JOB_ID"
echo "Node: $(hostname)"
echo "Started: $(date)"
echo "============================================"

cd /scratch/drn2/PROJECTS/PROJECT_NAME || exit 1
python scripts/your_script.py

echo "============================================"
echo "Completed: $(date)"
echo "============================================"
```

### GPU Job

```bash
#!/bin/bash
#SBATCH --job-name=gpu_task
#SBATCH --partition=nvidia
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=28
#SBATCH --gres=gpu:4
#SBATCH --mem=90G
#SBATCH --time=48:00:00
#SBATCH --output=logs/slurm_gpu_%j.out
#SBATCH --error=logs/slurm_gpu_%j.err

export HOME=/scratch/drn2/newhome
export TMPDIR=/scratch/drn2/tmp
export PYTHONUSERBASE=/scratch/drn2/newhome/.local
mkdir -p $TMPDIR
unset NETWORKX_BACKEND_CONFIG
unset NX_BACKEND_CONFIG

module load gcc/13.2.0 cuda/12.2.0
source /scratch/drn2/newhome/miniconda3/etc/profile.d/conda.sh
conda activate /scratch/drn2/software/conda-mamba_1

echo "GPUs allocated:"
nvidia-smi --query-gpu=index,name,memory.total --format=csv

cd /scratch/drn2/PROJECTS/PROJECT_NAME || exit 1
python scripts/gpu_script.py
```

### Array Job

```bash
#!/bin/bash
#SBATCH --job-name=array_job
#SBATCH --partition=compute
#SBATCH --array=1-10
#SBATCH --cpus-per-task=28
#SBATCH --mem=90G
#SBATCH --time=12:00:00
#SBATCH --output=logs/slurm_%A_%a.out
#SBATCH --error=logs/slurm_%A_%a.err

export HOME=/scratch/drn2/newhome
export TMPDIR=/scratch/drn2/tmp
export PYTHONUSERBASE=/scratch/drn2/newhome/.local
mkdir -p $TMPDIR
unset NETWORKX_BACKEND_CONFIG
unset NX_BACKEND_CONFIG

module load gcc/13.2.0
source /scratch/drn2/newhome/miniconda3/etc/profile.d/conda.sh
conda activate /scratch/drn2/software/conda-mamba_1

echo "Job ID: $SLURM_ARRAY_JOB_ID | Task: $SLURM_ARRAY_TASK_ID | Node: $(hostname)"

cd /scratch/drn2/PROJECTS/PROJECT_NAME || exit 1
python scripts/process_task.py --task-id $SLURM_ARRAY_TASK_ID
```

---

## Resource Guidelines

**CPU Jobs:**
- `--cpus-per-task=28` (full node)
- `--mem=90G` (safe default), `--mem=180G` (memory-intensive)

**GPU Jobs:**
- `--gres=gpu:1` (single GPU) or `--gres=gpu:4` (multi-GPU training)
- `--cpus-per-task=28`, `--mem=90G`

**Array Jobs:**
- `--array=1-100` (100 tasks)
- `--array=1-100%10` (max 10 concurrent)

---

## Job Management Commands

```bash
# Submit
sbatch script.sbatch
sbatch --array=1-10 script.sbatch
sbatch --dependency=afterok:12345 script.sbatch

# Monitor
squeue -u drn2
squeue -u drn2 --format="%.10i %.12P %.20j %.8u %.2t %.10M %.6D %R"
sacct -j 12345 --format=JobID,State,ExitCode,Elapsed,MaxRSS,MaxVMSize
sinfo -p nvidia
sinfo -p compute

# Cancel
scancel 12345
scancel 12345_5          # single array task
scancel -u drn2          # all jobs
scancel -u drn2 --state=PENDING

# Hold / Release
scontrol hold 12345
scontrol release 12345
```

---

## Job Dependencies (Pipeline)

```bash
JOB1=$(sbatch --parsable step1.sbatch)
JOB2=$(sbatch --parsable --dependency=afterok:$JOB1 step2.sbatch)
JOB3=$(sbatch --parsable --dependency=afterok:$JOB2 step3.sbatch)
```

---

## Conda Environment Management

```bash
# Source conda (required in batch scripts)
source /scratch/drn2/newhome/miniconda3/etc/profile.d/conda.sh

# Activate main env
conda activate /scratch/drn2/software/conda-mamba_1

# Create new project env
conda create -p /scratch/drn2/software/my_new_env python=3.11
conda activate /scratch/drn2/software/my_new_env

# Install packages (prefer conda, fall back to pip)
conda install numpy pandas scipy matplotlib
pip install specific-package
pip check   # verify no conflicts
```

---

## Module System

```bash
module avail             # List all
module list              # Show loaded
module load gcc/13.2.0   # Required for many packages
module load cuda/12.2.0  # Required for GPU work
```

---

## Known Package Issues

| Issue | Fix |
|-------|-----|
| numba/shap needs NumPy < 2.1 | `pip install "numpy<2.1"` |
| NetworkX 3.6.1 nx-loopback bug | `unset NETWORKX_BACKEND_CONFIG NX_BACKEND_CONFIG` or `pip install "networkx<3.6"` |

---

## Log File Patterns

- Single job: `logs/slurm_%j.out` -> `slurm_12345.out`
- Array job: `logs/slurm_%A_%a.out` -> `slurm_12345_3.out`
  - `%A` = array job ID, `%a` = task ID

---

## Debugging Checklist

1. `sacct -j JOBID --format=JobID,State,ExitCode,Elapsed`
2. `cat logs/slurm_JOBID.err`
3. `cat logs/slurm_JOBID.out`
4. Common fixes:

| Error | Cause | Fix |
|-------|-------|-----|
| `/home/drn2` not found | Wrong HOME | `export HOME=/scratch/drn2/newhome` |
| FileNotFoundError | Local paths in Python | Add hostname detection |
| ModuleNotFoundError | Missing package | `conda install` / `pip install` |
| conda: command not found | Not sourced | `source conda.sh` before activate |
| DependencyNeverSatisfied | Previous job failed | Check upstream job logs |
| OUT_OF_MEMORY | Insufficient RAM | Increase `--mem=` |
| TIMEOUT | Exceeded wall time | Increase `--time=` |

---

## Interactive Testing on HPC

```bash
ssh drn2@jubail.abudhabi.nyu.edu
ho && mamba

# Request interactive session
srun --pty --partition=compute --cpus-per-task=4 --mem=16G --time=1:00:00 bash

# In interactive session, set up env manually
export HOME=/scratch/drn2/newhome
source /scratch/drn2/newhome/miniconda3/etc/profile.d/conda.sh
conda activate /scratch/drn2/software/conda-mamba_1

cd /scratch/drn2/PROJECTS/PROJECT_NAME/
python scripts/your_script.py
exit
```

---

## HPC Support

**Email:** nyuad.it.help@nyu.edu
**Subject:** "Jubail HPC - [your issue]"
