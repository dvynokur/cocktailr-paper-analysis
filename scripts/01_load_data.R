# ============================================================
# 01_load_data.R
# Load cleaned South Europe data
# ============================================================

source(here::here("scripts", "00_setup.R"))

# 1. Input paths ----------------------------------------------------------

veg_path <- here::here("data", "processed", "vegmatrix_clean.rds")
hea_path <- here::here("data", "processed", "header_clean.rds")


# 2. Check that local data files exist ------------------------------------

if (!file.exists(veg_path)) {
  stop(
    "Vegetation matrix file not found:\n",
    veg_path,
    "\n\nPlace 'vegmatrix_clean.rds' in data/processed/."
  )
}

if (!file.exists(hea_path)) {
  stop(
    "Header file not found:\n",
    hea_path,
    "\n\nPlace 'header_clean.rds' in data/processed/."
  )
}


# 3. Load prepared data ---------------------------------------------------

veg <- readRDS(veg_path)
hea <- readRDS(hea_path)


# 4. Basic checks ---------------------------------------------------------

message("Vegetation matrix loaded: ", nrow(veg), " plots × ", ncol(veg), " species")

if (nrow(veg) != nrow(hea)) {
  warning(
    "Number of plots differs between vegetation matrix and header: ",
    nrow(veg), " vs ", nrow(hea)
  )
}

if (anyDuplicated(rownames(veg)) > 0) {
  warning("Duplicated plot IDs found in vegetation matrix.")
}

if (anyDuplicated(colnames(veg)) > 0) {
  warning("Duplicated species names found in vegetation matrix.")
}


# 5. Save lightweight summary --------------------------------------------

data_summary <- tibble::tibble(
  object = c("vegetation_matrix", "header"),
  n_rows = c(nrow(veg), nrow(hea)),
  n_columns = c(ncol(veg), ncol(hea))
)

readr::write_csv(
  data_summary,
  here::here("outputs", "tables", "data_summary.csv")
)

message("Prepared data loaded successfully.")
