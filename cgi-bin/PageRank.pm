package PageRank;
# !/usr/bin/perl -w
# Test program for project of class CSCE 5200.001: Information Retrieval
# and Web Search. 
# This file is a simple implements of PageRank algorithm.
#
# Author: Guangchun Cheng
# Email: guangchuncheng@my.unt.edu

use strict;
use warnings;
use Crawler;

our $version = '1.00';
use base 'Exporter';
our @EXPORT = qw(pageRank);

### Compute PageRank score for each of the webpage in the downloaded
### webpage collection.
# @Arguments
#	$_[0]: directory of all the webpages
#	$_[1]: file of webpage-file-name and url correspondence
# %Result
#	%ranks: PageRank scores (hash{PageId=>score})
sub pageRank{
	my ($collection, $fileUrl) = @_;
	my %dagIN;		# In oriented hash: Vij=1 if Vi<--Vj.
	my %dagOUT;		# Out oriented hash: Vij=1 if Vi-->Vj. invert of dagIN
	my %FileId_URL;		# The correspondence of fileids and urls
	my %URL_FileId;		# Swap value-key of %FileId_URL
	my %Scores_prev;	# PageRank score at previous iteration
	my %Scores_curr;	# PageRank score at current iteration
	my $d = 0.85;		# Damping factor

	# read in file-url correspondences	
	open FILEURL, "<$fileUrl";
	(-r FILEURL) || die "Cannot open File-URLs file $fileUrl\n";
	while (my $line = <FILEURL>){
		chomp($line);
		$line =~ m/(\d+)\W+(.+)/g;
		my $fileid = $1; my $Url = $2;
		$FileId_URL{$fileid} = $Url;
		$URL_FileId{$Url} = $fileid;
	}
	close FILEURL;

	my $urlsNum = keys %URL_FileId;
	print "Total URLs: $urlsNum\n";

	# set adjacent matrix
	foreach my $fileId (keys %FileId_URL){
		my $Url = $FileId_URL{$fileId};
		my %UrlsInFile = &extractURLs($Url, $collection."/".$fileId.".txt", "unt.edu");
		foreach my $subURL (keys %UrlsInFile){
			if (exists($URL_FileId{$subURL})){
				my $subFileId = $URL_FileId{$subURL};
				if ($subFileId != $fileId){
					$dagIN{$subFileId}{$fileId} = 1;
					$dagOUT{$fileId}{$subFileId} = 1;
				}	
			}else{
				#print "$subURL not indexed!\n";
			}
		}
	}

	# initialise the PageRank scores
	foreach my $fileId2 (keys %FileId_URL){
		$Scores_curr{$fileId2} = 0.5;
		$Scores_prev{$fileId2} = 0.5;
	}

	# interate to get page rank
	my $max_its = 20;
	my $it = 1;
	while ($it <= $max_its){
		foreach my $fileId3 (keys %FileId_URL){
			my $inWeights = 0.0;
			my $refInPages = $dagIN{$fileId3};
			foreach my $j (keys %$refInPages){
				$inWeights += $Scores_prev{$j}/(&InOut($j, \%dagOUT));
			}
			$Scores_curr{$fileId3} = (1-$d)+$d*$inWeights;
		}
		%Scores_prev = %Scores_curr;	
		$it++;	
	}

	return (%Scores_curr);
}

### Obtain number of predecessors/successor of pave Vi
# @Arguments
#	$_[0]: webpage file_id
#	$_[1]: reference to adjacent matrix M(hash of hash). 
#	       See PageRank on Wikipedia for M.
# $Return
#	$InOutVi: number of predecessors/successor of pave Vi
sub InOut{
	my ($fileId, $refM) = @_;

	my $InOutVi = 0;
	if (exists($refM->{$fileId})){
		my %InOutPages = %{$refM->{$fileId}};
		$InOutVi = keys %InOutPages;
	}

	return ($InOutVi);
}

1;
