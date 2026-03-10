## Genomics variant-calling pipeline (exercise)

## Learning outcomes

**After having completed this chapter you will be able to:**

- Implement a small genomics pipeline that indexes BAM files and calls variants.
- Organise the workflow into an entry script, process modules and a configuration file.
- Use a sample sheet and reference files to drive the pipeline.
- Produce per-sample VCF files and indexes starting from pre-aligned BAM files.

## Material

[:fontawesome-solid-file-pdf: Download the presentation](../assets/pdf/site_under_construction.pdf){: .md-button }

## Scenario

You are given **pre-aligned BAM files** for a trio (mother, father, child) and a **reference genome**. Your task is to:

- **Index** each BAM file.
- **Call variants** on each indexed BAM using GATK HaplotypeCaller.
- Organise the outputs by type (BAMs and VCFs) in dedicated result folders.

You will write:

- A workflow file (entry point).
- Two modules (one for BAM indexing, one for variant calling).
- A configuration file with default parameters and a convenient profile.

The reference implementation can be found under `solutions/genomics-pipeline/`. Your goal is to recreate this behaviour as an exercise in the corresponding `exercises/` folder.

## Data and directory layout

### Starting directory

Work in the **exercise folder** (to be created if it does not exist yet):

```bash
cd exercises/genomics-pipeline
```

Create at least the following structure:

```text
exercises/genomics-pipeline/
├── data/
│   ├── bam/
│   │   ├── reads_mother.bam
│   │   ├── reads_father.bam
│   │   └── reads_son.bam
│   └── ref/
│       ├── ref.fasta
│       ├── ref.fasta.fai
│       ├── ref.dict
│       └── intervals.bed
├── data/samplesheet.csv
├── modules/
│   ├── samtools_index.nf
│   └── gatk_haplotypecaller.nf
├── genomics.nf
└── nextflow.config
```

### Sample sheet

The file `data/samplesheet.csv` contains one BAM per line:

```text
sample_id,reads_bam
NA12878,data/bam/reads_mother.bam
NA12877,data/bam/reads_father.bam
NA12882,data/bam/reads_son.bam
```

- `sample_id`: sample identifier.
- `reads_bam`: path to the input BAM (relative to the project root).

### Reference files

In `data/ref/` you have:

- `ref.fasta`: reference genome FASTA.
- `ref.fasta.fai`: FASTA index.
- `ref.dict`: sequence dictionary.
- `intervals.bed`: list of genomic intervals (subset of the genome to analyse).

## Exercise 1 – Configuration file

Create a `nextflow.config` file in `exercises/genomics-pipeline/` with the following requirements:

- **Container engine**
  - Enable Docker globally.
- **Profile `test`**
  - Sets:
    - `params.input` to `"$projectDir/data/samplesheet.csv"`.
    - `params.reference` to `"$projectDir/data/ref/ref.fasta"`.
    - `params.reference_index` to `"$projectDir/data/ref/ref.fasta.fai"`.
    - `params.reference_dict` to `"$projectDir/data/ref/ref.dict"`.
    - `params.intervals` to `"$projectDir/data/ref/intervals.bed"`.

You should be able to run the pipeline with:

```bash
nextflow run genomics.nf -profile test
```

??? success "Hint"
    - Use a `profiles { ... }` block in `nextflow.config`.
    - Refer to files with `${projectDir}` so that the paths work regardless of where the workflow is launched.

## Exercise 2 – BAM indexing module

Implement a module `modules/samtools_index.nf` that:

- Receives a BAM file as input.
- Runs `samtools index` to create the index (`.bai`).
- Emits both the original BAM and the index as outputs.
- Uses an appropriate Samtools container image.

### Requirements

- **Input**
  - A single `path` representing the BAM file.
- **Output**
  - A **tuple** with:
    - The original BAM file.
    - The corresponding `.bai` index file.
- **Command**
  - Call `samtools index` on the BAM.

??? success "Checklist"
    - Does the process emit **both** the BAM and its index?
    - Does the filename of the `.bai` match the BAM (e.g. `reads_mother.bam.bai`)?

## Exercise 3 – Variant-calling module

Implement a module `modules/gatk_haplotypecaller.nf` that:

- Receives:
  - A tuple with a BAM and its index.
  - The reference FASTA, its index and dictionary.
  - The intervals file.
- Runs GATK HaplotypeCaller to call variants.
- Produces a VCF file and its index.

### Requirements

- **Inputs**
  - Tuple: `(input_bam, input_bam_index)`.
  - Reference FASTA file.
  - Reference FASTA index file.
  - Reference dictionary file.
  - Interval list file.
- **Outputs**
  - A VCF file whose name is derived from the BAM filename.
  - A VCF index file with the same basename.
- **Command**
  - Use `gatk HaplotypeCaller` with:
    - `-R` pointing to the reference FASTA.
    - `-I` pointing to the BAM.
    - `-O` for the output VCF.
    - `-L` for the intervals.

Use a suitable GATK container image.

??? success "Checklist"
    - Does each input BAM produce exactly one VCF and one VCF index?
    - Are VCF filenames clearly linked to the BAM filenames?

## Exercise 4 – Workflow file

Create `genomics.nf` as the entry point of the pipeline with the following behaviour.

### Parameters

Define a `params` block with:

- `input`: input CSV (sample sheet).
- `reference`: reference FASTA.
- `reference_index`: FASTA index.
- `reference_dict`: sequence dictionary.
- `intervals`: intervals file.

These will be set by the `test` profile defined earlier.

### Module includes

At the top of `genomics.nf`, include the two modules:

- `SAMTOOLS_INDEX` from `./modules/samtools_index.nf`.
- `GATK_HAPLOTYPECALLER` from `./modules/gatk_haplotypecaller.nf`.

### Workflow logic

In the `workflow` block:

1. **Create the BAM channel**
   - Read `params.input` (CSV with header).
   - For each row, extract the `reads_bam` field and convert it to a file object.
2. **Load reference paths**
   - Convert the parameters for reference, index, dictionary and intervals into file objects.
3. **Index BAM files**
   - Run `SAMTOOLS_INDEX` on the BAM channel.
4. **Call variants**
   - Run `GATK_HAPLOTYPECALLER` using:
     - The output of `SAMTOOLS_INDEX`.
     - The reference files.

### Published outputs

Add a `publish` section in the `workflow` that:

- Assigns:
  - `indexed_bam` to the output of `SAMTOOLS_INDEX`.
  - `vcf` and `vcf_idx` to the outputs of `GATK_HAPLOTYPECALLER`.

Then add an `output` block that:

- Writes:
  - All indexed BAMs and `.bai` files under `results/bam/`.
  - All VCFs and VCF indexes under `results/vcf/`.

You should obtain, for each input BAM:

- An indexed BAM (`.bam` and `.bam.bai`) in `results/bam/`.
- A VCF and its index (`.vcf` and `.vcf.idx`) in `results/vcf/`.

??? success "Run and verify"
    - Run:
      ```bash
      nextflow run genomics.nf -profile test
      ```
    - Check:
      - `results/bam/` contains three BAM files and three `.bai` files.
      - `results/vcf/` contains three VCF files and three `.vcf.idx` files.
    - Optionally, inspect one of the VCFs to confirm that variants were called in the specified intervals.

