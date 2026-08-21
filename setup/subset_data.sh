#!/usr/bin/env bash

set -euo pipefail

docker run --rm \
  -v "$(pwd):/workshop" \
  -w /workshop \
  rocker/r2u:24.04 \
  bash -c '
    apt-get update &&
    apt-get install -y --no-install-recommends \
      r-bioc-dropletutils \
      r-cran-readr \
      r-cran-dplyr &&
    Rscript setup/subset_data.R
  '



