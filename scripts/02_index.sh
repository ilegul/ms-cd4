#!/usr/bin/env bash
# Step 2: Salmon transcriptome index (no decoy - see note below).
# Idempotent: if data/salmon_index_v112_utf8/info.json already exists, reuses it.
#
# Decoy note (16 GB RAM machine): a decoy-aware index adds the full GRCh38
# genome as a "decoy" sequence so reads from unannotated/intergenic/genomic
# regions don't get force-mapped to the closest transcript, at the cost of a
# much larger index build (needs >16 GB RAM for human). We default to a
# transcriptome-only index, which is what's already built here from GENCODE
# v28. Trade-off: slightly more multi-mapping/false-positive counts from
# genomic reads, acceptable for this mini-study's differential-expression
# scale. Set BUILD_DECOY=1 (and run overnight) to opt into the heavier index.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
source ./lib_common.sh

BUILD_DECOY="${BUILD_DECOY:-0}"
# Use a SEPARATE directory per index type, so BUILD_DECOY=1 does not silently reuse an
# already-built transcriptome-only index (and vice versa).
if [ "$BUILD_DECOY" = "1" ]; then
    INDEX_DIR_NAME="salmon_index_v112_decoy"
else
    INDEX_DIR_NAME="salmon_index_v112_utf8"
fi
INDEX_HOST="$DATA_DIR/$INDEX_DIR_NAME"
TX_FA="gencode.v28.transcripts.fa.gz"

log "=== Step 2: Salmon index (BUILD_DECOY=$BUILD_DECOY -> $INDEX_DIR_NAME) ==="

if [ -f "$INDEX_HOST/info.json" ]; then
    log "Index already built at $INDEX_HOST (info.json present) - reusing, skipping build."
    exit 0
fi

if [ "$BUILD_DECOY" = "1" ]; then
    log "BUILD_DECOY=1: building decoy-aware index (needs genome as decoy, heavier RAM use)."
    dock bash -c "
        set -e
        cd /project/data/reference
        if [ ! -f decoys.txt ]; then
            zcat GRCh38.p12.genome.fa.gz | grep '^>' | sed 's/>//g' | cut -d' ' -f1 > decoys.txt
        fi
        if [ ! -f gentrome.fa.gz ]; then
            cat $TX_FA GRCh38.p12.genome.fa.gz > gentrome.fa.gz
        fi
        salmon index -t gentrome.fa.gz -d decoys.txt -i /project/data/$INDEX_DIR_NAME -k 31 -p $THREADS
    " 2>&1 | tee "$LOG_DIR/02_index.log"
else
    log "Building transcriptome-only index (no decoy) from $TX_FA."
    dock salmon index \
        -t "/project/data/reference/$TX_FA" \
        -i "/project/data/$INDEX_DIR_NAME" \
        -k 31 -p "$THREADS" \
        2>&1 | tee "$LOG_DIR/02_index.log"
fi

mark_done "index" "$INDEX_DIR_NAME"
log "=== Step 2 complete ==="
