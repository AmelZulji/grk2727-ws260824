FROM rocker/rstudio:4.4.3

LABEL org.opencontainers.image.source="https://github.com/amelzulji/grk2727-ws260824"
LABEL org.opencontainers.image.description="Computational environment for the GRK2727 workshop held on 2026-08-24"

# Install pak
RUN R -q -e 'install.packages("pak", repos = sprintf("https://r-lib.github.io/p/pak/stable/%s/%s/%s", .Platform$pkgType, R.Version()$os, R.Version()$arch)); stopifnot(requireNamespace("pak", quietly = TRUE))'

# RUN R -q -e 'options(pkg.sysreqs_verbose = TRUE, pkg.include_linkingto = TRUE); pak::pkg_install(c( \
#     "tidyverse", \
#     "patchwork", \
#     "Seurat", \
#     "hdf5r", \
#     "harmony", \
#     "bioc::scDblFinder", \
#     "bioc::glmGamPoi", \
#     "bioc::DESeq2" \
#   ))'

RUN R -q -e 'options(pkg.sysreqs_verbose = TRUE, pkg.include_linkingto = TRUE); pak::pkg_install(c( \
    "tidyverse" \
  ))'


# Install presto from GitHub and clean the pak cache
RUN R -q -e 'pak::pkg_install("immunogenomics/presto"); pak::pak_cleanup(force = TRUE)'

# Set the default RStudio working directory
RUN echo "session-default-working-dir=/home/rstudio/workshop" \
    >> /etc/rstudio/rsession.conf