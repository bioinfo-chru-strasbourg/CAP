#!/bin/bash
#################################
##
## NGS environment
##
#################################

SCRIPT_NAME="CAPClipping"
SCRIPT_DESCRIPTION="CAP clipping"
SCRIPT_RELEASE="0.9.3b"
SCRIPT_DATE="11/05/2018"
SCRIPT_AUTHOR="Antony Le Bechec"
SCRIPT_COPYRIGHT="IRC"
SCRIPT_LICENCE="GNU-GPL"

# Realse note
RELEASE_NOTES=$RELEASE_NOTES"# 0.9b-30/05/2016: Script creation\n";
RELEASE_NOTES=$RELEASE_NOTES"# 0.9.1b-01/06/2016: Deletion of temporary files\n";
RELEASE_NOTES=$RELEASE_NOTES"# 0.9.2b-02/06/2016: Few bugs corrected\n";
RELEASE_NOTES=$RELEASE_NOTES"# 0.9.3b-11/05/2018: Temporary files in a temporary folder. Few bugs fixed.\n";


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
	echo "# -b/--bam              Aligned SAM/BAM file (mandatory)";
	echo "# -m/--manifest         MANIFEST file (mandatory)";
	echo "# -c/--chr              Filter reads on chromosome (defaut all reads)";
	echo "# -q/--clipping_mode    Clipping mode, either 'O' for SoftClipping or 'Q' for SoftClipping and Q0 (default 'O')";
	echo "# -a/--clipping_options Clipping options";
	echo "# -o/--output           Clipped Aligned BAM file (defaut *clipped.bam)";
	echo "# -e/--env              ENVironment file";
	echo "# -r/--ref              REFerence genome";
	echo "# -p/--picard           PICARD (disabled if ENV)";
	echo "# -s/--samtools         SAMTOOLS (disabled if ENV) ";
	echo "# -l/--bedtools         BEDTOOLS (disabled if ENV)";
	echo "# -t/--tmp              Temporary folder option (default /tmp)";
	echo "# -u/--threads          number of threads for multithreading and samtools option (default 1)";
	echo "# -z/--compress         compress level samtools option, from 0 to 9 (default 0)";
	#echo "# -x/--multithreading   Multithreading option (default false, need make installed)";
	echo "# -v/--verbose          VERBOSE option";
	echo "# -d/--debug            DEBUG option";
	echo "# -n/--release          RELEASE option";
	echo "# -h/--help             HELP option";
	echo "#";
}

# header
header;

#ARGS=$(getopt -o "f:b:m:o:q:c:a:e:r:p:s:l:t:u:z:xvdnh" --long "function:,bam:,manifest:,output:,chr:,clipping_mode:,clipping_options:,clip_overlapping_reads,env:,ref:,picardlib:,samtools:,bedtools:,tmp:,threads:,compress:,multithreading,verbose,debug,release,help" -- "$@" 2> /dev/null)
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


# auto parameters
if [ -z $OUTPUT ]; then
	OUTPUT=$(echo $BAM | sed "s/.bam$/.clipped.bam/gi" );
fi

# auto parameters
if [ -z $CHR ]; then
	CHR="";
fi

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

# MANIFEST
if [ "$MANIFEST_INPUT" != "" ]; then
	MANIFEST=$MANIFEST_INPUT;
fi;
if [ ! -e $MANIFEST ] || [ "$MANIFEST" == "" ]; then
	echo "#[ERROR] No MANIFEST file '$MANIFEST'"
        usage; exit;
fi;

# Mandatory parameters
if [ -z $BAM ] || [ -z $MANIFEST ]; then #  || [ -z $OUTPUT ]; then
        usage;
        exit;
fi

# CLIPPING OPTION
if [ "$CLIPPING_OPTION" != "" ]; then
	$CLIPPING_OPTION='O';
fi;


# REF
if [ ! -z $REF_INPUT ] && [ -e $REF_INPUT ]; then
	REF=$REF_INPUT
fi
if [ -z $REF ] || [ ! -e $REF ]; then
	echo "#[ERROR] No REF genome '$REF'"
	usage;
	exit;
fi

