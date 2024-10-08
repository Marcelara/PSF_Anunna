sink(file="./console_output/04_console_output.txt")  ## open sink connection to write console output to file

### 2. INFER sequence variants

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

# In this part of the pipeline dada2 will learn to distinguish error from biological 
# differences using a subset of our data as a training set. After it understands the 
# error rates, we will reduce the size of the dataset by combining all identical 
# sequence reads into "unique sequences". Then, using the dereplicated data and 
# error rates, dada2 will infer the sequence variants (OTUs) in our data. Finally, 
# we will merge the coresponding forward and reverse reads to create a list of the 
# fully denoised sequences and create a sequence table from the result.

#### Housekeeping step - set up and verify the file names for the output: 
   
# File parsing
filtFs <- list.files(filtpathF, pattern="fastq.gz", full.names = TRUE)
filtRs <- list.files(filtpathR, pattern="fastq.gz", full.names = TRUE)

# Sample names in order
sample.names <- basename(filtFs) # doesn't drop fastq.gz
sample.names <- gsub("_16S_R1.fastq.gz", "", sample.names)
sample.namesR <- basename(filtRs) # doesn't drop fastq.gz 
sample.namesR <- gsub("_16S_R2.fastq.gz", "", sample.namesR)

# Double check
if(!identical(sample.names, sample.namesR)) stop("Forward and reverse files do not match.")
names(filtFs) <- sample.names
names(filtRs) <- sample.names

#### Learn the error rates
# In this step we will learn the error rates for the sequencing run. Typically dada2 expects you to have data that has HiSeq or MiSeq-style quality scores - that is quality scores that range from 0-40. However, NovaSeq uses a technique called "binned" quality scores. This means that as quality scores are calculated from the sequencer, instead of assigning them a number between 0 and 40, they are instead assigned to 4 different quality scores, typically 0-40 scores are converted as shown below:
 
# 0-2 -> 2  
# 3-14 -> 11  
# 15-30 -> 25  
# 31-40 -> 37  
# 
# This means that the `learnErrors` function has 1/10th of the information that it usually uses to learn the appropriate error function, which often leads to error plots with characteristic troughs in odd places. Although a definitive solution to this has not been found yet, several have been [proposed](https://github.com/benjjneb/dada2/issues/1307). Typically UNH sequencing data will be NovaSeq data, but it's good to check. If you have data that doesn't have binned error scores (i.e. MiSeq or HiSeq data) you can proceed to learn error rates in the typical way, and not worry about the modifications below. (Use `errF` and `errR` for the sequence-variant identification in the next step.) Otherwise, you should carefully inspect the error plots generated by each method below and choose the one that looks the best. Error rate plots that look good have black points that are very close to the black line and are continuously decreasing (especially in the right side of the plot).
 
set.seed(100) # set seed to ensure that randomized steps are replicatable

##### Traditional way of learning error rates
# Learn forward error rates (Notes: randomize default is FALSE)
errF <- learnErrors(filtFs, nbases = 1e9, multithread = TRUE, randomize = TRUE)

# Learn reverse error rates
errR <- learnErrors(filtRs, nbases = 1e9, multithread = TRUE, randomize = TRUE)

saveRDS(errF, paste0(filtpathF, "/errF.rds"))
saveRDS(errR, paste0(filtpathR, "/errR.rds"))


##### Four options for learning error rates with NovaSeq data

