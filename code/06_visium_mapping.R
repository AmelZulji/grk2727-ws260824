library(tidyverse)
library(Seurat)

# Define input and output

visium_file <- "output/visium_processing/visium_processed.rds"
scrna_file <- "output/scRNA_annotate/SCT_snn_res.0.3_scRNA_annotated.rds"
output_dir <- "output/visium_mapping"

dir.create(
  output_dir,
  recursive = TRUE,
  showWarnings = FALSE
)

# Load processed objects
vis <- readRDS(visium_file)
seu <- readRDS(scrna_file)

# Find transfer anchors
anchors <- FindTransferAnchors(
  reference = seu,
  query = vis,
  dims = 1:30,
  reduction = "cca"
)

# Transfer cell-type annotations
predictions.assay <- TransferData(
  anchorset = anchors,
  refdata = seu$cell_type,
  prediction.assay = TRUE,
  weight.reduction = vis[["pca"]],
  dims = 1:30
)

# Add prediction scores to the Visium object
vis[["spatial_mapping"]] <- predictions.assay
DefaultAssay(vis) <- "spatial_mapping"

# Cell-type prediction scores
plot_feat <- Features(predictions.assay) |>
  str_subset(
    pattern = "^max$",
    negate = TRUE
  )

p_spatial_mapping <- SpatialFeaturePlot(
  vis,
  features = plot_feat,
  pt.size.factor = 6,
  ncol = 3
) & theme(
  legend.key.width = unit(1, "null"),
  legend.position = "bottom",
  legend.title.position = "bottom",
  legend.title = element_text(hjust = 0.5)
)

ggsave(
  filename = file.path(output_dir, "mapping_scores.png"),
  plot = p_spatial_mapping,
  width = 10,
  height = 12
)

# Assign the dominant predicted cell type to each spot
vis$mapped_cell_type <- GetTransferPredictions(
  vis,
  assay = "spatial_mapping",
  score.filter = 0
)

vis <- SetIdent(vis, value = "mapped_cell_type")


p_predicted_cell_type <- SpatialDimPlot(
  vis,
  group.by = "mapped_cell_type",
  image.alpha = 0.5,
  alpha = 0.8,
  pt.size.factor = 5
) & scale_fill_manual(values = DiscretePalette(10, palette = "polychrome")) &
  guides(fill = guide_legend(override.aes = list(size = 3.5)))

ggsave(
  filename = file.path(output_dir, "mapped_cell_types.png"),
  plot = p_predicted_cell_type,
  width = 8,
  height = 6
)

# Save mapped Visium object
saveRDS(
  vis,
  file.path(output_dir, "visium_mapped.rds"),
  compress = FALSE
)
