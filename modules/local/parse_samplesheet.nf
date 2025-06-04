workflow PARSE_SAMPLESHEET {
    take:
    samplesheet // path: [mandatory] csv
    

    main:
    Channel.fromPath(params.samplesheet)
        .splitCsv(header: true)
        .map { row ->
            def glob_pattern = "${params.run_dir}/${row.fastq_prefix}_*.fastq*"
            def fq_files = []
            new File(params.run_dir).traverse(type: groovy.io.FileType.FILES) {
                if (it.name ==~ /${row.fastq_prefix}_.*\.fastq.*/) {
                    fq_files << it.toString()
                }
            }
            if (!fq_files) {
                throw new IllegalArgumentException("No FASTQ files found for sample: ${row.id} at ${glob_pattern}")
            }
            def meta = [:]
            meta.id = row.id
            row.each { key, value ->
                if (key != 'id' && key != 'fastq_prefix') {
                    meta[key] = value
                }
            }
            [ meta, fq_files ]
        }
        .set { ch_fastqs }
    emit:
    ch_fastqs // channel: [mandatory] meta, reads
}