# **Option 1** from JacobRPrice alter loess arguments (weights and span and enforce monotonicity)  
# [https://github.com/benjjneb/dada2/issues/1307](https://github.com/benjjneb/dada2/issues/1307)
loessErrfun_mod1 <- function(trans) {
  qq <- as.numeric(colnames(trans))
  est <- matrix(0, nrow=0, ncol=length(qq))
  for(nti in c("A","C","G","T")) {
    for(ntj in c("A","C","G","T")) {
      if(nti != ntj) {
        errs <- trans[paste0(nti,"2",ntj),]
        tot <- colSums(trans[paste0(nti,"2",c("A","C","G","T")),])
        rlogp <- log10((errs+1)/tot)  # 1 psuedocount for each err, but if tot=0 will give NA
        rlogp[is.infinite(rlogp)] <- NA
        df <- data.frame(q=qq, errs=errs, tot=tot, rlogp=rlogp)
        
        # original
        # ###! mod.lo <- loess(rlogp ~ q, df, weights=errs) ###!
        # mod.lo <- loess(rlogp ~ q, df, weights=tot) ###!
        # #        mod.lo <- loess(rlogp ~ q, df)
        
        # Gulliem Salazar's solution
        # https://github.com/benjjneb/dada2/issues/938
        mod.lo <- loess(rlogp ~ q, df, weights = log10(tot),span = 2)
        
        pred <- predict(mod.lo, qq)
        maxrli <- max(which(!is.na(pred)))
        minrli <- min(which(!is.na(pred)))
        pred[seq_along(pred)>maxrli] <- pred[[maxrli]]
        pred[seq_along(pred)<minrli] <- pred[[minrli]]
        est <- rbind(est, 10^pred)
      } # if(nti != ntj)
    } # for(ntj in c("A","C","G","T"))
  } # for(nti in c("A","C","G","T"))
  
  # HACKY
  MAX_ERROR_RATE <- 0.25
  MIN_ERROR_RATE <- 1e-7
  est[est>MAX_ERROR_RATE] <- MAX_ERROR_RATE
  est[est<MIN_ERROR_RATE] <- MIN_ERROR_RATE
  
  # enforce monotonicity
  # https://github.com/benjjneb/dada2/issues/791
  estorig <- est
  est <- est %>%
    data.frame() %>%
    mutate_all(funs(case_when(. < X40 ~ X40,
                              . >= X40 ~ .))) %>% as.matrix()
  rownames(est) <- rownames(estorig)
  colnames(est) <- colnames(estorig)
  
  # Expand the err matrix with the self-transition probs
  err <- rbind(1-colSums(est[1:3,]), est[1:3,],
               est[4,], 1-colSums(est[4:6,]), est[5:6,],
               est[7:8,], 1-colSums(est[7:9,]), est[9,],
               est[10:12,], 1-colSums(est[10:12,]))
  rownames(err) <- paste0(rep(c("A","C","G","T"), each=4), "2", c("A","C","G","T"))
  colnames(err) <- colnames(trans)
  # Return
  return(err)
}

# check what this looks like
errF_1 <- learnErrors(
  filtFs,
  multithread = TRUE,
  nbases = 1e9,
  errorEstimationFunction = loessErrfun_mod1,
  verbose = TRUE
)
errR_1 <- learnErrors(
  filtRs,
  multithread = TRUE,
  nbases = 1e9,
  errorEstimationFunction = loessErrfun_mod1,
  verbose = TRUE
)

# **Option 2** enforce monotonicity only.  
# Originally recommended in: [https://github.com/benjjneb/dada2/issues/791](https://github.com/benjjneb/dada2/issues/791) 
loessErrfun_mod2 <- function(trans) {
  qq <- as.numeric(colnames(trans))
  est <- matrix(0, nrow=0, ncol=length(qq))
  for(nti in c("A","C","G","T")) {
    for(ntj in c("A","C","G","T")) {
      if(nti != ntj) {
        errs <- trans[paste0(nti,"2",ntj),]
        tot <- colSums(trans[paste0(nti,"2",c("A","C","G","T")),])
        rlogp <- log10((errs+1)/tot)  # 1 psuedocount for each err, but if tot=0 will give NA
        rlogp[is.infinite(rlogp)] <- NA
        df <- data.frame(q=qq, errs=errs, tot=tot, rlogp=rlogp)
        
        # original
        # ###! mod.lo <- loess(rlogp ~ q, df, weights=errs) ###!
        mod.lo <- loess(rlogp ~ q, df, weights=tot) ###!
        # #        mod.lo <- loess(rlogp ~ q, df)
        
        # Gulliem Salazar's solution
        # https://github.com/benjjneb/dada2/issues/938
        # mod.lo <- loess(rlogp ~ q, df, weights = log10(tot),span = 2)
        
        pred <- predict(mod.lo, qq)
        maxrli <- max(which(!is.na(pred)))
        minrli <- min(which(!is.na(pred)))
        pred[seq_along(pred)>maxrli] <- pred[[maxrli]]
        pred[seq_along(pred)<minrli] <- pred[[minrli]]
        est <- rbind(est, 10^pred)
      } # if(nti != ntj)
    } # for(ntj in c("A","C","G","T"))
  } # for(nti in c("A","C","G","T"))
  
  # HACKY
  MAX_ERROR_RATE <- 0.25
  MIN_ERROR_RATE <- 1e-7
  est[est>MAX_ERROR_RATE] <- MAX_ERROR_RATE
  est[est<MIN_ERROR_RATE] <- MIN_ERROR_RATE
  
  # enforce monotonicity
  # https://github.com/benjjneb/dada2/issues/791
  estorig <- est
  est <- est %>%
    data.frame() %>%
    mutate_all(funs(case_when(. < X40 ~ X40,
                              . >= X40 ~ .))) %>% as.matrix()
  rownames(est) <- rownames(estorig)
  colnames(est) <- colnames(estorig)
  
  # Expand the err matrix with the self-transition probs
  err <- rbind(1-colSums(est[1:3,]), est[1:3,],
               est[4,], 1-colSums(est[4:6,]), est[5:6,],
               est[7:8,], 1-colSums(est[7:9,]), est[9,],
               est[10:12,], 1-colSums(est[10:12,]))
  rownames(err) <- paste0(rep(c("A","C","G","T"), each=4), "2", c("A","C","G","T"))
  colnames(err) <- colnames(trans)
  # Return
  return(err)
}


