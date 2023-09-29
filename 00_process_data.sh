#!/bin/bash

### Local variables

MAX_MEMORY='30GB'
MAX_CPUS='3'
PIPELINE_VERSION="2.4.0"
ALIGNER="cellranger"
PROTOCOL="10XV2"
GENOME="GRCh38"
PROFILE="singularity"
export NXF_SINGULARITY_CACHEDIR=$(realpath ./singularity)

### Download the processed data

mkdir -p ./data/
wget -O ./GSE139891.tar 'https://www.ncbi.nlm.nih.gov/geo/download/?acc=GSE139891&format=file'
tar -xf ./GSE139891.tar
mv GSM4*_GC1_umi_grch38.txt.gz ./data/
mv GSM4*_GC2_umi_grch38.txt.gz ./data/
rm ./GSM*.gz




### Download the raw data

SRR_IDS="GC1:SRR11827034 GC2:SRR11827035"
OUTPUT_DIR=$(realpath ./raw )
CURR_DIR=$(realpath ./ )

echo "sample,fastq_1,fastq_2,expected_cells" > ${CURR_DIR}/samplesheet.csv
EXPECTED_CELLS="4500"

for SRR_NAME in $SRR_IDS; do
	SRR=$(echo $SRR_NAME | awk -F ':' '{print $2}' )
	SAMPLE=$(echo $SRR_NAME | awk -F ':' '{print $1}' )
	echo "${SRR} with name ${SAMPLE}"
	cd $OUTPUT_DIR
	[ -f ${SRR}_R1.fastq ] || [ -f ${SAMPLE}_R1.fastq.gz ] || fasterq-dump -S --include-technical $SRR
	[ -f ${SRR}_1.fastq ] && mv ${SRR}_1.fastq ${SAMPLE}_R1.fastq
	[ -f ${SRR}_2.fastq ] && mv ${SRR}_1.fastq ${SAMPLE}_R2.fastq
	[ -f ${SAMPLE}_R1.fastq.gz ] || gzip ./${SAMPLE}_R1.fastq
	[ -f ${SAMPLE}_R2.fastq.gz ] || gzip ./${SAMPLE}_R2.fastq
	[ -f ${SRR}_3.fastq.gz ] || gzip ./${SRR}_3.fastq
	echo "${SAMPLE},${OUTPUT_DIR}/${SAMPLE}_R1.fastq.gz,${OUTPUT_DIR}/${SAMPLE}_R2.fastq.gz,${EXPECTED_CELLS}" >> ${CURR_DIR}/samplesheet.csv
	cd $CURR_DIR
done

### Running the NextFlow pipeline

export NXF_OPTS='-Xms1g -Xmx4g'

## Local Configuration

echo "
executor {
  local {
      cpus = ${MAX_CPUS}
      memory = '${MAX_MEMORY}'
  }
}
" > ./nextflow.config

ADDITIONAL=""
if [[ ${ALIGNER} == "cellranger" ]] && [[ ${GENOME} == "GRCh38" ]] ; then
	[ -f ./refdata-gex-GRCh38-2020-A.tar.gz ] ||  wget "https://cf.10xgenomics.com/supp/cell-exp/refdata-gex-GRCh38-2020-A.tar.gz"
	[ -d ./refdata-gex-GRCh38-2020-A ] || tar -xvf refdata-gex-GRCh38-2020-A.tar.gz
	ADDITIONAL="--cellranger_index $(realpath ./refdata-gex-GRCh38-2020-A)"
	
fi

echo nextflow run nf-core/scrnaseq -r ${PIPELINE_VERSION} --input ./samplesheet.csv --outdir ./results --genome ${GENOME} -profile ${PROFILE} --aligner ${ALIGNER} --max_cpus ${MAX_CPUS} --max_memory "${MAX_MEMORY}" --protocol ${PROTOCOL} $ADDITIONAL
