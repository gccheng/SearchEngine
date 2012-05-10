package Crawler;
# This is a module for webpage collection--a web crawler. The main
# functionalities are grabing webpages and store them in variables
# or files.
#
# The configuration involved here are the parameters used by wget:
# 	-T seconds	timeout senconds
#	-t retry	retrying times
#
# Author: Guangchun Cheng
# Email: guangchuncheng@my.unt.edu

use strict;
use warnings;

our $version = '1.00';

use base 'Exporter';
our @EXPORT = qw(gCrawler extractURLs);


### Main interface for webpage crawlering. It accepts an string in
### first argument as root URL, and travel in a specific domain (the
### secon argument) in a breadth-first manner.
# @Arguments
# 	$_[0]:	the starting URL
# 	$_[1]:	the restricted domain
#	$_[2]:	number of URLs to retrieve
# 	$_[3]:	file name for storing URLs
# 	$_[4]:	folder name for storing webpages
#	$_[5]:	if print processing steps to screen
#	$_[6]:	file of webpage file id - url correspondence
# %Results
# 	%URLs:	grabbed URLs (url=>1)
sub gCrawler{
	my ($startURL, $domain, $number, $fileURL, $dirPages, $printProcess, $FileUrlCorrespond) = @_;
	my %URLs = ();
	my @qWebPages = ();
	my %hWebPages = ();
	chomp($startURL);
	push @qWebPages, $startURL; 
	$hWebPages{$startURL} = "";
	
	# check the folder to hold the temporal webpages and remove the files inside
	if ($dirPages eq ""){
		$dirPages = "tmp";
	}
	chomp($dirPages);
	unless (-d $dirPages){
		mkdir $dirPages or die "Cannot create directory $dirPages.\n";
	}

	if ($FileUrlCorrespond eq ""){
		my $FileUrlCorrespond = "file-url.txt";
	}
	open FILEURL, ">$FileUrlCorrespond";
	(-w FILEURL) || die "Cannot write File-URLs to file $FileUrlCorrespond\n";

	if (1==$printProcess){
		print "\n===>", "PageId\t(", "URL)\n";
	}
	my $pageId = 1;
	while ((@qWebPages > 0) && ($pageId<=$number)){
		my $pageUrl = shift @qWebPages;
		delete($hWebPages{$pageUrl});

		my $pageName = "$dirPages/$pageId.txt";
		
		# download webpage
		# The version of wget on CSP machine is old(2003), and it doesn't support max-redirect option,
		# which in some cases causes long time waiting and cannot be resolved even with -timeout set.
		# So here cURL is used instead.
		#my $cmd = "wget $pageUrl  -T 5 -t 2 -q -O $pageName";
		my $cmd = "curl -L -m 5 --retry 2 -s -o $pageName $pageUrl"; 
		my $result = system($cmd);
		if (-1 == $?){
	                print "Cannot download webpage $pageUrl: $?\n";
			#delete($URLs{$pageUrl});
	                next;
	        }

		# Add URLs if successfully downloaded
		$URLs{$pageUrl} = 1;
		print FILEURL "$pageId\t$pageUrl\n";

		if (1==$printProcess){
			print "===>", "$pageId\t(", "$pageUrl)\n";
		}else{
			print "$pageId.\n";
		}

		$pageId = $pageId + 1;

		# get result URLs in this page and push them into queue
		my %pageUrls = &extractURLs($pageUrl, $pageName, $domain);		

		# avoid duplicate URLs
		foreach my $url (keys %pageUrls){
			if (!exists($URLs{$url}) && !exists($hWebPages{$url})){
				#2012-4-21: For search engine, we really need to download all the webpages,
				#           not only the URLs
				#$URLs{$url} = 1;
				push @qWebPages, $url;
				$hWebPages{$url} = $pageUrl;
			}
		}	
	}
	print "\n";

	# print out URLs to file if file name is provided
	if ($fileURL ne ""){
		open URLFILE, ">$fileURL";
		(-w URLFILE) || die "Cannot write URLs to file $fileURL\n";	

		foreach my $url_write (keys %URLs){
			print URLFILE "$url_write\n";
		}
		close URLFILE;
	}

	# delete temporal folder and webpage files
	#system("rm $dirPages/*");
	#system("rmdir $dirPages");
		
	close FILEURL;
	return (%URLs);
}


### Extract URLs in a webpage page file specified as the first argument
# @Arguments
#	$_[0]:	url to the original webpage
# 	$_[1]:	locally stored webpage file name
#	$_[2]:	restricted domain for webpage indexing
# %Result
# 	%containURLs:	all URLs in file $_[0]
sub extractURLs{
	my ($pageUrl, $pageName, $domain) = @_;
	my %containURLs = ();

	# open the file for read
	unless (-e $pageName){
		return (%containURLs);
	}
	open PAGEFILE, "<$pageName";
	(-r PAGEFILE) || die "Cannot find local webpage $pageName.\n";

	# read the file into content
	my $content = "";
	while(my $line = <PAGEFILE>){
		$content .= $line;
	}
	close PAGEFILE;

	# get all URLs in the file
	while ($content =~ m/<a[^>]+href="\s*([^"]+)">/gi){
		my $str = $1; 
		chomp($str);

		# ignore mailto uri
		if (0 == index($str, "mailto:")){
			next;
		}
		# remove parameters 
		$str =~ s/\?.+$//;
		# ignore URL outside of unt.edu
		if (-1 == index($str, $domain)){
			next;
		}
		# ignore pdf (and other types of) files
		if ($str =~ m/.pdf$|.doc$|.png$|.gif$|.jpg$|.ico$|.wmv$|.avi$|.mpg4$|.cfm$|.jsp$|.asp$|.php$|.cgi$|.GBL$/i){
			next;
		}
		# remove the trailing / if any
		$str =~ s|/$||;
		# remove anchor from the address
		$str =~ s/#.+$//;		
		# complete relative URIs		
		if (-1 == index($str, "://")){
			#$str = "http://www.unt.edu/".$str;
			my $pageUrl_copy = $pageUrl;
			if ($pageUrl_copy =~ m/\.[^\/]+$/i){
				$pageUrl_copy =~ s/\/[^\/]+$//;
			}
			if ("/" eq $str){
				$str = $pageUrl_copy;
			}else{
				if (0 == index($str, "/")){
					$str = $pageUrl_copy.$str;
				}else{
					$str = $pageUrl_copy."/".$str;
				}
			}			
		}
		# not existing
		if (!exists($containURLs{$str})){
			$containURLs{$str} = $pageUrl;
		}
	}
	#my @ll = keys %containURLs;
	#foreach my $pp (@ll)	{
	#	print $pp, "\n";
	#}

	return (%containURLs);
}

# a module should return a true value to be loaded, or it would die()
1;