# check what this looks like
errF_2 <- learnErrors(
  filtFs,
  multithread = TRUE,
  nbases = 1e9,
  errorEstimationFunction = loessErrfun_mod2,
  verbose = TRUE
)

errR_2 <- learnErrors(
  filtRs,
  multithread = TRUE,
  nbases = 1e9,
  errorEstimationFunction = loessErrfun_mod2,
  verbose = TRUE
)

# **Option 3** alter loess function (weights only) and enforce monotonicity  
# From JacobRPrice [https://github.com/benjjneb/dada2/issues/1307](https://github.com/benjjneb/dada2/issues/1307)
loessErrfun_mod3 <- function(trans) {
  qq <- as.numeric(colnames(trans))
  est <- matrix(0, nrow=0, ncol=length(qq))
  for(nti in c("A","C","G","T")) {
    for(ntj in c("A","C","G","T")) {
      if(nti != ntj) {
        errs <- trans[paste0(nti,"2",ntj),]
        tot <- colSums(trans[paste0(nti,"2",c("A","C","G","T")),])
        rlogp <- log10((errs+1)/tot)  # 1 psuedocount for each err, but if tot=0 will give NA
        rlogp[is.infinite(rlogp)] <- NA
        df <- data.frame(q=qq, errs=errs, tot=tot, rlogp=rlogp)
        
        # original
        # ###! mod.lo <- loess(rlogp ~ q, df, weights=errs) ###!
        # mod.lo <- loess(rlogp ~ q, df, weights=tot) ###!
        # #        mod.lo <- loess(rlogp ~ q, df)
        
        # Gulliem Salazar's solution
        # https://github.com/benjjneb/dada2/issues/938
        # mod.lo <- loess(rlogp ~ q, df, weights = log10(tot),span = 2)
        
        # only change the weights
        mod.lo <- loess(rlogp ~ q, df, weights = log10(tot))
        
        pred <- predict(mod.lo, qq)
        maxrli <- max(which(!is.na(pred)))
        minrli <- min(which(!is.na(pred)))
        pred[seq_along(pred)>maxrli] <- pred[[maxrli]]
        pred[seq_along(pred)<minrli] <- pred[[minrli]]
        est <- rbind(est, 10^pred)
      } # if(nti != ntj)
    } # for(ntj in c("A","C","G","T"))
  } # for(nti in c("A","C","G","T"))
  
  # HACKY
  MAX_ERROR_RATE <- 0.25
  MIN_ERROR_RATE <- 1e-7
  est[est>MAX_ERROR_RATE] <- MAX_ERROR_RATE
  est[est<MIN_ERROR_RATE] <- MIN_ERROR_RATE
  
  # enforce monotonicity
  # https://github.com/benjjneb/dada2/issues/791
  estorig <- est
  est <- est %>%
    data.frame() %>%
    mutate_all(funs(case_when(. < X40 ~ X40,
                              . >= X40 ~ .))) %>% as.matrix()
  rownames(est) <- rownames(estorig)
  colnames(est) <- colnames(estorig)
  
  # Expand the err matrix with the self-transition probs
  err <- rbind(1-colSums(est[1:3,]), est[1:3,],
               est[4,], 1-colSums(est[4:6,]), est[5:6,],
               est[7:8,], 1-colSums(est[7:9,]), est[9,],
               est[10:12,], 1-colSums(est[10:12,]))
  rownames(err) <- paste0(rep(c("A","C","G","T"), each=4), "2", c("A","C","G","T"))
  colnames(err) <- colnames(trans)
  # Return
  return(err)
}

