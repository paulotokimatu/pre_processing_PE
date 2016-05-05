#!/usr/bin/perl 
#===============================================================================
#         FILE:  clean_solexa.pl
#  DESCRIPTION: run clean_solexa -h or perldoc
#
#      OPTIONS: run clean_solexa -h or perldoc
#       AUTHOR:  Gustavo Gilson Lacerda Costa, glacerda@lge.ibi.unicamp.br
#      COMPANY:  State University of Campinas, Institute of Biology, Laboratory of Genomics and Expression
#      VERSION:  1.0
#      CREATED:  02/17/2010 15:28:52 AM
#===============================================================================
use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case bundling);
use Pod::Usage;


my $file="";
my $file1 ="";
my $file2 ="";
my $nfilter=1;
my $minqual=0;
my $trimbegin=0;
my $trimend=0;
my $prefix = "out";
my $verbose=1;
my $help=0;
my $mincomp=-1;

my $result = GetOptions(
	"file1|1=s" =>\$file1, #file containing left mates  (fastq Illumina format)
	"file2|2=s" =>\$file2, #file containing right mates (fastq Illumina format)
	"file|f=s" => \$file, #file containing both mates interleaved (if used, file1 and file2 are ignored)
	"nfilter|n!" => \$nfilter, #Discard both mates when one (or both) of them have at least one N in the sequence
	"minqualitythreshold|q:f" => \$minqual, #Discard both mates when one (or both) of them have average quality less than minqualthreshold
	"mincomplexitythreshold|c:f" => \$mincomp, #Discard both mates when one (or both) of them have sequence complexity less than mincomplexity
	"trimbegin|b:i" => \$trimbegin, #if used, all reads are trimmed starting at trimbegin position
	"trimend|e:i" => \$trimend, #if used, all reads are trimmed ending at trimend position
        "prefix|p:s" => \$prefix, #prefix to output files (Default: out)
	"verbose|v!"   => \$verbose,   #toggles verbosity
        "help|h!"      => \$help       #displays help
)  or pod2usage( -verbose => 2, -output => ">&STDOUT" ) && exit;

if ($help) {
	pod2usage( -verbose => 2, -output => ">&STDOUT" ) && exit;
}

my $mode=paramOk();

if ( !$mode ) {
	pod2usage( -verbose => 2, -output => ">&STDOUT" ) && exit;
} else {
	if ($mode ==1) {
		open(F,"<$file") || die "Could not open $file\n";
	} else {
		open(G,"<$file1") || die "Could not open $file1\n";
		open(H,"<$file2") || die "Could not open $file2\n";
	}
}

open(P,">$prefix.paired");
open(S,">$prefix.single");
open(D,">$prefix.discarded");
my $count=0;

while (my ($hs1,$s1,$hq1,$q1,$hs2,$s2,$hq2,$q2) = getMate($mode)) {
	if ($verbose) {
		$count++;
		if (($count%1000000)==0) {
			print STDERR "Processed $count pairs of reads...\n";
		}
	}
        if (($trimbegin)||($trimend)) {
                chomp $s1;
                chomp $q1;
                chomp $s2;
                chomp $q2;

                my $len=length $s1;

                if ($trimbegin<1) { $trimbegin = 1 }
                if ($trimend > $len) { $trimend = $len }

                my $start = $trimbegin - 1;
                my $end = $trimend - $trimbegin + 1;

                $s1 = substr($s1, $start, $end) . "\n";
                $q1 = substr($q1, $start, $end) . "\n";
                $s2 = substr($s2, $start, $end) . "\n";
                $q2 = substr($q2, $start, $end) . "\n";
        }

	my ($mate1_nfilter_ok,$mate2_nfilter_ok,$mate1_qualfilter_ok,$mate2_qualfilter_ok,$mate1_comp_ok,$mate2_comp_ok,$mate1_ok,$mate2_ok)=(1,1,1,1,1,1,1,1);
	if ($nfilter) {
		if ($s1 =~ /N/) {
			$mate1_nfilter_ok=0;
		}
                if ($s2 =~ /N/) {
                        $mate2_nfilter_ok=0;
                }
	}

	if ($mincomp>-1) {
		my $len=length $s1;
		my %count1=(); my %count2=();
		$count1{$_}++ foreach split //, $s1;
		$count2{$_}++ foreach split //, $s2;
		foreach ("A","C","G","T") { $count1{$_} = 0 if (! defined $count1{$_}) };
		foreach ("A","C","G","T") { $count2{$_} = 0 if (! defined $count2{$_}) };
		my $comp1=1 - ($count1{A}/$len)**2 - ($count1{C}/$len)**2 - ($count1{G}/$len)**2 - ($count1{T}/$len)**2;
		my $comp2=1 - ($count2{A}/$len)**2 - ($count2{C}/$len)**2 - ($count2{G}/$len)**2 - ($count2{T}/$len)**2;
		if ($comp1 <= $mincomp) {
			$mate1_comp_ok=0;
		}
                if ($comp2 <= $mincomp) {
                        $mate2_comp_ok=0;
                }
	}

	if ($minqual) {
		if (avgqual($q1)<$minqual) {
			$mate1_qualfilter_ok=0;
		}
                if (avgqual($q2)<$minqual) {
                        $mate2_qualfilter_ok=0;
                }
	}
	if (!($mate1_nfilter_ok && $mate1_qualfilter_ok && $mate1_comp_ok)) {
		$mate1_ok=0;
	}
        if (!($mate2_nfilter_ok && $mate2_qualfilter_ok && $mate2_comp_ok)) {
                $mate2_ok=0;
        }

	if ($mate1_ok && $mate2_ok) {
		print P $hs1,$s1,$hq1,$q1,$hs2,$s2,$hq2,$q2;
	} elsif ($mate1_ok) {
		print S $hs1,$s1,$hq1,$q1;
		print D $hs2,$s2,$hq2,$q2;
	} elsif ($mate2_ok) {
		print S $hs2,$s2,$hq2,$q2;
		print D $hs1,$s1,$hq1,$q1;
	} else {
		print D $hs1,$s1,$hq1,$q1,$hs2,$s2,$hq2,$q2;
	}
}


