#!/usr/bin/perl
####################################
# OPTION from BED&FASTA            #
# Author: Antony Le Béchec         #
# Copyright: IRC                   #
####################################

## Main Information
#####################

our %information = ( #
	'script'	=>  	$0,		# Script
	'release'	=>  	"0.9.2b",	# Release
	'description'	=>  	"Option from BED & FASTA",	# Description
	#'beta'		=>  	"beta",		# Man parameter
	'date'		=>  	"20200206",	# Release parameter
	'author'	=>  	"ALB",		# Debug parameter
	'copyright'	=>  	"IRC",		# Verbose parameter
	'licence'	=>  	"GNU-AGPL",	# Licence
);


## Modules
############

use Getopt::Long;		# Catch Options
use Pod::Usage;			# Pod
use Time::localtime;		# Time
use Data::Dumper;		# Data
use File::Basename;		# File
use Switch;			# Switch
#use File::Temp qw/ tempfile tempdir tmpnam /;
use File::Temp qw/ tmpnam /;
use lib dirname (__FILE__);	# Add lib in the same folder

require "functions.inc.pl";	# Common functions


## HELP/MAN
#############

=head1 NAME

ManifestToPrimerBED.pl - BED File from Illumina Manifest

=head1 DESCRIPTION

Description

=head1 BUGS

Bugs...

=head1 ACKNOWLEDGEMENTS

Thank U!

=head1 COPYRIGHT

IRC - GNU GPL License

=head1 AUTHOR

ALB

=head1 USAGE

$ARGV[0] [options] --input=<BED> [--fasta=<FASTA>] --output=<BED>

=head1 OPTIONS

=head2 MAIN options

=over 2

=item B<--help|h|?>

Print a brief help message and exits.

=item B<--man>

Prints the manual page and exits.

=back

=head2 CONFIGURATION

=over 2

=item B<--config|config_file=<file>>

Configuration file for main parameters (default 'config.ini')

=item B<--config_annotation|config_annotation_file=<file>>

Configuration file for annotation parameters (default 'config.annotation.ini').

=back

=cut

=head2 OTHER OPTIONS

=over 2

=item B<--type|=<string>>

Type of manifest ("TruSeq", "XT Nextera"..., default=auto) TODO

=back

=cut


## Parameters
###############

## Parameters default values

our %parameters = ( #
	# Main options
	'help'		=>  	0,	# Help parameter
	'man'		=>  	0,	# Man parameter
	'release'	=>  	0,	# Release parameter
	'debug'		=>  	0,	# Debug parameter
	'verbose'	=>  	0,	# Verbose parameter
	# Configuration
	'config'		=>	'config.ini',			# Configuration file
	'config_annotation'    	=>  	"config.annotation.ini",	# Configuratin annotation file
	# Input
	'input'		=>	undef,		# Input BED file
	'fasta'		=>	undef,		# Input Fasta file
	'type'		=>	'auto',		# Type of Manifest
	# Output
	'output'	=>	undef,		# Output BED file
);

## Parameters definition

our @options=(
	# Main options
	'help|h|?',		# Help
	'man',			# Man
	'release',		# Release
	'debug',		# Debug
	'verbose',		# Verbose
	# Configuration
	'config|config_file=s',				# Configuration file
	'config_annotation|config_annotation_file=s',	# Configuratin annotation file
	# Input
	'input|input_file=s',	# Input BED file
	'fasta|fasta_file=s',	# Input FASTAfile
	'type=s',		# Type
	# output
	'output|output_file=s',	# Output file
);

## Catch Options and put into parameters
GetOptions (\%parameters,@options,@common_options)  or pod2usage();

## Main parameters
$date=timestamp();
$basename = dirname (__FILE__);

## Header
$header="##\n";
$header.="## Script: ".$information{"script"}." (release ".$information{"release"}."/".$information{"date"}.")\n";
$header.="## Excecution Date: ".$date."\n";
$header.="##\n";


## PrePorcessing
##################

