# Dockerized-qiime-pipeline
Run qiime analysis inside a docker container.

```
rvilla@bioinfo:/home/oncosmart/qiime$ ./run_qiime.sh --help
Usage: bash ./run_qiime.sh [options]

Options:
  -b|--barcode                             STRING                 Input type    (one of 'fastq', required)
  -s|--sequence                            STRING                 Input type    (one of 'fastq', required)
  -f|--forward                             STRING                 Input type    (one of 'fastq', required)
  -r|--reverse                             STRING                 Input type    (one of 'fastq', required)
  -m|--metadata                            STRING                 Input type    (one of 'tsv',   required)
  -o|--output                              STRING                 Output folder (default .)
  --deblur-trim-length                     INTEGER                Sequences to truncate during quality control. (default 120)
  --quality-filter                         STRING                 Sequences quality control methods (one of 'dada2' 'deblur', default 'deblur')
  --generate-toxicological-classification  FLAG                   (default TRUE)
  --generate-phylogenetic-tree             FLAG                   (default TRUE)
  --generate-alpha-beta-diversity          FLAG                   (default TRUE)
  --generate-html-reports                  FLAG                   Generate an html report for each result obtained. (default TRUE)
```