# PICARD
if [ "$PICARD_INPUT" != "" ]; then
        PICARD=$PICARD_INPUT
fi
if [ -z $PICARD ] || [ ! -e $PICARD ]; then
	echo "#[ERROR] No PICARD library"
	usage;
	exit;
fi

# SAMTOOLS
#echo $SAMTOOLS_INPUT
#echo $SAMTOOLS
if [ "$SAMTOOLS_INPUT" != "" ]; then
        SAMTOOLS=$SAMTOOLS_INPUT
fi
if [ -z $SAMTOOLS ] || [ ! -e $SAMTOOLS ]; then
	echo "#[ERROR] No SAMTOOLS"
	usage;
	exit;
fi

# BEDTOOLS
if [ "$BEDTOOLS_INPUT" != "" ]; then
        BEDTOOLS=$BEDTOOLS_INPUT
fi
if [ -z $BEDTOOLS ] || [ ! -e $BEDTOOLS ]; then
	echo "#[ERROR] No BEDTOOLS"
	usage;
	exit;
fi

# TMP
if [ ! -z $TMP_INPUT ] && [ -d $TMP_INPUT ]; then
	TMP_SYS_FOLDER=$TMP_INPUT;
fi;
if [ -z $TMP_SYS_FOLDER ] || [ ! -d $TMP_SYS_FOLDER ]; then
	TMP_SYS_FOLDER=/tmp
	(($VERBOSE)) && echo "#[WARNING] TMP=$TMP_SYS_FOLDER"
	#usage;
	#exit;
fi
TMP_CAP=$TMP_SYS_FOLDER/CAP_$RANDOM$RANDOM
mkdir -p $TMP_CAP

# THREADS
if [ ! -z $THREADS_INPUT ]; then
	THREADS=$THREADS_INPUT
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

# COMPRESSION
if [ -z $COMPRESS ]; then
	COMPRESS=0
	(($VERBOSE)) && echo "#[WARNING] No COMPRESS defined. COMPRESS=$COMPRESS"
	#usage;
	#exit;
fi

# BAM indexing
if [ ! -s $BAM.bai ]; then
	(($VERBOSE)) && echo "#[WARNING] No BAI file associated with BAM '$BAM'";
	(($VERBOSE)) && echo "#[WARNING] Generation of BAI file '$BAM.bai'";
	$SAMTOOLS index $BAM
fi

#echo "TMP_SYS_FOLDER=$TMP_SYS_FOLDER"; exit 0;
# TMP_FILES
TMP_FILES=""


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
echo ""



# Test manifest empty
if [ ! -s $MANIFEST ]; then
	(($VERBOSE)) && echo "# No manifest defined"

	# Output compression and chr filter
	OUTPUT_SORTED=$TMP_CAP/$RANDOM$RANDOM
	OUTPUT_SORTED_BAM=$OUTPUT_SORTED.bam
	$SAMTOOLS view -h -b $BAM $CHR | $SAMTOOLS sort -l $COMPRESS -@ $THREADS - -o $OUTPUT_SORTED
	mv $OUTPUT_SORTED $OUTPUT
	(($VERBOSE)) && echo "# No clipping on the output BAM $OUTPUT (compress=$COMPRESS, chromosome=$CHR)..."
	exit 0;
fi;



