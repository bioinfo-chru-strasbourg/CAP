#!/bin/bash
#################################
##
## NGS environment
##
#################################

SCRIPT_NAME="CAPCoverage"
SCRIPT_DESCRIPTION="CAP coverage calculation on amplicons"
SCRIPT_RELEASE="0.9.3b"
SCRIPT_DATE="31/05/2018"
SCRIPT_AUTHOR="Antony Le Bechec"
SCRIPT_COPYRIGHT="IRC"
SCRIPT_LICENCE="GNU-GPL"

# Realse note
RELEASE_NOTES=$RELEASE_NOTES"# 0.9b-02/06/2016: Script creation\n";
RELEASE_NOTES=$RELEASE_NOTES"# 0.9.1b-28/03/2017: Bug fixed on output if no primers defined\n";
RELEASE_NOTES=$RELEASE_NOTES"# 0.9.2b-11/05/2017: Temporary files in a temporary folder. Bug fixed.\n";
RELEASE_NOTES=$RELEASE_NOTES"# 0.9.3b-31/05/2017: Multithreading. Bug fixed.\n";


# Header
function header () {
	echo "#######################################";
	echo "# $SCRIPT_NAME [$SCRIPT_RELEASE-$SCRIPT_DATE]";
	echo "# $SCRIPT_DESCRIPTION ";
	echo "# $SCRIPT_AUTHOR @ $SCRIPT_COPYRIGHT © $SCRIPT_LICENCE";
	echo "#######################################";
}

# Release
function release () {
	echo "# RELEASE NOTES:";
	echo -e $RELEASE_NOTES
}

# Usage
function usage {
	echo "# USAGE: $(basename $0) --bam=<BAM> --manifest=<MANIFEST> --output=<OUTPUT> [options...]";
	echo "# -b/--bam                      Aligned and clipped BAM file (mandatory)";
	echo "# -m/--manifest                 MANIFEST file (mandatory)";
	echo "# -k/--unclipped                Indicates if the BAM file is NOT clipped (yet) (default: 0/FALSE, means that the BAM IS clipped)";
	echo "# -g/--clip_overlapping_reads   Clip overlapping reads from PICARD.";
	echo "# -c/--chr                      Filter reads on chromosome (defaut all reads)";
	echo "# -o/--output                   Coverage file from Aligned BAM file depending on Manifest (defaut BAM.coverage)";
	echo "# -e/--env                      ENVironment file";
	echo "# -r/--ref                      REFerence genome";
	echo "# -p/--picard                   PICARD JAR (disabled if ENV)";
	echo "# -s/--samtools                 SAMTOOLS (disabled if ENV) ";
	echo "# -l/--bedtools                 BEDTOOLS (disabled if ENV)";
	echo "# -j/--java                     JAVA (disabled if ENV, default 'java')";
	echo "# -t/--tmp                      Temporary folder option (default /tmp)";
	echo "# -u/--threads                  number of threads for multithreading and samttols option (default 1)";
	#echo "# -x/--multithreading           Use multithreading (default FALSE)";
	echo "# -v/--verbose                  VERBOSE option";
	echo "# -d/--debug                    DEBUG option";
	echo "# -n/--release                  RELEASE option";
	echo "# -h/--help                     HELP option";
	echo "#";
}

# header
header;

#ARGS=$(getopt -o "f:b:m:kgo:c:e:r:p:i:s:u:j:t:u:xvdrh" --long "function:,bam:,manifest:,unclipped,clip_overlapping_reads,output:,chr:,env:,ref::,picard:,samtools:,bedtools:,java:,tmp:,threads:,multithreading,verbose,debug,release,help" -- "$@" 2> /dev/null)
ARGS=$(getopt -o "f:b:m:o:r:e:kgc:q:a:t:u:z:p:s:l:j:vdnh" --long "function:,bam:,manifest:,output:,ref:,env:,unclipped,clip_overlapping_reads,chr:,clipping_mode:,clipping_options:,tmp:,threads:,compress:,picard:,samtools:,bedtools:,java:,verbose,debug,release,help" -- "$@" 2> /dev/null)

if [ $? -ne 0 ]; then
	echo $?
	usage;
	exit;
fi;

PARAM=$@

