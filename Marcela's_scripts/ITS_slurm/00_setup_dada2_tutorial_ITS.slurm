#!/bin/bash -login

#SBATCH --time=2:00:00
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=4G
#SBATCH --job-name 00_setup
#SBATCH --output=00_setup_%j.output


## Load the appropriate modules first.  Linuxbrew/colsa contains most
## programs, though some are contained within the anaconda/colsa
## module.  Refer to http://premise.sr.unh.edu for more info.

conda activate dada2_ernakovich

## Instruct your program to make use of the number of desired threads.
## As your job will be allocated an entire node, this should normally
## be 24.
Rscript ../R/00_setup_dada2_tutorial_ITS.R

conda deactivate

