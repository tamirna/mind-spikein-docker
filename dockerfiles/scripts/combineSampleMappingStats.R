# This script combines miRNA and spike-in mappings into a table for further processing
library("tidyr")
library("dplyr")
library("tibble")
library("ggplot2")
library("magrittr")
library("stringr")
library("readr")
library("R.utils")
message(capture.output(sessionInfo()))

testrun <- 0

args <- R.utils::commandArgs(trailingOnly = TRUE, asValues = TRUE, defaults = list(
  includeSequence = 0,
  input.spikeins = ""
))


outFile <- args$outFile
input.miRNA <- args$input.miRNA
input.spikeins <- args$input.spikeins

# miRDeep2 normalizes to the number of total reads mapped against miRNA precursors.
# "total reads" is the sum of reads mapped and counts miRNAs that map against multiple precursors
# multiple times. This overestimates the library size and makes the library size dependent
# of the number of miRNAs that have multiple hairpins

# fastq lib size = 2 165 037
# mirdeep lib size = 924 126
# lib size is also part of the bbduk.sh output

reads.lib <- read_delim(input.spikeins, "\t", skip = 1, n_max = 1, col_names = F)[, 2] %>% as.numeric()

miRNAMappings <- read_delim(input.miRNA, "\t") %>%
  dplyr::rename("ID" = "#miRNA") %>%
  dplyr::rename("reads" = "read_count") %>%
  dplyr::group_by(ID) %>%
  dplyr::summarize(reads = max(reads))

reads.miRNA <- sum(miRNAMappings$reads)

miRNAMappings <- miRNAMappings %>%
  add_column("rpm.lib" = miRNAMappings$reads / reads.lib * 1000000) %>%
  add_column("rpm.miRNA" = miRNAMappings$reads / reads.miRNA * 1000000)

  spikeinMappings <- read_delim(input.spikeins, "\t", skip = 3, col_types = cols_only("#Name" = col_character(), Reads = col_double())) %>%
    dplyr::rename("ID" = "#Name") %>%
    dplyr::rename("reads" = "Reads")
  spikeinMappings <- spikeinMappings %>%
    add_column("rpm.lib" = spikeinMappings$reads / reads.lib * 1000000) %>%
    add_column("rpm.miRNA" = spikeinMappings$reads / reads.miRNA * 1000000)

  combinedTibble <- bind_rows(miRNAMappings, spikeinMappings)

combinedTibble %>% write_delim(outFile, delim = "\t")
