#!/usr/bin/perl
###############################
# Clipping Amplicons' Primers #
# Author: Antony Le Béchec    #
# Copyright: IRC              #
###############################

## Main Information
#####################

our %information = ( #
	'name'		=>  	"Base Quality CHange for Soft Clip",	# Name
	'release'	=>  	"0.9b",	# Release
	'script'	=>  	basename($0),	# Script name
	#'beta'		=>  	"beta",		#
	'date'		=>  	"20190322",	# Date
	'author'	=>  	"ALB",		# Author
	'copyright'	=>  	"HUS",		# Copyright
	'licence'	=>  	"GNUAGPL",	# Licence
);

our %realse_note = (
	"0.9/20190322"	=>	"Create Script"
);

# TODO
# mark as unaligned (CIGAR=* )

use Getopt::Std;
use POSIX;
use Time::HiRes qw/ time sleep /;
use Data::Dumper;
use File::Basename;

$usage = "\nusage: samtools view <BAM> -h | perl $0 | samtools view -O BAM > <BAM> \n\n".
        "".basename($0)." Change base quality to 0 for soft clipped bases.\n\n".
        "Version: ".$information{"release"}."\n".
        "Copyright © ".$information{"copyright"}." (".$information{"licence"}." licence)\n\n".
        "options:\n".
         #"-a [ATCG]+,[ATCG]+(,pos)	look for sequence ^[ATCG]+.*[ATCG]+.*\$ in read if at position 'pos' (option, format chr?:1000-2000), as for option -B\n".
         #"-t type of input     		Input type is either 'FASTQ' or 'SAM' (default)\n".
         #"-l min read length		minimum length of the read (default 10)\n".
         #"-s strinct output		output only read matching the a primer binome TODO\n".
         #"-m mode of clipping		Either 'O' to do nothing, 'Q' for changing quality by '#' (default ''). TODO 'X' for removing, 'N' for changing bases and quality\n".
         #"-c change CIGAR		Change the CIGAR string (default 1) TODO\n".
         #"-p perfect match		Applied Perfect matching (default 1)\n".
         #"-w window match		Applied Window matching (default 1)\n".
         #"-k window match half		Applied Window matching Half (default 1), i.e. one primer full length and the other windowed\n".
         #"-f window match full		Applied Window matching Full (default 0), i.e. both primers windowed\n".
         #"-e window & mismatch		Applied Window matching with 1 mismatch (default 0), i.e. both primers windowed\n".
         #"-r Speed up mismatch 		SpeedUp Window matching with 1 mismatch (default 0), by using onlys shortest primers (see -n option) \n".
         #"-o window match full		Applied Heuristic (default 1), by checking 'worst' patterns and/or primers separetly\n".
	 	#"-n min window     		minimum window's length for the primer (default 0, automatic calculation of the half size of the primer)\n".
	 	#"-B start position		Theoritical position of the read (only for SAM aligned, default 0, disable)\n".
	 	#"-b start window		Range of the start position (only for SAM aligned, default 15, 0 for auto TODO (available onluy for forward))\n".
        # "-i min window     		limit minimum of the window around primers (if automatic calculation, this limit is taken into account. default 15)\n".
	 	"-d debug     			1 for debug, 0 (default) for no debug \n".
        "-v verbose     			1 for verbose, 0 (default) for no verbose \n".
        "-h help     			help\n".
        "\n";
