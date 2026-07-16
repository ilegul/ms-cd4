# FINAL VALIDATION

Honest record of what was validated, what was corrected, and what remains open. Per the project
rule, an explicit limitation or `NA` is preferred over an apparently complete but invalid result.

## Commands run / checks performed
- `bash -n` on all shell scripts (syntax): to be confirmed in the final pass (see "Open items").
- Python helper import/compile check for `scripts/state.py`.
- Notebook executed end-to-end in a clean `bsb` kernel via
  `jupyter nbconvert --to notebook --execute --inplace`; result: 0 error outputs (final re-run).
- Downloaded and gzip-validated the fixed STRING v12.0 human physical interactome
  (`gzip -t` passed on both links and info files).
- Verified the final 8 samples across every working folder (raw_fastq, fastq_trimmed,
  salmon_quants, results/qc/fastp, trimmed_fastqc) contain exactly the final cohort.
- Verified 8 unique donors from GEO titles (`results/qc/sample_design_audit.csv`).

## Design / cohort (validated)
- 4 treatment-naive MS + 4 HC, 2F/2M per group, ages 31-32, CD4+ T cells, 8 unique donors,
  baseline. `SRR10089503` replaced by `SRR10089494` on cell-identity QC grounds.
- `data/metadata/samples.csv` (final), `data/metadata/initial_samples_before_qc.csv` (with the
  outlier), `results/qc/sample_design_audit.csv` (design fields; batch/pool/lane = `NA`).

## Key scientific corrections (validated)
- DEA re-run on the clean cohort (VST PCA, correct heatmap linkage, top-20 by padj, top-20
  protein-coding, both padj-only and padj+LFC counts).
- GSEA/ORA re-run; the previous "neutrophil degranulation" up-signal was an outlier artefact and is
  gone. Neddylation comparison softened (NAE1 nominal p ~0.005, NOT FDR-significant).
- Drug-disease proximity recomputed on a **fixed** STRING v12.0 physical interactome (15,640 nodes,
  independent of drugs/module), degree-matched null (1000, no replacement). All three drugs
  reported; none significant on the fixed network (|z|<2); score>=700 sensitivity agrees. This
  replaces an earlier seed-dependent network that gave spurious large positive z-scores.
- DrugBank roles corrected (KEAP1 not an enzyme; NFE2L2 downstream; GAPDH literature-supported);
  draft "verify against your DrugBank" notes removed.

## Unresolved limitations (honest)
- 4-vs-4 design: low power; few FDR DEGs; sex-stratified analyses are 2-vs-2 (unstable, exploratory,
  retained at the instructor's request).
- No usable `library_batch` / `sequencing_pool` / `lane` fields in the metadata -> batch effects
  cannot be modelled or excluded; stated as a limitation, not claimed to be controlled.
- Transcriptome-only Salmon index (RAM constraint); Salmon estimated counts are rounded before
  PyDESeq2 (approximation, not identical to a tximport-to-DESeq2 workflow).
- The DEG-derived disease module is small/exploratory; proximity is inconclusive rather than
  positive; a firm claim would need the full-cohort module.

## Open items NOT completed in this pass (do not assume done)
- `scripts/00_download.sh` with ENA md5 / atomic `.part` rename is NOT added; FASTQ download is
  documented in the notebook with a `gzip` integrity check, and integrity was verified manually.
- `01_qc_trim.sh` still runs fastp + MultiQC only; FastQC(raw)+FastQC(trimmed) were run separately
  (reports are under `results/qc/`), not yet folded into that script.
- `results/qc/fastqc_module_summary.csv` (parsed FastQC PASS/WARN/FAIL) NOT generated; before/after
  is shown via MultiQC and the fastp per-cycle quality curves.
- `tx2gene.tsv` / `gene_annotation.tsv` are present and validated at use, but a from-GTF generation
  script is not added; Salmon inferred library type is not yet extracted/reported.
- Full manifest/hash-based cache invalidation is not implemented (only a sample-set-keyed DEA cache).
- LFC shrinkage, MA plot, and per-sample mitochondrial/ribosomal-fraction plots are not added.
- `results/network/node_info.tsv` is generated from the final network tables (see final pass).
- The Italian study-report `.docx` is not regenerated with the latest numbers (generator has an
  unresolved string-escaping bug); the notebook is the authoritative deliverable.

These open items are recorded honestly so they are not mistaken for completed work.
