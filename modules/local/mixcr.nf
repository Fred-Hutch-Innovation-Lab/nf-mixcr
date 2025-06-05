process MIXCR {
    tag "${meta.id}"
    //conda "${moduleDir}/environment.yml"
    container 'ghcr.io/milaboratory/mixcr/mixcr:4.7.0-164-develop'
    containerOptions '--bind $TMPDIR'

    input:
    tuple val(meta), path(reads)
    path(mi_license)
    tuple val(preset), 
          val(material),
          val(species),
          val(assemble_clonotypes_by),
          val(left_alignment_boundary), val(left_alignment_anchor),
          val(right_alignment_boundary), val(right_alignment_anchor),
          val(tag_pattern),
          val(additional_arguments)

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
    def left_alignment = [
        (left_alignment_boundary == 'float' ? '--floating-left-alignment-boundary' :
        left_alignment_boundary == 'rigid' ? '--rigid-left-alignment-boundary' : ''),
        left_alignment_anchor
    ].join(' ')

    def right_alignment = [
        (right_alignment_boundary == 'float' ? '--floating-right-alignment-boundary' :
        right_alignment_boundary == 'rigid' ? '--rigid-right-alignment-boundary' : ''),
        right_alignment_anchor
    ].join(' ')
    def m_args = additional_arguments ? additional_arguments.collect { "-M $it" }.join(' ') : ''

    // TODO nf-core: It MUST be possible to pass additional parameters to the tool as a command-line string via the "task.ext.args" directive
    """
    mixcr analyze \
        ${preset} \
        --${material} \
        --species ${species} \
        --threads ${task.cpus} \
        ${left_alignment} \
        ${right_alignment} \
        --assemble-clonotypes-by ${assemble_clonotypes_by} \
        --tag-pattern "${tag_pattern}" \
        ${m_args} \
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
    def prefix = task.ext.prefix ?: "${meta.id}"
    // TODO nf-core: A stub section should mimic the execution of the original module as best as possible
    //               Have a look at the following examples:
    //               Simple example: https://github.com/nf-core/modules/blob/818474a292b4860ae8ff88e149fbcda68814114d/modules/nf-core/bcftools/annotate/main.nf#L47-L63
    //               Complex example: https://github.com/nf-core/modules/blob/818474a292b4860ae8ff88e149fbcda68814114d/modules/nf-core/bedtools/split/main.nf#L38-L54
    """
    mixcr -v 
    touch ${prefix}.clones_TRA.tsv
    touch ${prefix}.clones_TRB.tsv
    touch qc.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mixcr: \$(mixcr -v | sed -n '1p' | sed -E 's/MiXCR v([0-9\\.]+).*/\1/' || true)
    END_VERSIONS
    """
}
