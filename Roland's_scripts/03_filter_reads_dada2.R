sink(file="./console_output/03_console_output.txt")  ## open sink connection to write console output to file

#### Filter the data

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


filt_out <- filterAndTrim(fwd=file.path(subF.fp, fastqFs), filt=file.path(filtpathF, fastqFs),
                          rev=file.path(subR.fp, fastqRs), filt.rev=file.path(filtpathR, fastqRs),
                          maxEE=c(1,1), truncQ=2, maxN=0, rm.phix=TRUE,
                          compress=TRUE, verbose=TRUE, multithread=TRUE)

# look at how many reads were kept
head(filt_out)

# summary of samples in filt_out by percentage
filt_out %>% 
  data.frame() %>% 
  mutate(Samples = rownames(.),
         percent_kept = 100*(reads.out/reads.in)) %>%
  select(Samples, everything()) %>%
  summarise(min_remaining = paste0(round(min(percent_kept), 2), "%"), 
            median_remaining = paste0(round(median(percent_kept), 2), "%"),
            mean_remaining = paste0(round(mean(percent_kept), 2), "%"), 
            max_remaining = paste0(round(max(percent_kept), 2), "%"))

# Plot the quality of the filtered fastq files.
# If the number of samples greater than 20 figure out which samples, if any, have been filtered out
# so we won't try to plot them, otherwise just plot all the samples that remain
if( length(fastqFs) <= 20) {
  remaining_samplesF <-  fastqFs[
    which(fastqFs %in% list.files(filtpathF))] # keep only samples that haven't been filtered out
  remaining_samplesR <-  fastqRs[
    which(fastqRs %in% list.files(filtpathR))] # keep only samples that haven't been filtered out

  fwd_qual_plots_filt <- plotQualityProfile(paste0(filtpathF, "/", remaining_samplesF))
  rev_qual_plots_filt <- plotQualityProfile(paste0(filtpathR, "/", remaining_samplesR))
} else {
  remaining_samplesF <-  fastqFs[rand_samples][
    which(fastqFs[rand_samples] %in% list.files(filtpathF))] # keep only samples that haven't been filtered out
  remaining_samplesR <-  fastqRs[rand_samples][
    which(fastqRs[rand_samples] %in% list.files(filtpathR))] # keep only samples that haven't been filtered out
  fwd_qual_plots_filt <- plotQualityProfile(paste0(filtpathF, "/", remaining_samplesF))
  rev_qual_plots_filt <- plotQualityProfile(paste0(filtpathR, "/", remaining_samplesR))
}

fwd_qual_plots_filt
rev_qual_plots_filt

# write plots to disk
saveRDS(fwd_qual_plots_filt, paste0(filter.fp, "/fwd_qual_plots_filt.rds"))
saveRDS(rev_qual_plots_filt, paste0(filter.fp, "/rev_qual_plots_filt.rds"))

ggsave(plot = fwd_qual_plots_filt, filename = paste0(filter.fp, "/fwd_qual_plots_filt.png"), 
       width = 10, height = 10, dpi = "retina")
ggsave(plot = rev_qual_plots_filt, filename = paste0(filter.fp, "/rev_qual_plots_filt.png"), 
       width = 10, height = 10, dpi = "retina")


# this is to save the R environment if you are running the pipeline in pieces
save.image(file = "dada2_ernakovich_Renv.RData")


sink()  ## close sink connection
