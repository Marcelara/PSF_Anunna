#!/bin/bash -login

#SBATCH --time=08:00:00				  	### limit of wall clock time - original time was 8 hours
#SBATCH --ntasks=1					      ### number of tasks - how many tasks (nodes) that you require (same as -n)
#SBATCH --cpus-per-task=16			  ### number of CPUs (or cores) per task (same as -c)
#SBATCH --mem=32G					        ### memory required per node - amount of memory (in bytes)
#SBATCH --job-name="tree"			### you can give your job a name for easier identification (same as -J)
#SBATCH --output="tree_%j.output"


# activates qiime2 environment
conda activate qiime2-2022.8

#From Qiime2(https://docs.qiime2.org/2022.8/tutorials/phylogeny/):
#This pipeline will start by creating a sequence alignment using MAFFT,
#after which any alignment columns that are phylogenetically uninformative or ambiguously aligned will be removed (masked).
#The resulting masked alignment will be used to infer a phylogenetic tree and then subsequently rooted at its midpoint.
#Output files from each step of the pipeline will be saved.
#This includes both the unmasked and masked MAFFT alignment from q2-alignment methods, and both the rooted and unrooted phylogenies from q2-phylogeny methods.

#Import refseq from R in fasta format for the pipeline to work
qiime tools import \
  --input-path /lustre/nobackup/INDIVIDUAL/arago004/ernakovichlab_pipeline/ITS_processed_MA/03_tabletax/repset.fasta \
  --output-path /lustre/nobackup/INDIVIDUAL/arago004/ernakovichlab_pipeline/ITS_processed_MA/repset_ITS.qza \
  --type 'FeatureData[Sequence]'

#Run qiime2 fast pipeline to make a phylogenetic tree
qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences /lustre/nobackup/INDIVIDUAL/arago004/ernakovichlab_pipeline/ITS_processed_MA/repset_ITS.qza \
  --output-dir /lustre/nobackup/INDIVIDUAL/arago004/ernakovichlab_pipeline/ITS_processed_MA/04_phylogenetic_tree

# export tree from .qza to .nwk format
qiime tools export \
  --input-path /lustre/nobackup/INDIVIDUAL/arago004/ernakovichlab_pipeline/ITS_processed_MA/04_phylogenetic_tree/rooted_tree.qza \
  --output-path /lustre/nobackup/INDIVIDUAL/arago004/ernakovichlab_pipeline/ITS_processed_MA/04_phylogenetic_tree/exported_rooted_tree

conda deactivate


