FROM rocker/rstudio:4.5.0

LABEL org.opencontainers.image.source="https://github.com/amelzulji/grk2727-ws260824"
LABEL org.opencontainers.image.description="Computational environment for the GRK2727 snRNA-seq and Visium workshop"

# Install pak from its pre-built binary repository
RUN R -q -e 'install.packages("pak")'

# Install Seurat + R dependencies + system dependencies
RUN R -q -e 'pak::pkg_install("Seurat")'

RUN R -q -e 'pak::pak_cleanup(force = TRUE)'

