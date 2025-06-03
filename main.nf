#!/usr/bin/env nextflow

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    NEXTFLOW OPTIONS AND EXPERIMENTAL FEATURES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

nextflow.enable.dsl=2
// needed to use the output directive
// currently experimental, so implementation may change
// https://www.nextflow.io/docs/latest/workflow.html#workflow-outputs
nextflow.preview.output = true

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    HELP MESSAGE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def helpMessage() {
    log.info """
    Usage:
    The typical command for running the pipeline is as follows:
    ./nextflow run main.nf -c run_arguments.config

    Edit the run_arguments.config file to add run parameters
    """.stripIndent()
}

// Show help message
params.help = ""
if (params.help) {
    helpMessage()
    exit 0
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS, MODULES, PROCESSES, WORKFLOWS, AND SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { CONCATENATE_FASTQ } from './modules/local/concatenate_fastq.nf'
include { DOWNSAMPLE_FASTQ } from './modules/local/downsample_fastq.nf'
include { PARSE_SAMPLESHEET } from './modules/local/parse_samplesheet.nf'
include { LOG_VERSIONS } from './modules/local/log_versions.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {
    main:
    ch_fastqs = PARSE_SAMPLESHEET(params.samplesheet)
    ch_versions = Channel.empty()

    CONCATENATE_FASTQ(ch_fastqs)
    ch_fastqs = CONCATENATE_FASTQ.out.fastqs
    DOWNSAMPLE_FASTQ(ch_fastqs, params.downsample_target)

    ch_versions = ch_versions.mix(
        // CONCATENATE_FASTQ.out.versions
        DOWNSAMPLE_FASTQ.out.versions
    )
    LOG_VERSIONS(ch_versions)

    publish:
    versions = LOG_VERSIONS.out.versions // >> 'versions'
}

output {
    versions {
        // path "pipeline_versions.yml"
        mode 'copy'
    }
}