package Utility;
# Some utilities are provided, such as stopwords, Porter stemmer
#
# Author: Guangchun Cheng
# Email: guangchuncheng@my.unt.edu

use strict;
use warnings;
use PorterStemmer;

our $VERSION = '1.00';

use base 'Exporter';
our @EXPORT = qw(loadStopwords applyStemmer checkStopwords corpusLength applyStemStopword minx maxx);

### Apply stemming and stop word removal
# @Arguments
#	$_[0]:	"STEM"(stemming) or not
#	$_[1]:	"SPWD"(stopword removal) or not
#	@_[3]:	a list of words
# @return
#	postSeq: a sequence after application of stemming and stopword removal
sub applyStemStopword{
	my ($stemming, $stopelimnt, @words) = @_;
	my @postSeq = ();
	my %stopwords = &loadStopwords();

	foreach my $word (@words){
		my $newword = $word;
		if ("SPWD" eq $stopelimnt){
			if (exists($stopwords{$word})){
				next;
			}
		}
		if ("STEM" eq $stemming){
			$newword = applyStemmer($word);
		}
		push @postSeq, $newword;
	}
	return (@postSeq);
}

### Load stopwords from a file.
# @Arguments
# @Return
#	stopwords: a hashtable of stopwords
sub loadStopwords{
	my %stopwords = ();
	my $spwdfilename = "stopwords";

	# open file for read
	open STOPWORDFILE, "<$spwdfilename";
	(-r STOPWORDFILE) || die "Cannot open $spwdfilename to load stopwords!";

	# read all lines from the file	
	my $line = "";
	while($line = <STOPWORDFILE>){
		# trim off newline sign and leading/tailing whitespace
		chomp($line); 
		$line =~s/^\s+//;
		$line =~s/\s+$//;
		if ($line ne ""){
			$stopwords{$line} = 0.1;
		}		
	}
	close STOPWORDFILE;

	return (%stopwords);
}


### Apply stemmer to text content, given by the first argument.
# @Arguments
#	$_[0]:	a word to be stemmed
# $Return
#	$stemstr: a stemmed word by Porter Stemmer
sub applyStemmer{
	my $str = $_[0];

	# initialize constants
	initialise();

	# turn to lower case before calling:
	my $word = lc $str; 
	$word = stem($word);
	
	return($word);
}

### Stopword checking. Given an array of words, return the stopwords in it
# @Arguments
#	$_[0]:	reference to an array of words
# @Return
#	@spwd:	an array of stopwords among $_[0]
sub checkStopwords{
	my @wordlist = @{$_[0]};
	my @spwd = ();
	my %stopwords = &loadStopwords();

	# if stopword, push to @spwd
	while (my $word = pop @wordlist){
		if (exists($stopwords{$word})){
			push @spwd, $word;
		}
	}

	return (reverse(@spwd));
}


### Get number of corpus in a (Word=>Frequency) hashtable
# @Argument
#	$_[0]:	reference to a hashtable of the reverted word statistics 
# $Return
#	nCorpus: length of corpus in the collection
sub corpusLength{
	my %voc = %{$_[0]};

	# get total number of words in the collection
	my $nCorpus = 0;
	foreach my $keyword (keys %voc){
		$nCorpus += $voc{$keyword};		
	}
	
	return ($nCorpus);
}

### Get minimum value in an array
sub minx{
	my @ar = @_;
	my $minVal = 65535;
	foreach my $val (@ar){
		if ($val < $minVal){
			$minVal = $val;
		}
	}
	return $minVal;
}

### Get maximum value in an array
sub maxx{
	my @ar = @_;
	my $maxVal = -65535;
	foreach my $val (@ar){
		if ($val > $maxVal){
			$maxVal = $val;
		}
	}
	return $maxVal;
}

# a module should return a true value to be loaded, or it would die()
1;
