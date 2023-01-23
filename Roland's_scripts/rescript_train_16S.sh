#!/bin/bash -login

conda activate qiime2-2022.2

# downloading Silva database (SSU, version 138.1), filtering, training classifier for Qiime2
# performing steps according to this tutorial: https://forum.qiime2.org/t/processing-filtering-and-evaluating-the-silva-database-and-other-reference-sequence-data-with-rescript/15494


## first: install Rescript (https://github.com/bokulich-lab/RESCRIPt)
# conda install -c conda-forge -c bioconda -c qiime2 -c defaults xmltodict
# pip install git+https://github.com/bokulich-lab/RESCRIPt.git


# downloading data
qiime rescript get-silva-data \
    --p-version '138.1' \
    --p-target 'SSURef_NR99' \
    --p-include-species-labels \
    --o-silva-sequences silva-138.1-ssu-nr99-rna-seqs.qza \
    --o-silva-taxonomy silva-138.1-ssu-nr99-tax.qza

# reverse transcription
qiime rescript reverse-transcribe \
    --i-rna-sequences silva-138.1-ssu-nr99-rna-seqs.qza 
    --o-dna-sequences silva-138.1-ssu-nr99-seqs.qza

# "culling" low-quality sequences: removing sequences that contain 5 or more ambiguous bases and any homopolymers that are 8 or more bases in length
qiime rescript cull-seqs \
    --i-sequences silva-138.1-ssu-nr99-seqs.qza \
    --o-clean-sequences silva-138.1-ssu-nr99-seqs-cleaned.qza

# filtering sequences by length and taxonomy: removing rRNA sequences that do not meet the following criteria: Archaea (16S) >= 900 bp ; Bacteria (16S) >= 1200 bp ; Eukaryota (18S) >= 1400 bp
qiime rescript filter-seqs-length-by-taxon \
    --i-sequences silva-138.1-ssu-nr99-seqs-cleaned.qza \
    --i-taxonomy silva-138.1-ssu-nr99-tax.qza \
    --p-labels Archaea Bacteria Eukaryota \
    --p-min-lens 900 1200 1400 \
    --o-filtered-seqs silva-138.1-ssu-nr99-seqs-filt.qza \
    --o-discarded-seqs silva-138.1-ssu-nr99-seqs-discard.qza

# dereplicating sequences and taxonomy
qiime rescript dereplicate \
    --i-sequences silva-138.1-ssu-nr99-seqs-filt.qza  \
    --i-taxa silva-138.1-ssu-nr99-tax.qza \
    --p-rank-handles 'silva' \
    --p-mode 'uniq' \
    --o-dereplicated-sequences silva-138.1-ssu-nr99-seqs-derep-uniq.qza \
    --o-dereplicated-taxa silva-138.1-ssu-nr99-tax-derep-uniq.qza

# trimming to amplicon (16S V3-V4 ; 341F - 805R)
qiime feature-classifier extract-reads \
    --i-sequences silva-138.1-ssu-nr99-seqs-derep-uniq.qza \
    --p-f-primer CCTACGGGNGGCWGCAG \
    --p-r-primer GACTACHVGGGTATCTAATCC \
    --p-n-jobs 2 \
    --p-read-orientation 'forward' \
    --o-reads silva-138.1-ssu-nr99-seqs-341f-805r.qza

# dereplicating sequences and taxonomy
qiime rescript dereplicate \
    --i-sequences silva-138.1-ssu-nr99-seqs-341f-805r.qza \
    --i-taxa silva-138.1-ssu-nr99-tax-derep-uniq.qza \
    --p-rank-handles 'silva' \
    --p-mode 'uniq' \
    --o-dereplicated-sequences silva-138.1-ssu-nr99-seqs-341f-805r-uniq.qza \
    --o-dereplicated-taxa  silva-138.1-ssu-nr99-tax-341f-805r-derep-uniq.qza

# making classifier (naive bayes)
qiime feature-classifier fit-classifier-naive-bayes \
    --i-reference-reads silva-138.1-ssu-nr99-seqs-341f-805r-uniq.qza \
    --i-reference-taxonomy silva-138.1-ssu-nr99-tax-341f-805r-derep-uniq.qza \
    --o-classifier silva-138.1-ssu-nr99-341f-805r-classifier.qza

conda deactivate
