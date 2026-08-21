# Data preparation

This directory contains code used to prepare the workshop data. It is not part of the workshop itself and does not need to be run by participants.

From the repository root, run:

```bash
bash setup/download_data.sh && \
  bash setup/subset_data.sh && \
  bash setup/archive_data.sh
```

The scripts create:

- `data/raw/` — downloaded scRNA-seq and Visium data
- `data/subset/` — reproducible scRNA-seq subsets (seed: `123456`)
- `archives/` — one ZIP file per raw or subset dataset

Each shell script installs its R dependencies in a temporary container and runs the matching `.R` script.

Once prepared, the required archives are uploaded to heiBOX (this step is not programatic and heibox gui was used for it) and their public download links are added to [`code/00_download_data.R`](../code/00_download_data.R). Participants run that script to download and extract the ready-to-use data.
