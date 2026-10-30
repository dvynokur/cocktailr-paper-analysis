# ============================================================
# 02_dune_cocktail.R
# Figures 2-4, vegan::dune example
# ============================================================

source(here::here("scripts", "00_setup.R"))
if (!requireNamespace("vegan", quietly = TRUE)) {
  stop("Please install vegan: install.packages('vegan')")
}

fig_dir <- here::here("outputs", "figures")
tab_dir <- here::here("outputs", "tables")

# 1. Cocktail clustering ----------------------------------------------------

data("dune", package = "vegan")
vm_dune <- as.matrix(dune)

res_dune <- cocktailr::cocktail_cluster(
  vegmatrix = vm_dune,
  plot_values = "rel_cover",
  species_cluster_phi = TRUE,
)

# 2. Select diagnostic groups
selected_table <- select_clusters(
  x = res_dune,
  min_phi = 0.20,
  min_k = 2,
  min_n = 1,
  min_score = 0,
  score_method = "h_logk_logm",
  mode = "strict",
  return = "table"
)

write_csv(selected_table, file.path(tab_dir, "dune_selected_groups.csv"))

# 3. Figure 2: Cocktail species dendrogram ----------------------------------
cocktail_plot(
  x = res_dune,
  file = file.path(fig_dir, "fig2_dune_cocktail.pdf"),
  clusters = selected_ids,
  label_clusters = TRUE,
  width_in = 12,
  height_in = 7.5,
  cex_species = 1,
  cex_clusters = 1,
  alpha_fill = 0.20,
  palette = "Set3"
)
cocktail_plot(
  x = res_dune,
  file = file.path(fig_dir, "fig2_dune_cocktail.png"),
  clusters = selected_ids,
  label_clusters = TRUE,
  width_in = 12,
  height_in = 7.5,
  cex_species = 1,
  cex_clusters = 1,
  alpha_fill = 0.20,
  circle_inch = 0.1,
  palette = "Set3"
)

# 4. Figure 3: Relationships among selected groups --------------------------
D <- cocktailr::cluster_dist(
  x = res_dune, clusters = selected_ids,
  method = "containment", return = "dist"
)
hc <- stats::hclust(D, method = "average")

save_hc <- function(file, format = c("pdf", "png")) {
  format <- match.arg(format)
  if (format == "pdf") {
    grDevices::pdf(file, width = 8, height = 5.5, useDingbats = FALSE)
  } else {
    grDevices::png(file, width = 8, height = 5.5, units = "in", res = 300)
  }
  on.exit(grDevices::dev.off(), add = TRUE)
  graphics::par(mar = c(6, 4.5, 1, 1))
  graphics::plot(hc, main = "", xlab = "", sub = "", ylab = "Height", cex = 1.15)
}
save_hc(file.path(fig_dir, "fig3_dune_group_relationships.pdf"), "pdf")
save_hc(file.path(fig_dir, "fig3_dune_group_relationships.png"), "png")
write_csv(as.data.frame(as.table(as.matrix(D))),
                 file.path(tab_dir, "dune_group_containment_distances.csv"))

# 5. Figure 4: plot assignments across strategies and membership modes ------
strategies <- c("count", "cover", "phi", "phi_cover")
modes <- c("member-only", "all-plots")

assignment_min_phi <- NULL

assignments <- purrr::map_dfr(modes, function(mode_i) {
  purrr::map_dfr(strategies, function(strategy_i) {
    a <- cocktailr::assign_releves(
      x = res_dune,
      strategy = strategy_i,
      clusters = selected_ids,
      plot_membership = (mode_i == "member-only"),
      min_phi = assignment_min_phi,
      min_group_size = 1
    )
    labels <- as.character(a[rownames(vm_dune)])
    labels <- ifelse(is.na(labels), "NA", labels)
    labels <- ifelse(grepl("^u_[0-9]+$", labels),
                     sub("^u_", "g_", labels), labels)
    tibble::tibble(
      plot_id = rownames(vm_dune),
      strategy = strategy_i,
      mode = mode_i,
      assigned_group = labels
    )
  })
})

# Calculate ordination once (same coordinates in all eight panels).
set.seed(14)
nmds <- vegan::metaMDS(
  vm_dune, distance = "bray", k = 2,
  trymax = 100, autotransform = FALSE, trace = FALSE
)
xy <- as.data.frame(vegan::scores(nmds, display = "sites"))
xy$plot_id <- rownames(xy)
assignment_plot_data <- dplyr::left_join(assignments, xy, by = "plot_id")
assignment_plot_data$strategy <- factor(assignment_plot_data$strategy, levels = strategies)
assignment_plot_data$mode <- factor(assignment_plot_data$mode, levels = modes)

# Make transparent convex hulls only where a group has >= 3 unique sites.
hulls <- assignment_plot_data |>
  filter(grepl("^g_", assigned_group)) |>
  group_by(strategy, mode, assigned_group) |>
  filter(dplyr::n() >= 3) |>
  group_modify(function(df, key) {
    idx <- grDevices::chull(df$NMDS1, df$NMDS2)
    if (length(idx) < 3) return(df[FALSE, , drop = FALSE])
    df[idx, , drop = FALSE]
  }) |>
  ungroup()

all_assignments <- c("+", "NA", paste0("g_", sub("^c_", "", sort(selected_ids))))
assignment_plot_data$assigned_group <- factor(
  assignment_plot_data$assigned_group, levels = all_assignments
)
hulls$assigned_group <- factor(hulls$assigned_group, levels = all_assignments)

palette <- c(
  "+" = "#e7a3aa", "NA" = "#c2ac52",
  "g_7" = "#df8fce", "g_11" = "#51b330", "g_14" = "#23bfa1",
  "g_19" = "#16b2db", "g_24" = "#b59be8"
)
shapes <- c("+" = 3, "NA" = 4, "g_7" = 8,
            "g_11" = 16, "g_14" = 17, "g_19" = 15, "g_24" = 18)

fig4 <- ggplot(assignment_plot_data, aes(NMDS1, NMDS2)) +
  geom_polygon(
    data = hulls,
    aes(fill = assigned_group, group = assigned_group),
    colour = NA, alpha = 0.19, show.legend = FALSE
  ) +
  geom_point(
    aes(colour = assigned_group, shape = assigned_group),
    size = 2.6, stroke = 0.6
  ) +
  facet_grid(mode ~ strategy) +
  scale_colour_manual(values = palette, drop = FALSE) +
  scale_fill_manual(values = palette, drop = FALSE) +
  scale_shape_manual(values = shapes, drop = FALSE) +
  labs(
    title = "Assignments across strategies and membership modes",
    x = "NMDS1", y = "NMDS2", colour = "Assigned group", shape = "Assigned group",
    caption = sprintf("NMDS (Bray-Curtis), stress = %.3f", nmds$stress)
  ) +
  coord_equal() +
  theme_bw(base_size = 14) +
  theme(
    panel.grid = element_blank(),
    legend.position = "right",
    strip.background = element_rect(fill = "grey95"),
    plot.caption = element_text(hjust = 1)
  )

ggsave(file.path(fig_dir, "fig4_dune_assignments.png"),
                fig4, width = 12, height = 6.5, dpi = 300)
ggsave(file.path(fig_dir, "fig4_dune_assignments.pdf"),
                fig4, width = 12, height = 6.5)
write_csv(assignments, file.path(tab_dir, "dune_assignments_8_methods.csv"))