# check what this looks like
errF_3 <- learnErrors(
  filtFs,
  multithread = TRUE,
  nbases = 1e9,
  errorEstimationFunction = loessErrfun_mod3,
  verbose = TRUE
)


# check what this looks like
errR_3 <- learnErrors(
  filtRs,
  multithread = TRUE,
  nbases = 1e9,
  errorEstimationFunction = loessErrfun_mod3,
  verbose = TRUE
)

# **Option 4** Alter loess function arguments (weights and span and degree, also enforce monotonicity)  
# From Jonalim's comment in [https://github.com/benjjneb/dada2/issues/1307](https://github.com/benjjneb/dada2/issues/1307)
loessErrfun_mod4 <- function(trans) {
  qq <- as.numeric(colnames(trans))
  est <- matrix(0, nrow=0, ncol=length(qq))
  for(nti in c("A","C","G","T")) {
    for(ntj in c("A","C","G","T")) {
      if(nti != ntj) {
        errs <- trans[paste0(nti,"2",ntj),]
        tot <- colSums(trans[paste0(nti,"2",c("A","C","G","T")),])
        rlogp <- log10((errs+1)/tot)  # 1 psuedocount for each err, but if tot=0 will give NA
        rlogp[is.infinite(rlogp)] <- NA
        df <- data.frame(q=qq, errs=errs, tot=tot, rlogp=rlogp)
        
        # original
        # ###! mod.lo <- loess(rlogp ~ q, df, weights=errs) ###!
        # mod.lo <- loess(rlogp ~ q, df, weights=tot) ###!
        # #        mod.lo <- loess(rlogp ~ q, df)
        
        # jonalim's solution
        # https://github.com/benjjneb/dada2/issues/938
        mod.lo <- loess(rlogp ~ q, df, weights = log10(tot),degree = 1, span = 0.95)
        
        pred <- predict(mod.lo, qq)
        maxrli <- max(which(!is.na(pred)))
        minrli <- min(which(!is.na(pred)))
        pred[seq_along(pred)>maxrli] <- pred[[maxrli]]
        pred[seq_along(pred)<minrli] <- pred[[minrli]]
        est <- rbind(est, 10^pred)
      } # if(nti != ntj)
    } # for(ntj in c("A","C","G","T"))
  } # for(nti in c("A","C","G","T"))
  
  # HACKY
  MAX_ERROR_RATE <- 0.25
  MIN_ERROR_RATE <- 1e-7
  est[est>MAX_ERROR_RATE] <- MAX_ERROR_RATE
  est[est<MIN_ERROR_RATE] <- MIN_ERROR_RATE
  
  # enforce monotonicity
  # https://github.com/benjjneb/dada2/issues/791
  estorig <- est
  est <- est %>%
    data.frame() %>%
    mutate_all(funs(case_when(. < X40 ~ X40,
                              . >= X40 ~ .))) %>% as.matrix()
  rownames(est) <- rownames(estorig)
  colnames(est) <- colnames(estorig)
  
  # Expand the err matrix with the self-transition probs
  err <- rbind(1-colSums(est[1:3,]), est[1:3,],
               est[4,], 1-colSums(est[4:6,]), est[5:6,],
               est[7:8,], 1-colSums(est[7:9,]), est[9,],
               est[10:12,], 1-colSums(est[10:12,]))
  rownames(err) <- paste0(rep(c("A","C","G","T"), each=4), "2", c("A","C","G","T"))
  colnames(err) <- colnames(trans)
  # Return
  return(err)
}

# check what this looks like
errF_4 <- learnErrors(
  filtFs,
  multithread = TRUE,
  nbases = 1e9,
  errorEstimationFunction = loessErrfun_mod4,
  verbose = TRUE
)
errR_4 <- learnErrors(
  filtRs,
  multithread = TRUE,
  nbases = 1e9,
  errorEstimationFunction = loessErrfun_mod4,
  verbose = TRUE
)


#### Plot Error Rates
# We want to make sure that the machine learning algorithm is learning the error rates properly. In the plots below, the red line represents what we should expect the learned error rates to look like for each of the 16 possible base transitions (A->A, A->C, A->G, etc.) and the black line and grey dots represent what the observed error rates are. If the black line and the red lines are very far off from each other, it may be a good idea to increase the ```nbases``` parameter. This allows the machine learning algorthim to train on a larger portion of your data and may help improve the fit. 

