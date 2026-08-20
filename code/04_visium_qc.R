library(tidyverse)
library(Seurat)
library(patchwork)

# Define input and output
visium_dir <- "data/visium/outs/"
output_dir <- "output/visium_qc"
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

# Parameters
# # Unlike scRNA-seq, high counts/features in Visium spots can reflect
# # biologically RNA-rich tissue regions rather than doublets.
# # Therefore, only lower thresholds are applied to counts and features.
qc_quantile <- 0.025
max_mito <- 25

# Load Visium data
vis <- Load10X_Spatial(visium_dir)

# Inspect the Seurat object
print(vis)
head(vis@meta.data)

# Calculate mitochondrial transcript percentage
vis[["percent.mt"]] <- PercentageFeatureSet(
  vis,
  pattern = "^MT-"
)

count_threshold <- quantile(
  vis$nCount_Spatial,
  qc_quantile
)
print(count_threshold)

feature_threshold <- quantile(
  vis$nFeature_Spatial,
  qc_quantile
)
print(feature_threshold)

# Record QC status
vis[["qc_status"]] <- ifelse(
  vis$nCount_Spatial > count_threshold &
    vis$nFeature_Spatial > feature_threshold &
    vis$percent.mt < max_mito,
  "Keep",
  "Remove"
)

# Visualize spatial distribution of QC metrics
p_counts_spatial <- SpatialFeaturePlot(
  vis,
  features = "nCount_Spatial",
  pt.size.factor = 6
) +
  labs(
    title = NULL,
    fill = "Detected transcripts (n)"
  )

p_features_spatial <- SpatialFeaturePlot(
  vis,
  features = "nFeature_Spatial",
  pt.size.factor = 6
) +
  labs(
    title = NULL,
    fill = "Detected genes (n)"
  )

p_mito_spatial <- SpatialFeaturePlot(
  vis,
  features = "percent.mt",
  pt.size.factor = 6
) +
  labs(
    title = NULL,
    fill = "Mitochondrial genes (%)"
  )

p_metric_spatial <-
  p_counts_spatial +
  p_features_spatial +
  p_mito_spatial &
  theme(
    legend.position = "right",
    legend.title.position = "left",
    legend.title = element_text(angle = 90)
  )

# Visualize QC metric distributions and thresholds
p_counts_violin <- VlnPlot(
  vis,
  features = "nCount_Spatial",
  pt.size = 0.01,
  log = TRUE,
  layer = "counts"
) +
  geom_hline(
    yintercept = count_threshold,
    linetype = "dashed"
  ) +
  labs(y = "Detected transcripts (n)")

p_features_violin <- VlnPlot(
  vis,
  features = "nFeature_Spatial",
  pt.size = 0.01,
  log = TRUE,
  layer = "counts"
) +
  geom_hline(
    yintercept = feature_threshold,
    linetype = "dashed"
  ) +
  labs(y = "Detected genes (n)")

p_mito_violin <- VlnPlot(
  vis,
  features = "percent.mt",
  pt.size = 0.01,
  layer = "counts"
) +
  geom_hline(
    yintercept = max_mito,
    linetype = "dashed"
  ) +
  ylim(c(0, max_mito)) +
  labs(y = "Mitochondrial transcripts (%)")


p_metric_violin <-
  p_counts_violin +
  p_features_violin +
  p_mito_violin +
  plot_layout(ncol = 3) &
  NoLegend() &
  theme(
    plot.title = element_blank(),
    axis.title.x = element_blank(),
    axis.text.x = element_blank(),
    axis.ticks.x = element_blank(),
  )


p_metric <- p_metric_spatial / p_metric_violin
ggsave(
  file.path(output_dir, "metrics.png"),
  p_metric,
  width = 12,
  height = 6
)


# Visualize retained and removed spots
p_qc_status_spatial <- SpatialDimPlot(
  vis,
  group.by = "qc_status",
  pt.size.factor = 6
)

p_qc_status_bar <-
  vis@meta.data %>%
  count(qc_status) %>%
  ggplot(aes(x = qc_status, y = n, fill = qc_status)) +
  geom_col() +
  geom_text(
    aes(label = n),
    vjust = -0.5
  ) +
  labs(
    title = NULL,
    x = NULL,
    y = "Number of spots"
  )

p_qc_status <- p_qc_status_spatial + p_qc_status_bar

ggsave(
  file.path(output_dir, "filter_summary.png"),
  p_qc_status,
  width = 10,
  height = 8
)

# Save object
saveRDS(
  vis,
  file.path(output_dir, "visium_qc.rds"),
  compress = FALSE
)
