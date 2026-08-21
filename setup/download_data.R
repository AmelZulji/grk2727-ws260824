library(BiocFileCache)
library(OSTA.data)

project_dir <- "/workshop"

# Define directories
cache_dir <- file.path(project_dir, "data", "cache")
raw_dir <- file.path(project_dir, "data", "raw")

scrna_dir <- file.path(raw_dir, "scRNA")
visium_dir <- file.path(raw_dir, "visium")

dir.create(cache_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(scrna_dir, recursive = TRUE, showWarnings = FALSE)
dir.create(visium_dir, recursive = TRUE, showWarnings = FALSE)

# Install OSTA.data at runtime because it is not available as an r2u/apt package in the version used
if (!requireNamespace("OSTA.data", quietly = TRUE)) {
  BiocManager::install(
    "OSTA.data",
    ask = FALSE,
    update = FALSE
  )
}

# Create a separate cache for downloaded archives
bfc <- BiocFileCache(
  cache_dir,
  ask = FALSE
)

# Download source data
sc_zip <- OSTA.data_load(
  "Chromium_HumanColon_Oliveira",
  bfc = bfc
)

visium_zip <- OSTA.data_load(
  "Visium_HumanColon_Oliveira",
  bfc = bfc
)

# Extract source data into data/raw
unzip(
  sc_zip,
  exdir = scrna_dir
)

unzip(
  visium_zip,
  exdir = visium_dir
)

# report extracted data
cat("\nscRNA data:\n")
print(
  list.files(
    scrna_dir,
    recursive = TRUE
  )
)

cat("\nVisium data:\n")
print(
  list.files(
    visium_dir,
    recursive = TRUE
  )
)