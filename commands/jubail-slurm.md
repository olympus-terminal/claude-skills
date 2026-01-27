---
description: Generate a SLURM batch script for Jubail HPC
---

Generate a SLURM batch script for the Jubail HPC cluster based on: $ARGUMENTS

Steps:

1. Determine job requirements from the user's description:
   - **Partition**: `compute` for CPU-only, `nvidia` for GPU work (NEVER use `gpu`)
   - **Resources**: CPUs (default 28), memory (default 90G), GPUs if needed
   - **Wall time**: estimate appropriately (max 48:00:00)
   - **Job type**: single, GPU, or array job
   - **Project name**: infer from context or ask

2. Generate the `.sbatch` script with ALL mandatory environment setup:

   ```bash
   export HOME=/scratch/drn2/newhome
   export TMPDIR=/scratch/drn2/tmp
   export PYTHONUSERBASE=/scratch/drn2/newhome/.local
   mkdir -p $TMPDIR
   unset NETWORKX_BACKEND_CONFIG
   unset NX_BACKEND_CONFIG
   ```

3. Include module loading and conda activation:

   ```bash
   module load gcc/13.2.0
   # Add cuda/12.2.0 ONLY for nvidia partition
   source /scratch/drn2/newhome/miniconda3/etc/profile.d/conda.sh
   conda activate /scratch/drn2/software/conda-mamba_1
   ```

4. Set project directory to `/scratch/drn2/PROJECTS/<PROJECT_NAME>/`

5. Include job info echo block and log output paths:
   - Single: `logs/slurm_%j.out` / `logs/slurm_%j.err`
   - Array: `logs/slurm_%A_%a.out` / `logs/slurm_%A_%a.err`

6. For GPU jobs, add:
   - `#SBATCH --gres=gpu:N`
   - `module load cuda/12.2.0`
   - `nvidia-smi` info block

7. For array jobs, add:
   - `#SBATCH --array=RANGE`
   - Pass `$SLURM_ARRAY_TASK_ID` to the Python script

8. Remind the user to run `mkdir -p logs results figures` on HPC before submission

9. If a pipeline of dependent jobs is needed, show the `--dependency=afterok` chain:
   ```bash
   JOB1=$(sbatch --parsable step1.sbatch)
   JOB2=$(sbatch --parsable --dependency=afterok:$JOB1 step2.sbatch)
   ```

CRITICAL VALIDATION before output:
- [ ] No paths reference `/home/drn2` (must use `/scratch/drn2/newhome`)
- [ ] Partition is `nvidia` not `gpu`
- [ ] conda.sh is sourced before `conda activate`
- [ ] Log directory uses `logs/` prefix
- [ ] `unset NETWORKX_BACKEND_CONFIG` is present