# Manifest to BED primers
if ((1)); then
	(($VERBOSE)) && echo -e "# Manifest to primers BED..."

	BED_PRIMERS=$TMP_CAP/$RANDOM$RANDOM.primers.bed
	MANIFESTTOBED_PRIMERS_OUTPUT=$TMP_CAP/$RANDOM$RANDOM.output
	MANIFESTTOBED_PRIMERS_ERR=$TMP_CAP/$RANDOM$RANDOM.err
	TMP_FILES=$TMP_FILES" $BED_PRIMERS $MANIFESTTOBED_PRIMERS_OUTPUT $MANIFESTTOBED_PRIMERS_ERR"
	$SCRIPT_DIR/CAP.ManifestToBED.pl --input=$MANIFEST --output=$BED_PRIMERS --output_type=primer  1>$MANIFESTTOBED_PRIMERS_OUTPUT 1>$MANIFESTTOBED_PRIMERS_ERR
	$SCRIPT_DIR/CAP.ManifestToBED.pl --input=$MANIFEST --output=$BED_PRIMERS --output_type=primer  1>$MANIFESTTOBED_PRIMERS_OUTPUT 1>$MANIFESTTOBED_PRIMERS_ERR
	(($DEBUG)) && cat $MANIFESTTOBED_PRIMERS_OUTPUT;
	(($DEBUG)) && cat $MANIFESTTOBED_PRIMERS_ERR;
	(($VERBOSE)) && echo "# BED_PRIMERS=$BED_PRIMERS"
	(($DEBUG)) && head -n 10 $BED_PRIMERS && echo "...";
	if [ ! -s $BED_PRIMERS ]; then
		(($VERBOSE)) && echo "# No primers defined in manifest"
		# Output compression and chr filter
		OUTPUT_SORTED=$TMP_CAP/$RANDOM$RANDOM
		OUTPUT_SORTED_BAM=$OUTPUT_SORTED.bam
		$SAMTOOLS view -h -b $BAM $CHR | $SAMTOOLS sort -l $COMPRESS -@ $THREADS - -o $OUTPUT_SORTED
		mv $OUTPUT_SORTED $OUTPUT
		(($VERBOSE)) && echo "# No clipping on the output BAM $OUTPUT (compress=$COMPRESS, chromosome=$CHR)..."
		exit 0;
	fi;

fi;


# Multithreading
if (($MULTITHREADING)) && [ -e $ENV ] && [ "$ENV" != "" ]; then
	(($VERBOSE)) && echo "# Multithreading..."
	MULTITHREADING_LOG=$TMP_CAP/$RANDOM$RANDOM.log
	MULTITHREADING_ERR=$TMP_CAP/$RANDOM$RANDOM.err

	# DEV
	#
	if ((1)); then

		# PARAM
		#PARAM_MULTITHREADING=$(echo "$PARAM " | sed "s/--threads=.*[ |$]//g" | sed "s/-t=.*[ |$]//g" | sed "s/--threads .*[ |$]//g" | sed "s/-t .*[ |$]//g" | sed "s/--multithreading[ |$]//g" | sed "s/-x[ |$]//g")
		PARAM_MULTITHREADING=$(echo "$PARAM " | sed "s/--threads=[^ |$]*//gi" | sed "s/-t=[^ |$]*//gi" | sed "s/--multithreading[^ |$]*//gi" | sed "s/-x[^ |$]*//gi")
		PARAM_MULTITHREADING=$(echo "$PARAM_MULTITHREADING " | sed "s/--clipping_options=$CLIPPING_OPTIONS//gi" | sed "s/-a=$CLIPPING_OPTIONS//gi")
		#sed "s/--clipping_options=$co//gi"
		MK=$TMP_CAP/$RANDOM$RANDOM.mk
		SPLIT_PATTERN=$TMP_CAP/$RANDOM$RANDOM.splitted_bam.
		BAM_HEADER=$TMP_CAP/$RANDOM$RANDOM.bam.header

		TMP_FILES=$TMP_FILES" $MK $BAM_HEADER"

		NB_READS=$($SAMTOOLS view -c $BAM)
		SPLIT_LINES=$(echo "$(scale=0; $SAMTOOLS view  -c $BAM) / $THREADS + 1 " | bc)
		# prevent error
		MIN_SPLIT_LINES=10000;
		if [ $SPLIT_LINES -lt $MIN_SPLIT_LINES ]; then SPLIT_LINES=$MIN_SPLIT_LINES; fi;
		# minimum of reads
		#if [ $SPLIT_LINES -lt 10000 ]; then SPLIT_LINES=10000; fi;
		#SPLIT_LINES=100000

		# SPLIT
		$SAMTOOLS view $BAM | split - -l $SPLIT_LINES $SPLIT_PATTERN

		# MK

		# ALL
		echo -e "all: $OUTPUT	" >>$MK;

		# BAM HEADER
		echo -e "$BAM_HEADER: $BAM
			@$SAMTOOLS view -H $BAM > $BAM_HEADER
			" >>$MK;

		# CLIPPED FILES
		CLIPPED_LIST=""
		for P in $(ls $SPLIT_PATTERN*); do
			CLIPPED_P=$P.clipped
			#cat $BAM_HEADER $P > $P.sam
			echo "$P.bam: $P $BAM_HEADER
				@cat $BAM_HEADER $P | $SAMTOOLS view -O BAM > $P.bam
				@rm -f $P
			" >>$MK;
			echo "$CLIPPED_P: $P.bam
				@$0 $PARAM_MULTITHREADING --bam=$P.bam --manifest=$MANIFEST --output=$CLIPPED_P --env=$ENV --clipping_options='$CLIPPING_OPTIONS' --ref=$REF; #--verbose;
				@rm -f $P.bam
			" >>$MK;
			CLIPPED_LIST=$CLIPPED_LIST" $CLIPPED_P"
		done;

		# CAT
		echo "$OUTPUT: $CLIPPED_LIST
			@$SAMTOOLS merge  -l $COMPRESS -f $OUTPUT $CLIPPED_LIST;
			@# Cleaning
			@-rm -f $^
		" >>$MK;

