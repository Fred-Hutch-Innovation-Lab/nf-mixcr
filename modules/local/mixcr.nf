/*
 * MiXCR is a universal framework that processes big immunome data from raw sequences 
 * to quantitated clonotypes. MiXCR efficiently handles paired- and single-end reads, 
 * considers sequence quality, corrects PCR errors and identifies germline hypermutations.
 */

// process MIXCR_ANALYZE {
//     tag "${meta.id}"
//     label 'process_medium'

//     // conda "${moduleDir}/environment.yml"
//     // container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
//     //     'https://depot.galaxyproject.org/singularity/mixcr:4.7.0--hdfd78af_0':
//     //     'biocontainers/mixcr:4.7.0--hdfd78af_0' }"

//     container 'ghcr.io/milaboratory/mixcr/mixcr:4.7.0-164-develop'
//     containerOptions '--bind $TMPDIR'

//     input:
//     tuple val(meta), path(reads)
//     path mi_license
//     tuple val(preset), val(species)

//     output:
//     tuple val(meta), path("*clones*.tsv"), emit: clonotypes
//     tuple val(meta), path("*.txt"),        emit: reports
//     tuple val(meta), path("*.clns"),       emit: clns,   optional: true
//     path "versions.yml",                   emit: versions

//     when:
//     task.ext.when == null || task.ext.when

//     script:
//     def args = task.ext.args ?: ''
//     def prefix = task.ext.prefix ?: "${meta.id}"
//     """
//     mixcr -Xmx${task.memory.toGiga()}g analyze \\
//         ${preset} \\
//         --species ${species} \\
//         ${args} \\
//         --threads ${task.cpus} \\
//         ${reads} \\
//         ${prefix}

//     cat <<-END_VERSIONS > versions.yml
//     "${task.process}":
//         mixcr: \$(mixcr -v |& sed -n '1p' | sed -E 's/MiXCR v([0-9\\.]+).*/\1/' || true)
//     END_VERSIONS
//     """

//     stub:
//     def prefix = task.ext.prefix ?: "${meta.id}"
//     """
//     mixcr -v 
//     touch ${prefix}.clones_TRA.tsv
//     touch ${prefix}.clones_TRB.tsv
//     touch ${prefix}.clns
//     touch ${prefix}.report.txt

//     cat <<-END_VERSIONS > versions.yml
//     "${task.process}":
//         mixcr: \$(mixcr -v 2>&1 | sed -n '1p' | sed -E 's/MiXCR v([0-9\\.]+).*/\1/' || true)
//     END_VERSIONS
//     """
// }

process MIXCR_ALIGN {
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
    tuple val(meta), path("*.vdjca"),      emit: vdjca
    tuple val(meta), path("*report.txt"),  emit: reports, optional: true
    path "versions.yml",                   emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def mem = task.memory.toGiga()
    // def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mixcr -Xmx${mem}g align \\
        ${preset} \\
        --species ${species} \\
        ${args} \\
        --threads ${task.cpus} \\
        ${reads} 

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mixcr: \$(mixcr -v |& sed -n '1p' | sed -E 's/MiXCR v([0-9\\.]+).*/\1/' || true)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mixcr -v 
    touch sample.vdjca
    touch report.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mixcr: \$(mixcr -v 2>&1 | sed -n '1p' | sed -E 's/MiXCR v([0-9\\.]+).*/\1/' || true)
    END_VERSIONS
    """
}

process MIXCR_REFINE_TAGS_AND_SORT {
    tag "${meta.id}"
    label 'process_medium'

    // conda "${moduleDir}/environment.yml"
    // container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //     'https://depot.galaxyproject.org/singularity/mixcr:4.7.0--hdfd78af_0':
    //     'biocontainers/mixcr:4.7.0--hdfd78af_0' }"

    container 'ghcr.io/milaboratory/mixcr/mixcr:4.7.0-164-develop'
    containerOptions '--bind $TMPDIR'

    input:
    tuple val(meta), path(vdjca)
    path mi_license

    output:
    tuple val(meta), path("*.refined.vdjca"),  emit: refined_vdjca
    tuple val(meta), path("*report.txt"),      emit: reports, optional: true
    path "versions.yml",                       emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def mem = task.memory.toGiga()
    // def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mixcr -Xmx${mem}g refineTagsAndSort \\
        ${args} \\
        --threads ${task.cpus} \\
        ${vdjca} 

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mixcr: \$(mixcr -v |& sed -n '1p' | sed -E 's/MiXCR v([0-9\\.]+).*/\1/' || true)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mixcr -v 
    touch sample.refined.vdjca
    touch report.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mixcr: \$(mixcr -v 2>&1 | sed -n '1p' | sed -E 's/MiXCR v([0-9\\.]+).*/\1/' || true)
    END_VERSIONS
    """
}

