#!/bin/bash -login

#SBATCH --time=01:00:00                            ### limit of wall clock time - how long the job will run (same as -t)
#SBATCH --ntasks=1                                 ### number of tasks - how many tasks (nodes) that you require (same as -n)
#SBATCH --cpus-per-task=16                         ### number of CPUs (or cores) per task (same as -c)
#SBATCH --mem=64G                                  ### memory required per node - amount of memory (in bytes)

#SBATCH --job-name="02_check_quality_dada2"
#SBATCH --output="02_check_quality_dada2_%j.output"

conda activate dada2_ernakovich

Rscript ../R/02_check_quality_dada2_tutorial_16S.R

conda deactivate