# If you have NovaSeq data, you will notice a characteristic dip in the default error plots and you may have points that are far off of the line. This is typical and you will likely want to use one of the other options for error rate functions as simply increasing ```nbases``` will not solve this problem. There are four options, none of which will yield "ideal" error plots. Instead look for the solution where the black line is continuously decreasing (i.e. as quality scores improve on the x-axis the predicted error rate (y-axis) goes down) and for plots that have points that mostly align with the black lines, although you will likely have some points along 0 on the y-axis.

# Original default recommended way (not optimal for NovaSeq data!)
errF_plot <- plotErrors(errF, nominalQ = TRUE)
errR_plot <- plotErrors(errR, nominalQ = TRUE)

errF_plot
errR_plot

saveRDS(errF_plot, paste0(filtpathF, "/errF_plot.rds"))
saveRDS(errR_plot, paste0(filtpathR, "/errR_plot.rds"))

ggsave(plot = errF_plot, filename = paste0(filtpathF, "/errF_plot.png"), 
       width = 10, height = 10, dpi = "retina")
ggsave(plot = errR_plot, filename = paste0(filtpathR, "/errR_plot.png"), 
       width = 10, height = 10, dpi = "retina")

# Trial 1 (alter span and weight in loess, enforce montonicity)
errF_plot1 <- plotErrors(errF_1, nominalQ = TRUE)
errR_plot1 <-plotErrors(errR_1, nominalQ = TRUE)

errF_plot1
errR_plot1

saveRDS(errF_plot1, paste0(filtpathF, "/errF_plot1.rds"))
saveRDS(errR_plot1, paste0(filtpathR, "/errR_plot1.rds"))

ggsave(plot = errF_plot1, filename = paste0(filtpathF, "/errF_plot1.png"), 
       width = 10, height = 10, dpi = "retina")
ggsave(plot = errR_plot1, filename = paste0(filtpathR, "/errR_plot1.png"), 
       width = 10, height = 10, dpi = "retina")

# Trial 2 (only enforce monotonicity - don't change the loess function)
errF_plot2 <- plotErrors(errF_2, nominalQ = TRUE)
errR_plot2 <-plotErrors(errR_2, nominalQ = TRUE)

errF_plot2
errR_plot2

saveRDS(errF_plot2, paste0(filtpathF, "/errF_plot2.rds"))
saveRDS(errR_plot2, paste0(filtpathR, "/errR_plot2.rds"))

ggsave(plot = errF_plot2, filename = paste0(filtpathF, "/errF_plot2.png"), 
       width = 10, height = 10, dpi = "retina")
ggsave(plot = errR_plot2, filename = paste0(filtpathR, "/errR_plot2.png"), 
       width = 10, height = 10, dpi = "retina")

# Trial 3 (alter loess (weights only) and enforce monotonicity)
errF_plot3 <- plotErrors(errF_3, nominalQ = TRUE)
errR_plot3 <-plotErrors(errR_3, nominalQ = TRUE)

errF_plot3
errR_plot3

saveRDS(errF_plot3, paste0(filtpathF, "/errF_plot3.rds"))
saveRDS(errR_plot3, paste0(filtpathR, "/errR_plot3.rds"))

ggsave(plot = errF_plot3, filename = paste0(filtpathF, "/errF_plot3.png"), 
       width = 10, height = 10, dpi = "retina")
ggsave(plot = errR_plot3, filename = paste0(filtpathR, "/errR_plot3.png"), 
       width = 10, height = 10, dpi = "retina")

# Trial 4 (alter loess (span, weight, and degree) and enforce monotonicity)
errF_plot4 <- plotErrors(errF_4, nominalQ = TRUE)
errR_plot4 <-plotErrors(errR_4, nominalQ = TRUE)

errF_plot4
errR_plot4

saveRDS(errF_plot4, paste0(filtpathF, "/errF_plot4.rds"))
saveRDS(errR_plot4, paste0(filtpathR, "/errR_plot4.rds"))

ggsave(plot = errF_plot4, filename = paste0(filtpathF, "/errF_plot4.png"),
       width = 10, height = 10, dpi = "retina")
ggsave(plot = errR_plot4, filename = paste0(filtpathR, "/errR_plot4.png"),
       width = 10, height = 10, dpi = "retina")



# this is to save the R environment if you are running the pipeline in pieces
save.image(file = "dada2_ernakovich_Renv.RData")


sink()  ## close sink connection