#gunzip -c /media/data2/NGSEnv/test/clipping/HT0018/HT0018_AACCCCTC-TGTTCTCT_L001_R1_001.fastq.gz | perl /NGS/scripts/CAP.pl -a TGTGGGACCGCCCTGGGCCAGCCTCCGGCG,AGGGGAGAATTCTTGGGGCTGAG
#samtools view /media/data2/NGSEnv/test/clipping/HT0018/HT0018.unaligned.bam | perl /NGS/scripts/CAP.pl -a TGTGGGACCGCCCTGGGCCAGCCTCCGGCG,AGGGGAGAATTCTTGGGGCTGAG
#"-a [ATCG]+,[ATCG]+;[ATCG]+,[ATCG]+...     look for sequences ^[ATCG]+.*[ATCG]+.*$ in read\n";
getopts('a:m:t:d:l:s:p:w:k:f:e:h:n:r:o:B:b:c:i:v:') or die $usage;
if (!defined($opt_a) or !($opt_a =~ /^[ATCGNchr0-9XYM,;:\-]+$/)) { $opt_a = "" }
if (!defined($opt_t) or !($opt_t =~ /^FASTQ|SAM$/)) { $opt_t = "SAM"  }
if (!defined($opt_m) or !($opt_m =~ /^O|Q$/)) { $opt_m = "O"  }
if (!defined($opt_d) or !($opt_d =~ /^0|1$/)) { $opt_d = 0 }
if (!defined($opt_l) or !($opt_l =~ /^\d+$/)) { $opt_l = 0 }
if (!defined($opt_s) or !($opt_s =~ /^.*$/)) { $opt_s = 0}
if (!defined($opt_p) or !($opt_p =~ /^0|1$/)) { $opt_p = 1}
if (!defined($opt_w) or !($opt_w =~ /^0|1$/)) { $opt_w = 1}
if (!defined($opt_k) or !($opt_k =~ /^0|1$/)) { $opt_k = 1}
if (!defined($opt_f) or !($opt_f =~ /^0|1$/)) { $opt_f = 0}
if (!defined($opt_e) or !($opt_e =~ /^0|1$/)) { $opt_e = 0}
if (!defined($opt_r) or !($opt_r =~ /^0|1$/)) { $opt_r = 0}
if (!defined($opt_o) or !($opt_o =~ /^0|1$/)) { $opt_o = 1}
if (!defined($opt_n) or !($opt_n =~ /^\d+|auto$/)) { $opt_n = -1 }
if (!defined($opt_i) or !($opt_i =~ /^\d+$/)) { $opt_i = 15 }
if (!defined($opt_h) or ($opt_h = "")) { $opt_h = 0} else { $opt_h = 1}
if (!defined($opt_B) or !($opt_B =~ /^[0-9]+$/)) { $opt_B = 0}
if (!defined($opt_b) or !($opt_b =~ /^[0-9]+$/)) { $opt_b = 0}
if (!defined($opt_c) or !($opt_c =~ /^0|1$/)) { $opt_c = 1}
if (!defined($opt_v) or !($opt_v =~ /^0|1$/)) { $opt_v = 0}



if ($opt_h) {
	print "$usage\n";
	die ();
};#if

# opt_m auto
if ($opt_n eq "auto") {
	$opt_n=-1;
};#if
# Read length
#my $minReadLength_default=70;
my $minReadLength=$opt_l;
my $maxReadLength="";
if ($opt_l < 0) {
	$minReadLength=0;
};#if
# trimming mode
my $OUTPUT_MATCH_ONLY=$opt_s;
my $Match_Perfect=$opt_p;
my $Match_ProtoPatternWindows=1;
my $Match_ProtoPatternWindows_Half=$opt_k;
my $Match_ProtoPatternWindows_Full=$opt_f;
my $Match_ProtoPatternMismatch=$opt_e;
my $Match_ProtoPatternMismatch_speed=$opt_r;
my $heuristic=$opt_o;

my $format=$opt_t; # SAM or FASTQ

my $pos_window=$opt_b;

if ($format ne "SAM") {
	$opt_B=0;
	#print "$opt_B $opt_b\n"; die();
};#if

my $mode=$opt_m; # X means clip/remove; N means change base to N and quality to '#'; Q means change only quality to '#'
my $bad_b="N";
#my $bad_q="#";
my $bad_q="#";

# SOFT clipping default value
$base_q_ref=33;
$base_ce_clip="S"; # "S" for soft clip "H" for hard clip
$base_q_min=2;

$OUTPUT=1;

