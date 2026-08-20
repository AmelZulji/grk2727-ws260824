library(tidyverse)
library(Seurat)
library(scDblFinder)
library(patchwork)

# Define input and output
count_file <- "data/scRNA_P2_12pct/filtered_feature_bc_matrix.h5"
metadata_file <- "data/scRNA_P2_12pct/cell_metadata.csv"
output_dir <- "output/scRNA_qc"

dir.create(
  output_dir,
  recursive = TRUE,
  showWarnings = FALSE
)

# Parameters
qc_quantiles <- c(0.025, 0.975)
max_mito <- 25
random_seed <- 123456

# Load count matrix and cell metadata
counts <- Read10X_h5(count_file)

metadata <- read_csv(
  metadata_file,
  show_col_types = FALSE
) |>
  column_to_rownames("Barcode")

seu <- CreateSeuratObject(
  counts = counts,
  meta.data = metadata
)

# Inspect the Seurat object
print(seu)
head(seu@meta.data)

# Calculate mitochondrial transcript percentage
seu[["percent.mt"]] <- PercentageFeatureSet(
  seu,
  pattern = "^MT-"
)

# Calculate data-driven QC thresholds
count_threshold <- quantile(
  seu$nCount_RNA,
  qc_quantiles
)

feature_threshold <- quantile(
  seu$nFeature_RNA,
  qc_quantiles
)

# Visualize basic QC metrics
p_counts <- VlnPlot(
  seu,
  features = "nCount_RNA",
  group.by = "Patient",
  pt.size = 0.01,
  log = TRUE,
  layer = "counts"
) +
  geom_hline(
    yintercept = count_threshold,
    linetype = "dashed"
  ) +
  labs(title = NULL, y = "Detected transcripts (n)")

p_features <- VlnPlot(
  seu,
  features = "nFeature_RNA",
  group.by = "Patient",
  pt.size = 0.01,
  log = TRUE,
  layer = "counts"
) +
  geom_hline(
    yintercept = feature_threshold,
    linetype = "dashed"
  ) +
  labs(title = NULL, y = "Detected genes (n)")

p_mito <- VlnPlot(
  seu,
  features = "percent.mt",
  group.by = "Patient",
  pt.size = 0.01,
  layer = "counts"
) +
  geom_hline(
    yintercept = max_mito,
    linetype = "dashed"
  ) +
  labs(title = NULL, y = "Mitochondrial transcripts (%)")

p_qc <- p_counts +
  p_features +
  p_mito +
  plot_layout(guides = "collect") &
  theme(axis.title.x = element_blank())

ggsave(
  file.path(output_dir, "metrics.png"),
  p_qc,
  width = 6,
  height = 9
)

# Detect doublets
set.seed(random_seed)

sce <- as.SingleCellExperiment(seu)

sce <- scDblFinder(
  sce,
  samples = sce$Patient
)

seu$scDblFinder.score <- sce$scDblFinder.score
seu$scDblFinder.class <- sce$scDblFinder.class

# Visualize doublet scores
p_doublets <- VlnPlot(
  seu,
  features = "scDblFinder.score",
  group.by = "Patient",
  split.by = "scDblFinder.class",
  pt.size = 0.01,
  layer = "counts"
) +
  labs(
    title = NULL,
    y = "scDblFinder score"
  )

ggsave(
  file.path(output_dir, "doublet_scores.png"),
  p_doublets,
  width = 6,
  height = 5
)

# Record qc values
seu[["qc_status"]] <- ifelse(
  test = seu$nCount_RNA > count_threshold[1] &
    seu$nCount_RNA < count_threshold[2] &
    seu$nFeature_RNA > feature_threshold[1] &
    seu$nFeature_RNA < feature_threshold[2] &
    seu$percent.mt < max_mito &
    seu$scDblFinder.class == "singlet",
  yes = "Keep",
  no = "Remove"
)

table(seu@meta.data$Patient, seu@meta.data$qc_status)

p_summary <- ggplot(
  seu@meta.data,
  aes(x = Patient, fill = qc_status)
) +
  geom_bar(position = "dodge") +
  labs(
    title = NULL,
    x = NULL,
    y = "Number of cells"
  ) +
  theme_classic()

ggsave(
  file.path(output_dir, "filter_summary.png"),
  p_summary,
  width = 5,
  height = 3
)

# Save object
saveRDS(
  seu,
  file.path(output_dir, "scRNA_qc.rds"),
  compress = FALSE
)
