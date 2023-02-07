#!/usr/bin/env bash


CONTAINER="quay.io/qiime2/core"
VERSION="2022.8"
WORKDIR="/data"
CMD="echo 'Start Analysis'"
P_TRIM_LENGTH="120"
OUT_FOLDER="$PWD"
QUALITY_FILTER="deblur"
GENERATE_PHYLO_TREE=true
GENERATE_ALPHA_BETA_DIVERSITY=true
GENERATE_HTML_REPORT=true
INPUT_TYPE='emp'
USE_DEBLUR=true
GENERATE_SUMMARY_TABLE=true
GENERATE_TOXICOLOGICAL_CLASSIFICATION=true
METADATA_FILE=''

usage() {
  echo "Usage: bash $0 [options]" 1>&2
  echo 1>&2
  echo "Options:" 1>&2
  echo "  -b|--barcode                             STRING                 Input type    (one of 'fastq', required)" 1>&2
  echo "  -s|--sequence                            STRING                 Input type    (one of 'fastq', required)" 1>&2
  echo "  -f|--forward                             STRING                 Input type    (one of 'fastq', required)" 1>&2
  echo "  -r|--reverse                             STRING                 Input type    (one of 'fastq', required)" 1>&2
  echo "  -m|--metadata                            STRING                 Input type    (one of 'tsv',   required)" 1>&2
  echo "  -o|--output                              STRING                 Output folder (default .)" 1>&2
  echo "  --deblur-trim-length                     INTEGER                Sequences to truncate during quality control. (default 120)" 1>&2
  echo "  --quality-filter                         STRING                 Sequences quality control methods (one of 'dada2' 'deblur', default 'deblur')" 1>&2
  echo "  --generate-toxicological-classification  FLAG                   (default TRUE)" 1>&2
  echo "  --generate-phylogenetic-tree             FLAG                   (default TRUE)" 1>&2
  echo "  --generate-alpha-beta-diversity          FLAG                   (default TRUE)" 1>&2
  echo "  --generate-html-reports                  FLAG                   Generate an html report for each result obtained. (default TRUE)" 1>&2
  echo 1>&2
}

exit_abnormal_usage() {
  echo "$1" 1>&2
  usage
  exit 1
}

absolute_path() {
  FILE=$1 
  if [[ ${FILE::2} == "./" ]]
  then
    echo "${PWD}/${1:2:${#1}}";
  else
    if [[ ${FILE::1} == "/" ]]
    then
      echo "$FILE"; 
    else
      echo "${PWD}/${FILE}"
    fi
  fi
}

## Get parameters
POSITIONAL_ARGS=()
while [[ $# -gt 0 ]]; do
  case $1 in
    -i|--input-type)
      _INPUT_TYPE="$2"
      shift
      shift
      ;;
    -b|--barcode)
      FIRST_FILE="$2"
      FIRST_TARGET='/data/emp-single-end-sequences/barcodes.fastq.gz '
      shift # past argument
      shift # past value
      ;;
    -s|--sequence)
      SECOND_FILE="$2"
      SECOND_TARGET='/data/emp-single-end-sequences/sequences.fastq.gz'
      shift # past argument
      shift # past value
      ;;
    -f|--forward)
      SECOND_FILE="$2"
      SECOND_TARGET='/data/emp-single-end-sequences/forward.fastq.gz'
      shift # past argument
      shift # past value
      ;;
    -r|--reverse)
      THIRD_FILE="$2"
      THIRD_TARGET='/data/emp-single-end-sequences/reverse.fastq.gz'
      shift # past argument
      shift # past value
      ;;
    -m|--metadata)
      METADATA_FILE="$2"
      shift # past argument
      shift # past value
      ;;
    -o|--output)
      OUT_FOLDER="$2"
      shift # past argument
      shift # past value
      ;;
    --deblur-trim-length)
      P_TRIM_LENGTH="$2"
      shift # past argument
      shift # past value
      ;;
    --quality_filter)
      [[ "$2" == "deblur" ]] && USE_DEBLUR=true
      [[ "$2" == "dada2" ]] && USE_DEBLUR=false
      shift # past argument
      shift # past value
      ;;
    --generate-phylogenetic-tree)
      GENERATE_PHYLO_TREE=true
      #shift # past argument
      shift # past value
      ;;
    --generate-alpha-beta-diversity)
      GENERATE_ALPHA_BETA_DIVERSITY=true
      #shift # past argument
      shift # past value
      ;;    
    --generate-html-reports)
      GENERATE_HTML_REPORT=true
      #shift # past argument
      shift # past value
      ;;
    --casava-demultiplexed)
      CASAVA_DEMULTIPLEXED=true
      #shift # past argument
      shift # past value
      ;;
    --paired-end)
      PAIRED_END=true
      #shift # past argument
      shift # past value
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    -*|--*)
      echo "Unknown option $1"
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1") # save positional arg
      shift # past argument
      ;;
  esac
