process DOWNSAMPLE_FASTQ_PROCESS {
    tag "${meta.id}"

    container "staphb/seqtk:1.4"
    
    input:
    tuple val(meta), path(fastq)
    val(downsample_target)
    
    output:
    tuple val(meta), path("*_downsampled.fastq.gz", includeInputs: false), emit: fastqs
    path "versions.yml", emit: versions
    
    script:
    // https://nf-co.re/docs/guidelines/components/modules#optional-command-arguments
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${fastq.simpleName}"
    """
    seqtk sample \
        ${fastq} \
        ${args} \
        | gzip > ${prefix}_downsampled.fastq.gz
    
    ## https://nf-co.re/docs/guidelines/components/modules#emission-of-versions
    ## |& to capture stderr, sed to grab line containing "Version" and remove the prefix,
    ## || true because running seqtk with no arguments returns error code 1
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
    seqtk: \$( seqtk |& sed '/Version:/!d; s/Version: //' || true )
    END_VERSIONS
    """
}

workflow DOWNSAMPLE_FASTQ {
    take:
        ch_fastqs // channel: [mandatory] meta, reads
        downsample_target // value: [mandatory] target number of reads

    main:
        ch_fastq_individuals = ch_fastqs
            .flatMap { meta, fq_list ->
                fq_list.collect { fq -> [ meta, fq ] }
            }
        DOWNSAMPLE_FASTQ_PROCESS(ch_fastq_individuals, downsample_target)
        ch_grouped_downsampled = DOWNSAMPLE_FASTQ_PROCESS.out.fastqs
            .groupTuple()
        ch_versions = DOWNSAMPLE_FASTQ_PROCESS.out.versions

    emit:
        fastqs = ch_grouped_downsampled // channel: [mandatory] meta, reads
        versions = ch_versions // channel: [mandatory] versions.yml
}