/*
 * MiXCR is a universal framework that processes big immunome data from raw sequences 
 * to quantitated clonotypes. MiXCR efficiently handles paired- and single-end reads, 
 * considers sequence quality, corrects PCR errors and identifies germline hypermutations.
 */

process MIXCR {
    tag "${meta.id}"
    label 'process_medium'

    // conda "${moduleDir}/environment.yml"
    // container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //     'https://depot.galaxyproject.org/singularity/mixcr:4.7.0--hdfd78af_0':
    //     'biocontainers/mixcr:4.7.0--hdfd78af_0' }"

    container 'ghcr.io/milaboratory/mixcr/mixcr:4.7.0-164-develop'
    containerOptions '--bind $TMPDIR'

    input:
    tuple val(meta), path(reads)
    path mi_license
    tuple val(preset), val(species)

    output:
    tuple val(meta), path("*clones*.tsv"), emit: clones
    tuple val(meta), path("*.txt"),        emit: reports
    tuple val(meta), path("*.clns"),       emit: clns,   optional: true
    path "versions.yml",                   emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mixcr -Xmx${task.memory.toGiga()}g analyze \\
        ${preset} \\
        --species ${species} \\
        ${args} \\
        ${reads} \\
        --threads ${task.cpus} \\
        ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mixcr: \$(mixcr -v |& sed -n '1p' | sed -E 's/MiXCR v([0-9\\.]+).*/\1/' || true)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mixcr -v 
    touch ${prefix}.clones_TRA.tsv
    touch ${prefix}.clones_TRB.tsv
    touch ${prefix}.clns
    touch ${prefix}.report.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mixcr: \$(mixcr -v 2>&1 | sed -n '1p' | sed -E 's/MiXCR v([0-9\\.]+).*/\1/' || true)
    END_VERSIONS
    """
}
