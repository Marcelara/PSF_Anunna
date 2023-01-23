#!/bin/bash

# conda activate qiime2-2022.2

# this script trains a classifier for Qiime2 using the UNITE database
# we use the QIIME release of UNITE version 8.3, with all eukaryotes (not only fungi), the "dynamic version": https://plutof.ut.ee/#/doi/10.15156/BIO/1264819
# the developer version of the database includes untrimmed data. we will train our classifier on the full, untrimed, eukaryote-containing references. that is the suggestion of qiime2 docs for ITS: https://github.com/qiime2/docs/blob/master/source/tutorials/feature-classifier.rst 

# load UNITE fasta reference sequences of Species Hipothesis (SH)
qiime tools import \
 --type FeatureData[Sequence] \
 --input-path sh_refs_qiime_ver8_dynamic_all_10.05.2021_dev.fasta \
 --output-path unite-seq-ver8_dynamic_all_10.05.2021.qza

# load UNITE taxonomies for reference sequences
qiime tools import \
 --type FeatureData[Taxonomy] \
 --input-path sh_taxonomy_qiime_ver8_dynamic_all_10.05.2021_dev.txt \
 --output-path unite-tax-ver8_dynamic_all_10.05.2021.qza \
 --input-format HeaderlessTSVTaxonomyFormat

# train the classifier on the entire unite database, incluing plants, ITS2, etc
qiime feature-classifier fit-classifier-naive-bayes \
    --i-reference-reads unite-seq-ver8_dynamic_all_10.05.2021.qza \
    --i-reference-taxonomy unite-tax-ver8_dynamic_all_10.05.2021.qza \
    --o-classifier unite-tax-ver8_dynamic_all_10.05.2021_dev_classifier.qza

