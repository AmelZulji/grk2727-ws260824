library(tidyverse)
library(Seurat)

# Input and output
input_file <- "output/scRNA_processing/scRNA_processed.rds"
output_dir <- "output/scRNA_annotate"
dir.create(
  output_dir,
  recursive = TRUE,
  showWarnings = FALSE
)

# Parameters
resolution <- 0.3
n_markers <- 5
rsl <- paste0("SCT_snn_res.", resolution)
marker_file <- file.path(
  "output/scRNA_processing",
  paste0(rsl, "-full_markers.csv")
)

# Load the processed dataset and marker statistics for the selected resolution
seu <- readRDS(input_file)
markers <- read_csv(
  marker_file,
  show_col_types = FALSE
)

# Use the selected clustering resolution as the active cell identity
if (!rsl %in% colnames(seu@meta.data)) {
  stop("Clustering column not found: ", rsl)
}
seu <- SetIdent(seu, value = rsl)

# Explore the clustering together with the sample of origin
p_clusters <- DimPlot(
  seu,
  group.by = c(rsl, "Patient"),
  pt.size = 0.01
)

ggsave(
  file.path(
    output_dir,
    paste0(rsl, "_umap.png")
  ),
  p_clusters,
  width = 10,
  height = 5,
  dpi = 300
)

# Check whether clusters are represented across samples or dominated by one sample
cluster_samples <- seu@meta.data |>
  count(.data[[rsl]], Patient, name = "n_cells") |>
  group_by(.data[[rsl]]) |>
  mutate(fraction = n_cells / sum(n_cells)) |>
  ungroup()

write_csv(
  cluster_samples,
  file.path(
    output_dir,
    paste0(rsl, "_sample_composition.csv")
  )
)

p_cluster_samples <- ggplot(
  cluster_samples,
  aes(
    x = .data[[rsl]],
    y = fraction,
    fill = Patient
  )
) +
  geom_col() +
  scale_y_continuous(
    labels = scales::label_percent()
  )

ggsave(
  file.path(
    output_dir,
    paste0(rsl, "_sample_composition.png")
  ),
  p_cluster_samples,
  width = 8,
  height = 5,
  dpi = 300
)

# Select the strongest positive markers that distinguish each cluster
top_markers <- markers |>
  filter(
    logFC > 0,
    auc > 0.5,
    padj < 0.05
  ) |>
  slice_max(
    order_by = auc,
    n = n_markers,
    by = group,
    with_ties = FALSE
  ) |>
  arrange(group)

write_csv(
  top_markers,
  file.path(
    output_dir,
    paste0(rsl, "_top_markers.csv")
  )
)

# Visualize the selected markers across all clusters
p_markers <- DotPlot(
  seu,
  features = unique(top_markers$feature),
  assay = "SCT"
) +
  RotatedAxis() + 
  theme(
    axis.title.x = element_blank(),
    legend.position = "bottom", 
    legend.title.position = "top",
    legend.justification.bottom = "center", 
    panel.grid = element_line(linewidth = 0.05)
    )

ggsave(
  file.path(
    output_dir,
    paste0(rsl, "_top_markers.png")
  ),
  p_markers,
  width = 14,
  height = 7,
  dpi = 300
)

# Assign broad cell types based on the cluster marker profiles
cluster_annotations <- c(
  "0" = "Tumor",
  "1" = "Smooth Muscle",
  "2" = "T cells",
  "3" = "Intestinal Epithelial",
  "4" = "Myeloid",
  "5" = "Fibroblast",
  "6" = "B cells",
  "7" = "Smooth Muscle",
  "8" = "Smooth Muscle",
  "9" = "Endothelial",
  "10" = "B cells",
  "11" = "Neuronal"
)

# Replace cluster identities with the corresponding biological annotation
seu <- RenameIdents(
  seu,
  cluster_annotations
)
seu[["cell_type"]] <- Idents(seu)

# Inspect the final cell-type annotation on the UMAP
p_annotation <- DimPlot(
  seu,
  group.by = "cell_type",
  label = TRUE,
  repel = TRUE
)

ggsave(
  file.path(
    output_dir,
    paste0(rsl, "_cell_types.pdf")
  ),
  p_annotation,
  width = 7,
  height = 6,
  dpi = 300
)

# Save the annotated reference for downstream spatial mapping
saveRDS(
  seu,
  file.path(
    output_dir,
    paste0(rsl, "_scRNA_annotated.rds")
  ),
  compress = FALSE
)
