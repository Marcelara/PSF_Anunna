### 3. REMOVE Chimeras and EXPORT files_Marcela 

#save R output to sink file 
sink(file="./06_console_output.txt")

# Originally this script also included the step where taxonomy is assigned via dada2::assignTaxonomy()
# We will use qiime2 classify-sklearn externally instead in a next step, as by doing this much less NAs
# are produced than when using dada2::assignTaxonomy() function (tested before by Pedro Beschoren & recommended by Anna)

# this is to load in the previous R environment and necessary packages
# if you are running the pipeline in pieces

# Load DADA2 and required packages
library(dada2); packageVersion("dada2") # the dada2 pipeline
library(ShortRead); packageVersion("ShortRead") # dada2 depends on this
library(dplyr); packageVersion("dplyr") # for manipulating data
library(tidyr); packageVersion("tidyr") # for creating the final graph at the end of the pipeline
library(Hmisc); packageVersion("Hmisc") # for creating the final graph at the end of the pipeline
library(ggplot2); packageVersion("ggplot2") # for creating the final graph at the end of the pipeline
library(plotly); packageVersion("plotly") # enables creation of interactive graphs, especially helpful for quality plots

load(file = "dada2_ernakovich_Renv.RData")


#' Although dada2 has searched for indel errors and subsitutions, there may still be chimeric
#' sequences in our dataset (sequences that are derived from forward and reverse sequences from 
#' two different organisms becoming fused together during PCR and/or sequencing). To identify 
#' chimeras, we will search for rare sequence variants that can be reconstructed by combining
#' left-hand and right-hand segments from two more abundant "parent" sequences. 

# Read in RDS 
st.all <- readRDS(paste0(table.fp, "/seqtab.rds"))

# Remove chimeras
seqtab.nochim <- removeBimeraDenovo(st.all, method="consensus", multithread=TRUE)

# Print percentage of our sequences that were not chimeric.
100*sum(seqtab.nochim)/sum(seqtab)

# Write results to disk
saveRDS(seqtab.nochim, paste0(table.fp, "/seqtab_final_nofiltered.rds")) #save it so you see the difference in size 

# PEDRO'S ALTERATION: check number of columns (ASV) per rows (samples) of the original object and when reducing the number of ASVs by minimal abundance
# number of samplex X ASVs in full dataset, and then the same dataset by filtering more than 0, 1, 2, 3 occurences
dim(seqtab.nochim)
dim(seqtab.nochim[,colSums(seqtab.nochim)>0])
dim(seqtab.nochim[,colSums(seqtab.nochim)>1])
dim(seqtab.nochim[,colSums(seqtab.nochim)>2])
dim(seqtab.nochim[,colSums(seqtab.nochim)>3])

# PEDRO'S ALTERATION: overwrite the ASV table, removing ASVs that do not appear at least 3 times
# this is necessary because the original 'no_filtered' table might be too large to be processed by R in our local computers
# and anyhow you will need to make the same filtering of less than 3 occurrences per ASV after, so we better do it from now.

seqtab.nochim<-seqtab.nochim[,colSums(seqtab.nochim)>2]

# Write results to disk
saveRDS(seqtab.nochim, paste0(table.fp, "/seqtab_final.rds"))


#' ### 4. Optional - FORMAT OUTPUT to obtain ASV IDs and repset, and input for mctoolsr
#' For convenience sake, we will now rename our ASVs with numbers, output our 
#' results as a traditional taxa table, and create a matrix with the representative
#' sequences for each ASV. 

# Flip table
seqtab.t <- as.data.frame(t(seqtab.nochim))

# Pull out ASV repset
rep_set_ASVs <- as.data.frame(rownames(seqtab.t))
rep_set_ASVs <- mutate(rep_set_ASVs, ASV_ID = 1:n())
rep_set_ASVs$ASV_ID <- sub("^", "ASV_", rep_set_ASVs$ASV_ID)
rep_set_ASVs$ASV <- rep_set_ASVs$`rownames(seqtab.t)` 
rep_set_ASVs$`rownames(seqtab.t)` <- NULL

# Add ASV numbers to table
rownames(seqtab.t) <- rep_set_ASVs$ASV_ID

# Write repset to fasta file
# create a function that writes fasta sequences
writeRepSetFasta<-function(data, filename){
  fastaLines = c()
  for (rowNum in 1:nrow(data)){
    fastaLines = c(fastaLines, as.character(paste(">", data[rowNum,"ASV_ID"], sep = ""))) #changed
    fastaLines = c(fastaLines,as.character(data[rowNum,"ASV"])) #changed
  }
  fileConn<-file(filename)
  writeLines(fastaLines, fileConn)
  close(fileConn)
}

# write repset to fasta file
writeRepSetFasta(rep_set_ASVs, paste0(table.fp, "/repset.fasta"))

# Also export files as .txt
write.table(seqtab.t, file = paste0(table.fp, "/seqtab_final.txt"),
            sep = "\t", row.names = TRUE, col.names = NA)

#' ### Summary of output files:
#' 1. seqtab_final.txt - A tab-delimited sequence-by-sample (i.e. OTU) table 
#' 2. repset.fasta - a fasta file with the representative sequence of each ASV. Fasta headers are the ASV ID and taxonomy string.  



#' ### 5. Summary of reads throughout pipeline
#' Here we track the reads throughout the pipeline to see if any step is resulting in
#' a greater-than-expected loss of reads. If a step is showing a greater than expected loss of reads,
#' it is a good idea to go back to that step and troubleshoot why reads are dropping out.
#' The dada2 tutorial has more details about what can be changed at each step. 
#' 

