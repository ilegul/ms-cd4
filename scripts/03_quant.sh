#!/usr/bin/env bash
# Step 3: Salmon gene-level quantification (--geneMap) from fastp-trimmed reads,
# one sample at a time (RAM-conscious). Idempotent: skips a sample whose
# quant.genes.sf already exists and is marked done in pipeline_state.json.
#
# This is the long-running step (~60-70 min/sample observed previously) -
# run it in the background and watch logs/03_quant_<sample>.log per sample.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
source ./lib_common.sh

SAMPLES_CSV="$DATA_DIR/metadata/samples.csv"
INDEX_DIR_NAME="salmon_index_v112_utf8"
GENE_MAP="reference/tx2gene.tsv"

log "=== Step 3: Salmon quant (gene-level, from trimmed reads) ==="

if [ ! -f "$DATA_DIR/$INDEX_DIR_NAME/info.json" ]; then
    log "ERROR: index not found at data/$INDEX_DIR_NAME - run 02_index.sh first."
    exit 1
fi

tail -n +2 "$SAMPLES_CSV" | while IFS=',' read -r sample_id label gsm condition sex age cell_type fastq_1 fastq_2; do
    r1="$DATA_DIR/fastq_trimmed/${sample_id}_1.trimmed.fastq.gz"
    r2="$DATA_DIR/fastq_trimmed/${sample_id}_2.trimmed.fastq.gz"
    quant_out="$DATA_DIR/salmon_quants/${sample_id}"

    if [ ! -s "$r1" ] || [ ! -s "$r2" ]; then
        log "$sample_id - trimmed FASTQs missing, run 01_qc_trim.sh first. Skipping."
        continue
    fi

    if is_done "quant" "$sample_id" && [ -s "$quant_out/quant.genes.sf" ]; then
        log "$sample_id - quant already done, skipping"
        continue
    fi

    log "$sample_id - running salmon quant"
    dock salmon quant \
        -i "/project/data/$INDEX_DIR_NAME" \
        -l A -p "$THREADS" \
        -1 "/project/data/fastq_trimmed/${sample_id}_1.trimmed.fastq.gz" \
        -2 "/project/data/fastq_trimmed/${sample_id}_2.trimmed.fastq.gz" \
        --geneMap "/project/data/$GENE_MAP" \
        --validateMappings --gcBias --seqBias \
        -o "/project/data/salmon_quants/${sample_id}" \
        2>&1 | tee "$LOG_DIR/03_quant_${sample_id}.log"

    mark_done "quant" "$sample_id"
    log "$sample_id - quant done"
done

log "=== running MultiQC on salmon outputs ==="
dock multiqc "/project/data/salmon_quants" -o "/project/results/qc/multiqc" -n multiqc_salmon -f \
    2>&1 | tee "$LOG_DIR/03_multiqc.log"

log "=== Step 3 complete: all samples quantified ==="
