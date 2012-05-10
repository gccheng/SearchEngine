package PreProc;
# PreProc module deals with the pre-processing to the Cranfield collection
# and other text collection, including SGML (and its derivatives) removal
# and tokenization.
#
# Author: Guangchun Cheng
# Email: guangchuncheng@my.unt.edu

use strict;
use warnings;

our $VERSION = '1.00';

use base 'Exporter';
our @EXPORT = qw(removeSGMLtag tokenize);

### This is a routine that removes the SGML tags from the document
### specified by the first argument to it.
# @Arguments
#	$_[0]:	 file name of the text ducoment
# $Return
#	$buffer: the corresponding text with SGML tags removed	 
sub removeSGMLtag{
	my $buffer = "";
	my $filename   = $_[0];
	chomp($filename);

	# open file for read
	open INFILE, "<$filename";
	(-r INFILE) || die "Cannot open SGML file!";

	# read all lines from the file	
	my $line = "";
	while($line = <INFILE>){
		$buffer .= $line;
	}

	# remove SGML tags
	$buffer =~s/<[^>]+>//g;
	
	close INFILE;
	
	return ($buffer);
}

### Tokenize the text in the first argument $_[0] with separators.
### The strategy is firstly replacing potential separators with whitespace,
### and then spliting the text using whitespace.
# @Arguments
#	$_[0]:	 string (with SGML tags removed, expected)
# @Return
#	@tokens: a list containing all the tokens in $_[0]
sub tokenize{
	my $filecontent = $_[0];
	
	# substitute whitespace (" ") for non-digit-surrounded punctuation symbols,
	# including .+-/*, etc. The reason for twice substitutes is that they remove
	# the punctuation symbols without leading- or following digits.
	$filecontent =~s/([^\d])[[:punct:]]+/$1 /g;
	$filecontent =~s/[[:punct:]]+([^\d])/ $1/g;

	# other rules if needed
	# ....

	# split the text into an array by whitespace	
	my @tokens = split /\s+/, $filecontent;
	
	return (@tokens);
}

# a module should return a true value to be loaded, or it would die()
1;



