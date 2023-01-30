#!/bin/bash -login

#SBATCH --time=16:00:00				  		### limit of wall clock time - how long the job will run (same as -t)
#SBATCH --ntasks=1					     	### number of tasks - how many tasks (nodes) that you require (same as -n)
#SBATCH --cpus-per-task=16					### number of CPUs (or cores) per task (same as -c)
#SBATCH --mem=64G					        ### memory required per node - amount of memory (in bytes)
#SBATCH --job-name="06.2_assing_taxonomy_sklearn_qiime2_SILVA"	### you can give your job a name for easier identification (same as -J)
#SBATCH --output="06.2_assing_taxonomy_sklearn_qiime2_SILVA_%j.output"


# activates qiime2 environment
conda activate qiime2-2022.8

# imports representative sequences in FASTA format
qiime tools import \
  --input-path /lustre/nobackup/INDIVIDUAL/kreek001/Pilot3_output_slurm_16S/03_tabletax/repset.fasta \
  --output-path /lustre/nobackup/INDIVIDUAL/kreek001/Pilot3_output_slurm_16S/03_tabletax_qiime2/rep-seqs_16S.qza \
  --type 'FeatureData[Sequence]'


# assing taxonomy ranks on your representative sequences, based on the trained SILVA reference
qiime feature-classifier classify-sklearn \
  --i-classifier /lustre/nobackup/INDIVIDUAL/kreek001/dada2_ernakovichlab-main/taxonomy_files/silva_138.1_newlytrained_database_qimme2_2022.8/silva-138-ssu-nr99-341f-805r-classifier.qza \
  --i-reads /lustre/nobackup/INDIVIDUAL/kreek001/Pilot3_output_slurm_16S/03_tabletax_qiime2/rep-seqs_16S.qza \
  --o-classification /lustre/nobackup/INDIVIDUAL/kreek001/Pilot3_output_slurm_16S/03_tabletax_qiime2/taxonomy_16S.qza

# Export the taxonomy from the .qza taxonomy assingment trained with the correct primer set, it also crates a new folder in the process
qiime tools export \
--input-path /lustre/nobackup/INDIVIDUAL/kreek001/Pilot3_output_slurm_16S/03_tabletax_qiime2/taxonomy_16S.qza \
--output-path /lustre/nobackup/INDIVIDUAL/kreek001/Pilot3_output_slurm_16S/03_tabletax_qiime2/16S_sklearn_taxonomy

# Deactivate qiime2 environment
conda deactivate


