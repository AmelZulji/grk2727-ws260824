library(DropletUtils)
library(readr)
library(dplyr)

project_dir <- "/workshop"
setwd(project_dir)

# Define input
raw_dir <- file.path(project_dir, "data", "raw", "scRNA")
matrix_path <- file.path(raw_dir, "filtered_feature_bc_matrix.h5")
metadata_path <- file.path(raw_dir, "cell_metadata.csv")
license_path <- file.path(raw_dir, "LICENSE.txt")

# Define output
output_dir <- file.path(
  project_dir,
  "data",
  "subset"
)

all_dir <- file.path(
  output_dir,
  "scRNA_all_4pct"
)

p2_dir <- file.path(
  output_dir,
  "scRNA_P2_12pct"
)

for (i in c(all_dir, p2_dir)) {
  dir.create(
    i,
    recursive = TRUE,
    showWarnings = FALSE
  )
}

# Load metadata
cm <- read_csv(
  metadata_path,
  show_col_types = FALSE
)

# Load count matrix once
sce <- read10xCounts(
  matrix_path,
  col.names = TRUE
)

set.seed(123456)

# Subset 1: 4% of each celltype from each sample
cm_all <- cm |>
  slice_sample(
    prop = 0.04,
    by = c(Patient, Level1)
  ) |>
  arrange(desc(parse_number(Barcode)), QCFilter)

# Subset 2: P2CRC and P2NAT, 12% of cells per cell type
cm_p2 <- cm |>
  filter(
    Patient %in% c("P2CRC", "P2NAT")
  ) |>
  slice_sample(
    prop = 0.15,
    by = c(Patient, Level1)
  ) |>
  arrange(desc(parse_number(Barcode)), QCFilter)

# Function to write a subset
write_subset <- function(metadata, output_dir) {

  barcode_index <- match(
    metadata$Barcode,
    colnames(sce)
  )

  if (anyNA(barcode_index)) {
    stop("Some metadata barcodes were not found in the count matrix.")
  }

  sce_subset <- sce[, barcode_index]

  write10xCounts(
    path = file.path(
      output_dir,
      "filtered_feature_bc_matrix.h5"
    ),
    x = counts(sce_subset),
    barcodes = colnames(sce_subset),
    gene.id = rowData(sce_subset)$ID,
    gene.symbol = rowData(sce_subset)$Symbol,
    gene.type = rowData(sce_subset)$Type,
    type = "HDF5",
    version = "3",
    overwrite = TRUE
  )
  
  # write metadata
  write_csv(
    metadata,
    file.path(
      output_dir,
      "cell_metadata.csv"
    )
  )
  
  # write LICENCE
  file.copy(
    license_path,
    file.path(output_dir, "LICENSE.txt"),
    overwrite = TRUE
  )
}

# Write both subsets
write_subset(
  cm_all,
  all_dir
)

write_subset(
  cm_p2,
  p2_dir
)

# report subset sizes
cat(
  "\nAll samples: ",
  nrow(cm_all),
  " cells\n",
  sep = ""
)

cat(
  "P2CRC + P2NAT: ",
  nrow(cm_p2),
  " cells\n",
  sep = ""
)