if ($verbose) {
	print STDERR "Processed $count pairs of reads...\n";
	print STDERR "Finished.\n";
}

close(P);
close(S);
close(D);
close(F) if (-f $file);
close(G) if (-f $file1);
close(H) if (-f $file2);


sub avgqual {
	my $q = shift;
	chomp $q;
        my @phred= map {ord($_)-33} split //,$q;
	my $sum=0;
        for (my $i=0;$i<=$#phred;$i++) {
                $sum +=$phred[$i];
        }
	my $avg=$sum/($#phred+1);
	return $avg;
}


sub getMate {
	my $mode=shift;
	if ($mode==1) {
		my $hs1=<F> || return;
		my $s1=<F> || return;
		my $hq1=<F> || return;
		my $q1=<F> || return;
                my $hs2=<F> || return;
                my $s2=<F> || return;
                my $hq2=<F> || return;
                my $q2=<F> || return;
		return ($hs1,$s1,$hq1,$q1,$hs2,$s2,$hq2,$q2);
	} else {
                my $hs1=<G> || return;
                my $s1=<G> || return;
                my $hq1=<G> || return;
                my $q1=<G> || return;
                my $hs2=<H> || return;
                my $s2=<H> || return;
                my $hq2=<H> || return;
                my $q2=<H> || return;
                return ($hs1,$s1,$hq1,$q1,$hs2,$s2,$hq2,$q2);
	}
}

sub paramOk {
    #Checks if all required parameters were provided and if the files exist. OK=2 => 2 input files OK=1 => 1 interleaved input file
    my $ok = 0;
    if (-f $file) {
	$ok=1;
	return $ok;
    } elsif ( ( -f $file1 ) && ( -f $file2 ) ) {
	$ok=2;
	return $ok;
    } else {    
	    return $ok;
    }
}



=head1 NAME

 clean_solexa.pl

=head1 SYNOPSIS

 Use:
 clean_solexa.pl [--file1 path] [--file2 path] [--file path] [--[no]nfilter] [--minqualthreshold int]  [--mincomplexitythreshold float] [--trimbegin int] [--trimend int] [--prefix string] [--[no]verbose]]

 Examples:
 clean_solexa.pl
 	--file1 s_1_1_sequences.fastq
 	--file2 s_1_2_sequences.fastq
	--nfilter
 	--minqualthreshold 20
	--mincomplexitythreshold 0.2
	--prefix myrun

=head1 DESCRIPTION

 clean_solexa.pl is a script to automate the sequencing cleaning of Illumina sequencing data. Some sequencing runs benefit from agressively trimming reads prior to de novo assembly (or  mapping). clean_solexa.pl can discard reads containing uncalled bases (Ns), low quality or low complexity reads. It can also be configured to trim all reads at a a fixed psoition

=head1 OPTIONS

 Arguments:
 --file1            | -1  fastafile Path to fastq file containing left mates
 --file2            | -2  fastafile Path to fastq file containing right mates
 --file             | -f  fastafile Path to fastq file containing both mates interleaved
 --minqualitythreshold | -q  int       Minimum quality for a read to be kept (Default: no quality filter)
 --mincomplexitythreshold | -c  float       Minimum complexity for a read to be kept (Default: no complexity filter)
 --trimbegin        | -b  int       Trim all reads starting at trimbegin (Default: no trim)
 --trimend          | -e  int       Trim all reads ending at trimend (Default: no trim)
 --prefix           | -p string     Prefix to output files (Default: out)
 Switches:
 --[no]nfilter      | -n  string    Discard both mates when at least one of them have uncalled bases (Default: on)
 --[no]verbose      | -v  Enables or disables verbosity
 --help             | -h  Displays help message

=head1 AUTHOR

 Gustavo Gilson Lacerda Costa, < glacerda@lge.ibi.unicamp.br >.

=head1 BUGS

 Probable many.

=cut
