#################################
## CAP environment
#################################
export ENV_NAME="CAP"
export ENV_DESCRIPTION="CAP"
export ENV_RELEASE="0.9.11b"
export ENV_DATE="07/08/2019"
export ENV_AUTHOR="Antony Le Bechec"
export ENV_COPYRIGHT="IRC"
export ENV_LICENCE="GNU-GPL"


# FOLDERS
export DATABASES_FOLDER=/databases					    # DATABASES FOLDER folder
export TOOLS=/tools			# TOOLS FOLDER


# GENOME REF
export GENOMES_FOLDER=$DATABASES_FOLDER/genomes			# Genomes folder in NGS folder
export ASSEMBLY=hg19						        # default Assembly
export REF=$GENOMES_FOLDER/$ASSEMBLY/$ASSEMBLY.fa	# Default REF


# JAVA
export JAVA=java			    # BIN
export JAVA_PATH=/usr/bin		# BIN
export JAVA_VERSION=1.8			# VER
export JAVA_DESCRIPTION="A high-level programming language developed by Sun Microsystems"
export JAVA_REF="http://java.com"

# SAMTOOLS
export SAMTOOLS=$TOOLS/samtools/current/bin/samtools		# BIN
export SAMTOOLS_VERSION=1.8					                # VER
export SAMTOOLS_DESCRIPTION="Reading/writing/editing/indexing/viewing SAM/BAM/CRAM format"
export SAMTOOLS_REF="Li H.*, Handsaker B.*, Wysoker A., Fennell T., Ruan J., Homer N., Marth G., Abecasis G., Durbin R. and 1000 Genome Project Data Processing Subgroup (2009) The Sequence alignment/map (SAM) format and SAMtools. Bioinformatics, 25, 2078-9. [PMID: 19505943]. Li H A statistical framework for SNP calling, mutation discovery, association mapping and population genetical parameter estimation from sequencing data. Bioinformatics. 2011 Nov 1;27(21):2987-93. Epub 2011 Sep 8. [PMID: 21903627]"

# PICARD
export PICARD=$TOOLS/picard/current/bin/picard.jar		    # BIN
#export PICARDLIB=$PICARD		                            # LIB
export PICARD_VERSION=2.18.5					            # VER
export PICARD_DESCRIPTION="Java command line tools for manipulating high-throughput sequencing data (HTS) data and formats"
export PICARD_REF="http://broadinstitute.github.io/picard/"


# BEDTOOLS
export BEDTOOLS=$TOOLS/bedtools/current/bin/			    # DIR
export BEDTOOLS_VERSION=2.27.1					            # VER
export BEDTOOLS_DESCRIPTION="a powerful toolset for genome arithmetic"
export BEDTOOLS_REF="http://bedtools.readthedocs.org/"
