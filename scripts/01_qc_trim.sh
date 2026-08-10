#!/usr/bin/env bash
# Step 1: fastp QC + trimming for all samples in data/metadata/samples.csv.
# Idempotent: skips a sample if its fastp JSON report + trimmed FASTQs already exist.
# Safe to Ctrl-C and re-run - only in-flight sample is redone.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
source ./lib_common.sh

SAMPLES_CSV="$DATA_DIR/metadata/samples.csv"
FASTP_QC_DIR="$RESULTS_DIR/qc/fastp"
mkdir -p "$FASTP_QC_DIR" "$DATA_DIR/fastq_trimmed"

log "=== Step 1: fastp QC/trim ==="

tail -n +2 "$SAMPLES_CSV" | while IFS=',' read -r sample_id label gsm condition sex age cell_type fastq_1 fastq_2 strandedness; do
    json_host="$FASTP_QC_DIR/${sample_id}.fastp.json"

    if is_done "fastp" "$sample_id" && [ -s "$json_host" ] \
       && [ -s "$DATA_DIR/fastq_trimmed/${sample_id}_1.trimmed.fastq.gz" ] \
       && [ -s "$DATA_DIR/fastq_trimmed/${sample_id}_2.trimmed.fastq.gz" ]; then
        log "$sample_id - fastp already done, skipping"
        continue
    fi

    log "$sample_id - running fastp"
    dock fastp \
        -i "/project/data/raw_fastq/${fastq_1}" -I "/project/data/raw_fastq/${fastq_2}" \
        -o "/project/data/fastq_trimmed/${sample_id}_1.trimmed.fastq.gz" \
        -O "/project/data/fastq_trimmed/${sample_id}_2.trimmed.fastq.gz" \
        --detect_adapter_for_pe -w "$THREADS" \
        -j "/project/results/qc/fastp/${sample_id}.fastp.json" \
        -h "/project/results/qc/fastp/${sample_id}.fastp.html" \
        2>&1 | tee "$LOG_DIR/01_fastp_${sample_id}.log"

    mark_done "fastp" "$sample_id"
    log "$sample_id - fastp done"
done

log "=== fastp done for all samples, running MultiQC ==="
mkdir -p "$RESULTS_DIR/qc/multiqc"
dock multiqc "/project/results/qc/fastp" -o "/project/results/qc/multiqc" -n multiqc_fastp -f \
    2>&1 | tee "$LOG_DIR/01_multiqc.log"

log "=== Step 1 complete ==="