eval set -- "$ARGS"
while true
do
	#echo "$1=$2"
	#echo "Eval opts";
	case "$1" in

		-f|--function)
			FUNCTION="$2";
			shift 2
			;;
		-b|--bam)
			if [ ! -e $2 ] || [ "$2" == "" ]; then
				echo "#[ERROR] No BAM file '$2'"
				usage; exit;
			else
				BAM="$2";
			fi;
			shift 2
			;;
		-m|--manifest)
			if [ ! -e $2 ] || [ "$2" == "" ]; then
				echo "#[ERROR] No MANIFEST file '$2'"
				usage; exit;
			else
				MANIFEST_INPUT="$2";
			fi;
			shift 2
			;;
		-o|--output)
			OUTPUT="$2"
			shift 2
			;;
		-r|--ref)
			REF_INPUT="$2"
			shift 2
			;;
		-e|--env)
			ENV="$2"
			shift 2
			;;
		-k|--unclipped)
			CLIPPED_BAM=0
			shift 1
			;;
		-g|--clip_overlapping_reads)
			CLIP_OVERLAPPING_READS=1;
			shift 1
			;;
		-c|--chr)
			CHR="$2"
			shift 2
			;;
		-a|--clipping_options)
			CLIPPING_OPTIONS="$2"
			shift 2
			;;
		-q|--clipping_mode)
			CLIPPING_MODE="$2"
			shift 2
			;;
		-t|--tmp)
			TMP_INPUT="$2"
			shift 2
			;;
		-u|--threads)
			THREADS_INPUT="$2"
			shift 2
			;;
		-z|--compress)
			COMPRESS="$2"
			shift 2
			;;
		-p|--picard)
			PICARD_INPUT="$2"
			shift 2
			;;
		-s|--samtools)
			SAMTOOLS_INPUT="$2"
			shift 2
			;;
		-l|--bedtools)
			BEDTOOLS_INPUT="$2"
			shift 2
			;;
		-j|--java)
			JAVA_INPUT="$2"
			shift 2
			;;
		-v|--verbose)
			VERBOSE=1
			shift 1
			;;
		-d|--debug)
			VERBOSE=1
			DEBUG=1
			shift 1
			;;
		-n|--release)
			release;
			exit 0
			;;
		-h|--help)
			usage
			exit 0
			;;
		--) shift
			break
			;;
		*) 	echo "# Option $1 is not recognized. " "Use -h or --help to display the help." && \
			exit 1
			;;
	esac
done


# Script folder
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# ENV
if [ -z $ENV ] || [ ! -e $ENV ]; then
	if [ -e $SCRIPT_DIR/env.sh ]; then
		ENV=$SCRIPT_DIR/env.sh
	else
		echo "#[WARNING] No ENV defined"
	fi;

	#usage;
	#exit;
fi;
if [ -e $ENV ] && [ "$ENV" != "" ]; then
	(($VERBOSE)) && echo "#[WARNING] ENV=$ENV";
	source $ENV
fi;

if [ -e $MANIFEST_INPUT ] && [ "$MANIFEST_INPUT" != "" ]; then
	MANIFEST=$MANIFEST_INPUT
fi;
if [ ! -e $MANIFEST ] || [ "$MANIFEST" == "" ]; then
	echo "#[ERROR] No MANIFEST file '$MANIFEST'"
	usage; exit;
fi;

# Mandatory parameters
if [ -z $BAM ] || [ -z $MANIFEST ]; then #  || [ -z $OUTPUT ]; then
	if [ -z $BAM ]; then
		echo "#[ERROR] No BAM file '$BAM'"
		usage; exit;
	fi;
	if [ -z $MANIFEST ]; then
		echo "#[ERROR] No MANIFEST file '$MANIFEST'"
		usage; exit;
	fi;
	usage; exit;
fi

if [ -z $CLIPPED_BAM ]; then
	CLIPPED_BAM=1;
fi;

# CLIP_OVERLAPPING_READS
if [ -z $CLIP_OVERLAPPING_READS ]; then
	CLIP_OVERLAPPING_READS=0;
fi;
#echo "CLIP_OVERLAPPING_READS=$CLIP_OVERLAPPING_READS"; exit 0;

# auto parameters
if [ -z $OUTPUT ]; then
	OUTPUT=$BAM.coverage;
fi

# auto parameters
if [ -z $CHR ]; then
	CHR="";
fi

# ref
if [ "$REF_INPUT" != "" ]; then
	REF=$REF_INPUT;
fi;
if [ -z $REF ] || [ ! -e $REF ]; then
	echo "#[ERROR] No REF genome"
	usage;
	exit;
