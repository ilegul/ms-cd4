# CHANGELOG (final remediation)

All substantive changes made during the senior-review remediation, most recent first.
The graded deliverable is `notebooks/BSB_CD4_MS_assignment.ipynb` plus `results/`.

## Sample-level QC and cohort
- Detected `SRR10089503` as a CD4+ library with a strong myeloid/monocyte-like expression profile
  (very high `LYZ`, `CD14`, `S100A9`, `FCN1`, `CST3`; depressed pan-T markers; global correlation
  ~0.52 vs ~0.85; dominates PC1) incompatible with the other CD4 libraries.
- Excluded it on independent cell-identity grounds (not on DEG count) and replaced it with
  `SRR10089494` (treatment-naive CD4+, female, 32y), restoring the balanced 4 MS / 4 HC, 2F/2M
  design. The initial 8-sample list is kept in `data/metadata/initial_samples_before_qc.csv`;
  the excluded sample's reads/quant are moved (not deleted) to `data/_excluded_SRR10089503_outlier/`.
- Added a Task 2b sample-QC section (PCA, multi-marker identity table, global correlation) and a
  DEA sensitivity analysis with vs without the outlier. Exclusion is justified by identity QC.

## Differential expression
- Rebuilt the count matrix and re-ran PyDESeq2 (`~ sex + condition`, MS vs HC) on the clean cohort.
- PCA/heatmap use a proper VST; the sample-distance heatmap uses an explicit linkage from the
  condensed distances. Volcano labelled with gene symbols.
- `top20_DEGs.csv` now reports the top 20 by padj with a `significant` flag; added a
  top-20 protein-coding table (`top20_DEGs_protein_coding.csv`). Report both padj<0.05 and
  padj<0.05 & |log2FC|>=1 counts.
- Restored the sex-stratified analyses (instructor-requested) as secondary/exploratory, with
  numbers printed from the code (no hard-coded values) and a strong 2-vs-2 caveat.

## Enrichment and paper comparison
- Re-ran GSEA (Wald-stat ranking) and ORA on the clean cohort. The dominant up signal is
  translation/ribosome; down is interferon/IL-8/NK. The earlier "neutrophil degranulation" signal
  was an artefact of the contaminated sample and is gone.
- Added a targeted neddylation/ubiquitin table (`neddylation_genes.csv`).
- Corrected the comparison: cited as **Kim et al.**; NAE1 is directionally and nominally consistent
  (nominal p ~0.005) but NOT FDR-significant (padj ~0.39) - the paper result is not reproduced at
  gene level; broad ubiquitin/E3-ligase enrichment is not specific proof of neddylation.

## Part 2 network
- Primary PPI from FDR-significant protein-coding DEGs (small/fragmented, reported with a mapping
  funnel); secondary exploratory network (nominal p) kept and clearly labelled as exploratory.
- Community count taken from the output (Leiden); Louvain vs Leiden compared.
- **Drug-disease proximity recomputed on a FIXED human physical interactome** (STRING v12.0,
  precomputed, independent of the drugs/module), replacing the earlier seed-dependent network that
  produced spurious z-scores. Degree-matched null (1000 sets, without replacement). All three drugs
  reported; on the fixed network all are non-significant (|z|<2), with a score>=700 sensitivity.
- Corrected DrugBank target roles (KEAP1 = regulatory adaptor not enzyme; NFE2L2 = downstream
  transcription factor; GAPDH = literature-supported); removed draft "verify against your DrugBank"
  notes. Added a disease-drug overlap table.

## QC / FastQC before-after
- Added FastQC on trimmed reads for all 8 samples and a before/after MultiQC report
  (`results/qc/multiqc/multiqc_fastqc_beforeafter.html`); the notebook draws the per-base sequence
  quality before vs after and adapter content before vs after from the fastp JSONs (all 8 samples).

## Scripts and reproducibility
- `03_quant.sh`: real completion check (non-zero exit if a sample is missing) instead of an
  unconditional "all quantified" message.
- `02_index.sh`: `BUILD_DECOY=1` now uses a separate index directory instead of silently reusing an
  existing transcriptome-only index.
- Added FASTQ download documentation + a gzip integrity check cell; DEA cache is invalidated when
  the sample set changes.

## Repository organisation
- Consolidated all QC under `results/qc/` (`fastp/`, `raw_fastqc/`, `trimmed_fastqc/`, `multiqc/`,
  `outlier/`). Each working folder now contains exactly the 8 final samples; the excluded outlier is
  isolated under `data/_excluded_*` (git-ignored). Citation corrected to Kim et al. throughout.
