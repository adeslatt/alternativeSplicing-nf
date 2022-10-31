process trimmomatic {
    tag "$name"
    label 'low_memory'
    publishDir "${params.outdir}/process-logs/${task.process}/${name}", pattern: "command-logs-*", mode: 'copy'

    input:
    set val(name), file(reads), val(singleEnd), file(adapter) from raw_reads_trimmomatic_adapter

    output:
    set val(name), file(output_filename), val(singleEnd) into (trimmed_reads_fastqc, trimmed_reads_star)
    file ("logs/${name}_trimmomatic.log") into trimmomatic_logs
    file("command-logs-*") optional true

    script:
    mode = singleEnd ? 'SE' : 'PE'
    out = singleEnd ? "${name}_trimmed.fastq.gz" : "${name}_trimmed_R1.fastq.gz ${name}_unpaired_R1.fastq.gz ${name}_trimmed_R2.fastq.gz ${name}_unpaired_R2.fastq.gz"
    output_filename = singleEnd ? "${name}_trimmed.fastq.gz" : "${name}_trimmed_R{1,2}.fastq.gz"
    slidingwindow = params.slidingwindow ? 'SLIDINGWINDOW:4:15' : ''
    keepbothreads = singleEnd == true ? '' : ':2:true'
    """
    trimmomatic \
      $mode \
      -threads $task.cpus \
      -phred33 \
      $reads \
      $out \
      ILLUMINACLIP:${adapter}:2:30:10${keepbothreads} \
      LEADING:3 \
      TRAILING:3 \
      $slidingwindow \
      MINLEN:${minlen} \
      CROP:${params.readlength}

    mkdir logs
    cp .command.log logs/${name}_trimmomatic.log

    # save .command.* logs
    ${params.savescript}
    """
}