getN <- function(x) sum(getUniques(x)) # function to grab sequence counts from output objects

# tracking reads by counts
filt_out_track <- filt_out %>%
  data.frame() %>%
  mutate(Sample = gsub("_R1.fastq.gz","",rownames(.))) %>% #changed to avoid mistake
  rename(input = reads.in, filtered = reads.out)
rownames(filt_out_track) <- filt_out_track$Sample

ddF_track <- data.frame(denoisedF = sapply(ddF[sample.names], getN)) %>%
  mutate(Sample = row.names(.))
ddR_track <- data.frame(denoisedR = sapply(ddR[sample.names], getN)) %>%
  mutate(Sample = row.names(.))
merge_track <- data.frame(merged = sapply(mergers, getN)) %>%
  mutate(Sample = row.names(.))
chim_track <- data.frame(nonchim = rowSums(seqtab.nochim)) %>%
  mutate(Sample = row.names(.))


track <- left_join(filt_out_track, ddF_track, by = "Sample") %>%
  left_join(ddR_track, by = "Sample") %>%
  left_join(merge_track, by = "Sample") %>%
  left_join(chim_track, by = "Sample") %>%
  replace(., is.na(.), 0) %>%
  select(Sample, everything())

row.names(track) <- track$Sample
head(track)

# tracking reads by percentage
track_pct <- track %>% 
  data.frame() %>%
  mutate(Sample = rownames(.),
         filtered_pct = ifelse(filtered == 0, 0, 100 * (filtered/input)),
         denoisedF_pct = ifelse(denoisedF == 0, 0, 100 * (denoisedF/filtered)),
         denoisedR_pct = ifelse(denoisedR == 0, 0, 100 * (denoisedR/filtered)),
         merged_pct = ifelse(merged == 0, 0, 100 * merged/((denoisedF + denoisedR)/2)),
         nonchim_pct = ifelse(nonchim == 0, 0, 100 * (nonchim/merged)),
         total_pct = ifelse(nonchim == 0, 0, 100 * nonchim/input)) %>%
  select(Sample, ends_with("_pct"))

# summary stats of tracked reads averaged across samples
track_pct_avg <- track_pct %>% summarize_at(vars(ends_with("_pct")), 
                                            list(avg = mean))
head(track_pct_avg)

track_pct_med <- track_pct %>% summarize_at(vars(ends_with("_pct")), 
                                            list(avg = stats::median))
head(track_pct_avg)
head(track_pct_med)

# Plotting each sample's reads through the pipeline
track_plot <- track %>% 
  data.frame() %>%
  mutate(Sample = rownames(.)) %>%
  gather(key = "Step", value = "Reads", -Sample) %>%
  mutate(Step = factor(Step, 
                       levels = c("input", "filtered", "denoisedF", "denoisedR", "merged", "nonchim"))) %>%
  ggplot(aes(x = Step, y = Reads)) +
  geom_line(aes(group = Sample), alpha = 0.2) +
  geom_point(alpha = 0.5, position = position_jitter(width = 0)) + 
  stat_summary(fun.y = median, geom = "line", group = 1, color = "steelblue", size = 1, alpha = 0.5) +
  stat_summary(fun.y = median, geom = "point", group = 1, color = "steelblue", size = 2, alpha = 0.5) +
  stat_summary(fun.data = median_hilow, fun.args = list(conf.int = 0.5), 
               geom = "ribbon", group = 1, fill = "steelblue", alpha = 0.2) +
  geom_label(data = t(track_pct_avg[1:5]) %>% data.frame() %>% 
               rename(Percent = 1) %>%
               mutate(Step = c("filtered", "denoisedF", "denoisedR", "merged", "nonchim"),
                      Percent = paste(round(Percent, 2), "%")),
             aes(label = Percent), y = 1.1 * max(track[,2])) +
  geom_label(data = track_pct_avg[6] %>% data.frame() %>%
               rename(total = 1),
             aes(label = paste("Total\nRemaining:\n", round(track_pct_avg[1,6], 2), "%")), 
             y = mean(track[,6]), x = 6.5) +
  expand_limits(y = 1.1 * max(track[,2]), x = 7) +
  theme_classic()

track_plot

# Write results to disk
saveRDS(track, paste0(project.fp, "/tracking_reads.rds"))
saveRDS(track_pct, paste0(project.fp, "/tracking_reads_percentage.rds"))
saveRDS(track_plot, paste0(project.fp, "/tracking_reads_summary_plot.rds"))
ggsave(plot = track_plot, filename = paste0(project.fp, "/tracking_reads_summary_plot.png"), width = 10, height = 10, dpi = "retina")


#' ## Next Steps
#' You can now transfer over the output files onto your local computer. 
#' The table and taxonomy can be read into R with 'mctoolsr' package or another R package of your choosing. 
#' 
#' ### Post-pipeline considerations  
#' After following this pipeline, you will need to think about the following in downstream applications:
#' 
#' 1. Remove mitochondrial and chloroplast sequences
#' 2. Remove reads assigned as eukaryotes
#' 3. Remove reads that are unassigned at domain level (also consider removing those unassigned at phylum level)
#' 4. Normalize or rarefy your ASV table
#' 
#' Enjoy your data!
#' 
#+ include=FALSE
# this is to save the R environment if you are running the pipeline in pieces with slurm

save.image(file = "dada2_ernakovich_Renv.RData")