#cat $MK; #exit;

		# MAKE
		if [ "$CLIPPED_LIST" != "" ]; then
			if (($VERBOSE)); then
				make -f $MK -j $THREADS
			else
				make -f $MK -j $THREADS 1>$MULTITHREADING_LOG 2>$MULTITHREADING_ERR
			fi;
		else
			$SAMTOOLS view -H $BAM > $MK.sam
			$SAMTOOLS view $MK.sam -o $OUTPUT
			rm $MK.sam
		fi;
	fi;


	(($VERBOSE)) && echo "# OUTPUT=$OUTPUT [$($SAMTOOLS view -c $OUTPUT) reads]"
	(($DEBUG)) && $SAMTOOLS view $OUTPUT | head -n 10 && echo "...";
	TMP_FILES=$TMP_FILES" $MULTITHREADING_ERR"

	# TMP_FILES
	if ((1)); then
		rm -Rf $TMP_FILES
		rm -rf $TMP_CAP
	fi;

	exit 0;
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
	TMP_FILES=$TMP_FILES" $BED_PRIMERS_FASTA $BED_PRIMERS_OPTIONS $BEDTOOLS_OUTPUT $BEDTOOLS_ERR $BEDTOOPTION_OUTPUT $BEDTOOPTION_ERR"
	(($VERBOSE)) && echo -e "\n# BED to FASTA..."
	$BEDTOOLS getfasta -fi $REF -bed $BED_PRIMERS -fo $BED_PRIMERS_FASTA 1>$BEDTOOLS_OUTPUT 1>$BEDTOOLS_ERR
	(($VERBOSE)) && echo "# BED_PRIMERS_FASTA=$BED_PRIMERS_FASTA"
	(($DEBUG)) && head -n 10 $BED_PRIMERS_FASTA && echo "...";
	(($VERBOSE)) && echo -e "\n# BED to options using FASTA..."
	$SCRIPT_DIR/CAP.BEDToOption.pl --input=$BED_PRIMERS --output=$BED_PRIMERS_OPTIONS --fasta=$BED_PRIMERS_FASTA 1>$BEDTOOPTION_OUTPUT 2>$BEDTOOPTION_ERR
	(($DEBUG)) && cat $BEDTOOPTION_OUTPUT;
	(($DEBUG)) && cat $BEDTOOPTION_ERR;
	(($VERBOSE)) && echo "# BED_PRIMERS_OPTIONS=$BED_PRIMERS_OPTIONS"
	(($DEBUG)) && head -c 200 $BED_PRIMERS_OPTIONS && echo "...";

fi;


# Clipping
if ((1)); then
	(($VERBOSE)) && echo -e "\n# Clipping..."

	OUTPUT_SAM=$TMP_CAP/$RANDOM$RANDOM.sam
	CAP_ERR=$TMP_CAP/$RANDOM$RANDOM.err
	SAMTOOLS_ERR=$TMP_CAP/$RANDOM$RANDOM.err
	TMP_FILES=$TMP_FILES" $OUTPUT_SAM $CAP_ERR $SAMTOOLS_ERR"
	A=$(cat $BED_PRIMERS_OPTIONS | tr ';' '\n' | grep "$CHR:" | tr '\n' ';')
