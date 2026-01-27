---
description: Debug a failed Jubail HPC job
---

Help debug a failed HPC job on Jubail: $ARGUMENTS

Steps:

1. Gather information about the failed job:
   - Job ID (if provided)
   - Error messages or symptoms
   - Which script was submitted

2. If a job ID is available, suggest checking:
   ```bash
   sacct -j JOBID --format=JobID,State,ExitCode,Elapsed,MaxRSS,MaxVMSize
   cat logs/slurm_JOBID.err
   cat logs/slurm_JOBID.out
   ```

3. If the user provides error output, diagnose against known issues:

   | Error Pattern | Diagnosis | Fix |
   |---------------|-----------|-----|
   | `No such file: /home/drn2/...` | HOME not overridden | Add `export HOME=/scratch/drn2/newhome` to SLURM script |
   | `FileNotFoundError` on data | Hardcoded local paths | Add `get_base_dir()` environment detection to Python |
   | `ModuleNotFoundError` | Package not installed | `conda activate ... && pip install PACKAGE` |
   | `conda: command not found` | conda.sh not sourced | Add `source /scratch/drn2/newhome/miniconda3/etc/profile.d/conda.sh` before `conda activate` |
   | `Permission denied` | File ownership issue | Check `ls -la` on the file, may need `chmod` |
   | Job state `OUT_OF_MEMORY` | Insufficient RAM | Increase `--mem=` (try 180G) or optimize code |
   | Job state `TIMEOUT` | Exceeded wall time | Increase `--time=` or optimize code |
   | `DependencyNeverSatisfied` | Upstream job failed | Check logs of the dependency job |
   | `Numba needs NumPy 2.0 or less` | NumPy version conflict | `pip install "numpy<2.1"` |
   | `nx-loopback` / NetworkX error | NetworkX 3.6.1 bug | Ensure `unset NETWORKX_BACKEND_CONFIG` in SLURM script, or `pip install "networkx<3.6"` |
   | `CUDA error` / `no CUDA-capable device` | Wrong partition or missing module | Use `--partition=nvidia` and `module load cuda/12.2.0` |

4. If the error doesn't match known patterns:
   - Read the SLURM script and check all environment setup lines
   - Read the Python script and check for hardcoded paths
   - Suggest interactive testing:
     ```bash
     srun --pty --partition=compute --cpus-per-task=4 --mem=16G --time=1:00:00 bash
     export HOME=/scratch/drn2/newhome
     source /scratch/drn2/newhome/miniconda3/etc/profile.d/conda.sh
     conda activate /scratch/drn2/software/conda-mamba_1
     cd /scratch/drn2/PROJECTS/PROJECT_NAME/
     python scripts/failing_script.py
     ```

5. Walk through the full debugging checklist:
   - [ ] SLURM script has `export HOME=/scratch/drn2/newhome`
   - [ ] SLURM script has `export TMPDIR=/scratch/drn2/tmp`
   - [ ] SLURM script has `unset NETWORKX_BACKEND_CONFIG`
   - [ ] conda.sh is sourced before `conda activate`
   - [ ] Correct partition (`nvidia` for GPU, `compute` for CPU)
   - [ ] Appropriate resources (CPUs, memory, time, GPUs)
   - [ ] Python script has environment detection
   - [ ] No hardcoded `/home/drn2/` or `/media/drn2/` paths
   - [ ] Log directory `logs/` exists on HPC
   - [ ] Input data files exist on HPC

6. Propose a fix and offer to:
   - Edit the SLURM script
   - Edit the Python script
   - Generate a corrected version of either
