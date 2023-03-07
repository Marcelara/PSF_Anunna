#!/bin/bash -login
 
#SBATCH --time=16:00:00				  	### limit of wall clock time - how long the job will run (same as -t)
#SBATCH --ntasks=1					      ### number of tasks - how many tasks (nodes) that you require (same as -n)
#SBATCH --cpus-per-task=16			  ### number of CPUs (or cores) per task (same as -c)
#SBATCH --mem=64G					        ### memory required per node - amount of memory (in bytes)
#SBATCH --job-name="07_assing_taxonomy_sklearn"			### you can give your job a name for easier identification (same as -J)
#SBATCH --output="07_assign_taxonomy_sklearn_%j.output"

# activates qiime2 environment
conda activate qiime2-2022.8

# imports representative sequences in FASTA format
qiime tools import \
  --input-path /lustre/nobackup/INDIVIDUAL/arago004/ernakovichlab_pipeline/16S_processed_MA/03_tabletax/repset.fasta \
  --output-path /lustre/nobackup/INDIVIDUAL/arago004/ernakovichlab_pipeline/16S_processed_MA/03_tabletax/rep-seqs_16S.qza \
  --type 'FeatureData[Sequence]'


# assing taxonomy ranks on your representative sequences, based on the trained SILVA reference
qiime feature-classifier classify-sklearn \
  --i-classifier /lustre/nobackup/INDIVIDUAL/arago004/ernakovichlab_pipeline/silva-138.1-ssu-nr99-341f-805r-classifier.qza \
  --i-reads /lustre/nobackup/INDIVIDUAL/arago004/ernakovichlab_pipeline/16S_processed_MA/03_tabletax/rep-seqs_16S.qza \
  --o-classification /lustre/nobackup/INDIVIDUAL/arago004/ernakovichlab_pipeline/16S_processed_MA/03_tabletax/taxonomy_16S.qza


# Export the taxonomy from the .qza taxonomy assingment trained with the correct priemr set, it also crates a new folder in the process
qiime tools export \
--input-path /lustre/nobackup/INDIVIDUAL/arago004/ernakovichlab_pipeline/16S_processed_MA/03_tabletax/taxonomy_16S.qza \
--output-path /lustre/nobackup/INDIVIDUAL/arago004/ernakovichlab_pipeline/16S_processed_MA/03_tabletax/16S_sklearn_taxonomy

conda deactivate