## Help
if ($parameters{"help"}) {
	pod2usage(1);
};#if

## Man
if ($parameters{"man"}) {
	pod2usage(-exitstatus => 0, -verbose => 2);
};#if

## Release
if ($parameters{"release"}) {
	print "## Script Information\n";
	while ((my $var, $val) = each(%information)){
		print "# $var: $val\n";
	};#while
	exit 0;
};#if

## Debug
my $DEBUG=1 if $parameters{"debug"};

## Verbose
my $VERBOSE=1 if $parameters{"verbose"};


## Configuration files

# Config file
my $config_file;
if (-e $parameters{"config"}) {
	$config_file=$parameters{"config"};
} elsif (-e "$basename/".$parameters{"config"}) {
	$config_file="$basename/".$parameters{"config"};
} elsif (-e "$basename/config.ini") {
	$config_file="$basename/config.ini";
} else {
	print "# No Configuration file...\n";
	#pod2usage(1);
};#if

# Set parameters from config file
if (-e $config_file) {

	# read ini file
	our %config=read_ini($config_file);
	# Folders
	$data_folder=$config{"folders"}{"data_folder"}."/";
	$annovar_databases=$config{"folders"}{"annovar_databases"}."/";

	# ANNOVAR folder (default "$basename")
	if (defined $config{"folders"}{"annovar_folder"} && -d $config{"folders"}{"annovar_folder"}) {
		$annovar_folder=$config{"folders"}{"annovar_folder"};
	} else {
		$annovar_folder=$basename;
	};#if
	if (trim($annovar_folder) ne "") {$annovar_folder.="/"};

	# VCFTOOLS folder in $PATH by default (default "")
	if ((defined $config{"folders"}{"vcftools_folder"} && -d $config{"folders"}{"vcftools_folder"}) || trim($config{"folders"}{"vcftools_folder"}) eq "") {
		$vcftools_folder=$config{"folders"}{"vcftools_folder"};
	} else {
		$vcftools_folder=$basename;
	};#if
	if (trim($vcftools_folder) ne "") {$vcftools_folder.="/"};

	# R folder in $PATH by default (default "")
	if ((defined $config{"folders"}{"R_folder"} && -d $config{"folders"}{"R_folder"}) || trim($config{"folders"}{"R_folder"}) eq "") {
		$R_folder=$config{"folders"}{"R_folder"};
	} else {
		$R_folder=$basename;
	};#if
	if (trim($R_folder) ne "") {$R_folder.="/"};

	# Database connexion
	$host = $config{"database"}{"host"};
	$driver = $config{"database"}{"driver"};
	$database= $config{"database"}{"database"};
	$user = $config{"database"}{"user"};
	$pw = $config{"database"}{"pw"};
	$port = $config{"database"}{"port"};
	#Project
	$assembly=$config{"project"}{"assembly"};
	$platform=$config{"project"}{"platform"};

};#if

# Config annotation file
my $config_annotation_file;
if (-e $parameters{"config_annotation"}) {
    $config_annotation_file=$parameters{"config_annotation"};
} elsif (-e "$basename/".$parameters{"config_annotation"}) {
    $config_annotation_file="$basename/".$parameters{"config_annotation"};
} elsif (-e "$basename/config.annotation.ini") {
    $config_annotation_file="$basename/config.annotation.ini";
} else {
	#print "No Annotation Configuration file...\n";
	#pod2usage(1);
};#if

# Read the config annotation file
#our %config_annotation=read_ini($config_annotation_file);


## Input file
my $input_file;
if (-e $parameters{"input"}) {
	$input_file=$parameters{"input"};
	$header.="## Input file: ".$parameters{"input"}."\n";
} else {
	print "# ERROR: input file '".$parameters{"input"}."' DOES NOT exist\n";
	pod2usage();
	exit 1;
};#if

