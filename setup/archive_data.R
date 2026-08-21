library(zip)

project_dir <- "/workshop"

# Define input
datasets <- c(
  visium = file.path(
    project_dir,
    "data",
    "raw",
    "visium"
  ),
  
  scRNA = file.path(
    project_dir,
    "data",
    "raw",
    "scRNA"
  ),
  
  scRNA_P2_12pct = file.path(
    project_dir,
    "data",
    "subset",
    "scRNA_P2_12pct"
  ),
  
  scRNA_all_4pct = file.path(
    project_dir,
    "data",
    "subset",
    "scRNA_all_4pct"
  )
)

# Define output
output_dir <- file.path(
  project_dir,
  "archives"
)

dir.create(
  output_dir,
  recursive = TRUE,
  showWarnings = FALSE
)

# Create one archive per dataset
for (name in names(datasets)) {
  
  archive_file <- file.path(
    output_dir,
    paste0(name, ".zip")
  )
  
  unlink(
    archive_file,
    force = TRUE
  )
  
  zipr(
    zipfile = archive_file,
    files = datasets[[name]]
  )
  
  if (!file.exists(archive_file)) {
    stop("Could not create: ", archive_file)
  }
}

# report created archives
cat("\nArchives created:\n")

print(
  list.files(
    output_dir,
    full.names = TRUE
  )
)