#!/bin/bash -login

#SBATCH --time=8:00:00				  		### limit of wall clock time - how long the job will run (same as -t)
#SBATCH --ntasks=1					      	### number of tasks - how many tasks (nodes) that you require (same as -n)
#SBATCH --cpus-per-task=8			 		### number of CPUs (or cores) per task (same as -c)
#SBATCH --mem=32G					        ### memory required per node - amount of memory (in bytes)
#SBATCH --job-name AssingTaxonomy_sklearn			### you can give your job a name for easier identification (same as -J)
#SBATCH --output="06.2_assing_taxonomy_sklearn_qiime2_UNITE_%j.output"  ### Name of the job output


# activates qiime2 environment
conda activate qiime2-2022.8

# imports representative sequences in FASTA format
qiime tools import \
  --input-path /lustre/nobackup/INDIVIDUAL/kreek001/Pilot3_output_slurm_ITS/03_tabletax/repset.fasta \
  --output-path /lustre/nobackup/INDIVIDUAL/kreek001/Pilot3_output_slurm_ITS/03_tabletax/rep-seqs_ITS.qza \
  --type 'FeatureData[Sequence]'

# assing taxonomy ranks on your representative sequences, based on the trained UNITE reference
qiime feature-classifier classify-sklearn \
  --i-classifier /lustre/nobackup/INDIVIDUAL/kreek001/dada2_ernakovichlab-ITS/taxonomy_files/quiime2/developer/unite-tax-ver9_dynamic_all_29.11.2022_dev.qza \
  --i-reads /lustre/nobackup/INDIVIDUAL/kreek001/Pilot3_output_slurm_ITS/03_tabletax/rep-seqs_ITS.qza \
  --o-classification /lustre/nobackup/INDIVIDUAL/kreek001/Pilot3_output_slurm_ITS/03_tabletax/taxonomy_ITS.qza

# Export the taxonomy from the .qza taxonomy assingment trained with the correct priemr set, it also crates a new folder in the process
qiime tools export \
  --input-path /lustre/nobackup/INDIVIDUAL/kreek001/Pilot3_output_slurm_ITS/03_tabletax/taxonomy_ITS.qza \
  --output-path /lustre/nobackup/INDIVIDUAL/kreek001/Pilot3_output_slurm_ITS/03_tabletax/ITS_sklearn_taxonomy

# deactivate conda environment
conda deactivate