done
set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

## Set input type
if [[ "$_INPUT_TYPE" == "emp" ]]; then
  if [[ "$PAIRED_END" == "true" ]]; then
    INPUT_TYPE='EMPPairedEndSequences'
  else
    INPUT_TYPE='EMPSingleEndSequences'
  fi
fi 

if [[ "$_INPUT_TYPE" == "bis" ]]; then
  if [[ "$PAIRED_END" == "true" ]]; then
    INPUT_TYPE='MultiplexedSingleEndBarcodeInSequence'
  else
    INPUT_TYPE='MultiplexedPairedEndBarcodeInSequence'
  fi
fi 

if [[ "$_INPUT_TYPE" == "casava" ]]; then
  INPUT_FORMAT='CasavaOneEightSingleLanePerSampleDirFmt'
  SECOND_TARGET='/data/emp-single-end-sequences/'
  if [[ "$PAIRED_END" == "true" ]]; then
    INPUT_TYPE='SampleData[PairedEndSequencesWithQuality]'
  else
    INPUT_TYPE='SampleData[SequencesWithQuality]'
  fi
fi 


## Download classifier
CMD="$CMD && curl -sL \
  'https://data.qiime2.org/2022.11/common/gg-13-8-99-515-806-nb-classifier.qza' > \
  'gg-13-8-99-515-806-nb-classifier.qza'"


## IMPORT DATA
CMD="$CMD && qiime tools import \
  --type $INPUT_TYPE \
  $([ "$INPUT_FORMAT" != '' ] && echo --input-format $INPUT_FORMAT) \
  --input-path emp-single-end-sequences \
  --output-path emp-single-end-sequences.qza"

echo "qiime tools import \
  --type $INPUT_TYPE \
  $([ "$INPUT_FORMAT" != '' ] && echo --input-format $INPUT_FORMAT) \
  --input-path emp-single-end-sequences \
  --output-path emp-single-end-sequences.qza"
#exit 0

## Demultiplexing
if [[ "$_INPUT_TYPE" != "casava" ]]; then
  CMD="$CMD && qiime demux emp-single \
    --i-seqs emp-single-end-sequences.qza \
    --m-barcodes-file sample-metadata.tsv \
    --m-barcodes-column barcode-sequence \
    --o-per-sample-sequences demux.qza \
    --o-error-correction-details demux-details.qza"
  CMD="$CMD && qiime demux summarize \
    --i-data demux.qza \
    --o-visualization demux.qzv"
else
  CMD="$CMD && cp emp-single-end-sequences.qza demux.qza"
fi

## Quality Filtering 
if [[ "$USE_DEBLUR" == "true" ]]; then
  CMD="$CMD && qiime quality-filter q-score \
    --i-demux demux.qza \
    --o-filtered-sequences demux-filtered.qza \
    --o-filter-stats demux-filter-stats.qza"
  CMD="$CMD && qiime deblur denoise-16S \
    --i-demultiplexed-seqs demux-filtered.qza \
    --p-trim-length $P_TRIM_LENGTH \
    --o-representative-sequences rep-seqs-deblur.qza \
    --o-table table-deblur.qza \
    --p-sample-stats \
    --o-stats deblur-stats.qza"
  CMD="$CMD && mv rep-seqs-deblur.qza rep-seqs.qza && mv table-deblur.qza table.qza"
else
  CMD="$CMD && qiime dada2 denoise-single \
    --i-demultiplexed-seqs demux.qza \
    --p-trim-left 0 \
    --p-trunc-len $P_TRIM_LENGTH \
    --o-representative-sequences rep-seqs-dada2.qza \
    --o-table table-dada2.qza \
    --o-denoising-stats stats-dada2.qza"
  CMD="$CMD && qiime metadata tabulate \
    --m-input-file stats-dada2.qza \
    --o-visualization stats-dada2.qzv"    
  CMD="$CMD && mv rep-seqs-dada2.qza rep-seqs.qza && mv table-dada2.qza table.qza"  
fi

## GENERATE SUMMARY TABLES
if [[ "$GENERATE_SUMMARY_TABLE" == "true" && "$METADATA_FILE" != '' ]]; then
  CMD="$CMD && qiime feature-table summarize \
    --i-table table.qza \
    --o-visualization table.qzv \
    --m-sample-metadata-file sample-metadata.tsv"
  CMD="$CMD && qiime feature-table tabulate-seqs \
    --i-data rep-seqs.qza \
    --o-visualization rep-seqs.qzv"
fi

