project_dir <- "/workshop"
setwd(project_dir)

if (!requireNamespace("OSTA.data", quietly = TRUE)) {
  BiocManager::install(
    "OSTA.data",
    ask = FALSE,
    update = FALSE
  )
}

library(BiocFileCache)
library(OSTA.data)
library(DropletUtils)
library(readr)
library(dplyr)

unlink("data", recursive = TRUE, force = TRUE)
unlink("workshop-data.zip", force = TRUE)

dir.create(
  "data",
  recursive = TRUE,
  showWarnings = FALSE
)
# Create Bioconductor file cache

bfc <- BiocFileCache(
  file.path(project_dir, "data"),
  ask = FALSE
)

# Download Chromium data

sc_zip <- OSTA.data_load(
  "Chromium_HumanColon_Oliveira",
  bfc = bfc
)

sc_zip <- normalizePath(sc_zip, mustWork = TRUE)
setwd(project_dir)

# Download Visium data

visium_zip <- OSTA.data_load(
  "Visium_HumanColon_Oliveira",
  bfc = bfc
)

visium_zip <- normalizePath(visium_zip, mustWork = TRUE)
setwd(project_dir)

# Create extraction directories

dir.create(
  "data/scRNA",
  recursive = TRUE,
  showWarnings = FALSE
)

dir.create(
  "data/visium",
  recursive = TRUE,
  showWarnings = FALSE
)

# Extract Chromium data

unzip(
  sc_zip,
  exdir = file.path(project_dir, "data/scRNA")
)

# Read and subset cell metadata

cm_path <- "data/scRNA/cell_metadata.csv"

cm <- read_csv(
  cm_path,
  show_col_types = FALSE
)

set.seed(123456)

cm_sub <- cm %>%
  slice_sample(
    prop = 0.04,
    by = c(Patient, Level1)
  )

# Read Chromium count matrix

matrix_path <- "data/scRNA/filtered_feature_bc_matrix.h5"

sce <- read10xCounts(
  matrix_path,
  col.names = TRUE
)

# Find selected barcodes in the H5 matrix

brc_idx <- match(
  cm_sub$Barcode,
  colnames(sce)
)

if (anyNA(brc_idx)) {
  stop("Some selected metadata barcodes were not found in the H5 matrix.")
}

# Subset count matrix

sce_sub <- sce[, brc_idx]

# Write subsetted H5

subset_path <- "data/scRNA/filtered_feature_bc_matrix_subset.h5"

write10xCounts(
  path = subset_path,
  x = counts(sce_sub),
  barcodes = colnames(sce_sub),
  gene.id = rowData(sce_sub)$ID,
  gene.symbol = rowData(sce_sub)$Symbol,
  gene.type = rowData(sce_sub)$Type,
  type = "HDF5",
  version = "3",
  overwrite = TRUE
)

# Replace original H5 with subsetted H5

unlink(matrix_path)

if (!file.rename(subset_path, matrix_path)) {
  stop("Could not rename subsetted H5 file.")
}

# Replace original metadata with subsetted metadata

write_csv(
  cm_sub,
  cm_path
)

# Extract Visium data

unzip(
  visium_zip,
  exdir = file.path(project_dir, "data/visium")
)

# Remove BiocFileCache and downloaded archives

rm(bfc)
gc()

data_contents <- list.files(
  "data",
  full.names = TRUE,
  all.files = TRUE,
  no.. = TRUE
)

keep <- normalizePath(
  c("data/scRNA", "data/visium"),
  mustWork = FALSE
)

remove <- data_contents[
  !normalizePath(data_contents, mustWork = FALSE) %in% keep
]

unlink(
  remove,
  recursive = TRUE,
  force = TRUE
)

# Inspect final data

print(
  list.files(
    "data",
    recursive = TRUE
  )
)

# Create workshop archive

zip::zipr(
  zipfile = "workshop-data.zip",
  files = "data"
)

# Remove unpacked data after successful archive creation

if (!file.exists("workshop-data.zip")) {
  stop("workshop-data.zip was not created.")
}

unlink(
  "data",
  recursive = TRUE,
  force = TRUE
)

cat(
  "\nDone\n",
  "Archive: ", file.path(project_dir, "workshop-data.zip"), "\n",
  "Temporary data directory removed.\n",
  sep = ""
)