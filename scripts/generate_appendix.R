# scripts/generate_appendix.R
# Render Appendix S1 for the cocktailr manuscript

source("scripts/00_setup.R")

dir.create(
  here::here("outputs", "appendix", "figures"),
  recursive = TRUE,
  showWarnings = FALSE
)

rmarkdown::render(
  input = here::here("appendix", "Appendix_S1_user_guide_cocktailr.Rmd"),
  output_format = "pdf_document",
  output_file = "Appendix_S1_user_guide_cocktailr.pdf",
  output_dir = here::here("outputs", "appendix"),
  clean = TRUE
)