## GENERATE TOXICOLOGICAL CLASSIFICATION
if [[ "$GENERATE_TOXICOLOGICAL_CLASSIFICATION" == "true" ]]; then
  CMD="$CMD && echo 'Generate Toxicological classification'"
  CMD="$CMD && qiime feature-classifier classify-sklearn \
    --i-classifier gg-13-8-99-515-806-nb-classifier.qza \
    --i-reads rep-seqs.qza \
    --o-classification taxonomy.qza"
  CMD="$CMD && qiime metadata tabulate \
    --m-input-file taxonomy.qza \
    --o-visualization taxonomy.qzv"
fi

## Generate a tree for phylogenetic diversity analyses
if [[ "$GENERATE_PHYLO_TREE" == "true" ]]; then
  CMD="$CMD && echo 'Generate Phylological tree'"
  CMD="$CMD && qiime phylogeny align-to-tree-mafft-fasttree \
    --i-sequences rep-seqs.qza \
    --o-alignment aligned-rep-seqs.qza \
    --o-masked-alignment masked-aligned-rep-seqs.qza \
    --o-tree unrooted-tree.qza \
    --o-rooted-tree rooted-tree.qza"
fi

##Alpha and beta diversity analysis
if [[ "$GENERATE_ALPHA_BETA_DIVERSITY" == "true" ]]; then
  if [[ "$METADATA_FILE" != '' ]]; then 
    CMD="$CMD && echo 'Generate Alpha-Beta deversity'"
    CMD="$CMD && qiime diversity core-metrics-phylogenetic \
      --i-phylogeny rooted-tree.qza \
      --i-table table.qza \
      --p-sampling-depth 1103 \
      --m-metadata-file sample-metadata.tsv \
      --output-dir core-metrics-results"
    CMD="$CMD && qiime diversity alpha-group-significance \
      --i-alpha-diversity core-metrics-results/faith_pd_vector.qza \
      --m-metadata-file sample-metadata.tsv \
      --o-visualization core-metrics-results/faith-pd-group-significance.qzv"
    CMD="$CMD && qiime diversity alpha-group-significance \
      --i-alpha-diversity core-metrics-results/evenness_vector.qza \
      --m-metadata-file sample-metadata.tsv \
      --o-visualization core-metrics-results/evenness-group-significance.qzv"
    CMD="$CMD && qiime emperor plot \
      --i-pcoa core-metrics-results/unweighted_unifrac_pcoa_results.qza \
      --m-metadata-file sample-metadata.tsv \
      --p-custom-axes days-since-experiment-start \
      --o-visualization core-metrics-results/unweighted-unifrac-emperor-days-since-experiment-start.qzv"
    CMD="$CMD && qiime emperor plot \
      --i-pcoa core-metrics-results/bray_curtis_pcoa_results.qza \
      --m-metadata-file sample-metadata.tsv \
      --p-custom-axes days-since-experiment-start \
      --o-visualization core-metrics-results/bray-curtis-emperor-days-since-experiment-start.qzv"
    CMD="$CMD && qiime diversity alpha-rarefaction \
      --i-table table.qza \
      --i-phylogeny rooted-tree.qza \
      --p-max-depth 4000 \
      --m-metadata-file sample-metadata.tsv \
      --o-visualization alpha-rarefaction.qzv"
  else
    CMD="$CMD && echo 'Alpha-Beta deversity cant be generated without metadata'"
  fi
fi

##COPY ALL DATA IN OUTFOLDER
mkdir -p "$PWD/$OUT_FOLDER"
CMD="$CMD && cp -r /data/* /output/"

echo "Creating container..."
docker run -it --rm \
    $([ "$FIRST_FILE" != '' ] && echo --mount type=bind,source="$(absolute_path "$FIRST_FILE")",target="$FIRST_TARGET") \
    $([ "$SECOND_FILE" != '' ] && echo --mount type=bind,source="$(absolute_path "$SECOND_FILE")",target="$SECOND_TARGET") \
    $([ "$THIRD_FILE" != '' ] && echo --mount type=bind,source="$(absolute_path "$THIRD_FILE")",target="$THIRD_TARGET") \
    $([ "$METADATA_FILE" != '' ] && echo --mount type=bind,source=$(absolute_path "$METADATA_FILE"),target="/data/sample-metadata.tsv" ) \
    -v "$PWD/$OUT_FOLDER:/output/" \
$CONTAINER:$VERSION \
/bin/bash -c "$CMD"

[[ "$GENERATE_HTML_REPORT" == "true" ]] && mkdir -p "$PWD/$OUT_FOLDER/reports" && \
docker run --rm -v "$PWD/$OUT_FOLDER:/data" -w /data kubeless/unzip /bin/bash -c 'for i in $(ls /data | grep qzv); do unzip -q "/data/$i" "*/data/*" -d "/data/reports/$i"; done;'