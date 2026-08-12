# CLI toolchain for the CD4/MS RNA-seq pipeline (salmon, fastp, MultiQC).
# The notebook runs these tools inside this image so the exact tool
# versions are reproducible on any machine with Docker, without a local install.
#
# Build once from the repository root:
#     docker build -t mscd4-bioinfo:latest .
FROM condaforge/miniforge3:24.9.2-0

LABEL description="salmon 1.12.0 + fastp 0.20.1 + MultiQC 1.25.2"

RUN conda install -y -c bioconda -c conda-forge \
        salmon=1.12.0 \
        fastp=0.20.1 \
        multiqc=1.25.2 \
    && conda clean -afy

WORKDIR /project
