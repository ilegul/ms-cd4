# CD4+ T-cell Transcriptomics in Treatment-Naive Multiple Sclerosis

Bioinformatics & Systems Biology - exam project.

This repository reproduces, at small scale, the CD4+ T-cell arm of the study behind
**GEO GSE137143** and then performs a network-medicine analysis on the results. It is
organised in two parts:

- **Part 1 — RNA-seq pipeline:** quality control → transcript/gene quantification →
  differential expression analysis (DEA) → functional enrichment.
- **Part 2 — Systems biology:** STRING physical PPI network → betweenness centrality and the
  betweenness-derived disease module → Louvain community detection → drug-extended network and
  drug–disease proximity.

The analysis compares **4 treatment-naive Multiple Sclerosis (MS)** patients against
**4 healthy controls (HC)**, balanced by sex (2 F + 2 M per group) and age-matched, all
CD4+ T cells.

---

## Repository structure

```
MS_CD4/
├── notebooks/
│   └── BSB_CD4_MS_assignment.ipynb   # main analysis notebook (run this)
├── data/
│   ├── metadata/                     # sample sheet + GEO metadata (small, tracked)
│   │   ├── samples.csv               # the 8 selected samples (SRR / GSM / condition / sex / age)
│   │   ├── GSE137143_family.soft.gz  # full series metadata
│   │   ├── gsm_metadata_parsed.csv
│   │   └── RunInfo_SRP221152.csv
│   ├── reference/                    # GENCODE v28 (FASTA/GTF are downloaded; *.tsv maps tracked)
│   ├── raw_fastq/                    # input reads (not tracked — see "Data" below)
│   ├── fastq_trimmed/                # fastp output (not tracked)
│   ├── salmon_index_v112_utf8/       # Salmon index (not tracked)
│   └── salmon_quants/                # per-sample quantifications (not tracked)
├── results/                          # all deliverables (tracked)
│   ├── qc/                           # fastp/MultiQC reports + QC summary tables
│   ├── dea/                          # count matrix, DEA tables, PCA/volcano/heatmap
│   ├── enrichment/                   # GSEA/ORA tables + plots
│   └── network/                      # STRING edges, centralities, communities, .graphml
├── Dockerfile                        # salmon + fastp + MultiQC image
├── requirements.txt                  # Python analysis dependencies
└── README.md
```

---

## Requirements

- **Python 3.10**
- **Docker** (runs the command-line tools - salmon 1.12.0, fastp 0.20.1, MultiQC 1.25.2 -
  so no local bioinformatics install is needed)


---

## Setup

**1. Python environment and Jupyter kernel**

```bash
python -m venv .venv
# Windows:  .venv\Scripts\activate      |  Linux/macOS:  source .venv/bin/activate
pip install -r requirements.txt
python -m ipykernel install --user --name bsb --display-name "Python (bsb)"
```

**2. Build the command-line tool image** (once)

```bash
docker build -t mscd4-bioinfo:latest .
```

The notebook's first cells resolve all project paths and check that the Docker image and inputs are
available, so no separate setup script is needed.

---

## Running the analysis

### Option A — Reproduce the downstream analysis from the provided tables (fast)

The differential expression, enrichment and network analyses can be reproduced directly from
the count matrix and result tables included under `results/` and `data/`. Open the notebook,
select the **Python (bsb)** kernel and run all cells: these sections regenerate in a few
minutes. The heavy upstream steps (FASTQ preprocessing and Salmon quantification) are **not**
re-run here — they require the large untracked input files (see *Data* below); their
quantification cells simply report the samples they would process. Use *Option B* to rebuild
those inputs from raw reads.

```bash
jupyter lab   # then open notebooks/BSB_CD4_MS_assignment.ipynb
```

### Option B — Full pipeline from raw reads

1. **Download the 8 FASTQ files.** The runs are listed in `data/metadata/samples.csv`
   (column `sample_id`: `SRR10089413, SRR10089428, SRR10089431, SRR10089494, SRR10089583,
   SRR10089589, SRR10089616, SRR10089670`). Download the paired-end reads into
   `data/raw_fastq/`, named `<SRR>_1.fastq.gz` and `<SRR>_2.fastq.gz`.

   > `samples.csv` holds the final cohort. Sample-level QC on the quantified counts
   > (notebook Task 2b) showed that one initially-selected run had a myeloid/monocyte-like
   > expression profile incompatible with the other CD4+ libraries, so it was replaced by
   > another eligible age- and sex-matched CD4+ run before differential expression; the
   > screening that motivated this is kept under `results/qc/outlier/`.

   *Option 1 — ENA (direct download, no tools needed).* Search each accession at
   [https://www.ebi.ac.uk/ena/browser](https://www.ebi.ac.uk/ena/browser/text-search?query=SRR10089589)
   and download the two FASTQ files, or fetch them from the ENA FTP, e.g.:
   ```bash
   cd data/raw_fastq
   wget ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR100/089/SRR10089589/SRR10089589_1.fastq.gz
   wget ftp://ftp.sra.ebi.ac.uk/vol1/fastq/SRR100/089/SRR10089589/SRR10089589_2.fastq.gz
   ```
   *Option 2 — SRA Toolkit.*
   ```bash
   prefetch SRR10089589
   fasterq-dump --split-files SRR10089589 -O data/raw_fastq
   gzip data/raw_fastq/SRR10089589_*.fastq
   ```

2. **Provide the reference** (GENCODE v28, human) in `data/reference/` **before** running the
   notebook's quantification cells, because the Salmon index build needs the transcript FASTA and the
   quantification needs the transcript-to-gene map. The small maps (`tx2gene.tsv`, `gene_annotation.tsv`) are tracked in
   the repository; download the FASTA/GTF (or run the notebook's reference cell once, which
   fetches them) from
   [https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_28](https://ftp.ebi.ac.uk/pub/databases/gencode/Gencode_human/release_28/)
   (`gencode.v28.transcripts.fa.gz` and `gencode.v28.annotation.gtf.gz`).

3. **Run the notebook's preprocessing and quantification cells** (FastQC → fastp QC/trim → Salmon index →
   Salmon quantification). They execute the command-line tools directly through Docker, one sample at
   a time, and each step is idempotent and can be safely resumed.

4. **Run the remaining notebook cells** for DEA, enrichment and the network analysis.

> The pipeline processes one sample at a time.

---

## Data

The raw FASTQ files, the reference FASTA/GTF, the Salmon index and the per-sample
quantifications are **not committed** (they are large and can be regenerated). Only the
sample metadata and the final results/figures are tracked. Follow *Option B* above to
recreate the raw and intermediate data or *Option A* to work directly from the included
results.

Random seeds are fixed (42) and all figures/tables are written under `results/` for
reproducibility; the PPI networks are also exported as `.graphml` for Cytoscape.
