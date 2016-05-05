# Workflow for pre-processing raw reads

This workflow was designed to work in paired-end reads from Illumina technology. It includes three steps:

1) Removing reads of low quality (Phred quality score < 20) or those with uncalled bases (N);

2) Excluding duplicated reads;

3) Trimming the adaptor sequences.

The resulting files can now be used in genome assembling, variation analysis and others.

**Requirements:**

- [Trim Galore!](http://www.bioinformatics.babraham.ac.uk/projects/trim_galore/) installed;

- [Cutadapt](http://cutadapt.readthedocs.io/en/stable/index.html) in your path.

**Usage:**

  make -f pre_processing r1=[read_r1.fastq] r2=[read_r2.fastq] NAME=[sample_name]

**Potential problems:**

