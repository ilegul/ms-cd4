#!/usr/bin/env bash
# Environment check - safe to re-run any time. No WSL is used: the CLI tools
# (salmon/fastp/multiqc) run in the pre-built `mscd4-bioinfo:latest` Docker
# image; the Python/Jupyter analysis side runs in the native Windows venv
# at ../.venv (registered as Jupyter kernel "bsb").
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
source ./lib_common.sh

log "=== Environment check ==="

if ! docker info > /dev/null 2>&1; then
    log "ERROR: Docker engine not reachable. Start Docker Desktop and re-run this script."
    exit 1
fi
log "Docker engine: OK"

if ! docker image inspect "$IMAGE" > /dev/null 2>&1; then
    log "ERROR: Docker image '$IMAGE' not found locally."
    log "Build it once from the Dockerfile at the repository root (salmon 1.12.0,"
    log "fastp 0.20.1, multiqc 1.25.2):"
    log "    docker build -t $IMAGE ."
    exit 1
fi
log "Docker image '$IMAGE': OK"

for bin in salmon fastp multiqc; do
    ver=$(dock "$bin" --version 2>&1 | head -1)
    log "  $bin -> $ver"
done

if [ ! -f "$PROJECT_DIR/.venv/Scripts/python.exe" ]; then
    log "WARNING: Windows venv not found at .venv - run: python -m venv .venv && .venv\\Scripts\\pip install -r requirements.txt"
else
    log "Python venv: OK ($PROJECT_DIR/.venv)"
fi

log "=== Environment check complete ==="
