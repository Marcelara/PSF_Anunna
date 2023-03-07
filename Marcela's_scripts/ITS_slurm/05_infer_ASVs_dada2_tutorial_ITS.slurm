#!/bin/bash -login

#SBATCH --time=16:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=64G
#SBATCH --job-name="05_infer_ASVs_dada2"
#SBATCH --output="05_infer_ASVs_dada2_%j.output"

conda activate dada2_ernakovich

## Instruct your program to make use of the number of desired threads.
## As your job will be allocated an entire node, this should normally
## be 24.
Rscript ../R/05_infer_ASVs_dada2_tutorial_ITS.R

conda deactivate