## Input file
my $fasta_file;
if (-e $parameters{"fasta"}) {
	$fasta_file=$parameters{"fasta"};
	$header.="## Input FASTA file: ".$parameters{"fasta"}."\n";
} else {
	print "# WARNING: input fasta file '".$parameters{"fasta"}."' DOES NOT exist\n";
	print "# Creation of FASTA File from BED '".$parameters{"input"}."'\n";
	my $FASTA=tmpnam();
	$header.="## Input FASTA file: $FASTA\n";
	my $TOOL_fastaFromBed=$config{"tools"}{"bedtools"}."/fastaFromBed";
	my $REF=$config{"folders"}{"NGS_genomes"}."/".$config{"project"}{"assembly"}."/".$config{"project"}{"assembly"}.".fa";
	my $BED=$input_file;
	#NGS_genomes
	my $cmd="$TOOL_fastaFromBed -fi $REF -bed $BED -fo $FASTA";
	print "$cmd\n" if $DEBUG;
	my $result=`$cmd`;
	if (-e $FASTA) {
		print "# FASTA File created!\n";
		$fasta_file=$FASTA;
	} else {
		print "# FASTA File NOT created!\n";
		exit 1;
	};#if
	#pod2usage();
	#exit 1;
};#if


## Output file
my $output_file;
if (-e $parameters{"output"} && 0) {
	print "# ERROR: output file '".$parameters{"output"}."' DOES exist\n";
	pod2usage();
	exit 1;
} else {
	#$output_file=$parameters{"output"};
	if ($parameters{"output"} ne "") {
		$output_file=$parameters{"output"};
	} else {
		$output_file=$input_file.".option";
	};#if
	$header.="## Output file: $output_file\n";
};#if


## Type of manifest TODO
# Type detection
$manifest_type=$parameters{"type"};


## DEBUG
##########

#print Dumper(\%parameters) if $DEBUG;
#print Dumper(\%config) if $DEBUG;
#print Dumper(\%config_annotation) if $DEBUG;


## MAIN
#########

# Variables
$output="";


## VCF into ANNOVAR

# ANNOVAR temporary file
my $tmp_file=tmpnam();

# ANNOVAR convert command
my $cmd="perl $convert2annovar --format vcf4old --includeinfo --allallele --outfile $annovar_file $input_file 2>&1";
#print "$cmd_convert2annovar\n" if $DEBUG;

# Launch command
#my $result = `$cmd`;

open(FILE_INPUT, $input_file) || die "Problem to open the file '$input_file': $!";
open(FILE_FASTA, $fasta_file) || die "Problem to open the file '$input_file': $!";
my $line=0;
my $line_info_read=0;
my %targets;
my %primers;
my $BEDcontent;

#read the file
while(<FILE_INPUT>) {

	# init
	chomp; #delete \n character
	my $line++;
	my $line_content=$_;

	# Null line
	if (trim($line_content) eq "") {
		next;
	};

	my @line_content_split=split("\t",$line_content);

	# Process
	#print "@line_content_split\n" if $DEBUG;
	if ($line_content  =~ /(\w+)\t(\d+)\t(\d+)\t\+\t(.*)\t(.*)/) {
		#print "!!!Match $1 $2 $3 $4 $5\n" if $DEBUG;
		#@myarray = ($line_content =~ m/(\w+)\t(\d+)\t(\d+)\t\+\t(.*)(.*)/g);
		#print join(",", @myarray);
		my $chr=$1;
		#my $start=($2+1); # 1-based format
		my $start=$2; # 1-based format
		my $start_1_based=($2+1); # 1-based format
		my $stop=$3;
		my $stop_1_based=($3);
		my $targetID=$line_content_split[4];
		#my $targetID=$4;
		#my $targetID="$chr:$start-$stop";
		my $primerType=$line_content_split[5];
		#my $primerType=$5;
		print "$chr | $start | $stop | $targetID | $primerType\n" if $DEBUG;
		#$primers{"$chr:$start-$stop"}{$primerType}="$chr:$start-$stop";
		#$targets{$targetID}{$primerType}="$chr:$start-$stop";

		#$targets{$targetID}{$primerType}="$chr:$start_1_based-$stop";
		#$targets{$targetID}{"Region"}{"chr"}="$chr";
		#$targets{$targetID}{"Region"}{$primerType}{"start"}="$start_1_based";
		#$targets{$targetID}{"Region"}{$primerType}{"stop"}="$stop_1_based";

		$targets{$targetID}{$primerType}="$chr:$start_1_based-$stop_1_based";
		$targets{$targetID}{"primers"}{$primerType}{"length"}=($stop-$start);
		$targets{$targetID}{"Region"}{"chr"}="$chr";
		$targets{$targetID}{"Region"}{$primerType}{"start"}="$start_1_based";
		$targets{$targetID}{"Region"}{$primerType}{"stop"}="$stop_1_based";

		#$targets{$targetID}{$primerType}="$targetID";
		# BED
		#$BEDcontent.="$primer1_chr\t$primer1_start\t$primer1_stop\t+\t$chr:$start-$stop\tForward\n";
		#$BEDcontent.="$primer2_chr\t$primer2_start\t$primer2_stop\t+\t$chr:$start-$stop\tReverse\n";
	};#if


};#while