fi
# PICARD LIB
if [ "$PICARD_INPUT" != "" ]; then
	PICARD=$PICARD_INPUT;
fi;
if [ ! -e $PICARD ] || [ ! -e $PICARD ]; then
	echo "#[ERROR] No PICARD JAR or library found"
	usage;
	exit;
fi
# SAMTOOLS
if [ "$SAMTOOLS_INPUT" != "" ]; then
	SAMTOOLS=$SAMTOOLS_INPUT;
fi;
if [ -z $SAMTOOLS ] || [ ! -e $SAMTOOLS ]; then
	echo "#[ERROR] No SAMTOOLS"
	usage;
	exit;
fi
# BEDTOOLS
if [ "$BEDTOOLS_INPUT" != "" ]; then
	BEDTOOLS=$BEDTOOLS_INPUT;
fi;
if [ -z $BEDTOOLS ] || [ ! -e $BEDTOOLS ]; then
	echo "#[ERROR] No BEDTOOLS"
	usage;
	exit;
fi

# JAVA
if [ "$JAVA_INPUT" != "" ]; then
	JAVA=$JAVA_INPUT;
fi;
if [ -z $JAVA ] || [ ! -e $JAVA ]; then
	if [ -f $(type -p java) ]; then
		echo "#[WARNING] JAVA found in PATH '$(type -p java)'"
		JAVA=java
	elif [[ -n "$JAVA_HOME" ]] && [[ -x "$JAVA_HOME/bin/java" ]];  then
		echo "#[WARNING] JAVA found in JAVA_HOME '$JAVA_HOME/bin/java'"
		JAVA="$JAVA_HOME/bin/java"
	else
		echo "#[ERROR] No JAVA"
		usage;
		exit;
	fi
fi
#if [ -z $TMP_SYS_FOLDER ] || [ ! -d $TMP_SYS_FOLDER ]; then
if [ ! -z $TMP_INPUT ] && [ -d $TMP_INPUT ]; then
	TMP_SYS_FOLDER=$TMP_INPUT
fi;
if [ -z $TMP_SYS_FOLDER ]; then
	TMP_SYS_FOLDER=/tmp
	(($VERBOSE)) && echo "#[WARNING] TMP=$TMP_SYS_FOLDER"
	#usage;
	#exit;
fi
TMP_CAP=$TMP_SYS_FOLDER/CAP_$RANDOM$RANDOM
mkdir -p $TMP_CAP

if [ ! -z $THREADS_INPUT ]; then
	THREADS=$THREADS_INPUT;
fi;
if [ -z $THREADS ]; then
	THREADS=1
	(($VERBOSE)) && echo "#[WARNING] No THREADS defined. THREADS=$THREADS"
	#usage;
	#exit;
fi

# MULTITHREADING
if [ $THREADS -gt 1 ]; then
	MULTITHREADING=1
fi;

if [ ! -s $BAM.bai ]; then
	(($VERBOSE)) && echo "#[WARNING] No BAI file associated with BAM '$BAM'";
	(($VERBOSE)) && echo "#[WARNING] Generation of BAI file '$BAM.bai'";
	$SAMTOOLS index $BAM
fi

# TMP_FILES
TMP_FILES=""

# NB_OVERLAP
NB_OVERLAP=4



echo "#[INFO] BAM=$BAM"
echo "#[INFO] MANIFEST=$MANIFEST"
echo "#[INFO] OUTPUT=$OUTPUT"
echo "#[INFO] REF=$REF"
echo "#[INFO] ENV=$ENV"
echo "#[INFO] UNCLIPPED=$CLIPPED_BAM"
echo "#[INFO] CLIP_OVERLAPPING_READS=$CLIP_OVERLAPPING_READS"
echo "#[INFO] CHR=$CHR"
echo "#[INFO] CLIPPING_OPTIONS=$CLIPPING_OPTIONS"
echo "#[INFO] CLIPPING_MODE=$CLIPPING_MODE"
echo "#[INFO] TMP=$TMP"
echo "#[INFO] THREADS=$THREADS"
echo "#[INFO] COMPRESS=$COMPRESS"
echo "#[INFO] PICARD=$PICARD"
echo "#[INFO] SAMTOOLS=$SAMTOOLS"
echo "#[INFO] BEDTOOLS=$BEDTOOLS"
echo "#[INFO] JAVA=$JAVA"


