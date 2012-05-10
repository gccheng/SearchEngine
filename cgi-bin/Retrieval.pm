package Retrieval;
# Retrieval module fulfills the steps in information retrieval, namely inverted term
# indexing, retrieval (score computing for query), and result ranking.
#
# Author: Guangchun Cheng
# Email: guangchuncheng@my.unt.edu

use strict;
use warnings;
use PreProc;
use WordFreq;
use Utility;

our $VERSION = '1.00';

use base 'Exporter';
our @EXPORT = qw(constructInvertedIndex computeDocLength computeSimilarity ranking 
                 computeRawTermWeight getMaxTF processQuery getDocVector);


### Construct the inverted index structure of a corpus of documents. A hash 
### table of hash table is used with the following structure:
### 		%InvertedIndex{term=>%DocTermFreq}
### Two passes are needed. First for the term frequencies, and the sencond
### for the inverse document frequencies. The document frequency is the size
### of corresponding %DocTermFreq.
# @Arguments
#	$_[0]: the directory of the corpus
#	S_[1]: reference to list of max TF of each document (hash)
#	$_[2]: (optional) if apply a stemmer, "STEM" or otherwise. No by default.
#	$_[3]: (optional) if eliminate stopwords, "SPWD" or otherwise. No by default.
# %Return
#	indexInverted: the inverted index
sub constructInvertedIndex{
	my ($dirname, $refMaxTF, $stemming, $stopelimnt) = @_;

	my %indexInverted = ();

	# Retrieve all files in $dirname with pattern $filepatt
	my @files = <$dirname/*>;

	# First pass the documents, get the term frequencies in each document
	foreach my $file (@files){
		my %TermFreq = &extractVocabulary(".", $file, $stemming, $stopelimnt);
		my $maxTF = 0;
		foreach my $term (keys %TermFreq){
			$indexInverted{$term}{$file} = $TermFreq{$term};
			if ($TermFreq{$term} > $maxTF){
				$maxTF = $TermFreq{$term};
			}
		}
		# set refMaxTF
		${$refMaxTF}{$file} = $maxTF;
	}
	return (%indexInverted);	
}

### Compute document length (after the inverted index is constructed)
# @Arguments
#	$_[0]:	the directory of the corpus
#	$_[1]:  reference to an inverted index structure
#	$_[2]:	reference to list of max TF of each document (hash)
#	$_[3]:	b/t/n: term frequency component (Document term weight)
#	$_[4]:	x/f/p: collection frequency component (Document term weight)
#	$_[5]:  (optional) if apply a stemmer, "STEM" or otherwise. No by default.
#	$_[6]:  (optional) if eliminate stopwords, "SPWD" or otherwise. No by default.
# %Return
#	%lengthTotal: the length of each document
sub computeDocLength{
	my ($dirname, $refIndex, $refMaxTFs, $termComp, $collectComp, $stemming, $stopelimnt) = @_;

	my %lengthTotal = ();

	# Retrieve all files in $dirname with pattern $filepatt
	my @files = <$dirname/*>;
	my $N = @files;

	# Second pass the documents, get the document length
	foreach my $file (@files){
		my $length = 0.0;
		my %TermFreq = &extractVocabulary(".", $file, $stemming, $stopelimnt);
		foreach my $term (keys %TermFreq){
			my $nDocFreq = scalar keys %{$refIndex->{$term}};
			my $termWeight = &computeRawTermWeight($refIndex, $refMaxTFs, $term, $N, $termComp, $collectComp, $file);
			$length += $termWeight * $termWeight;
		}
		$lengthTotal{$file} = sqrt($length);
	}
	return (%lengthTotal);	
}


### Compute similary between a query sequence and each of the documents in corpus
### using cosine similarity measurement.
# @Arguments
#	$_[0]:	reference to inverted index structure (hash table)
#	$_[1]:	reference to document length
#	$_[2]:	reference to list of max TF of each document (hash)
#	$_[3]:	query sequence
#	$_[4]:	b/t/n: term frequency component (Document term weight)
#	$_[5]:	x/f/p: collection frequency component (Document term weight)
#	$_[6]:	x/c: normalization component (Document term weight)
#	$_[7]:	b/t/n: term frequency component (Query term weight)
#	$_[8]:	x/f/p: collection frequency component (Query term weight)
#	$_[9]:  (optional) if apply a stemmer, "STEM" or otherwise. No by default.
#	$_[10]: (optional) if eliminate stopwords, "SPWD" or otherwise. No by default.
# %Reture
#	scores:	similarity score between query and each document
sub computeSimilarity{
	my ($refIndex, $refLenghtTotal, $refMaxTFs, $strQuery, $termComp, $collectComp, 
		$normalize, $termCompQuery, $collectCompQuery, $stemming, $stopelimnt) = @_;

	# preprocessing to query terms
	my @postQuery = &processQuery($strQuery, $stemming, $stopelimnt);

	my %queryVocab = ();
	my $maxQueryTF = 0;
	foreach my $qterm (@postQuery){
		$queryVocab{$qterm}++;
		if ($queryVocab{$qterm} > $maxQueryTF){
			$maxQueryTF = $queryVocab{$qterm};
		}
	}

	my %scores = ();	# hash{doc=>score} for each document
	my %candidate_doc = ();	# documents containing at least one query word
	my $N = scalar keys %{$refLenghtTotal};
	
	# retrieve documents containing at least one query word
	foreach my $term (keys %queryVocab){
		my @tmpDocs = keys %{$refIndex->{$term}};
		#print "$term:  @tmpDocs\n";
		foreach my $doc (@tmpDocs){
			$candidate_doc{$doc}++;
		}
	}

	# compute score for each candidate file
	foreach my $file (keys %candidate_doc){
		my $score = 0.0;
		foreach my $term (keys %queryVocab){
			my $queryTermWeight = computeQueryTermWeight($refIndex, $term, $N, $termCompQuery, 
							$collectCompQuery, $queryVocab{$term}, $maxQueryTF);
			my $docTermWeight = &computeRawTermWeight($refIndex, $refMaxTFs, $term, $N, $termComp, $collectComp, $file);
			$score += $docTermWeight * $queryTermWeight;
		}
		if ($normalize eq "c"){
			$score = $score / ($refLenghtTotal->{$file});
		}
		$scores{$file} = $score;
	}
	return (%scores);
}

### Sort the hashtable including the retrieved documents based on 
### the value of similarity scores. And then return the top K.
# @Arguments
#	$_[0]:	reference to the scores
#	$_[1]:	K value
# %Return
#	topK:	the top K document
sub ranking{
	my ($refScores,$K) = @_;
	my %topK = ();

	foreach my $file (sort {${$refScores}{$b} <=> ${$refScores}{$a}} (keys %{$refScores})){
		$topK{$file} = ${$refScores}{$file};
		$K--;
		if ($K<=0){
			last;
		}
	}
	return (%topK);	
}

### Compute a term's raw weight of one document (not normalized one)
# @Arguments
#	$_[0]:	reference to an inverted index structure
#	S_[1]:  reference to hash of max TF of each document (hash)
#	$_[2]:	term
#	$_[3]:	N: number of documents
#	$_[4]:	b/t/n: term frequency component
#	$_[5]:	x/f/p: collection frequency component
#	$_[6]:	document id (name)
# $Return
#	weightTerm: term weight
sub computeRawTermWeight{
	my ($refIndex, $refMaxTFs, $term, $N, $termComp, $collectComp, $document) = @_;
	my $termcomponent = 0.0;
	my $collectioncomponent = 0.0;
	my $weightTerm = 0.0;

	# raw term frequency + inverse collection frequency (TF-IDF)	
	if (($termComp eq "t") && ($collectComp eq "f")){
		if (exists(${$refIndex}{$term}{$document})){
			$termcomponent = ${$refIndex->{$term}}{$document};
		}else{
			$termcomponent = 0.0;
		}
		my $nDocFreq = scalar keys %{$refIndex->{$term}};
		if (0 == $nDocFreq){
			$collectioncomponent = 0.0;
		}else{
			$collectioncomponent = log($N/$nDocFreq) / log(2);
		}
	}
	# augmented normalized term frequency + no collection component (nx)
	if (($termComp eq "n") && ($collectComp eq "x")){
		# retrieve max tf from hash table if provided (more efficient)
		# otherwise, compute it from inverted index hash
		my $maxTF = 0;
		if (exists(${$refMaxTFs}{$document})){
			$maxTF = ${$refMaxTFs}{$document};
		}else{
			$maxTF = getMaxTF($refIndex, $document);
		}
		if (exists(${$refIndex->{$term}}{$document})){
			$termcomponent = 0.5 + 0.5*(${$refIndex->{$term}}{$document} / $maxTF);
		}else{
			$termcomponent = 0.5;
		}
		$collectioncomponent = 1.0;
	}
	# augmented normalized term frequency + inverse collection frequency
	if (($termComp eq "n") && ($collectComp eq "f")){
		# retrieve max tf from hash table if provided (more efficient)
		# otherwise, compute it from inverted index hash
		my $maxTF = 0;
		if (exists(${$refMaxTFs}{$document})){
			$maxTF = ${$refMaxTFs}{$document};
		}else{
			$maxTF = getMaxTF($refIndex, $document);
		}
		if (exists(${$refIndex->{$term}}{$document})){
			$termcomponent = 0.5 + 0.5*(${$refIndex->{$term}}{$document} / $maxTF);
		}else{
			$termcomponent = 0.5;
		}
		my $nDocFreq = scalar keys %{$refIndex->{$term}};
		if (0 == $nDocFreq){
			$collectioncomponent = 0.0;
		}else{
			$collectioncomponent = log($N/$nDocFreq) / log(2);
		}
	}	
	# raw term frequency + no inverse collection frequency	
	if (($termComp eq "t") && ($collectComp eq "x")){
		if (exists(${$refIndex}{$term}{$document})){
			$termcomponent = ${$refIndex->{$term}}{$document};
		}else{
			$termcomponent = 0.0;
		}
		$collectioncomponent = 1.0;
	}

	$weightTerm = $termcomponent * $collectioncomponent;
	return ($weightTerm);
}

### Compute a term's raw weight in the query (no need to normalize)
# @Argument
#	$_[0]:	reference to an inverted index structure
#	$_[1]:	term
#	$_[2]:	N: number of documents
#	$_[3]:	b/t/n: term frequency component
#	$_[4]:	x/f/p: collection frequency component
#	$_[5]:	raw term frequency
#	$_[6]:	max term frequency in query
# $Return
#	weightTerm: term weight
sub computeQueryTermWeight{
	my ($refIndex, $term, $N, $termComp, $collectComp, $termFreq, $maxQueryTF) = @_;
	
	my $weightTerm = 1.0;
	my $termcomponent = 1.0;
	my $collectioncomponent = 1.0;

	# raw term frequency + inverse collection frequency (TF-IDF)	
	if (($termComp eq "t") && ($collectComp eq "f")){
		my $nDocFreq = scalar keys %{$refIndex->{$term}};
		if (0 == $nDocFreq){
			$collectioncomponent = 0.0;
		}else{
			$collectioncomponent = log($N/$nDocFreq) / log(2);
		}
		$termcomponent = $termFreq;
	}

	# augmented normalized term frequency + no collection component (nx)
	if (($termComp eq "n") && ($collectComp eq "x")){
		$termcomponent = 0.5 + 0.5*($termFreq / $maxQueryTF);
		$collectioncomponent = 1.0;
	}
	
	# augmented normalized term frequency + inverse collection frequency	
	if (($termComp eq "n") && ($collectComp eq "f")){
		my $nDocFreq = scalar keys %{$refIndex->{$term}};
		if (0 == $nDocFreq){
			$collectioncomponent = 0.0;
		}else{
			$collectioncomponent = log($N/$nDocFreq) / log(2);
		}
		$termcomponent = 0.5 + 0.5*($termFreq / $maxQueryTF);
	}
	
	# binary weighted term frequency + probabilistic inverse collection frequency
	if (($termComp eq "b") && ($collectComp eq "p")){
		my $nDocFreq = scalar keys %{$refIndex->{$term}};
		if ((0 == $nDocFreq) || ($N == $nDocFreq)){
			$collectioncomponent = 0.0;
		}else{
			$collectioncomponent = log(($N-$nDocFreq)/$nDocFreq) / log(2);
		}
		$termcomponent = 0.5 + 0.5*($termFreq / $maxQueryTF);
	}

	$weightTerm = $termcomponent * $collectioncomponent;
	return ($weightTerm);
}

### Return maximum term frequency in one ducument
# @Arguments
#	$_[0]:	reference to inverted index structure
#	$_[1]:	document id
# $Return
#	maxTF:	maximum term frequency
sub getMaxTF{
	my ($refIndex, $file) = @_;
	my $maxTF = 10.0;
	foreach my $term (keys %{$refIndex}){
		my %DocTermfreq = %{$refIndex->{$term}};
		if (exists($DocTermfreq{$file})){
			if ($DocTermfreq{$file}>$maxTF){
				$maxTF = $DocTermfreq{$file};
			}
		}
	}
	return $maxTF;
}

### Preprocessing to query
# @Argument
#	$_[0]:	the query string
#	$_[1]:	(optional) "STEM" (stemming) or otherwise
#	$_[2]:	(optional) "SPWD" (stopwords removal) or otherwise
# @Return
#	@postQuery: query terms after tokenization, optional stemming
#			and stopwords removal
sub processQuery{
	my ($queryStr, $stemming, $stopelimnt) = @_;

	# tokenize the query
	my @queryArr = &tokenize($queryStr);

	# remove stopwords and stem(optinally)
	my @postQuery = &applyStemStopword($stemming, $stopelimnt, @queryArr);

	return (@postQuery);
}


###       !!!!! RESERVED  !!!!
### Return document weight vector using inverted index
# @Arguments
#	$_[0]:	reference to inverted index structure
#	$_[1]:	b/t/n: term frequency component (Document term weight)
#	$_[2]:	x/f/p: collection frequency component (Document term weight)
# @Return
#	vector:	document vector
sub getDocVector{
	my ($refIndex, $termComp, $collectComp) = @_;
	my @vector = ();
	
	foreach my $term (keys %{$refIndex}){
	}

	return (@vector);
}

# a module should return a true value to be loaded, or it would die()
1;