#echo "$SAMTOOLS view -h $BAM $CHR -c"; exit;
	NB_READS=$($SAMTOOLS view -h $BAM $CHR -c)
#echo "$SAMTOOLS view -h $BAM $CHR -c"
#$SAMTOOLS view -h $BAM $CHR -c
#echo "NB_READS=$NB_READS"
	CHROMPOS=$CHR
	#CHROMPOS=$(echo $BED_PRIMERS_OPTIONS | tr ";" "\n" | cut -d "," -f3 | tr "\n" " ")

	CAP_OPTIONS=" -v1 -n$NB_READS $CLIPPING_OPTIONS"
	if [ "$A" != "" ]; then
		if (($VERBOSE)); then
			$SAMTOOLS view -h $BAM $CHRPOS 2> $SAMTOOLS_ERR | $SCRIPT_DIR/CAP.pl -a "$A" $CAP_OPTIONS > $OUTPUT_SAM;
		else
			$SAMTOOLS view -h $BAM $CHRPOS 2> $SAMTOOLS_ERR | $SCRIPT_DIR/CAP.pl -a "$A" $CAP_OPTIONS > $OUTPUT_SAM 2>$CAP_ERR;
		fi;
	else
		(($VERBOSE)) && echo "# No primers defined"
		(($VERBOSE)) && [ "$CHR" != "" ] && echo "# Filtering SAM on '$CHR'"
		$SAMTOOLS view -h $BAM $CHR > $OUTPUT_SAM
		#exit 0;
	fi;
	(($VERBOSE)) && echo "# OUTPUT_SAM=$OUTPUT_SAM"
	(($DEBUG)) && $SAMTOOLS view $OUTPUT_SAM | head -n 10 && echo "...";
fi;

# SAM to BAM
if ((1)); then
	(($VERBOSE)) && echo -e "\n# SAM to BAM..."
	#OUTPUT_UNSORTED_BAM=$TMP_CAP/$RANDOM$RANDOM.bam
	#OUTPUT_UNSORTED_SAM=$OUTPUT_SORTED.sam
	OUTPUT_SORTED=$TMP_CAP/$RANDOM$RANDOM
	OUTPUT_SORTED_BAM=$OUTPUT_SORTED.bam
	SAMTOOLS_ERR=$TMP_CAP/$RANDOM$RANDOM.err
	TMP_FILES=$TMP_FILES" $OUTPUT_UNSORTED_BAM $OUTPUT_UNSORTED_SAM $OUTPUT_SORTED $SAMTOOLS_ERR"
	#$SAMTOOLS view -o $OUTPUT_UNSORTED_BAM -b -S -T $REF $OUTPUT_SAM -@ $THREADS
	#$SAMTOOLS sort $OUTPUT_UNSORTED_BAM -o $OUTPUT_SORTED -l $COMPRESS -@ $THREADS
	$SAMTOOLS view -O BAM -T $REF $OUTPUT_SAM -@ $THREADS | $SAMTOOLS sort - -o $OUTPUT_SORTED -l $COMPRESS -@ $THREADS #> $OUTPUT_SORTED
	mv $OUTPUT_SORTED $OUTPUT
	#(($VERBOSE)) && echo "# OUTPUT_UNSORTED_BAM=$OUTPUT_UNSORTED_BAM"
	#(($DEBUG)) && $SAMTOOLS view $OUTPUT_UNSORTED_BAM | head -n 10 && echo "...";
	(($VERBOSE)) && echo "# OUTPUT=$OUTPUT"
	(($DEBUG)) && $SAMTOOLS view $OUTPUT | head -n 10 && echo "...";
	(($VERBOSE)) && echo "# Output BAM $OUTPUT clipped (compress=$COMPRESS, chromosome=$CHR)..."
fi;

# TMP_FILES
if ! (($DEBUG)); then
	rm -Rf $TMP_FILES
	rm -rf $TMP_CAP
fi;

echo "";
exit 0;
