#!/usr/bin/perl
####################################
# BED File from Illumina Manifest  #
# Author: Antony Le Béchec         #
# Copyright: IRC                   #
####################################

## Main Information
#####################

our %information = ( #
	'script'	=>  	$0,		# Script
	'release'	=>  	"0.9.11.1b",	# Release
	'description'	=>  	"BED File from Illumina Manifest",	# Description
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

ManifestToBED.pl - BED File from Illumina Manifest.
Note: Manifest file format uses 1-based coordinates, BED file format uses 0-based coordinates

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

$ARGV[0] [options] --input=<MANIFEST> --output=<BED>

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

=item B<--type=<string>>

Type of manifest ("TruSeq", "PCR"..., default=auto) TODO

=back

=item B<--output_type=<string>>

Type of output ("primer", "amplicon", "region_clipped", "target" or "region", default="primer")

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
	'input'		=>	undef,		# Input Manifest file
	'type'		=>	'auto',		# Type of Manifest
	# Output
	'output'	=>	undef,		# Output BED file
	'output_type'	=>	"primer",	# Output type, either "primer", "amplicon" or "region"
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
	'input|input_file=s',	# Input file
	'type=s',		# Type
	# output
	'output|output_file=s',	# Output file
	'output_type=s',	# Output type
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
	print "# No Annotation Configuration file...\n";
	#pod2usage(1);
};#if

# Read the config annotation file
#our %config_annotation=read_ini($config_annotation_file);


## Input file
my $input_file;
if (-e $parameters{"input"}) {
	$input_file=$parameters{"input"};
	$header.="## Input  file: ".$parameters{"input"}."\n";
} else {
	print "# ERROR: input file '".$parameters{"input"}."' DOES NOT exist\n";
	pod2usage();
	exit 1;
};#if

## Output file
my $output_file;
if (-e $parameters{"output"} && 0) {
	print "# ERROR: output file '".$parameters{"output"}."' DOES exist\n";
	pod2usage();
	exit 1;
} else {
	if ($parameters{"output"} ne "") {
		$output_file=$parameters{"output"};
	} else {
		$output_file=$input_file.".bed";
	};#if
	$header.="## Output file: $output_file\n";
};#if

## Output type
my $output_type=$parameters{"output_type"};


## Type of manifest TODO
# Type detection
$manifest_type=$parameters{"type"};
my @type_allowed=("PCR","TRUSEQ");
#print "@type_allowed\n" if $DEBUG;
if (in_array(\@type_allowed,uc($manifest_type))) {
	$manifest_type=uc($manifest_type);
	# Check Manifest type
	$manifest_type_checked=manifest_type_test($input_file);

	if ($manifest_type eq uc($manifest_type_checked)) {
		#print "$manifest_type  $manifest_type_checked\n" if $DEBUG;
	} else {
		if (in_array(\@type_allowed,uc($manifest_type_checked))) {
			# Replace input manifest type by the good one
			print "# WARNING: Manifest file type is '$manifest_type_checked', not '$manifest_type'\n";
			$manifest_type=uc($manifest_type_checked);
		} else {
			# manifest type checked as 'unknown', but input manifest typ edifferent. Keep input manifest type!
		};#if
	};#if
} else {
	# Check Manifest type
	$manifest_type_checked=manifest_type_test($input_file);
	if (in_array(\@type_allowed,uc($manifest_type_checked))) {
		$manifest_type=uc($manifest_type_checked);
	} else {
		print "# ERROR: Manifest file type unknown\n";
		pod2usage();
		exit 1;
	};#if
};#if


## Function manifest_type_test
## Test manifest type
sub manifest_type_test {
## INPUT:
## $_[0]: manifest file
## OUTPUT
## $manifest_type: Manifest type

	my $manifest_file=$_[0];	# Manifest file
	my $manifest_type;		# Manifest type

	open(FILE_INPUT, $manifest_file) || die "Problem to open the file '$manifest_file': $!";
	my $line=0;
	my $section;

	#read the file
	while(<FILE_INPUT>) {

		# init
		chomp; #delete \n character
		$line++;
		$line_content=$_;

		## PCR
		if ($line_content =~ /Name	Chromosome	Amplicon Start	Amplicon End	Upstream Probe Length	Downstream Probe Length/) {
			$manifest_type="PCR";
		};#if
		## PCR light
		if ($line_content =~ /Name	Chromosome	Amplicon Start	Amplicon End/) {
			$manifest_type="PCR";
		};#if

		## TRUSEQ
		#if ($line_content =~ /Target Region Name	Target Region ID	Target ID	Species	Build ID	Chromosome	Start Position	End Position	Submitted Target Region Strand	ULSO Sequence	ULSO Genomic Hits	DLSO Sequence	DLSO Genomic Hits	Probe Strand	Designer	Design Score	Expected Amplifed Region Size	SNP Masking	Labels/) {
		#Target ID	Species	Build ID	Chromosome	Start Position	End Position	Strand	ULSO Sequence	DLSO Sequence	Probe Strand
		if ($line_content =~ /.*Target ID	Species	Build ID	Chromosome	Start Position	End Position.*ULSO Sequence.*DLSO Sequence.*/) {
			$manifest_type="TRUSEQ";
		};#if


	};#while

	if (!defined $manifest_type) {
		$manifest_type="unknown";
	};#if

	return $manifest_type;

}
$manifest_type_checked=manifest_type_test($input_file);


