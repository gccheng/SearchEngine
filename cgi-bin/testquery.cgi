#!/usr/bin/perl
# Sample CGI interface for a search engine
# Rada, 04/25/2006 

use strict;
use warnings;

use CGI qw(:standard);
use CGI::Carp qw(warningsToBrowser fatalsToBrowser);

##=============== VARIABLES YOU MIGHT NEED TO CHANGE======================
# Set this to the working directory
my $workingDir = "/home/gc0115/public_html";

# Set this to the name of your search-engine program
my $searchEngine = "perl SearchEngine";
#==========================================================================

## CALL THE SEARCH ENGINE
my $query = new CGI; 
my $start_time = time();

# read the query from the Web interface
my $myQuery = $query->param("QUERY_0");

# run my search engine and collect the results
# - the query read from the Web interface is stored in $myQuery
# - the search engine returns a list of documents, which is
# stored in @myResults
# undef($myResults);
my $perlcmd = "$searchEngine"." \"$myQuery\"";
my @myResults = `$perlcmd`;

my $numResults = @myResults/3;
my $time_diff = time() - $start_time;

my $urlsPerPage = 15;
my $numPages = $numResults/$urlsPerPage;

my $content = "<div align=\"center\">\n";

my @frames = ();

for(my $currpage=0; $currpage<$numPages; $currpage++){
	my $frame = "<HTML>\n";
	$frame = $frame."<HEAD>\n";
	$frame = $frame."<script type=\"text/javascript\">\n function reloadOnceOnly() {if (!top.reloaded) {top.reloaded = true;  	self.location.reload();} }\n";
	$frame = $frame."function clicksearch(){top.reloaded = false;}\n";
	$frame = $frame."</script>\n";
	$frame = $frame."</HEAD>\n";

	$frame = $frame."<BODY onload=\"reloadOnceOnly();\" ><BR><BR>\n<div align=\"center\">\n";
	$frame = $frame."<FORM ENCTYPE=\"multipart/form-data\" METHOD=\"POST\" NAME=\"queryForm\" ACTION=\"testquery.cgi\" >\n";
	$frame = $frame."<TABLE  WIDTH=\"600\" BORDER=\"0\" CELLPADDING=\"3\" CELLSPACING=\"5\">\n";

	# header
	$frame = $frame."<TR><TH BGCOLOR=\"FFFFFF\" COLSPAN=\"3\"><a href=\"http://students.csci.unt.edu/~gc0115/\" style=\"text-decoration:none\" ><FONT SIZE=\"5\" COLOR=BLACK FACE=\"ARIAL,HELVETICA\"><B>Search \@UNT</B></FONT></a></TH></TR>\n";
	$frame = $frame."<TR><TD COLSPAN=\"3\"><FONT SIZE=\"-1\" FACE=\"ARIAL,HELVETICA\"> </FONT></TD></TR>\n";
	$frame = $frame."<TR><TD COLSPAN=\"3\"><FONT SIZE=\"-1\" FACE=\"ARIAL,HELVETICA\"><B>Your query:</B><BR>";
	$frame = $frame."<INPUT NAME=\"QUERY_$currpage\" SIZE=\"50\" MAXLENGTH=\"100\" VALUE=\"$myQuery\">\n";
	$frame = $frame."<INPUT TYPE=\"SUBMIT\" VALUE=\"Search\" onclick=\"clicksearch();\" ></TD><BR></TR>\n";

	# statistics
	$frame = $frame."<TR><TD COLSPAN=\"3\" ALIGN=\"RIGHT\"><FONT SIZE=2>$numResults results ($time_diff seconds)</FONT></TD></TR>\n";

	# search results in this frame
	my $offset = $currpage * $urlsPerPage * 3;
	my $i=0;
	while (($i < $urlsPerPage*3) && ($offset+$i+2<$numResults*3)){
		my $url = $myResults[$offset+$i];
		my $score = sprintf("%.3f", $myResults[$offset+$i+1]);
		my $title = $myResults[$offset+$i+2];

		my $lenURL = length($url);
		my $lenTitle = length($title);
		my $urlToShow = $url;
		if ($lenURL>50){
			$urlToShow = substr($url,0, 25)." ... ".substr($url,$lenURL-25,25);
		}
		if ($lenTitle>70){
			$title = substr($title, 0, 35)." ... ".substr($title,$lenTitle-35,35);
		}else{
			if ($lenTitle<=1){
				$title = "No title";
			}
		}

		$frame = $frame."<TR>\n"."<TD>$score</TD>\n"."<TD COLSPAN=\"2\"><a href=\"$url\" target=\"_blank\">$title</a><BR><FONT SIZE=\"2\">$urlToShow</FONT></TD>\n"."</TR>\n";

		$i = $i + 3;
	}
	
	$frames[$currpage] = $frame;

	# footer
	#$frame = $frame."<TR><TD COLSPAN=\"3\" ALIGN=\"CENTER\"><FONT SIZE=\"-1\" FACE=\"ARIAL,HELVETICA\">\n";
	#$frame = $frame."<HR SIZE=\"1\" NOSHADE><P ALIGN=\"CENTER\"><A HREF=\"http://www.cse.unt.edu/~rada/CSCE5200/\">CSCE 5200 Information Retieval and Web Search</A></P></FONT></TD></TR>\n";

	#$frame = $frame."</TABLE>\n</div>\n</FRAME><BODY>\n</HTML>\n";

	#system("rm frame_$currpage.html");

	#open FILE, ">frame_$currpage.html";
	#(-w FILE) || die "Cannot retrieve page frame\n";
	#print FILE "$frame\n";
	#close FILE;

	$content = $content."<a href =\"frame_$currpage.html\" target =\"showresults\">$currpage</a>\n";

}