# Manifest to BED primers
if ((1)); then
	(($VERBOSE)) && echo -e "\n# Manifest to primers BED..."
	BED_PRIMERS=$TMP_CAP/$RANDOM$RANDOM.primers.bed
	MANIFESTTOBED_PRIMERS_OUTPUT=$TMP_CAP/$RANDOM$RANDOM.output
	MANIFESTTOBED_PRIMERS_ERR=$TMP_CAP/$RANDOM$RANDOM.err
	TMP_FILES=$TMP_FILES" $BED_PRIMERS $MANIFESTTOBED_PRIMERS_OUTPUT $MANIFESTTOBED_PRIMERS_ERR"
	$SCRIPT_DIR/CAP.ManifestToBED.pl --input=$MANIFEST --output=$BED_PRIMERS --output_type=primer  1>$MANIFESTTOBED_PRIMERS_OUTPUT 1>$MANIFESTTOBED_PRIMERS_ERR
	(($VERBOSE)) && echo "# BED_PRIMERS=$BED_PRIMERS"
	(($DEBUG)) && head -n 10 $BED_PRIMERS && echo "...";
	if [ ! -s $BED_PRIMERS ]; then
		(($VERBOSE)) && echo "# No primers defined"
		> $OUTPUT
		exit 0;
	fi;

fi;

# Manifest to BED primers
if ((1)); then
	(($VERBOSE)) && echo -e "\n# Manifest to targets BED..."
	BED_TARGETS=$TMP_CAP/$RANDOM$RANDOM.targets.bed
	MANIFESTTOBED_TARGETS_OUTPUT=$TMP_CAP/$RANDOM$RANDOM.output
	MANIFESTTOBED_TARGETS_ERR=$TMP_CAP/$RANDOM$RANDOM.err
	TMP_FILES=$TMP_FILES" $BED_TARGETS $MANIFESTTOBED_TARGETS_OUTPUT $MANIFESTTOBED_TARGETS_ERR"
	$SCRIPT_DIR/CAP.ManifestToBED.pl --input=$MANIFEST --output=$BED_TARGETS --output_type=target  1>$MANIFESTTOBED_TARGETS_OUTPUT 1>$MANIFESTTOBED_TARGETS_ERR
	(($VERBOSE)) && echo "# BED_TARGETS=$BED_TARGETS"
	(($DEBUG)) && head -n 10 $BED_TARGETS && echo "...";
	if [ ! -s $BED_TARGETS ]; then
		(($VERBOSE)) && echo "# No targets defined"
		> $OUTPUT
		exit 0;
	fi;

fi;

# BED to Options
if ((1)); then
	(($VERBOSE)) && echo -e "\n# BED to Options..."
	BED_PRIMERS_FASTA=$BED_PRIMERS.fasta
	BED_PRIMERS_OPTIONS=$BED_PRIMERS.options
	BEDTOOLS_OUTPUT=$TMP_CAP/$RANDOM$RANDOM.output
	BEDTOOLS_ERR=$TMP_CAP/$RANDOM$RANDOM.err
	BEDTOOPTION_OUTPUT=$TMP_CAP/$RANDOM$RANDOM.output
	BEDTOOPTION_ERR=$TMP_CAP/$RANDOM$RANDOM.err
	TMP_FILES=$TMP_FILES" $BEDTOOLS_OUTPUT $BEDTOOLS_ERR $BEDTOOPTION_OUTPUT $BEDTOOPTION_ERR"
	$BEDTOOLS getfasta -fi $REF -bed $BED_PRIMERS -fo $BED_PRIMERS_FASTA 1>$BEDTOOLS_OUTPUT 1>$BEDTOOLS_ERR
	(($VERBOSE)) && echo "# BED_PRIMERS_FASTA=$BED_PRIMERS_FASTA"
	(($DEBUG)) && head -n 10 $BED_PRIMERS_FASTA && echo "...";
	$SCRIPT_DIR/CAP.BEDToOption.pl --input=$BED_PRIMERS --output=$BED_PRIMERS_OPTIONS --fasta=$BED_PRIMERS_FASTA  1>$BEDTOOPTION_OUTPUT 1>$BEDTOOPTION_ERR
	(($VERBOSE)) && echo "# BED_PRIMERS_OPTIONS=$BED_PRIMERS_OPTIONS"
	(($DEBUG)) && head -n 10 -c 200 $BED_PRIMERS_OPTIONS && echo "...";
fi;

# MULTITHREADING
MK=$TMP_CAP/$RANDOM$RANDOM.mk
touch $MK