#$header.="## Input file type: ".$parameters{"type"}."\n";
#$header.="## Checked Input file type: $manifest_type_checked\n";
#$header.="## Selected Input file type: $manifest_type\n";
$header.="## Input file type: $manifest_type\n";





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
#my $cmd="perl $convert2annovar --format vcf4old --includeinfo --allallele --outfile $annovar_file $input_file 2>&1";
#print "$cmd_convert2annovar\n" if $DEBUG;

# Launch command
#my $result = `$cmd`;

open(FILE_INPUT, $input_file) || die "Problem to open the file '$input_file': $!";
my $line=0;
my $line_info_read=0;
my $section;
my $BEDcontent;
my %amplicon_probes_col_indexes;
my %amplicon_probes;
my %amplicon_targets_col_indexes;
my %amplicon_targets;
my %amplicons;
my %regions;

#read the file
while(<FILE_INPUT>) {

	# init
	chomp; #delete \n character
	$line++;
	my $line_content=$_;


	# Null line
	if (trim($line_content) eq "") {
		next;
	};

	@line_content_split=split("\t",$line_content);

	#print "@line_content_split\n" if $DEBUG;

	# Section
	if ($line_content_split[0] =~ /\[(.*)\]/) {
		$section=$1;
	};#if

	# Process
	switch (uc($manifest_type)){
		# Manifest type PCR
		case("PCR") {
			if ($section eq "Regions") {
				#print "$line_content\n" if $DEBUG;
				#print "@line_content_split\n" if $DEBUG;
				#EGFR_ex19 chr7 55242379 55242574 30 30
				#if ($line_content  =~ /(\w+)\t(\w+)\t(\d+)\t(\d+)\t(\d+)\t(\d+)/) {
				if ($line_content  =~ /(.+)\t(\w+)\t(\d+)\t(\d+)\t(\d+)\t(\d+)/) {
					#print "!!!Match $1 $2 $3 $4 $5 $6\n" if $DEBUG;
					my $sequence_name=$1;
					my $chr=$2;
					my $start=($3-1);
					my $stop=$4;
					my $primer1_length=$5;
					my $primer2_length=$6;
					my $B="N"; # default base
					my $chr_start_stop_0_based="$chr:$start-$stop";
					my $chr_start_stop_1_based="$chr:".($start+1)."-$stop";
					#print("$chr\t$start_clipped\t$stop_clipped\t+\t$sequence_name\n");
					# primer1 calculation
					my $primer1_chr=$chr;
					my $primer1_start=$start;
					my $primer1_stop=($start+$primer1_length);
					#my $primer1_sequence=s/^(.*)/(' ' x $primer1_length) . $B/e;
					my $primer1_sequence = ( $B x $primer1_length ) . $primer1_sequence;
					# primer2 calculation
					my $primer2_chr=$chr;
					my $primer2_start=($stop-$primer2_length);
					my $primer2_stop=($stop);
					my $primer2_sequence = ( $B x $primer2_length ) . $primer2_sequence;
					# clipping
					my $start_clipped=($start+$primer1_length);
					my $stop_clipped=($stop-$primer2_length);
					# BED
					$BEDcontent.="$primer1_chr\t$primer1_start\t$primer1_stop\t+\t$chr_start_stop_1_based\tForward\n";
					$BEDcontent.="$primer2_chr\t$primer2_start\t$primer2_stop\t+\t$chr_start_stop_1_based\tReverse\n";
					$BEDcontent_amplicon.="$chr\t$start\t$stop\t+\t$sequence_name\n";
					$BEDcontent_region.="$chr\t$start\t$stop\t+\t$sequence_name\n";
					$BEDcontent_region_clipped.="$chr\t$start_clipped\t$stop_clipped\t+\t$sequence_name\n";
					$BEDcontent_target.="$chr\t$start_clipped\t$stop_clipped\t+\t$sequence_name\t$primer1_sequence\t$primer2_sequence\t$chr:$start-$stop\n";
				} elsif ($line_content  =~ /(.+)\t(\w+)\t(\d+)\t(\d+)/) { # in case of no primer defined
					#print "!!!Match $1 $2 $3 $4\n" if $DEBUG;
					my $sequence_name=$1;
					my $chr=$2;
					my $start=($3-1);
					my $stop=$4;
					#$BEDcontent.="$chr\t$start\t$start\t+\t$chr:$start-$stop\tForward\n";
					#$BEDcontent.="$chr\t$stop\t$stop\t+\t$chr:$start-$stop\tReverse\n";
					$BEDcontent_amplicon.="$chr\t$start\t$stop\t+\t$sequence_name\n";
					$BEDcontent_region.="$chr\t$start\t$stop\t+\t$sequence_name\n";
					$BEDcontent_region_clipped.="$chr\t$start\t$stop\t+\t$sequence_name\n";
					$BEDcontent_target.="$chr\t$start\t$stop\t+\t$sequence_name\t$primer1_sequence\t$primer2_sequence\t$chr:$start-$stop\n";
				};#if
			};#if
		}
		# Manifest type TruSeq
		case("TRUSEQ") {
			# Section Probes
			if ($section eq "Probes") {
				# header of the section
				if ($line_content  =~ /ULSO/) {
					print "!!!Section [Probes] header\n$line_content\n" if $DEBUG;
					# find index of ULSO and DLSO
					my $col_index=0;
					foreach my $col_name (@line_content_split) {
						$amplicon_probes_col_indexes{trim($col_name)}=$col_index;
						$col_index++;
					};#foreach
				} else {
					# Probes lines
					while ((my $col_name, my $col_index) = each(%amplicon_probes_col_indexes)){
						$amplicon_probes{$line_content_split[$amplicon_probes_col_indexes{"Target ID"}]}{$col_name}=$line_content_split[$col_index];
						$regions{$line_content_split[$amplicon_probes_col_indexes{"Target Region ID"}]}{$col_name}=$line_content_split[$col_index];
					};#while
				};#if

			};#if
			# Section Targets
			if ($section eq "Targets") {
				# header of the section
				if ($line_content  =~ /^TargetA/) {
					print "!!!Section [Targets] header\n$line_content\n" if $DEBUG;
					# find index of ULSO and DLSO
					my $col_index=0;
					foreach my $col_name (@line_content_split) {
						$amplicon_targets_col_indexes{trim($col_name)}=$col_index;
						#print "$col_name)}=$col_index\n" if $DEBUG;
						$col_index++;
					};#foreach

				} else {
					# Probes lines
					#print $line_content_split[3]."\n" if $DEBUG;
					#if ($line_content_split[$amplicon_targets_col_indexes{"Target Number"}] ne "1") {
					#	print "@line_content_split\n" if $DEBUG;
					#	#print $line_content_split[($amplicon_targets_col_indexes{"Number"}+1)]."\n" if $DEBUG;
					#};#if
					#if (!defined $amplicon_targets{$line_content_split[$amplicon_targets_col_indexes{"TargetA"}]}) {
					if ($line_content_split[$amplicon_targets_col_indexes{"Target Number"}] eq "1") {
						while ((my $col_name, my $col_index) = each(%amplicon_targets_col_indexes)){
							$amplicon_targets{$line_content_split[$amplicon_targets_col_indexes{"TargetA"}]}{$col_name}=$line_content_split[$col_index];
						};#while
					};#if
				};#if

			};#if


		}
		# Else... ERROR
		else {
			#print "# other type\n" if $DEBUG;
			next;
		}# else
	}




};#while