process MIXCR_ASSEMBLE_PARTIAL {
    tag "${meta.id}"
    label 'process_medium'

    // conda "${moduleDir}/environment.yml"
    // container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //     'https://depot.galaxyproject.org/singularity/mixcr:4.7.0--hdfd78af_0':
    //     'biocontainers/mixcr:4.7.0--hdfd78af_0' }"

    container 'ghcr.io/milaboratory/mixcr/mixcr:4.7.0-164-develop'
    containerOptions '--bind $TMPDIR'

    input:
    tuple val(meta), path(refined_vdjca)
    path mi_license

    output:
    tuple val(meta), path("*.par.vdjca"),      emit: partial_vdjca
    tuple val(meta), path("*report.txt"),      emit: reports, optional: true
    path "versions.yml",                       emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def mem = task.memory.toGiga()
    // def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mixcr -Xmx${mem}g assemblePartial \\
        ${args} \\
        --threads ${task.cpus} \\
        ${refined_vdjca} 

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mixcr: \$(mixcr -v |& sed -n '1p' | sed -E 's/MiXCR v([0-9\\.]+).*/\1/' || true)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mixcr -v 
    touch sample.par.vdjca
    touch report.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mixcr: \$(mixcr -v 2>&1 | sed -n '1p' | sed -E 's/MiXCR v([0-9\\.]+).*/\1/' || true)
    END_VERSIONS
    """
}

process MIXCR_ASSEMBLE {
    tag "${meta.id}"
    label 'process_medium'

    // conda "${moduleDir}/environment.yml"
    // container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //     'https://depot.galaxyproject.org/singularity/mixcr:4.7.0--hdfd78af_0':
    //     'biocontainers/mixcr:4.7.0--hdfd78af_0' }"

    container 'ghcr.io/milaboratory/mixcr/mixcr:4.7.0-164-develop'
    containerOptions '--bind $TMPDIR'

    input:
    tuple val(meta), path(partial_vdjca)
    path mi_license

    output:
    tuple val(meta), path("*.clna"),       emit: clna
    tuple val(meta), path("*report.txt"), emit: reports, optional: true
    path "versions.yml",                   emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def mem = task.memory.toGiga()
    // def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mixcr -Xmx${mem}g assemble \\
        ${args} \\
        --threads ${task.cpus} \\
        ${partial_vdjca} 

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mixcr: \$(mixcr -v |& sed -n '1p' | sed -E 's/MiXCR v([0-9\\.]+).*/\1/' || true)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mixcr -v 
    touch sample.clna
    touch report.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mixcr: \$(mixcr -v 2>&1 | sed -n '1p' | sed -E 's/MiXCR v([0-9\\.]+).*/\1/' || true)
    END_VERSIONS
    """
}

