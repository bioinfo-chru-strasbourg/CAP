#!/bin/bash
#################################
##
## NGS environment
##
#################################

SCRIPT_NAME="CAPManifestToGenes"
SCRIPT_DESCRIPTION="CAP Manifest To Genes"
SCRIPT_RELEASE="0.9b"
SCRIPT_DATE="27/07/2016"
SCRIPT_AUTHOR="Antony Le Bechec"
SCRIPT_COPYRIGHT="IRC"
SCRIPT_LICENCE="GNU-GPL"

# Realse note
RELEASE_NOTES=$RELEASE_NOTES"# 0.9b-27/07/2016: Script creation\n";


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
	echo "# USAGE: $(basename $0) --manifest<MANIFEST> --output=<OUTPUT> [options...]";
	echo "# -m/--manifest         MANIFEST file (mandatory)";
	echo "# -o/--output           Clipped Aligned BAM file (defaut *clipped.bam)";
	echo "# -e/--env              ENVironment file";
	echo "# -v/--verbose          VERBOSE option";
	echo "# -d/--debug            DEBUG option";
	echo "# -n/--release          RELEASE option";
	echo "# -h/--help             HELP option";
	echo "#";
}

# header
header;

ARGS=$(getopt -o "m:o:e:vdnh" --long "manifest:,output:,verbose,debug,release,help" -- "$@" 2> /dev/null)
if [ $? -ne 0 ]; then
	echo $?
	usage;
	exit;
fi;

eval set -- "$ARGS"
while true
do
	#echo "$1=$2"
	#echo "Eval opts";
	case "$1" in
		-m|--manifest)
			if [ ! -e $2 ] || [ "$2" == "" ]; then
				echo "#[ERROR] No MANIFEST file '$2'"
				usage; exit;
			else
				MANIFEST="$2";
			fi;
			shift 2
			;;
		-o|--output)
			OUTPUT="$2"
			shift 2
			;;
		-e|--env)
			ENV="$2"
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

# Mandatory parameters
if [ -z $MANIFEST ]; then #  || [ -z $OUTPUT ]; then
	usage;
	exit;
fi

# auto parameters
if [ -z $OUTPUT ]; then
	OUTPUT=$MANIFEST.genes;
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

# TMP_FILES
TMP_FILES=""


# input
echo "
##################
# MANIFEST=$MANIFEST
# OUTPUT=$OUTPUT"

(($VERBOSE)) && echo "# ENV=$ENV";

(($VERBOSE)) && echo "";
(($VERBOSE)) && echo "##################"
(($VERBOSE)) && echo "";

# Test manifest empty
if [ ! -s $MANIFEST ]; then
	(($VERBOSE)) && echo "# No primers defined in manifest"
	> "$OUTPUT"
	exit 0;
fi;


# Manifest to BED target
if ((1)); then
	(($VERBOSE)) && echo -e "# Manifest to target BED..."

	BED_TARGET=$TMP_SYS_FOLDER/$RANDOM$RANDOM.target.bed
	MANIFESTTOBED_TARGET_OUTPUT=$TMP_SYS_FOLDER/$RANDOM$RANDOM.output
	MANIFESTTOBED_TARGET_ERR=$TMP_SYS_FOLDER/$RANDOM$RANDOM.err
	TMP_FILES=$TMP_FILES" $BED_TARGET $MANIFESTTOBED_TARGET_OUTPUT $MANIFESTTOBED_TARGET_ERR"
	$SCRIPT_DIR/CAP.ManifestToBED.pl --input="$MANIFEST" --output=$BED_TARGET --output_type=target  1>$MANIFESTTOBED_TARGET_OUTPUT 1>$MANIFESTTOBED_TARGET_ERR
	(($DEBUG)) && cat $MANIFESTTOBED_TARGET_OUTPUT;
	(($DEBUG)) && cat $MANIFESTTOBED_TARGET_ERR;
	(($VERBOSE)) && echo "# BED_TARGET=$BED_TARGET"
	(($DEBUG)) && head -n 10 $BED_TARGET && echo "...";
	if [ ! -s $BED_TARGET ]; then
		(($VERBOSE)) && echo "# No target defined"
		> "$OUTPUT"
		exit 0;
	fi;

fi;

# BED to Genes
if ((1)); then
	(($VERBOSE)) && echo -e "\n# BED to Genes..."

	GENES_OUTPUT=$TMP_SYS_FOLDER/$RANDOM$RANDOM.output
	GENES_ERR=$TMP_SYS_FOLDER/$RANDOM$RANDOM.err
	TMP_FILES=$TMP_FILES" $GENES_OUTPUT $GENES_ERR"
	cat $BED_TARGET | awk '{print $1"\t"$2"\t"$3"\t"$5}' | cut -d_ -f1 | cut -d: -f1 | cut -d. -f1 | cut -d\( -f1 1>$GENES_OUTPUT 2>$GENES_ERR
	(($DEBUG)) && head -n 10 $GENES_OUTPUT && echo "...";

	cp $GENES_OUTPUT "$OUTPUT"

fi;

# TMP_FILES
if ((1)); then
	rm -Rf $TMP_FILES
fi;

echo "";