#print Dumper(\%amplicon_probes) if $DEBUG;
print "# NB Amplicons Probes : ".scalar(keys %amplicon_probes)."\n" if $DEBUG;
#print Dumper(\%amplicon_targets) if $DEBUG;
print "# NB Amplicons Targets: ".scalar(keys %amplicon_targets)."\n" if $DEBUG;

if (uc($manifest_type) eq "TRUSEQ") {
	if (scalar(keys %amplicon_probes)!=scalar(keys %amplicon_targets) || 0) {
		print "# ERROR: Manifest file parsing! Nb of Amplicons incoherent\n";
		pod2usage();
		exit 1;
	} else {
		while ((my $probeID, my $probeInfo) = each(%amplicon_probes)){
			#print "# Amplicon:$probeID\t".$$probeInfo{"DLSO Sequence"}."\n" if $DEBUG;
			#$amplicons{$probeID}{}="";
			my $chr=$amplicon_probes{$probeID}{"Chromosome"};
			my $TargetID=$amplicon_probes{$probeID}{"Target ID"};
			#my $TargetRegionID=$amplicon_probes{$probeID}{"Target Region ID"};
			my $TargetRegionID=$amplicon_probes{$probeID}{"Target ID"}.".".$amplicon_probes{$probeID}{"Target Region ID"};
			#my $stop=$amplicon_probes{$probeID}{"End Position"};
			my $start=($amplicon_targets{$probeID}{"Start Position"}-1);
			my $stop=$amplicon_targets{$probeID}{"End Position"};
			my $probe_chr=$amplicon_targets{$probeID}{"Chromosome"};
			my $probe_strand=$amplicon_probes{$probeID}{"Probe Strand"};
			#my $probe_strand=$amplicon_targets{$probeID}{"Probe Strand"};
			#my $probe_start_position=$amplicon_targets{$probeID}{"Start Position"};
			#my $probe_stop_position=$amplicon_targets{$probeID}{"End Position"};
			my $probe_ULSO=$amplicon_probes{$probeID}{"ULSO Sequence"};
			my $probe_DLSO=$amplicon_probes{$probeID}{"DLSO Sequence"};
			my $probe_start;
			my $probe_stop;
			#if ($probe_strand == "+") {
			my $primer1_sequence=$probe_ULSO;
			my $primer2_sequence=$probe_DLSO;
			if ($probe_strand eq "-") {
				# Switch sequences
				$primer1_sequence_bis=$primer2_sequence;
				$primer2_sequence_bis=$primer1_sequence;
				# Translate sequences
				$primer1_sequence_bis=~ tr/ATGC/TACG/;
				$primer2_sequence_bis=~ tr/ATGC/TACG/;
				# Reverse sequences
				$primer1_sequence_bis=scalar reverse $primer1_sequence_bis;
				$primer2_sequence_bis=scalar reverse $primer2_sequence_bis;
				# Assign
				$primer1_sequence=$primer1_sequence_bis;
				$primer2_sequence=$primer2_sequence_bis;
			};#if
			my $primer1_start=$start;
			my $primer1_stop=$start+length($primer1_sequence);
			my $primer2_start=($stop-length($primer2_sequence));
			my $primer2_stop=$stop;
			# clipping
			my $start_clipped=($start+length($primer1_sequence)+1);
			my $stop_clipped=($stop-length($primer2_sequence));
			#} elsif ($probe_strand == "-") {
			#	$primer1_start=$primer_start_position;
			#	$primer1_stop=$primer_start_position+length($primer_ULSO);
			#} else {

			#};#if
			$BEDcontent.="$probe_chr\t$primer1_start\t$primer1_stop\t+\t$chr:$start-$stop\tForward\t$primer1_sequence\n";
			$BEDcontent.="$probe_chr\t$primer2_start\t$primer2_stop\t+\t$chr:$start-$stop\tReverse\t$primer2_sequence\n";
			$BEDcontent_amplicon.="$chr\t$start\t$stop\t$TargetID\n";
			$BEDcontent_region_clipped.="$chr\t$start_clipped\t$stop_clipped\t$TargetRegionID\t$TargetID\n";
			$BEDcontent_target.="$chr\t$start_clipped\t$stop_clipped\t+\t$TargetID\t$primer1_sequence\t$primer2_sequence\t$chr:$start-$stop\n";
		};#while
		while ((my $regionID, my $regionInfo) = each(%regions)){
			my $chr=$$regionInfo{"Chromosome"};
			my $start=($$regionInfo{"Start Position"}-1);
			my $stop=$$regionInfo{"End Position"};
			#my $TargetRegionName=$$regionInfo{"Target Region Name"};
			my $TargetRegionName=$$regionInfo{"Target Name"}.".".$$regionInfo{"Target Region ID"};
			my $ULSO_Sequence=$$regionInfo{"ULSO Sequence"};
			my $ULSO_Sequence_length=$$regionInfo{"ULSO Sequence"};
			my $DLSO_Sequence=$$regionInfo{"DLSO Sequence"};
			$BEDcontent_region.="$chr\t$start\t$stop\t$regionID\t$TargetRegionName\n";
			#$BEDcontent_region_clipped.="$chr\t$start\t$stop\t$regionID\t$TargetRegionName\n";
		};#while

	};#if
};#if



# Write BED file
open(FILE_OUTPUT, ">$output_file") || die "Problem to open the file '$output_file': $!";
switch (lc($output_type)){
	# Primers
	case("primer") {
		print FILE_OUTPUT "$BEDcontent";
	}
	# Amplicons
	case("amplicon") {
		print FILE_OUTPUT "$BEDcontent_amplicon";
	}
	# Regions
	case("region") {
		print FILE_OUTPUT "$BEDcontent_region";
	}
	# Regions Clipped
	case("region_clipped") {
		print FILE_OUTPUT "$BEDcontent_region_clipped";
	}
	# Regions Clipped
	case("target") {
		print FILE_OUTPUT "$BEDcontent_target";
	}
};#switch

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
