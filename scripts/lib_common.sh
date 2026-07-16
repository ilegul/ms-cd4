#!/usr/bin/env bash
# Shared helpers for the resumable BSB pipeline scripts.
# Run from Git Bash (no WSL needed) - all heavy tools execute inside the
# pre-built `mscd4-bioinfo:latest` Docker image (salmon 1.12.0, fastp 0.20.1,
# multiqc 1.25.2), the single toolset used for all quantification.
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_DIR="$PROJECT_DIR/data"
RESULTS_DIR="$PROJECT_DIR/results"
LOG_DIR="$PROJECT_DIR/logs"
STATE_FILE="$RESULTS_DIR/pipeline_state.json"
IMAGE="mscd4-bioinfo:latest"
THREADS=4

mkdir -p "$LOG_DIR" "$RESULTS_DIR"

# Run a command inside the project's Docker image with the whole project mounted
# at /project (matches the image's default WORKDIR). Use /project/data/... and
# /project/results/... paths in commands passed to this function.
dock() {
    MSYS_NO_PATHCONV=1 docker run --rm -v "${PROJECT_DIR}:/project" -w /project "$IMAGE" "$@"
}

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# Idempotent state marker: mark_done <step> <key>   /   is_done <step> <key>
# State is a small flat JSON object {"step.key": "done", ...} in results/pipeline_state.json,
# so both these scripts and the notebook can check progress without re-running anything.
mark_done() {
    local step="$1" key="$2"
    python "$PROJECT_DIR/scripts/state.py" set "$STATE_FILE" "${step}.${key}" "done"
}

is_done() {
    local step="$1" key="$2"
    python "$PROJECT_DIR/scripts/state.py" get "$STATE_FILE" "${step}.${key}"
}
