#!/bin/bash

# activates qiime2 environment - note: I activate the environment before running the script instead
# conda activate qiime2-2022.2

# imports representative sequences in FASTA format
qiime tools import \
  --input-path /lustre/BIF/nobackup/berda001/ernakovich_lab_pipeline/project_folder_16S/03_tabletax/repset.fasta \
  --output-path /lustre/BIF/nobackup/berda001/ernakovich_lab_pipeline/project_folder_16S/03_tabletax/rep-seqs_16S.qza \
  --type 'FeatureData[Sequence]'


# assing taxonomy ranks on your representative sequences, based on the trained SILVA reference
qiime feature-classifier classify-sklearn \
  --i-classifier /lustre/BIF/nobackup/berda001/taxonomy_databases/silva/qiime_classifier/silva-138.1-ssu-nr99-341f-805r-classifier.qza \
  --i-reads /lustre/BIF/nobackup/berda001/ernakovich_lab_pipeline/project_folder_16S/03_tabletax/rep-seqs_16S.qza \
  --o-classification /lustre/BIF/nobackup/berda001/ernakovich_lab_pipeline/project_folder_16S/03_tabletax/taxonomy_16S.qza

# Export the taxonomy from the .qza taxonomy assingment trained with the correct primer set, it also crates a new folder in the process
qiime tools export \
--input-path /lustre/BIF/nobackup/berda001/ernakovich_lab_pipeline/project_folder_16S/03_tabletax/taxonomy_16S.qza \
--output-path /lustre/BIF/nobackup/berda001/ernakovich_lab_pipeline/project_folder_16S/03_tabletax/  # it is saved as "taxonomy.tsv"

# conda deactivate


