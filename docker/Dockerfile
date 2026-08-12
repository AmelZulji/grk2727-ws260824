FROM rocker/rstudio:4.5.0

LABEL org.opencontainers.image.source="https://github.com/amelzulji/grk2727-ws260824"
LABEL org.opencontainers.image.description="Computational environment for the GRK2727 workshop held on 2026-08-24"

RUN R -q -e 'install.packages("pak")'
RUN R -q -e 'pak::pkg_install(c("Seurat", "hdf5r")); pak::pak_cleanup(force = TRUE)'

# Set the default RStudio working directory
RUN echo "session-default-working-dir=/home/rstudio/workshop" \
    >> /etc/rstudio/rsession.conf