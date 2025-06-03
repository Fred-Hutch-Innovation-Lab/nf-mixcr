process MIXCR {
    tag "${meta.id}"
    //conda "${moduleDir}/environment.yml"
    container 'ghcr.io/milaboratory/mixcr/mixcr:4.7.0-164-develop'
    containerOptions '--bind /loc/scratch:/loc/scratch'

    // Set environment variables for license
    // if (params.license_file) {
    //     env.MI_LICENSE_FILE = params.license_file
    // } else if (params.license_token) {
    //     env.MI_LICENSE = params.license_token
    // }

    input:
    tuple val(meta), path(reads)
    val preset
    env MI_LICENSE

    output:
    //tuple val(meta), path("*.tsv"), emit: tsv
    tuple val(meta), path("*clones*.tsv"), emit: clonotypes
    tuple val(meta), path("*.txt"),        emit: reports
    tuple val(meta), path("*.clns"),       emit: clns,   optional: true
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when
    // beforeScript "export NXF_SINGULARITY_HOME_MOUNT=true;"

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    // TODO nf-core: It MUST be possible to pass additional parameters to the tool as a command-line string via the "task.ext.args" directive
    """
    mixcr analyze \
        ${preset} \
        --threads ${task.cpus} \
        --species ${task.ext.species ?: 'hsa'} \
        ${args} \
        ${reads} \
        ${prefix}
  

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mixcr: \$(mixcr -v |& sed -n '1p' | sed -E 's/MiXCR v([0-9\\.]+).*/\1/' || true)
    END_VERSIONS
    """

    stub:
    // def args = task.ext.args ?: ''
    // def prefix = task.ext.prefix ?: "${meta.id}"
    // TODO nf-core: A stub section should mimic the execution of the original module as best as possible
    //               Have a look at the following examples:
    //               Simple example: https://github.com/nf-core/modules/blob/818474a292b4860ae8ff88e149fbcda68814114d/modules/nf-core/bcftools/annotate/main.nf#L47-L63
    //               Complex example: https://github.com/nf-core/modules/blob/818474a292b4860ae8ff88e149fbcda68814114d/modules/nf-core/bedtools/split/main.nf#L38-L54
    """
    touch ${prefix}.cloens_TRA.tsv
    touch ${prefix}.cloens_TRB.tsv
    touch qc.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mixcr: \$(mixcr -v | sed -n '1p' | sed -E 's/MiXCR v([0-9\\.]+).*/\1/' || true)
    END_VERSIONS
    """
}
