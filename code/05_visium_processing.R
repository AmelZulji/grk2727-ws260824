options(future.globals.maxSize = 32 * 1024^3) # Enables more RAM for sctransform

library(tidyverse)
library(Seurat)

# Define input and output
input_file <- "output/visium_qc/visium_qc.rds"
output_dir <- "output/visium_processing"

dir.create(
  output_dir,
  recursive = TRUE,
  showWarnings = FALSE
)

# Parameters
n_variable_features <- 3000
resolution <- seq(0.3, 0.8, 0.1)
random_seed <- 123456

# Load Visium object
vis <- readRDS(input_file)

# Inspect loaded object
print(vis)
head(vis@meta.data)

# apply qc filter
vis <- subset(
  vis,
  subset = qc_status == "Keep"
)

# Normalize spatial gene expression
vis <- SCTransform(vis, assay = "Spatial")
vis <- RunPCA(vis, assay = "SCT")
vis <- FindNeighbors(vis, reduction = "pca", dims = 1:30)
vis <- FindClusters(vis, resolution = resolution)
vis <- RunUMAP(vis, reduction = "pca", dims = 1:30)

rsl_name <- paste0("SCT_snn_res.", resolution)

p <-
  DimPlot(vis, group.by = rsl_name) &
  theme(legend.position = "bottom", legend.key.size = unit(0, "cm"))

ggsave(
  filename = file.path(output_dir, "clustering.png"),
  plot = p,
  width = 12,
  height = 9
)

saveRDS(
  vis,
  file.path(output_dir, "visium_processed.rds"),
  compress = FALSE
)
