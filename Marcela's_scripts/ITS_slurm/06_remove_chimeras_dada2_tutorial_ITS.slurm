#!/bin/bash -login

#SBATCH --time=16:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=128G
#SBATCH --job-name="06_remove_chimeras"
#SBATCH --output="06_remove_chimeras_dada2_%j.output"

conda activate dada2_ernakovich

Rscript ../R/06_remove_chimeras_dada2_tutorial_ITS.R

conda deactivate
