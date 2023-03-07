#!/bin/bash -login

#SBATCH --time=12:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=128G
#SBATCH --job-name="04_learn_error_rates_dada2"
#SBATCH --output="04_learn_error_rates_%j.output"

conda activate dada2_ernakovich

Rscript ../R/04_learn_error_rates_dada2_tutorial_ITS.R

conda deactivate
