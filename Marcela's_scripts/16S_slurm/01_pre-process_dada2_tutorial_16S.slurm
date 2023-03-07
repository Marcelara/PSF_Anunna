#!/bin/bash -login

#SBATCH --time=04:00:00                      ### limit of wall clock time - how long the job will run (same as -t)
#SBATCH --ntasks=1                          ### number of tasks - how many tasks (nodes) that you require (same as -n)
#SBATCH --cpus-per-task=16              ### number of CPUs (or cores) per task (same as -c)
#SBATCH --mem=64G                            ### memory required per node - amount of memory (in bytes)
#SBATCH --job-name 01_pre-process_dada2            ### you can give your job a name for easier identification (same as -J)
#SBATCH --output="01_pre-process_dada2_%j.output"



conda activate dada2_ernakovich

Rscript ../R/01_pre-process_dada2_tutorial_16S.R

conda deactivate 