$DEBUG=$opt_d;
$VERBOSE=$opt_v;
if ($DEBUG) {
	$OUTPUT=0;
};#if

my $nb_reads_input=$opt_n;

#if ("$opt_a" eq "") {
#	die("# ERROR: no adapters");
#};#if

# VARIABLES
my $nb_reads=0;
my $nb_reads_step=10000;
my $nb_reads_max=100000000;
my $nb_reads_clipped=0;
my %nb_reads_clipped_bypattern;
my $nb_reads_clipped_perfect=0;
my $nb_reads_clipped_semiprotopatterns=0;
my $nb_reads_clipped_semiprotopatternsA1=0;
my $nb_reads_clipped_semiprotopatternsA2=0;
my $nb_reads_clipped_protopatterns=0;
my $show_match=0;
my $try_match=1;
#my $minReadLength=70;
my $minBeginningErrorLength=2;
#my $format="FASTQ"; # SAM or FASTQ
my $out=0;
my $OUTPUT_MATCH=0;

## Header
if ($VERBOSE) {
	warn "##############################################\n";
	warn "## Name  \t$information{'name'}\n";
	warn "## Script\t$information{'script'}\n";
	warn "## Release\t$information{'release'}/$information{'date'}\n";
	warn "## Author\t$information{'author'}\n";
	warn "## Copyright\t$information{'copyright'}\n";
	warn "##############################################\n";
	warn "\n";
	#warn "## Parameters\n";
	#warn "## \t$information{'name'}\n";
	#warn "\n";
};#if


## FUNCTIONS


# CIGAR
sub expand_CIGAR {
	my $c=$_[0];
	my $ce;
	if (defined $c) {
		#print "CIGAR: $c\n";
		my @c_split_alpha=split(/\d+/,$c);
		my @c_split_number=split("[A-Z]",$c);
		my $i=0;
		foreach my $number (@c_split_number) {
			#print "#$i ".$c_split_alpha[$i+1]." $number \n";
			if (1) {
				$ce .= ($c_split_alpha[$i+1] x $number);
			};#if
			$i++;
		};#foreach
	};#if
	return $ce;
}

