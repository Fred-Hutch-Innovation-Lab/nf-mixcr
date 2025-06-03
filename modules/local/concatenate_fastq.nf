process CONCATENATE_FASTQ {
    tag "${meta.id}"

    container "python:3.13.3"
    
    input:
    tuple val(meta), path(fastqs)
    
    output:
    tuple val(meta), path("*.fastq.gz", includeInputs: false), emit: fastqs
    
    script:
    def files = fastqs.join(' ')
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    concatenate_fastq.py \
        --files ${files} \
        --sampleID ${prefix} \
        ${args}
    """
} 