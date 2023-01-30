#!/bin/bash -login

#SBATCH --time=04:00:00                            ### limit of wall clock time - how long the job will run (same as -t)
#SBATCH --ntasks=1                                 ### number of tasks - how many tasks (nodes) that you require (same as -n)
#SBATCH --cpus-per-task=16                         ### number of CPUs (or cores) per task (same as -c)
#SBATCH --mem=64G                                  ### memory required per node - amount of memory (in bytes)

#SBATCH --job-name="07_generate_github_report_dada2"
#SBATCH --output="07_generate_github_report_dada2_%j.output"

conda activate dada2_ernakovich

cd ..

Rscript R/prepare_for_github.R

conda deactivate
