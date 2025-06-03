def processVersionsFromYAML(yaml_file) {
    def yaml = new org.yaml.snakeyaml.Yaml()
    def versions = yaml.load(yaml_file).collectEntries { k, v -> [k.tokenize(':')[-1], v] }
    return yaml.dumpAsMap(versions).trim()
}

def softwareVersionsToYAML(ch_versions) {
    return ch_versions.unique().map { version -> processVersionsFromYAML(version) }.unique()//.mix(Channel.of(workflowVersionToYAML()))
}

workflow LOG_VERSIONS {
    take: 
        ch_versions // channel: [mandatory] version_files

    main:  
        ch_collated_versions = softwareVersionsToYAML(ch_versions)
            .collectFile(
                name: 'pipeline_versions.yml',
                sort: true,
                newLine: true,
            )

    emit: 
        versions = ch_collated_versions // channel: [mandatory] versions.yml

}

