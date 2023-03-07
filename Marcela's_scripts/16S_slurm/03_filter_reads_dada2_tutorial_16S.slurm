#!/bin/bash -login

#SBATCH --time=10:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=128G
#SBATCH --job-name="03_filter_reads_dada2"
#SBATCH --output="03_filter_reads_dada2_%j.output"


## Load the appropriate modules first.  Linuxbrew/colsa contains most
## programs, though some are contained within the anaconda/colsa
## module.  Refer to http://premise.sr.unh.edu for more info.
## module purge
## module load anaconda/colsa

conda activate dada2_ernakovich

## Instruct your program to make use of the number of desired threads.
## As your job will be allocated an entire node, this should normally
## be 24.

Rscript ../R/03_filter_reads_dada2_tutorial_16S.R

conda deactivate
