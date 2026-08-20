library(tidyverse)
library(Seurat)
library(patchwork)
library(harmony)

# Define input and output
input_file <- "output/scRNA_qc/scRNA_qc.rds"
output_dir <- "output/scRNA_processing"

dir.create(
  output_dir,
  recursive = TRUE,
  showWarnings = FALSE
)

# Parameters
update_geom_defaults("point", list(shape = 19)) # point shape
random_seed <- 123456
resolution <- seq(0.1, 0.9, 0.1)
print(resolution)

# Load QC object
seu <- readRDS(input_file)

# Keep cells that passed QC
table(seu@meta.data$Patient, seu@meta.data$qc_status)

seu <- subset(
  seu,
  subset = qc_status == "Keep"
)

seu <- SCTransform(seu)
seu <- RunPCA(seu)
seu <- RunHarmony(
  seu,
  group.by.vars = "Patient",
  assay.use = "SCT",
  max_iter = 30
)
seu <- FindNeighbors(seu, dims = 1:30, reduction = "harmony")
seu <- FindClusters(seu, resolution = resolution)
seu <- RunUMAP(seu, dims = 1:30, reduction = "harmony")

rsl_name <- paste0("SCT_snn_res.", resolution)

p_umap_patient <- DimPlot(seu, group.by = c("Patient"), pt.size = 0.01)

ggsave(
  filename = file.path(output_dir, "umap_patient.png"),
  plot = p_umap_patient,
  width = 7,
  height = 6
)

p_umap_rsl <-
  DimPlot(seu, group.by = rsl_name, pt.size = 0.0001) &
  theme(legend.position = "bottom", legend.key.size = unit(0, "cm"))

ggsave(
  filename = file.path(output_dir, "umap_rsl.png"),
  plot = p_umap_rsl,
  width = 12,
  height = 12
)

for (i in rsl_name) {
  full_mark_path <- file.path(output_dir, paste(i, "full_markers.csv", sep = "-"))
  full_mark <- presto:::wilcoxauc.Seurat(seu, group_by = i, assay = "data", seurat_assay = "SCT")
  write_csv(full_mark, full_mark_path)
}

saveRDS(
  seu,
  file = file.path(output_dir, "scRNA_processed.rds"),
  compress = FALSE
  )
