# ============================================================
# 00_setup.R
# General setup for cocktailr JVS paper analyses
# ============================================================

library(here)
library(dplyr)
library(tidyr)
library(readr)
library(ggplot2)
library(purrr)
library(scales)

library(cocktailr)

# Create output folders
dir.create(here::here("outputs", "figures"), recursive = TRUE, showWarnings = FALSE)
dir.create(here::here("outputs", "tables"), recursive = TRUE, showWarnings = FALSE)
dir.create(here::here("outputs", "appendix"), recursive = TRUE, showWarnings = FALSE)

# Create local data folders, ignored by Git
dir.create(here::here("data", "processed"), recursive = TRUE, showWarnings = FALSE)
dir.create(here::here("data", "raw"), recursive = TRUE, showWarnings = FALSE)
