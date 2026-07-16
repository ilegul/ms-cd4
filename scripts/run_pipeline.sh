#!/usr/bin/env bash
# Chains the resumable steps: 00 env check -> 01 fastp -> 02 index -> 03 quant.
# Intended to be launched once and left running (e.g. overnight); every step
# is idempotent, so Ctrl-C or a crash just means re-running
# this script picks up where it left off.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

./00_setup.sh
./01_qc_trim.sh
./02_index.sh
./03_quant.sh

echo "[$(date '+%Y-%m-%d %H:%M:%S')] === Preprocessing and quantification complete ==="