# Clustering
if ((1)); then
	(($VERBOSE)) && echo -e "\n# Amplicon Clustering..."
	CLUSTERS_PATTERN=$TMP_CAP/$RANDOM$RANDOM.CLUSTERS_PATTERN.
	NEW_CLUSTER=$CLUSTERS_PATTERN$RANDOM$RANDOM.bed
	TMP_FILES=$TMP_FILES" $CLUSTERS_PATTERN*"
	touch $NEW_CLUSTER

	NB_AMPLICONS=$(grep ^ $BED_TARGETS -c )
	old_IFS=$IFS
	IFS=$'\n'
	AMPLICON_I=0;

	for line in $(cat $BED_TARGETS | $BEDTOOLS sort -i - | grep -v ^@ -); do
	#for line in $(cat $BED_TARGETS | $BEDTOOLS/sortBed -i - | grep -v ^@ - | head -n 5); do
		#echo $line
		AMPLICON=$(echo -e "$line" | cut -f8)
		((AMPLICON_I++))
		CHR=$(echo $AMPLICON | cut -d: -f1)
		START=$(echo $AMPLICON | cut -d: -f2 | cut -d- -f1)
		STOP=$(echo $AMPLICON | cut -d: -f2 | cut -d- -f2)
		(($DEBUG)) && echo -n -e "# $CHR $START $STOP $AMPLICON [$AMPLICON_I/$NB_AMPLICONS]"

		IN_CLUSTER=0
		CLUSTER_NUM=""
		for CLUSTER in $(ls $CLUSTERS_PATTERN*); do
			if ((!$IN_CLUSTER)); then
				OVERLAP=0
				for line1 in $(tac $CLUSTER | grep -v ^@ - | grep ^$CHR | head -n $NB_OVERLAP)
				do
					AMPLICON1=$(echo -e "$line1" | cut -f8)
					CHR1=$(echo $AMPLICON1 | cut -d: -f1)
					START1=$(echo $AMPLICON1 | cut -d: -f2 | cut -d- -f1)
					STOP1=$(echo $AMPLICON1 | cut -d: -f2 | cut -d- -f2)
					if [ "$CHR" == "$CHR1" ] && [ $START -gt $START1 ] && [ $START -lt $STOP1 ] && ((!$OVERLAP)); then
						OVERLAP=1;
					fi;
				done

				if ((!$OVERLAP)); then
					echo -e "$line" >> $CLUSTER
					CLUSTER_NUM=$(echo $CLUSTER | rev | cut -d. -f2);
					IN_CLUSTER=1;
				fi;
			fi;

		done;
		#echo "IN_CLUSTER2=$IN_CLUSTER"
		if ((!$IN_CLUSTER)); then
			#echo "NOT IN CLUSTER !";
			NEW_CLUSTER=$CLUSTERS_PATTERN$RANDOM$RANDOM.bed
			touch $NEW_CLUSTER
			echo -e "$line" >> $NEW_CLUSTER
			CLUSTER_NUM=$(echo $NEW_CLUSTER | rev | cut -d. -f2);
		fi;

		(($DEBUG)) && echo -e " > CLUSTER '$CLUSTER_NUM'"

	done;
	IFS=$old_IFS

	for CLUSTER in $(ls $CLUSTERS_PATTERN*); do
		if (($VERBOSE)); then
			NB_AMPLICONS_CLUSTER=$(grep ^ $CLUSTER -c )
			CLUSTER_NUM=$(echo $CLUSTER | rev | cut -d. -f2);
			echo -e "# CLUSTER '$CLUSTER_NUM' [$NB_AMPLICONS_CLUSTER/$NB_AMPLICONS] "
			(($DEBUG)) && cat $CLUSTER
		fi;
	done;


	if ((1)); then

		PICARD_HSMETRICS_PER_TARGET_COVERAGE_FINAL_OUTPUT=$TMP_CAP/$RANDOM$RANDOM.HsMetrics.PER_TARGET_COVERAGE.FINAL
		PICARD_HSMETRICS_PER_TARGET_COVERAGE_MERGE_OUTPUT=$PICARD_HSMETRICS_PER_TARGET_COVERAGE_FINAL_OUTPUT.merge
		PICARD_HSMETRICS_PER_TARGET_COVERAGE_HEADER_OUTPUT=$PICARD_HSMETRICS_PER_TARGET_COVERAGE_FINAL_OUTPUT.header
		TMP_FILES=$TMP_FILES" $PICARD_HSMETRICS_PER_TARGET_COVERAGE_FINAL_OUTPUT*"

		#PARAM_CLIPPING=$PARAM
		#PARAM_CLIPPING=$(echo "$PARAM " | sed "s/--unclipped=.*[ |$]//g" | sed "s/-s=.*[ |$]//g" | sed "s/--threads .*[ |$]//g" | sed "s/-t .*[ |$]//g" | sed "s/--multithreading[ |$]//g" | sed "s/-x[ |$]//g")
		PARAM_CLIPPING=$(echo "$PARAM " | sed "s/--java=[^ |$]*//gi" | sed "s/-j=[^ |$]*//gi" | sed "s/--unclipped[^ |$]*//gi" | sed "s/-s[^ |$]*//gi")
		#PARAM_MULTITHREADING=$(echo "$PARAM " | sed "s/--threads=[^ |$]*//gi" | sed "s/-t=[^ |$]*//gi" | sed "s/--multithreading[^ |$]*//gi" | sed "s/-x[^ |$]*//gi")

		# -s|--unclipped)   -j|--java)

		#echo -e "\n\n"
		CLUSTERS_PATTERN_BAM=""
		for CLUSTER in $(ls $CLUSTERS_PATTERN*); do

			if (($VERBOSE)); then
				NB_AMPLICONS_CLUSTER=$(grep ^ $CLUSTER -c )
				CLUSTER_NUM=$(echo $CLUSTER | rev | cut -d. -f2);
				echo -e "\n# CLUSTER '$CLUSTER_NUM' [$NB_AMPLICONS_CLUSTER/$NB_AMPLICONS] BAM Creation"
				(($DEBUG)) && cat $CLUSTER | head -n 10
			fi;

			if ((1)); then

				(($VERBOSE)) && echo -e "\n# Reads extraction..."

				AMPLICON_BAM_HEADER=$CLUSTER.header
				AMPLICON_BAM_PATTERN=$CLUSTER.amplicon_

				# Manifest
				#echo "[Regions]" > $CLUSTER.manifest
				#echo "Name	Chromosome	Amplicon Start	Amplicon End	Upstream Probe Length	Downstream Probe Length" >> $CLUSTER.manifest
				#cat $CLUSTER | awk '{print $5"\t"$1"\t"$2"\t"$3"\t"length($6)"\t"length($7)}' >> $CLUSTER.manifest

				if (($CLIPPED_BAM)); then
					(($VERBOSE)) && echo -e "\n# BAM clipped..."
					echo "[Regions]" > $CLUSTER.manifest
					echo "Name	Chromosome	Amplicon Start	Amplicon End	Upstream Probe Length	Downstream Probe Length" >> $CLUSTER.manifest
					cat $CLUSTER | awk '{print $5"\t"$1"\t"$2"\t"$3"\t1\t1"}' >> $CLUSTER.manifest
				else
					(($VERBOSE)) && echo -e "\n# BAM unclipped..."
					echo "[Regions]" > $CLUSTER.manifest
					echo "Name	Chromosome	Amplicon Start	Amplicon End	Upstream Probe Length	Downstream Probe Length" >> $CLUSTER.manifest
					cat $CLUSTER | awk '{print $5"\t"$1"\t"$2-length($6)"\t"$3+length($7)"\t"length($6)"\t"length($7)}' >> $CLUSTER.manifest
				fi;

				(($DEBUG)) && cat $CLUSTER.manifest | head -n 10

				if (($MULTITHREADING)) && ((1)); then

					# MULTITHREADING
					echo "$CLUSTER.manifest.bam:
						+$SCRIPT_DIR/CAP.clipping.sh $PARAM_CLIPPING --bam=$BAM --manifest=$CLUSTER.manifest --clipping_options='-c0 -s1 ' --output=$CLUSTER.manifest.bam --verbose 1>$CLUSTER.clipping.log 2>$CLUSTER.clipping.err

					" >> $MK

					MK_BAM_LIST=$MK_BAM_LIST" $CLUSTER.manifest.bam "

				else

					$SCRIPT_DIR/CAP.clipping.sh $PARAM_CLIPPING --bam=$BAM --manifest=$CLUSTER.manifest --clipping_options=" -c0 -s1 " --output=$CLUSTER.manifest.bam --verbose 1>$CLUSTER.clipping.log 2>$CLUSTER.clipping.err

					(($DEBUG)) && echo "$CLUSTER.manifest.bam"

					echo "# Nb of extracted Reads: "$($SAMTOOLS view -c $CLUSTER.manifest.bam)

				fi;

				CLUSTERS_PATTERN_BAM=$CLUSTERS_PATTERN_BAM" $CLUSTER.manifest.bam"

			fi;

			if ((1)); then

				(($VERBOSE)) && echo -e "\n# Metrics Calculation..."

				CLUSTER_BED=$TMP_CAP/$RANDOM$RANDOM.bed;
				PICARD_HSMETRICS_OUTPUT=$TMP_CAP/$RANDOM$RANDOM.HsMetrics;
				TMP_FILES=$TMP_FILES" $CLUSTER_BED* $PICARD_HSMETRICS_OUTPUT*"
				PICARD_HSMETRICS_PER_TARGET_COVERAGE_OUTPUT=$PICARD_HSMETRICS_OUTPUT.PER_TARGET_COVERAGE;
				PICARD_HSMETRICS_LOG=$PICARD_HSMETRICS_OUTPUT.lor;
				PICARD_HSMETRICS_ERR=$PICARD_HSMETRICS_OUTPUT.err;
				TMP_FILES=$TMP_FILES" $CLUSTER_BED $PICARD_HSMETRICS_OUTPUT* $PICARD_HSMETRICS_PER_TARGET_COVERAGE_OUTPUT"
				$SAMTOOLS view -H $BAM > $CLUSTER_BED;
				cat $CLUSTER | cut -f1-5 >> $CLUSTER_BED
				(($VERBOSE)) && echo "# CLUSTER=$CLUSTER"
				(($DEBUG)) && grep ^@ -v $CLUSTER | head -n 10 && echo "...";
				(($VERBOSE)) && echo "# CLUSTER_BED=$CLUSTER_BED"
				(($DEBUG)) && grep ^@ -v $CLUSTER_BED | head -n 10 && echo "...";

				JAVA_FLAGS=""
				(($VERBOSE)) && echo "# Using PICARD JAR $PICARD"


				if (($MULTITHREADING)) && ((1)); then

					# MULTITHREADING
					echo "$PICARD_HSMETRICS_OUTPUT: $CLUSTER.manifest.bam
					$JAVA $JAVA_FLAGS -jar $PICARD CollectHsMetrics INPUT=$CLUSTER.manifest.bam OUTPUT=$PICARD_HSMETRICS_OUTPUT R=$REF BAIT_INTERVALS=$CLUSTER_BED TARGET_INTERVALS=$CLUSTER_BED PER_TARGET_COVERAGE=$PICARD_HSMETRICS_PER_TARGET_COVERAGE_OUTPUT METRIC_ACCUMULATION_LEVEL=ALL_READS VALIDATION_STRINGENCY=LENIENT CLIP_OVERLAPPING_READS=$(if (( $CLIP_OVERLAPPING_READS )); then echo "true"; else echo "false"; fi) 1>$PICARD_HSMETRICS_LOG 2>$PICARD_HSMETRICS_ERR
					head -n 1 $PICARD_HSMETRICS_PER_TARGET_COVERAGE_OUTPUT > $PICARD_HSMETRICS_PER_TARGET_COVERAGE_HEADER_OUTPUT
					sed 1d $PICARD_HSMETRICS_PER_TARGET_COVERAGE_OUTPUT >> $PICARD_HSMETRICS_PER_TARGET_COVERAGE_MERGE_OUTPUT

					" >> $MK

					MK_PICARD_HSMETRICS_OUTPUT_LIST=$MK_PICARD_HSMETRICS_OUTPUT_LIST" $PICARD_HSMETRICS_OUTPUT "

				else

					$JAVA $JAVA_FLAGS -jar $PICARD CollectHsMetrics INPUT=$CLUSTER.manifest.bam OUTPUT=$PICARD_HSMETRICS_OUTPUT R=$REF BAIT_INTERVALS=$CLUSTER_BED TARGET_INTERVALS=$CLUSTER_BED PER_TARGET_COVERAGE=$PICARD_HSMETRICS_PER_TARGET_COVERAGE_OUTPUT METRIC_ACCUMULATION_LEVEL=ALL_READS VALIDATION_STRINGENCY=LENIENT 1>$PICARD_HSMETRICS_LOG 2>$PICARD_HSMETRICS_ERR;
		# OUTPUT
					if ((1)); then
						(($VERBOSE)) && echo "# PICARD_HSMETRICS_PER_TARGET_COVERAGE_OUTPUT=$PICARD_HSMETRICS_PER_TARGET_COVERAGE_OUTPUT"
						#(($VERBOSE)) && cat $PICARD_HSMETRICS_PER_TARGET_COVERAGE_OUTPUT | cut -f5,7,8
						(($DEBUG)) && cat $PICARD_HSMETRICS_PER_TARGET_COVERAGE_OUTPUT  | head -n 10 #| cut -f5,7,8
						head -n 1 $PICARD_HSMETRICS_PER_TARGET_COVERAGE_OUTPUT > $PICARD_HSMETRICS_PER_TARGET_COVERAGE_HEADER_OUTPUT
						sed 1d $PICARD_HSMETRICS_PER_TARGET_COVERAGE_OUTPUT >> $PICARD_HSMETRICS_PER_TARGET_COVERAGE_MERGE_OUTPUT


					fi;

				fi;



			fi;



		done;



		if (($MULTITHREADING)) && ((1)); then

			# MULTITHREADING
			(($VERBOSE)) && echo -e "\n# Multithreading..."

			echo "$CLUSTERS_PATTERN.merged.bam: $MK_PICARD_HSMETRICS_OUTPUT_LIST
				$SAMTOOLS merge  -l 0 -f $CLUSTERS_PATTERN.merged.bam $CLUSTERS_PATTERN_BAM;

			" >> $MK

			echo "all: $CLUSTERS_PATTERN.merged.bam

			" >> $MK

			(($DEBUG)) && cat $MK;

			MULTITHREADING_LOG=$TMP_CAP/$RANDOM$RANDOM.log
			MULTITHREADING_ERR=$TMP_CAP/$RANDOM$RANDOM.err
			> $MULTITHREADING_LOG
			> $MULTITHREADING_ERR
			#if (($VERBOSE)); then
			#	make -f $MK all -j $THREADS
			#else
			#	make -f $MK all -j $THREADS 1>$MULTITHREADING_LOG 2>$MULTITHREADING_ERR
			#fi;
			make -f $MK all -j $THREADS 1>$MULTITHREADING_LOG 2>$MULTITHREADING_ERR

			(($DEBUG)) && cat $MULTITHREADING_LOG;
			(($DEBUG)) && cat $MULTITHREADING_ERR;
			#exit 0;

			(($VERBOSE)) && echo -e "\n"

		else

			$SAMTOOLS merge  -l 0 -f $CLUSTERS_PATTERN.merged.bam $CLUSTERS_PATTERN_BAM;

		fi;






		NB_READ_TOTAL=$($SAMTOOLS view $BAM -c)
		NB_READ_EXTRACTED=$($SAMTOOLS view $CLUSTERS_PATTERN.merged.bam -c)
		echo "# Total number of extracted Reads: $NB_READ_EXTRACTED out of $NB_READ_TOTAL ";

		MK_PICARD_HSMETRICS_OUTPUT_LIST=$MK_PICARD_HSMETRICS_OUTPUT_LIST" $PICARD_HSMETRICS_OUTPUT "



		# FINAL
		if ((1)); then
			cat $PICARD_HSMETRICS_PER_TARGET_COVERAGE_HEADER_OUTPUT > $PICARD_HSMETRICS_PER_TARGET_COVERAGE_FINAL_OUTPUT
			cat $PICARD_HSMETRICS_PER_TARGET_COVERAGE_MERGE_OUTPUT | sort -k1 -k2 >> $PICARD_HSMETRICS_PER_TARGET_COVERAGE_FINAL_OUTPUT
			cp $PICARD_HSMETRICS_PER_TARGET_COVERAGE_FINAL_OUTPUT $OUTPUT
			(($VERBOSE)) && echo "# OUTPUT=$OUTPUT"
			(($DEBUG)) && column -t $OUTPUT  | head -n 10 #| cut -f5,7,8
		fi;

		if ((1)); then
			rm -f $CLUSTERS_PATTERN_BAM $CLUSTERS_PATTERN.merged.bam
		fi;

	fi;

fi;

# CLEANING
if ! (($DEBUG)); then
	rm -rf $TMP_FILES
	rm -rf $TMP_CAP
fi;
#$CLUSTERS_PATTERN* $PICARD_HSMETRICS_PER_TARGET_COVERAGE_FINAL_OUTPUT*

exit 0;
