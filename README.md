# Nextflow Pipeline Template

This is a template Nextflow pipeline that follows nf-core guidelines for modular and maintainable workflow development.

## Pipeline Structure

The pipeline is organized into several directories:

- `main.nf`: The main workflow file that orchestrates the entire pipeline
- `modules/`: Contains individual process modules
- `subworkflows/`: Chains related processes/modules or wraps channel manipulation code
- `conf/`: Configuration files
  - `nextflow.config`: Main configuration file with default arguments and profiles
  - `modules.config`: Module-specific configurations
  - `nf-test.config`: For running tests
  - `profiles.config`: Defining profiles separately cleanliness
- `bin/`: Custom scripts and executables
- `tests/`: Test data and test configurations

## Running the Pipeline

Basic usage:
```bash
./nextflow run main.nf -c run_arguments.config
```

For more options, see the help message:
```bash
./nextflow run main.nf --help
```

## Modifying the Pipeline

Use the [nf-core guidelines](https://nf-co.re/docs/guidelines/components/overview) for best practices and further details on the workflow.

### Sample metadata

Best practice is to use explicit metadata (e.g. samplesheet, not filenames) and propogate them through channels as a tuple.
https://training.nextflow.io/2.1/advanced/metadata/

### Adding New Processes/Modules

1. Create new process modules in the `modules/` directory
2. Add process-specific configurations in `conf/modules.config`
4. Include the new module in `main.nf`

#### Module Configuration

To add adjustable command line arguments for script calls in processes, define the parameters in `nextflow.config`:

```groovy
params {
    my_param = 'default_value'
}
```

Ideally all file parameters should be passed into the channel as an input.

Command line arguments should be added to `conf/modules.config`. This follows [nf-core guidelines](https://nf-co.re/docs/guidelines/components/modules#optional-command-arguments) and allows them to be overwritten by an (advanced) user-provided config if necessary. For example:

```groovy
process {
    withName: DOWNSAMPLE_FASTQ {
    ext.args = {[
        params.downsample_target, 
        "-s100"
    ].join(' ')}
    ext.prefix = { "${fastq.baseName}" }
}
```

Then the process has an `$args` variable

```grovy
...
script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${fastq.baseName}"
    """
    seqtk sample \
        ${args} \
        ${fastq} \
        | gzip > ${prefix}_downsampled.fastq.gz
    """
```



### Subworkflows

Subworkflows are used to group related processes and improve code organization. They are defined in the `subworkflows/` directory and included in `main.nf`. Nf-core guidelines suggest subworkflows be used to group 2 or more processes.

## Testing

Use the `nf-test` package to create and run tests. There is an executable at `/fh/fast/_IRC/FHIL/grp/bioinfo_tools/nf-test`. To test the pipeline will complete, you can use the following command:

```
/fh/fast/_IRC/FHIL/grp/bioinfo_tools/nf-test test tests/main.nf.test -c conf/nf-test.config
```

Further reading:

https://nf-co.re/docs/tutorials/tests_and_test_data/nf-test_writing_tests

https://www.nf-test.com/docs/getting-started/



## Best Practices

1. **Modularity**: Keep processes independent and reusable
2. **Configuration**: Use `modules.config` for process-specific settings
3. **Containerization**: Try to use Apptainer rather than Gizmo modules
4. **Testing**: Include tests for all new functionality
