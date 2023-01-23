sink(file="./console_output/00_console_output.txt")  ## open sink connection to write console output to file

## Set up (part 2) - You are logged in to the server (or have Rstudio open on your computer) ##
# First load and test the installed packages to make sure they're working

# Load DADA2 and required packages
library(dada2); packageVersion("dada2") # the dada2 pipeline
library(ShortRead); packageVersion("ShortRead") # dada2 depends on this
library(dplyr); packageVersion("dplyr") # for manipulating data
library(tidyr); packageVersion("tidyr") # for creating the final graph at the end of the pipeline
library(Hmisc); packageVersion("Hmisc") # for creating the final graph at the end of the pipeline
library(ggplot2); packageVersion("ggplot2") # for creating the final graph at the end of the pipeline
library(plotly); packageVersion("plotly") # enables creation of interactive graphs, especially helpful for quality plots

# Set up pathway to cutadapt (primer trimming tool) and test
cutadapt <- "cutadapt" # change this if not in conda environment; will probably look something like this: "/usr/local/Python27/bin/cutadapt"
system2(cutadapt, args = "--version") # Check by running shell command from R

# We will now set up the directories for the script. We'll tell the script where our data is, and where we want to put the outputs of the script. We highly recommend NOT putting outputs of this script  directly into your home directory, or into this tutorial directory. A better idea is to create a new project directory to hold the output each project you work on.


# Set path to shared data folder and contents
data.fp <- "/lustre/BIF/nobackup/berda001/novaseq_data/family_experiment/16S"

# List all files in shared folder to check path
list.files(data.fp)


# Set up file paths in YOUR directory where you want data; 
# you do not need to create the sub-directories but they are nice to have for organizational purposes. 

project.fp <- "/lustre/BIF/nobackup/berda001/ernakovich_lab_pipeline/project_folder_16S" # CHANGE ME to project directory; don't append with a "/"

dir.create(project.fp)

# Set up names of sub directories to stay organized
preprocess.fp <- file.path(project.fp, "01_preprocess")
filtN.fp <- file.path(preprocess.fp, "filtN")
trimmed.fp <- file.path(preprocess.fp, "trimmed")
filter.fp <- file.path(project.fp, "02_filter") 
table.fp <- file.path(project.fp, "03_tabletax") 



# this is to save the R environment if you are running the pipeline in pieces
save.image(file = "dada2_ernakovich_Renv.RData")

sink()  ## close sink connection
