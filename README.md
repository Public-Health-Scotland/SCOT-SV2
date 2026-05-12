# Rebuilding SIP

## Rationale

Restructuring, and refactoring of SIP the SIP pipelines so they can be transferred to SG2. This entails the creation and use of defined Singularity images for separate steps, refactoring code to add in configuration options as parameters which can be set at runtime to avoid manipulating template config files.

## Aims

- Integrate singularity images into ncov2019 nextflow natively
- Refactor bash scripts
- Adapt ncov-QC to avoid manipulation of snakemake configs for each run
- Remove all hard-coded paths referencing locations on SG1
- Ensure restructured repo is largely self-contained (preventing the need for third-place referencing)

## Authors

- Sharif Shaaban
- Gonzalo Yebra
- Stefan Rooke
