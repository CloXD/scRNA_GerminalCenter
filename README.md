# scRNA_GerminalCenter
Quick analysis of the GC1 and GC2 samples associated with the dataset https://www.ncbi.nlm.nih.gov/geo/query/acc.cgi?acc=GSE139891 
Reference: https://rupress.org/jem/article/217/10/e20200483/151908/Single-cell-analysis-of-germinal-center-B-cells

## Files structure
00_process_data.sh - download the raw and processed files; using Nextflow nf-core/scrnaseq process the raw data
01_QC.Rmd - quality control