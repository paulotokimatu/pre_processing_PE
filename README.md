# Workflow for pre-processing raw reads

This workflow was designed for paired-end reads. It includes three steps:
1) Removing reads of low quality (Phred quality score < 20) or those having N nucleotide;
2) Excluding duplicated reads;
3) Trimming the adaptor sequences.
