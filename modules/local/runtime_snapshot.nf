process RUNTIME_SNAPSHOT {
    //publishDir "$pubDir", mode: 'move'
    // input:
    //     val pubDir
    executor 'local'
    output:
        path 'nextflow_run_details.txt', emit: 'run_details'
    script:
    def summary = """\
    ---------------------------
    Pipeline invocation summary
    ---------------------------
    Start   :   ${workflow.start}
    Command :   ${workflow.commandLine}
    runID   :   ${workflow.runName}
    workdir :   ${workflow.workDir}
    profile :   ${workflow.profile}
    resumed?:   ${workflow.resume}

    ---------------------------
    Config snapshot
    ---------------------------
    """.stripIndent()

    
    // workflow.config.each { key, value ->
    //     echo "Config option: $key = $value" >> nextflow_run_details.txt
    // }
    /*
    // Capture all config files, including those from the main configFile
    def configFiles = workflow.configFiles + workflow.config.includedFiles
    for (file in configFiles) {
        echo "Config file: \$file" >> nextflow_run_details.txt
        cat \$file >> nextflow_run_details.txt
    }
    */
  
    """
    echo "$summary" >> nextflow_run_details.txt
    for file in ${workflow.configFiles.toSet().join(' ')}; do
        echo "Config file: \$file" >> nextflow_run_details.txt;
        cat \$file >> nextflow_run_details.txt;
        echo "---------------------------" >> nextflow_run_details.txt;
    done
    """ 
    stub:
    """
    echo 'stubrun'# >> nextflow_run_details.txt
    """   
}