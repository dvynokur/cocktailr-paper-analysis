# ============================================================
# 02_benchmark_subsets.R
# Benchmark cocktailr runtime on increasing data subsets
# ============================================================

source(here::here("scripts", "01_load_data.R"))

set.seed(14)


# 1. Benchmark settings ---------------------------------------------------

subset_sizes <- c(500, 1000, 2500, 5000, 10000, 15000, 20000, nrow(veg))

# For quick testing, use:
# subset_sizes <- c(500, 1000, 2500, 5000)

subset_sizes <- sort(unique(subset_sizes[subset_sizes <= nrow(veg)]))

# Number of random replicates per subset size
n_replicates <- 3

# Benchmark type:
# TRUE  = Cocktail clustering + species-cluster phi profiles
# FALSE = Cocktail clustering only
use_species_cluster_phi <- TRUE


# 2. Helper function ------------------------------------------------------

run_single_benchmark <- function(
    veg,
    subset_size,
    replicate_id,
    species_cluster_phi = TRUE
) {
  
  message(
    "Running benchmark: ",
    subset_size, " plots, replicate ", replicate_id,
    ", species_cluster_phi = ", species_cluster_phi
  )
  
  # Randomly select plots
  plot_ids <- sample(
    rownames(veg),
    size = subset_size,
    replace = FALSE
  )
  
  veg_subset <- veg[plot_ids, , drop = FALSE]
  
  # Remove species absent from the subset
  species_present <- colSums(veg_subset > 0, na.rm = TRUE) > 0
  veg_subset <- veg_subset[, species_present, drop = FALSE]
  
  # Basic subset descriptors
  n_plots <- nrow(veg_subset)
  n_species <- ncol(veg_subset)
  n_records <- sum(veg_subset > 0, na.rm = TRUE)
  fill_percent <- 100 * n_records / (n_plots * n_species)
  
  # Run Cocktail clustering and measure runtime
  runtime <- system.time({
    
    res <- cocktail_cluster(
      vegmatrix = veg_subset,
      plot_values = "rel_cover",
      input_format = "wide",
      species_cluster_phi = species_cluster_phi,
      save_vegmatrix = FALSE,
      progress = FALSE
    )
    
  })
  
  elapsed_sec <- unname(runtime[["elapsed"]])
  
  # Keep only benchmark summary, not the full Cocktail result
  out <- tibble::tibble(
    subset_size = subset_size,
    replicate = replicate_id,
    species_cluster_phi = species_cluster_phi,
    n_plots = n_plots,
    n_species = n_species,
    n_records = n_records,
    fill_percent = fill_percent,
    elapsed_sec = elapsed_sec,
    user_sec = unname(runtime[["user.self"]]),
    system_sec = unname(runtime[["sys.self"]]),
    records_per_sec = n_records / elapsed_sec,
    plots_per_min = n_plots / (elapsed_sec / 60)
  )
  
  # Remove large objects from memory after each benchmark run
  rm(res, veg_subset)
  gc()
  
  out
}


# 3. Run benchmark --------------------------------------------------------

benchmark_results <- purrr::map_dfr(
  subset_sizes,
  function(size_i) {
    purrr::map_dfr(
      seq_len(n_replicates),
      function(rep_i) {
        run_single_benchmark(
          veg = veg,
          subset_size = size_i,
          replicate_id = rep_i,
          species_cluster_phi = use_species_cluster_phi
        )
      }
    )
  }
)


# 4. Save benchmark table -------------------------------------------------

readr::write_csv(
  benchmark_results,
  here::here("outputs", "tables", "benchmark_subsets_runtime.csv")
)


# 5. Summarise results ----------------------------------------------------

benchmark_summary <- benchmark_results |>
  dplyr::group_by(
    subset_size,
    species_cluster_phi,
    n_plots
  ) |>
  dplyr::summarise(
    n_replicates = dplyr::n(),
    n_species_mean = mean(n_species),
    n_species_sd = ifelse(dplyr::n() > 1, sd(n_species), NA_real_),
    n_records_mean = mean(n_records),
    n_records_sd = ifelse(dplyr::n() > 1, sd(n_records), NA_real_),
    fill_percent_mean = mean(fill_percent),
    fill_percent_sd = ifelse(dplyr::n() > 1, sd(fill_percent), NA_real_),
    elapsed_sec_mean = mean(elapsed_sec),
    elapsed_sec_sd = ifelse(dplyr::n() > 1, sd(elapsed_sec), NA_real_),
    elapsed_min_mean = elapsed_sec_mean / 60,
    elapsed_min_sd = elapsed_sec_sd / 60,
    records_per_sec_mean = mean(records_per_sec),
    records_per_sec_sd = ifelse(dplyr::n() > 1, sd(records_per_sec), NA_real_),
    plots_per_min_mean = mean(plots_per_min),
    plots_per_min_sd = ifelse(dplyr::n() > 1, sd(plots_per_min), NA_real_),
    .groups = "drop"
  )

readr::write_csv(
  benchmark_summary,
  here::here("outputs", "tables", "benchmark_subsets_summary.csv")
)


# 6. Plot runtime curve ---------------------------------------------------

runtime_plot <- ggplot2::ggplot(
  benchmark_summary,
  ggplot2::aes(
    x = n_plots,
    y = elapsed_min_mean
  )
) +
  ggplot2::geom_line(linewidth = 0.5) +
  ggplot2::geom_errorbar(
    ggplot2::aes(
      ymin = elapsed_min_mean - elapsed_min_sd,
      ymax = elapsed_min_mean + elapsed_min_sd
    ),
    width = 0,
    na.rm = TRUE
  ) +
  ggplot2::geom_point(size = 2) +
  ggplot2::scale_x_continuous(
    labels = scales::comma
  ) +
  ggplot2::labs(
    x = "Number of plots",
    y = "Runtime, minutes"
  ) +
  ggplot2::theme_bw() +
  ggplot2::theme(
    panel.grid.minor = ggplot2::element_blank()
  )

ggplot2::ggsave(
  filename = here::here("outputs", "figures", "benchmark_runtime_curve.png"),
  plot = runtime_plot,
  width = 7,
  height = 5,
  dpi = 300
)

# Save PDF if possible. On some Windows/R installations, PDF font encoding
# may fail; in that case the PNG output is still saved.
try(
  ggplot2::ggsave(
    filename = here::here("outputs", "figures", "benchmark_runtime_curve.pdf"),
    plot = runtime_plot,
    width = 7,
    height = 5,
    device = grDevices::cairo_pdf
  ),
  silent = TRUE
)


# 7. Print summary --------------------------------------------------------

print(benchmark_summary)

message("Benchmark finished.")
