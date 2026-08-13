#!/usr/bin/env bash

set -euo pipefail

docker run --rm \
  -v "$(pwd):/workshop" \
  -w /workshop \
  rocker/r2u:24.04 \
  bash -c '
    apt-get update &&
    apt-get install -y --no-install-recommends \
      r-cran-biocmanager \
      r-bioc-biocfilecache \
      r-bioc-dropletutils \
      r-cran-readr \
      r-cran-dplyr \
      r-cran-zip &&
    Rscript setup/prepare_workshop_data.R
  '



