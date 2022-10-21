---
title: "Pipeline for Anunna"
author: "Marcela Aragon"
date: "10/6/2022"
output: 
  html_document:
    toc: true
    toc_depth: 4
    toc_float: 
     collapsed: false
     smooth_scroll: false
    df_print: paged
    keep_md: true
editor_options: 
  chunk_output_type: console
---

# Summary
This file aims to keep track of how microbiome samples from the PSF experiment were pre-processed. 


# Why doing this? 

The reason for using a super computer or High Performance Computer -HPC for short- is that pre-processing of (lots of) microbiome samples requires high computational power which often is not available with normal PCs or laptops. Thus, to make it faster (and doable) we need to make use of an HPC. WUR has its own HPC which is called **"Anunna"**, people who run the HPC at WUR have made a [Wiki][https://wiki.anunna.wur.nl/index.php/Main_Page] available for users which contains a lot of information.  

MiSeq data is usually pre-processed with the [Qiime2 pipeline ][https://docs.qiime2.org/2022.8/], for this, Pedro Beschoren has already adapted this Qiime2 workflow to be used in the HPC. If your samples were sequenced with MiSeq you can have a look at his [GitHub repository][https://github.com/PedroBeschoren/WUR_HPC_Annuna] instead.

If, however, your samples were sequenced with NovaSeq the story changes. 


# Working in the HPC: Anunna 

Making use of an HPC is tricky, as it works on **Linux** as an operating system and requires that you use a terminal/command line (**Shell**) with a completely new language to ask for what you want. As I understand, the HPC works with **Bash** which is just a type of command line interpreter (language) that runs in the Shell (?).

# Access to Anunna 

Before going too technical, if you need to use Anunna from WUR you first need to ask for access as there are costs involved with using it. To do this you'll need to send an email to a staff member from Anunna stating that:

1. you have permission from your manager/supervisor
2. your WUR user account and,
3. Your project number.

![email to ask Anunna access](images/access_anunna_email.jpg)

Always check the Anunna wiki (https://wiki.anunna.wur.nl/index.php/Main_Page) for more updated instructions.



```bash

cd /lustre/nobackup/INDIVIDUAL/arago004 

```

#

#

#


# 01_pre-processed 

# 02_check-quality 

# 03_filter_reads 

# 04_learn_error_rates_dada2_tutorial_16S

Training and testing 4 different methods to distinguish between sequencing errors and biological differences. THIS is the reason why we are doing all this, because NovaSeq data "bins" error scores to just 4 categories instead of 40 like MiSeq, therefore it has less "resolution" (only 10%) to understand the "real" error rates (you have to "pay" this as you have more reads, otherwise it will be way too much information). There's not yet a standard solution to fix this, but it is clear that using the traditional way its not suitable **(see Fig. X)**, thus what Ernakovich lab does is to put together 4 different ways to learn error rates so you can choose, according to your data, which one is better (or less worse you can also say). 

Because we don't fully understand it, we will not go into details of how and why these 4 error rates learning options are different. If you would like to know more you can check the explanation on their GitHub page and try to understand the different codes. What we believe is important is to realize that there are different ways to do it, and that which one is better to choose will depend **every time** entirely on your dataset. The way I see it is it's like checking your data distribution before you run a statistical test, sometimes is normal and sometimes is not and when it's not you have to select the appropriate data distribution so your statistical test has meaning. 

After you run the `04_learn_error_rates_dada2_tutorial_16S.R` script you can find different plots that will show you how, according to each of the 4 options, your learned error rates (black dots and lines) match an expected value (red lines). You'll see that in any of the 4 options there's a perfect match but what Ernakovich's lab recommend is to check that your dots are somewhat close to your black lines and that this lines should decrease along the x-axis (see their better explanation for this). 

You can find these plots on your `processed` folder --> `02_filter` --> `preprocessed_F` & `preprocessed_R` --> `filtered` (all the way down, after you've passed all your .gz sequences, **Fig. X**). 

![Fig.X_04_output_plot-location](images/04_output_plot-location.JPG)

As you see, you'll have 2 plots per option per forward and reverse = 8 plots (+2 of traditional example just to compare). We suggest you to transfer them to you computer and paste them on some slides so you can compare between them on one go. 

With my samples I got this output:

**Traditional way**

![Fig.X_04_output_0-traditional](images/04_output_0-traditional.JPG)

As you can see if I was to use the traditional way my results would be a bit crappy

**Option 1**

![Fig.X_04_output_1](images/04_output_1.JPG)

Doesn't look that bad

**Option 2**

![Fig.X_04_output_2](images/04_output_2.JPG)

It looks off --> not the one to choose

**Option 3**

![Fig.X_04_output_3](images/04_output_3.JPG)

Doesn't look that bad but Option 1 still looks better 

**Option 4**

![Fig.X_04_output_4](images/04_output_4.JPG)

Also doesn't look that bad, so now it's between Option 1 and Option 4. 

**Comparison between 1 and 4**

![Fig.X_04_output_1vs4](images/04_output_1vs4.JPG)

Honestly I can't see a difference between these 2 options, both of them go down across the x axis and points seem to be scattered in the same way across the black line. Looking at this I will choose Option IV, only for the reason of keeping it consistent with Pedro's choice for the Family Experiment (where half of my samples come from). 


# 05_infer_ASVs_dada2_tutorial_16S

# 06_remove_chimeras_assign_taxonomy_dada2_tutorial_16S

















