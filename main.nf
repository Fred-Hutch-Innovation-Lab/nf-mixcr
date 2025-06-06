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
include { RUN_MIXCR } from './modules/local/mixcr.nf'
include { RUNTIME_SNAPSHOT } from './modules/local/runtime_snapshot.nf'
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow {
    main:
    RUNTIME_SNAPSHOT()
    PARSE_SAMPLESHEET(params.samplesheet)
    ch_fastqs = PARSE_SAMPLESHEET.out.ch_fastqs
    ch_versions = Channel.empty()

    CONCATENATE_FASTQ(ch_fastqs)
    CONCATENATE_FASTQ.out.stdout.view()
    ch_fastqs = CONCATENATE_FASTQ.out.fastqs

    // DOWNSAMPLE_FASTQ(ch_fastqs, params.downsample_target)
    // ch_fastqs = DOWNSAMPLE_FASTQ.out.fastqs

    mixcr_args = [
        params.mixcr_preset,
        params.mixcr_species
    ]
    RUN_MIXCR(ch_fastqs, params.mixcr_license, mixcr_args)
    ch_versions = ch_versions.mix(
        // CONCATENATE_FASTQ.out.versions
        // DOWNSAMPLE_FASTQ.out.versions.first(),
        MIXCR.out.versions
    )
    // LOG_VERSIONS(ch_versions)
    // ch_versions = LOG_VERSIONS.out.versions

    publish:
    clonotypes = MIXCR.out.clones
    reports = MIXCR.out.reports
    clns = MIXCR.out.clns
    run_details = RUNTIME_SNAPSHOT.out.run_details
    versions = ch_versions // >> 'versions'
}

output {
    versions {
        path "nextflow_logs/versions.txt"
        mode 'copy'
    }
    run_details {
        path "nextflow_logs/nextflow_parameters_log.txt"
        mode 'copy'
    }
    reports {
        mode 'copy'
        path { sample ->
            sample[1] >> "mixcr_ouputs/${sample[0].id}/"
        }
    }
    clones {
        mode 'copy'
        path { sample ->
            sample[1] >> "mixcr_ouputs/${sample[0].id}/"
        }
    }
    clns {
        mode 'copy'
        path { sample ->
            sample[1] >> "mixcr_ouputs/${sample[0].id}/"
        }
    }

}