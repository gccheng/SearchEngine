package WordFreq;
# WordFreq module gives analytic functions based on the word frequency,
# corresponding to Question 2 and Question 3.
# It uses functions in preprocessing module PreProc.
#
# Author: Guangchun Cheng
# Email: guangchuncheng@my.unt.edu

use strict;
use warnings;
use PreProc;
use Utility;

our $VERSION = '1.00';

use base 'Exporter';
our @EXPORT = qw(extractVocabulary vocabularySize topRankN halfOccurenceWordNum);

### Retrieve the vocabulary of a text collection, given by the first argument,
#### which is a directory. extractVocabulary travels all of the files in the
#### directory and return a hash table containing the vocabulary and each term's
#### frequency.
# @Arguments
#	$_[0]:	the directory containing the text collection
#	$_[1]:  (optional) filter/file name pattern
#	$_[2]:  (optional) if apply a stemmer, "STEM" or otherwise. No by default.
#	$_[3]:  (optional) if eliminate stopwords, "SPWD" or otherwise. No by default.
# %Return
#	vocab:	a hash table containing the vocabulary and the frequencies
sub extractVocabulary{
	my ($dirname, $filepatt, $stemming, $stopelimnt) = @_;
	chomp($dirname);
	chomp($filepatt);

	# All files in $dirname will be search by default
	if ($filepatt eq ""){
		$filepatt = "*";
	}
	# load stopwords in a hashtable
	my %stopwords = ();
	if ($stopelimnt eq "SPWD"){
		%stopwords = &loadStopwords();	
		#print %stopwords; print "\n";		
	}
	
	# Retrieve all files in $dirname with pattern $filepatt
	my @files = <$dirname/$filepatt>;
	#print "Files collected:\n", "@files\t", "\n";

	my %vocab = ();
	foreach my $file (@files){
		my $tagremoved = removeSGMLtag($file);
		my @tokens = tokenize($tagremoved);
		if (!@tokens){
			next;
		}
		while (my $word = pop @tokens){
			# process stopwords
			if ($stopelimnt eq "SPWD"){
				if (exists($stopwords{$word})){
					next;
				}
			}
			# apply a stemmer
			if ($stemming eq "STEM"){
				$word = applyStemmer($word);
			}
			$vocab{$word}++;
		}		
	}

	# print sorted vocabulary according to the frequency of each word
	#foreach my $w (sort {$vocab{$b} <=> $vocab{$a}} (keys %vocab)){
	#	print "$w:\t$vocab{$w}\n";
	#}

	return (%vocab);
}

### Get the vocabulary size of a text collection given by the first argument,
### which is a directory. It invokes extractVocabulary for frequency analysis.
# @Arguments
#	$_[0]:	the directory containing the text collection
#	$_[1]:  (optional) filter/file name pattern
#	$_[2]:  (optional) if apply a stemmer, "STEM" or otherwise. No by default.
#	$_[3]:  (optional) if eliminate stopwords, "SPWD" or otherwise. No by default.
# %Return
#	vocab_size: number of unique terms
sub vocabularySize{
	my %vocab = extractVocabulary(@_);
	my $vocab_size = keys %vocab;
}

### Get the top n words with the highest frequencies from a hash, which
### is referred by the first argument.
# @Arguments
#	$_[0]:	reference to a hashtable of words and their frequencies
#	$_[1]:	(optional) the number of words needed, 10 by default
# @Return
#	topNWords: a list of N words with most frequencies
sub topRankN{
	my ($vocabref, $N) = @_;
	if ($N eq ""){
		$N = 10;
	}
	my %vocab = %{$vocabref};

	my @topNWords;
	foreach my $keyword (sort {$vocab{$b} <=> $vocab{$a}} (keys %vocab)){
		if ($N == 0){
			last;
		}
		push @topNWords, $keyword;
		$N--;
	}

	return (@topNWords);
}


### Get the minimum number of unique words accounting for half of the total 
### number of words in the collection, which is outlined in the hashtable of
### word occurrence ["Word", Count], referred by the first argument
# @Arguments
#	$_[0]:	reference to a hashtable of words and their frequencies
# $Return
#	miniNum: the minimum number of words accouting for half content
sub halfOccurenceWordNum{
	my %vocab = %{$_[0]};

	# get total number of words in the collection
	my $totalWords = corpusLength(\%vocab);
	#foreach my $keyword (keys %vocab){
	#	$totalWords += $vocab{$keyword};		
	#}
	my $halfTotalWords = $totalWords/2;
	
	# get the the minimum number
	my $topFreqOccur = 0;
	my $miniNum = 0;
	foreach my $keyword (sort {$vocab{$b} <=> $vocab{$a}} (keys %vocab)){
		$topFreqOccur += $vocab{$keyword};
		$miniNum++;
		if ($topFreqOccur > $halfTotalWords){
			last;
		}
	} 
	
	return ($miniNum);
}

# a module should return a true value to be loaded, or it would die()
1;