#read the file
my $SEQ_NAME;
my $SEQ;
if (1) {
	while(<FILE_FASTA>) {

		# init
		chomp; #delete \n character
		my $line++;
		my $line_content=$_;

		# Null line
		if (trim($line_content) eq "") {
			next;
		};

		my @line_content_split=split("\t",$line_content);

		# Process
		#print "@line_content_split\n" if $DEBUG;
		if ($line_content  =~ />(.*)/) {
			#print "!!!Match SEQNAME $1\n" if $DEBUG;
			$SEQ_NAME=$1;
		} else {
			if (defined $SEQ_NAME) {
				$SEQ=uc($line_content);
				$primers{$SEQ_NAME}=$SEQ;
				#print "$SEQ_NAME=$SEQ\n" if $DEBUG;
			};#if
		};#if


	};#while
};#if

close(FILE_INPUT);
close(FILE_FASTA);


print Dumper(\%targets) if $DEBUG;
print Dumper(\%primers) if $DEBUG;

my $options;
while ((my $targetID, my $primers_info) = each(%targets)){
	#$options.=$primers{$$primers_info{"Forward"}}.",".$primers{$$primers_info{"Reverse"}}.",$targetID;";
	#$options.=$primers{$$primers_info{"Forward"}}.",".$primers{$$primers_info{"Reverse"}}.",".$$primers_info{"Region"}.";";
	my $primerF=("N" x $$primers_info{"primers"}{"Forward"}{"length"});
	if (defined $primers{$$primers_info{"Forward"}}) {
		$primerF=$primers{$$primers_info{"Forward"}};
	};#if
	my $primerR=("N" x $$primers_info{"primers"}{"Reverse"}{"length"});
	if (defined $primers{$$primers_info{"Reverse"}}) {
		$primerR=$primers{$$primers_info{"Reverse"}};
	};#if
	$options.=$primerF.",".$primerR.",".$$primers_info{"Region"}{"chr"}.":".$$primers_info{"Region"}{"Forward"}{"start"}."-".$$primers_info{"Region"}{"Reverse"}{"stop"}.";";

	#OK $options.=$primers{$$primers_info{"Forward"}}.",".$primers{$$primers_info{"Reverse"}}.",".$$primers_info{"Region"}{"chr"}.":".$$primers_info{"Region"}{"Forward"}{"start"}."-".$$primers_info{"Region"}{"Reverse"}{"stop"}.";";


	#$options.="X,X,chr13:32890470-32890724;";


	{"Region"}{$primerType}{"stop"}
};#while


# Write OPTION file
open(FILE_OUTPUT, ">$output_file") || die "Problem to open the file '$output_file': $!";
print FILE_OUTPUT "$options";
close(FILE_OUTPUT);

## PostProcess
################

$header.="##\n";


## OUTPUT
###########

# Header
print $header;
print $debug;
print $verbose;
print $output;


__END__