$content = $content."</DIV>\n"; #</BODY></HTML>\n";
#open FILE, ">contents.html";
#(-w FILE) || die "Cannot create navigation\n";
#print FILE "$content\n";
#close FILE;

for(my $currpage=0; $currpage<$numPages; $currpage++){
	my $frame_nav = $frames[$currpage];
	$frame_nav = $frame_nav."<TR><TD COLSPAN=\"3\" ALIGN=\"CENTER\">".$content."</TD></TR>\n";
	
	# footer
	$frame_nav = $frame_nav."<TR><TD COLSPAN=\"3\" ALIGN=\"CENTER\"><FONT SIZE=\"-1\" FACE=\"ARIAL,HELVETICA\">\n";
	$frame_nav = $frame_nav."<HR SIZE=\"1\" NOSHADE><P ALIGN=\"CENTER\"><A HREF=\"https://sites.google.com/site/chengguangchun/\">Guangchun Cheng \@ University of North Texas</A></P></FONT></TD></TR>\n";

	$frame_nav = $frame_nav."</TABLE>\n</div>\n</FRAME><BODY>\n</HTML>\n";

	system("rm frame_$currpage.html");

	open FILE, ">frame_$currpage.html";
	(-w FILE) || die "Cannot retrieve page frame\n";
	print FILE "$frame_nav\n";
	close FILE;
}

my $currpage=0;

print "Content-type: text/html\n\n";

print "<HTML>\n";
print "<HEAD>\n";

#top.reloadOnceOnly()

print <<JSCRIPT;
<script type="text/javascript">
	var reloaded = false;
#	function reloadOnceOnly() {
#    		if (!reloaded) {
#        		reloaded = true;
#        		window.showresults.location.reload();
#    		}
#	}
#
#	function clicksearch(){
#		reloaded = false;
#	}
</script>
JSCRIPT

print "</HEAD>\n";

print "<FRAMESET border=\"0\" name=\"framesetresults\" >\n\n";
print "<FRAME src=\"frame_0.html\" name=\"showresults\" />\n\n";

#print "<FRAME src=\"contents.html\" name=\"showresults\"  />\n\n";
#print "<FRAME src=\"footer.html\" />\n\n";

print "</FRAMESET>\n\n";

print "</HTML>\n\n";