sub nb_i_cigar {
#  Number of Insertion in a CIGAR string, between A and B index
	# INPUT
	my $CIGAR=$_[0];
	my $A_pos=$_[1];
	my $B_pos=$_[2];
	# Variable
	$nb_I=0;
	if ($CIGAR =~ /I/g) {
		$CIGAR_expanded=expand_CIGAR($CIGAR);
		my $i=1;
		foreach my $base (split(//,$CIGAR_expanded)) {
			if ($base eq "I") {
				if ( (!defined $A_pos || $i>=$A_pos) && (!defined $B_pos || $i<=$B_pos) ) {
					$nb_I++;
					if (defined $B_pos) {
						$B_pos++;
					};#if
				};#if
			};#if
			$i++;
		};#if
		#if ($nb_I!=0) {
		#	warn "$CIGAR\t$A_pos\t$B_pos\t$nb_I\n";
		#};#if
		return $nb_I;
	} else {
		return 0;
	};#if

}

sub position_change_CIGAR {
	# INPUT
	my $c_original=$_[0];
	my $c_new=$_[1];
	my $pos=$_[2];
	# Variables
	my $diff=0;
	my $pos_new=$pos;
	if (defined $c_original) {
		#print "$c_original => $c_new\n" if $DEBUG;
		# my $cnt = @{[$str =~ /(\.)/g]};

		@c_original_split_alpha=split(/\d+/,$c_original);
		@c_original_split_number=split("[A-Z]",$c_original);
		@c_new_split_alpha=split(/\d+/,$c_new);
		@c_new_split_number=split("[A-Z]",$c_new);

		my $c_original_i=0;
		#print "c_original_split_alpha[1]".$c_original_split_alpha[1]."\n" if $DEBUG;
		if ($c_original_split_alpha[1] eq "S") { # or H?
			$c_original_i=$c_original_split_number[0];
		};#if

		my $c_new_i=0;
		#print "c_new_split_alpha[1]".$c_new_split_alpha[1]."\n" if $DEBUG;
		if ($c_new_split_alpha[1] eq "S") { # or H?
			$c_new_i=$c_new_split_number[0];
		};#if

		# Number of I soft clipped in the original CIGAR
		my $nb_I=nb_i_cigar($c_original,$c_original_i+1,$c_new_i);

		# Difference
		$diff=($c_new_i-$c_original_i-$nb_I);

		# Extract number of I (insertion) in the soft clipped sequence


		#print "diff=$diff ($c_new_i-$c_original_i)\n" if $DEBUG;
		$pos_new=($pos+$diff);
	};#if
	return $pos_new;

}

sub compress_CIGAR {
	my $c=$_[0];
	#print "CE: $ce\n";
	#my $c=$ce;
	$c =~ s/((.)\2{0,})/ length($1) . $2  /ge;
	return $c;
}

sub clip { ## NOT USED!!!!!
	# Sequence Quality, mandatory
	my $q=$_[0];
	# Sequence CIGAR, mandatory
	my $c=$_[1];
	# Minimum Quality, default 2
	if (defined $_[2]) { $q_min=$_[3]; } else { $q_min=2 };
	# CIGAR String, either "S" or "H", default "S"
	if (defined $_[3]) { $ce_clip=$_[4]; } else { $ce_clip="S" };
	# Quality Reference, default 33
	if (defined $_[4]) { $q_ref=$_[5]; } else { $q_ref=33 };

	# Expand CIGAR
	$ce=expand_CIGAR($c);

	# output
	my $c_new;

	if (defined $ce) {

		# Read the sequence
		my $i=0;
		#my @s_split=split("",$s);
		my @q_split=split("",$q);
		my @ce_split=split("",$ce);
		my $ce_new="";
		#foreach my $base (@s_split) {
		foreach my $base_ce (@ce_split) {
			my $base_ce_new=$base_ce;
			#if ($base_ce eq "D" || $base_ce eq "H"  || $base_ce eq "I" ) {
			if ($base_ce eq "D" || $base_ce eq "H" ) {
				#$ce_new .= $base_ce;
			} else {
				my $base_q=$q_split[$i];
				#my $base=$s_split[$i];
				my $base_q_val=ord($base_q)-$base_q_ref;
				#my $base_ce_new=$base_ce;
				if ($base_q_val<=$base_q_min) { # Check if to clipped !!! eg neg ??? test also if bad quality???
					#if ($base_ce_new eq "D") { # No clip if deletion if deletion
					#	$base_ce_new="";
					#} else {
						$base_ce_new=$base_ce_clip;
					#};#if
				};#if
				$i++;

			};#if
			$ce_new .= $base_ce_new;

			#print "$base $base_q $base_q_val $base_ce $base_ce_new\n";

		};#foreach

		# Position calculation
		# Calculate the new position by counting the number of S (H?) at the begining of the read
		#    between the original and the new CIGAR string

		#print "CE   : $ce\n";
		#print "CENEW: $ce_new\n";

		# Compress CIGAR
		$c_new=compress_CIGAR($ce_new);

	};#if

	# Return
	return $c_new;
}

sub min_dist_adapter {
	my $chr_a=$_[0];	# position of the adapter
	my $pos_a=$_[1];	# position of the adapter
	my $min=$_[2];		# limit window
	my $adapters=$_[3];	# list of adapters


	#print "CHR: $chr_a	POS: $pos_a\n" if $DEBUG;
	#print Dumper(%$adapters)  if $DEBUG;
	#print $$adapters[1] if $DEBUG;
	#$c =~ s/((.)\2{0,})/ length($1) . $2  /ge;
	#return $c;

	#my $min=10000;
	foreach $adapters_binome (@$adapters) {
		#print "	$adapters_binome" if $DEBUG;
		my @adapters_binome_split_tmp=split(",",$adapters_binome);
		my @adapters_binome_split=($adapters_binome_split_tmp[0],$adapters_binome_split_tmp[1]);
		my $chr;
		my $pos;
		if (defined $adapters_binome_split_tmp[2] && $adapters_binome_split_tmp[2] ne "") {
			$chr=(split(":",$adapters_binome_split_tmp[2]))[0];
			$pos=(split("-",(split(":",$adapters_binome_split_tmp[2]))[1]))[0];
		};#if
		#print "		CHR: $chr	POS: $pos\n" if $DEBUG;
		if ($chr eq $chr_a && $pos_a != $pos) {
			my $dist=abs($pos_a-$pos);
			if ($min>$dist) {
				$min=$dist;
			};#if
		};#if

	};#foreach

	#print "		MIN=$min\n" if $DEBUG;
	return $min;

}

# ADAPTERS
my %pattern;
my %pattern_bychr;
my %pattern_H;
my %pattern_pos;
my %pattern_pos_window;
my %pattern_posstop_window;
my @adapters_list=split(";",$opt_a);
my %adapters_binome_array;
my $nb_perfect_patterns=0;
my $nb_protopatterns=0;
my $nb_protopatterns_W=0;
my $nb_protopatterns_WM=0;


#$t1_adapters=time();
#print "# Patterns Calculation\n" if $DEBUG;
my $amplicon_bad=0;
foreach $adapters_binome (@adapters_list) {
	#print "# BINOME: '$adapters_binome'\n" if $DEBUG;
	if ($adapters_binome eq "") {
		next;
	};#if
	my @adapters_binome_split_tmp=split(",",$adapters_binome);
	my @adapters_binome_split=($adapters_binome_split_tmp[0],$adapters_binome_split_tmp[1]);
	$adapters_binome_array{"left"}{$adapters_binome_split_tmp[0]}=1;
	$adapters_binome_array{"right"}{$adapters_binome_split_tmp[1]}=1;
	my $chr;
	my $pos;
	my $posstop;
	# Parsing Amplicon Definition
	if (defined $adapters_binome_split_tmp[2] && $adapters_binome_split_tmp[2] ne "") {
		$chr=(split(":",$adapters_binome_split_tmp[2]))[0];
		$pos=(split("-",(split(":",$adapters_binome_split_tmp[2]))[1]))[0];
		$posstop=(split("-",(split(":",$adapters_binome_split_tmp[2]))[1]))[1];
		$pattern_pos{$adapters_binome}=$pos;
	} else {
		$amplicon_bad++;
	};#if

	# Window around the primers
	my $pos_window_a=$pos_window;
	if ($pos_window_a <= 0) { # Auto
		#warn $adapters_binome;
		warn min_dist_adapter($chr,$pos,10000,\@adapters_list) if $DEBUG;
		$pos_window_a=floor((min_dist_adapter($chr,$pos,10000,\@adapters_list)/2))-1;
		warn $pos_window_a if $DEBUG;
		if ($pos_window_a>$opt_i) {
			$pos_window_a=$opt_i;
		};#if
	};#if

	# TODO: window upstream and downstream the primer!!!
	warn "# $adapters_binome" if $DEBUG;
	warn "START from ".($pos-$pos_window_a)." to ".($pos+$pos_window_a) if $DEBUG;
	warn "STOP  from ".($posstop-$pos_window_a)." to ".($posstop+$pos_window_a) if $DEBUG;

	# Assigning Patterns on allowed position around the potentiel primers
	if (defined $chr && defined $pos && defined $posstop) {
		# Forward
		#warn "START $pos_window_pos=$pos-$pos_window_a";
		#warn "STOP $pos_window_pos=$posstop-$pos_window_a\n";
		for ($pos_window_pos=$pos-$pos_window_a; $pos_window_pos<=($pos+$pos_window_a); $pos_window_pos++) {
			$pattern_pos_window{$chr}{$pos_window_pos}{$adapters_binome}=1;
		};#for
		# Reverse
		for ($pos_window_pos=$posstop-$pos_window_a; $pos_window_pos<=($posstop+$pos_window_a); $pos_window_pos++) {
			$pattern_posstop_window{$chr}{$pos_window_pos}{$adapters_binome}=1;
		};#for
	} else {
		$amplicon_bad++;
	};#if


};#foreach

#warn Dumper(%pattern_pos_window)  if $DEBUG;
#warn Dumper(%pattern_posstop_window)  if $DEBUG;

# PArameters
# $nb_reads_input
warn "# Number of Reads     : ".($nb_reads_input>=0?$nb_reads_input:"unknown")."\n" if $VERBOSE;
warn "# Number of Amplicons : ".@adapters_list."\n" if $VERBOSE;
warn "#    Bad definition   : $amplicon_bad\n" if $VERBOSE;
warn "#\n" if $VERBOSE;

$t1=time();
#$Mtime=0;
$m2=0;


#print "# test1\n" if $DEBUG;
my $notMatching=0;
my $NoChrPos=0;
my $outPrimerPositionWindow=0;
#$m=0;
#$in=0;
#$out=0;
my $t1_scan=time();
my $t2_scan=time();


my $ReadUnaligned=0;
my $nb_reads_match=0;
my $shortReadLength=0;
my $badPosition=0;
my $positionFiltered=0;
my $ReadWithMultiplePattern=0;
my $LengthSeqQual=0;

my $changed=0;
my $unchanged=0;

print "# READING $format FILE\n" if $DEBUG;

#warn "# READS Scanned\t\tExecTime".($nb_reads_input>=0?"/~Est.":"")."\tUnAligned\tMatching\t\tUnMatching\tTooShort|BadPosition|MultiAdapterErr|SeqQualLengthErr\n" if $VERBOSE;

$output_pattern="# %-20s%20s%20s%20s";
warn sprintf($output_pattern,"READS Scanned","ExecTime".($nb_reads_input>=0?"/~Est.":""),"Changed","UnChanged")."\n" if $VERBOSE;

if (1) {
while ($h1 = <>) {
	chomp($h1);
	#warn "$h1\n"; #next;
	if ($format eq "SAM" && substr($h1,0,1) eq "@") {
	#if (substr($h1,0,1) eq "@") {
	#if ($format eq "SAM" && substr($h1,0,1) eq "@" && ($OUTPUT) ) {
		if ($OUTPUT) {
			print "$h1\n";
		};#if
		#exit;
		next;
	};#if
	#exit;
	#$s = <>;
	#$h2 = <>;
	#$q = <>;
	my @col;
	my $CIGAR;
	my $CIGAR_original;
	my $s;
	my $s_original;
	my $q;
	my $q_original;
	my $chr="";
	my $pos="";
	my $posstop="";
	my $strand="";



	if ($DEBUG || 1) {
	if ( $nb_reads !=0 && (($nb_reads) % $nb_reads_step) == 0) {
		#print "# READS Scanned: $nb_reads\n" if $DEBUG;
		$t2_scan=time();
		#$exec_time_scan=sprintf("%.2f", ($t2_scan-$t1_scan));
		my $exec_time=sprintf("%.0f", ($t2_scan-$t1));
		#print "# Exec Time: ".$exec_time."sec\n" if $DEBUG;
		#print "# READS Scanned: ".($nb_reads)."   \tNB Match: $nb_reads_clipped   \tNB UnMatch: ".($nb_reads-$nb_reads_clipped)." (".sprintf("%.2f", (($nb_reads-$nb_reads_clipped)/$nb_reads)*100)."%)   \tExec Time: $exec_time_scan secs\n" if $DEBUG; # (P=$nb_reads_clipped_perfect, SPP=$nb_reads_clipped_semiprotopatterns(A1=$nb_reads_clipped_semiprotopatternsA1,A2=$nb_reads_clipped_semiprotopatternsA2), PP=$nb_reads_clipped_protopatterns)\n" if $DEBUG;
		#warn "# READS Scanned: $nb_reads".($nb_reads_input>=0?" (".sprintf("%.2f",(($nb_reads/$nb_reads_input)*100))."%)":"")."  \tUnAligned: $ReadUnaligned    \tMatching: $nb_reads_match (".sprintf("%.2f",(($nb_reads_match/$nb_reads)*100))."%)   \tUnMatching: ".($nb_reads-$nb_reads_match-$ReadUnaligned)." (".sprintf("%.2f",((($nb_reads-$nb_reads_match-$ReadUnaligned)/$nb_reads)*100))."%)\tTooShort: $shortReadLength\tBadPosition: $positionFiltered\tMultiAdapterErr: $ReadWithMultiplePattern\tSeqQualLengthErr: $LengthSeqQual\tExecTime: ".$exec_time."s".($nb_reads_input>=0?" (estim. ".sprintf("%.0f",(($exec_time*$nb_reads_input)/$nb_reads))."s)":"")."\n" if $VERBOSE; # (P=$nb_reads_clipped_perfect, SPP=$nb_reads_clipped_semiprotopatterns(A1=$nb_reads_clipped_semiprotopatternsA1,A2=$nb_reads_clipped_semiprotopatternsA2), PP=$nb_reads_clipped_protopatterns)\n" if $DEBUG;
		#warn "# $nb_reads".($nb_reads_input>=0?" (".sprintf("%.2f",(($nb_reads/$nb_reads_input)*100))."%)":"\t\t")."   \t".$exec_time."s".($nb_reads_input>=0?"/~".sprintf("%.0f",(($exec_time*$nb_reads_input)/$nb_reads))."s":"")."\t\t$ReadUnaligned (".sprintf("%.2f",(($ReadUnaligned/$nb_reads)*100))."%)\t$nb_reads_match (".sprintf("%.2f",(($nb_reads_match/$nb_reads)*100))."%)   \t".($nb_reads-$nb_reads_match-$ReadUnaligned)."(".sprintf("%.2f",((($nb_reads-$nb_reads_match-$ReadUnaligned)/$nb_reads)*100))."%)\t$shortReadLength|$positionFiltered|$ReadWithMultiplePattern|$LengthSeqQual\t\n" if $VERBOSE;
		warn sprintf($output_pattern,"$nb_reads".($nb_reads_input>=0?" (".sprintf("%.2f",(($nb_reads/$nb_reads_input)*100))."%)":""),$exec_time."s".($nb_reads_input>=0?"/~".sprintf("%.0f",(($exec_time*$nb_reads_input)/$nb_reads))."s":""),
			"$changed (".sprintf("%.2f",(($changed/$nb_reads)*100))."%)","$unchanged (".sprintf("%.2f",(($unchanged/$nb_reads)*100))."%)","".($nb_reads-$nb_reads_match-$ReadUnaligned)." (".sprintf("%.2f",((($nb_reads-$nb_reads_match-$ReadUnaligned)/$nb_reads)*100))."%)","$shortReadLength","$positionFiltered","$ReadWithMultiplePattern","$LengthSeqQual")."\n" if $VERBOSE;
		$t1_scan=time();

	};#if
	};#if
	$nb_reads++;

	if ($format eq "SAM") {
		@col=split("\t",$h1);
		#if ($col[2] ne "*") { print "#ERROR: SAM aligned!!! Not suported"; die();};#if SAM aligned!!!
		# CIGAR
		$CIGAR=$col[5];
		$CIGAR_original=$CIGAR;
		if (defined $CIGAR && $CIGAR ne "*") {
			$CIGAR_expanded=expand_CIGAR($CIGAR);
		} else {
			$ReadUnaligned++;
			next if $OUTPUT_MATCH_ONLY;
		};#if
		# Sequence
		$tlen=$col[8];
		$s=$col[9];
		$s_original=$s;
		# Quality
		$q=$col[10];
		$q_original=$q;
		#$name=$col[0];
		$chr=$col[2];
		$pos=$col[3];
		my $cntD = @{[$CIGAR_expanded =~ /D/g]};
		my $cntI = @{[$CIGAR_expanded =~ /I/g]};
		my $cntS = @{[$CIGAR_expanded =~ /S/g]};
		my $cntH = @{[$CIGAR_expanded =~ /H/g]};
		$posstop=$pos+length($s)+$cntD-$cntI-$cntS;	#TODO: calculate from CIGAR due to I and D
		#$posstop=$pos+length($s)+$cntD-$cntI;	#TODO: calculate from CIGAR due to I and D

		# STRAND
		$strand="?";
		#warn $tlen if $DEBUG;
		if ($tlen=~ /([-+]*)([0-9]*)/) {
			#warn "$1|$2\n" if $DEBUG;
			$strand=($1 eq "")?"+":$1;
			$len=$2;
		}; #if
		#warn $strand if $DEBUG;
		#next;


	};#if
	if ($format eq "FASTQ") {
		$s = <>;
		$h2 = <>;
		$q = <>;
		chomp($s);
		chomp($h2);
		chomp($q);
	};#if

	#warn "$chr $pos $posstop" if $DEBUG;





	if ( $nb_reads == $nb_reads_max) {
		print "# READS Scanned: $nb_reads STOP\n" if $DEBUG;
		#print "IN: $in OUT:$out\n";
		last; #die();
	};#if

	#$CIGAR_expanded =~ s/I//gi;
	$CIGAR_expanded =~ s/D//gi;
	$CIGAR_expanded =~ s/H//gi;

	if ($CIGAR ne "*") {
		if (length($CIGAR_expanded) == length($q)) {
			warn "\n" if $DEBUG;
			warn "CIGAR        $CIGAR\n" if $DEBUG;
			warn "CIGAR EXPAND $CIGAR_expanded\n" if $DEBUG;
			warn "Q            $q\n" if $DEBUG;

			my @CIGAR_expanded_split=split(//,$CIGAR_expanded);
			#my @CIGAR_expanded_split_new=@CIGAR_expanded_split;

			#my @q_split=split(//,$q);
			my @q_split_new=split(//,$q); #my @q_split_new=@q_split;

			#my @s_split=split(//,$s);
			#my @s_split_new=@s_split;
			#print "S :\t$s\n" if $DEBUG;
			#print "SS:\t@s_split\n" if $DEBUG;


			#my $pos_i;
			my $i=-1;
			foreach my $C (@CIGAR_expanded_split) {

				#print "" if $DEBUG;
				$i++;

				if ($C eq "S") {
					$q_split_new[$i]=$bad_q;
				};#if



			};#forach

			$q_new=join("",@q_split_new);

			#print "Q            $q\n" if $DEBUG;
			warn "Q NEW        $q_new\n" if $DEBUG;
			if (length($q_new) == length($q)) {
				$changed++;
				$col[10]=$q_new;
			} else {
				warn "ERROR\n" if $DEBUG;
				warn "CIGAR        $CIGAR\n" if $DEBUG;
				warn "Q            $q\n" if $DEBUG;
				warn "Q NEW        $q_new\n" if $DEBUG;
				$unchanged++;
			};#if

		} else {
			$unchanged++;
		};#if
	} else {
		$unchanged++;
	};#if

	if ($OUTPUT) {
		print join("\t",@col)."\n";
		$printed=1;
	};#if

}
};#if

print "# OUTPUT_MATCH $OUTPUT_MATCH\n" if $DEBUG;

$t2=time();

## STATS
$exec_time=sprintf("%.2f", ($t2-$t1));
warn "# STATS\n";
warn "# EXEC Time: ".$exec_time."secs\n";
warn "# READS
#   * Scanned   : $nb_reads\t
#   * Changed : $changed\t(".sprintf("%.2f",(($changed/$nb_reads)*100))."%)
#   * UnCHanged  : $unchanged\t(".sprintf("%.2f",(($unchanged/$nb_reads)*100))."%)
";