process MIXCR_ASSEMBLE_CONTIGS {
    tag "${meta.id}"
    label 'process_medium'

    // conda "${moduleDir}/environment.yml"
    // container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //     'https://depot.galaxyproject.org/singularity/mixcr:4.7.0--hdfd78af_0':
    //     'biocontainers/mixcr:4.7.0--hdfd78af_0' }"

    container 'ghcr.io/milaboratory/mixcr/mixcr:4.7.0-164-develop'
    containerOptions '--bind $TMPDIR'

    input:
    tuple val(meta), path(clna)
    path mi_license

    output:
    tuple val(meta), path("*.clns"),      emit: clns
    tuple val(meta), path("*report.txt"), emit: reports, optional: true
    path "versions.yml",                  emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def mem = task.memory.toGiga()
    // def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mixcr -Xmx${mem}g assembleContigs \\
        ${args} \\
        --threads ${task.cpus} \\
        ${partial_vdjca} 

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mixcr: \$(mixcr -v |& sed -n '1p' | sed -E 's/MiXCR v([0-9\\.]+).*/\1/' || true)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mixcr -v 
    touch sample.clns
    touch report.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mixcr: \$(mixcr -v 2>&1 | sed -n '1p' | sed -E 's/MiXCR v([0-9\\.]+).*/\1/' || true)
    END_VERSIONS
    """
}

process MIXCR_EXPORT_CLONES {
    tag "${meta.id}"
    label 'process_low'

    // conda "${moduleDir}/environment.yml"
    // container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
    //     'https://depot.galaxyproject.org/singularity/mixcr:4.7.0--hdfd78af_0':
    //     'biocontainers/mixcr:4.7.0--hdfd78af_0' }"

    container 'ghcr.io/milaboratory/mixcr/mixcr:4.7.0-164-develop'
    containerOptions '--bind $TMPDIR'

    input:
    tuple val(meta), path(clns)
    path mi_license

    output:
    tuple val(meta), path("*.tsv"),       emit: clones
    tuple val(meta), path("*.txt"),       emit: reports, optional: true
    path "versions.yml",                  emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def mem = task.memory.toGiga()
    // def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mixcr -Xmx${mem}g exportClones \\
        ${args} \\
        --threads ${task.cpus} \\
        ${clns} 

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mixcr: \$(mixcr -v |& sed -n '1p' | sed -E 's/MiXCR v([0-9\\.]+).*/\1/' || true)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mixcr -v 
    touch alignments.vdjca
    touch ${prefix}.report.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mixcr: \$(mixcr -v 2>&1 | sed -n '1p' | sed -E 's/MiXCR v([0-9\\.]+).*/\1/' || true)
    END_VERSIONS
    """
}

workflow MIXCR {
    take:
        ch_fastqs     // channel: [mandatory] meta, reads
        mixcr_license // path: [mandatory] license file for mixcr
        mixcr_preset  // value: [mandatory] preset for mixcr
        mixcr_species // value: [mandatory] species for mixcr

    main:
        ch_versions = Channel.empty()

        MIXCR_ALIGN(ch_fastqs, mixcr_license, [mixcr_preset, mixcr_species])
        ch_versions = ch_versions.mix(MIXCR_ALIGN.out.versions)

        MIXCR_REFINE_TAGS_AND_SORT(MIXCR_ALIGN.out.vdjca, mixcr_license)
        ch_versions = ch_versions.mix(MIXCR_REFINE_TAGS_AND_SORT.out.versions)

        MIXCR_ASSEMBLE_PARTIAL(MIXCR_REFINE_TAGS_AND_SORT.out.refined_vdjca, mixcr_license)
        ch_versions = ch_versions.mix(MIXCR_ASSEMBLE_PARTIAL.out.versions)

        MIXCR_ASSEMBLE(MIXCR_ASSEMBLE_PARTIAL.out.partial_vdjca, mixcr_license)
        ch_versions = ch_versions.mix(MIXCR_ASSEMBLE.out.versions)

        MIXCR_ASSEMBLE_CONTIGS(MIXCR_ASSEMBLE.out.clna, mixcr_license)
        ch_versions = ch_versions.mix(MIXCR_ASSEMBLE_CONTIGS.out.versions)

        MIXCR_EXPORT_CLONES(MIXCR_ASSEMBLE_CONTIGS.out.clns, mixcr_license)
        ch_versions = ch_versions.mix(MIXCR_EXPORT_CLONES.out.versions)

    emit:
        clones   = MIXCR_EXPORT_CLONES.out.clones     // channel: [meta, clone_files]
        clns     = MIXCR_ASSEMBLE_CONTIGS.out.clns    // channel: [meta, clns_files]
        reports  = MIXCR_EXPORT_CLONES.out.reports    // channel: [meta, report_files]
        versions = ch_versions                        // channel: versions.yml
}