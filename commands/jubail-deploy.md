---
description: Prepare and transfer files to/from Jubail HPC
---

Help deploy files to or retrieve results from Jubail HPC for: $ARGUMENTS

Steps:

1. Determine the direction of transfer:
   - **Upload** (local -> HPC): pushing code/data to the cluster
   - **Download** (HPC -> local): pulling results back
   - **Both**: sync in both directions

2. Identify the project and relevant paths:
   - Local: `/media/drn2/External/<PROJECT_NAME>/`
   - HPC: `/scratch/drn2/PROJECTS/<PROJECT_NAME>/`
   - Remote host: `drn2@jubail.abudhabi.nyu.edu`

3. Generate the appropriate rsync command(s):

   **Upload to HPC:**
   ```bash
   rsync -Pvrt /media/drn2/External/PROJECT/ \
     drn2@jubail.abudhabi.nyu.edu:/scratch/drn2/PROJECTS/PROJECT/
   ```

   **Download from HPC:**
   ```bash
   rsync -Pvrt drn2@jubail.abudhabi.nyu.edu:/scratch/drn2/PROJECTS/PROJECT/results/ \
     /media/drn2/External/PROJECT/results/
   ```

   **Selective sync (specific file types):**
   ```bash
   rsync -Pvrt --include='*/' --include='*.tsv' --exclude='*' \
     drn2@jubail.abudhabi.nyu.edu:/scratch/drn2/PROJECTS/PROJECT/results/ \
     /media/drn2/External/PROJECT/results/
   ```

4. For uploads, also generate the remote directory setup command:
   ```bash
   ssh drn2@jubail.abudhabi.nyu.edu "mkdir -p /scratch/drn2/PROJECTS/PROJECT/{data,scripts,results,figures,logs}"
   ```

5. For single files, offer scp as a simpler alternative:
   ```bash
   scp file.txt drn2@jubail.abudhabi.nyu.edu:/scratch/drn2/PROJECTS/PROJECT/
   ```

6. If deploying code that will run on HPC, verify:
   - Python scripts have environment detection (`get_base_dir()`)
   - SLURM scripts use `/scratch/drn2/newhome` as HOME
   - No hardcoded local paths remain in scripts

7. Offer a dry-run option first:
   ```bash
   rsync -Pvrt --dry-run /media/drn2/External/PROJECT/ \
     drn2@jubail.abudhabi.nyu.edu:/scratch/drn2/PROJECTS/PROJECT/
   ```

8. Provide a pre-submission checklist:
   - [ ] Input data transferred
   - [ ] Scripts transferred and have env detection
   - [ ] SLURM batch script transferred
   - [ ] `mkdir -p logs results figures` run on HPC
   - [ ] Test interactively before batch submission

IMPORTANT: All rsync commands use `-Pvrt` flags:
- `-P` = progress + partial (resume interrupted transfers)
- `-v` = verbose
- `-r` = recursive
- `-t` = preserve timestamps
