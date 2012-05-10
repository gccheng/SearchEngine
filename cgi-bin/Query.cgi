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
my $myQuery = $query->param("QUERY");

# run my search engine and collect the results
# - the query read from the Web interface is stored in $myQuery
# - the search engine returns a list of documents, which is
# stored in @myResults
# undef($myResults);
my $perlcmd = "$searchEngine"." \"$myQuery\"";
my @myResults = `$perlcmd`;

my $numResults = @myResults/3;
my $time_diff = time() - $start_time;


print "Content-type: text/html\n\n";

print <<END_HTML_A; 

<HTML> 
<HEAD> 
<TITLE>Search Engine Test Interface</TITLE> 
</HEAD> 

<BODY BGCOLOR="#FFFFFF" TEXT="#000000" VLINK="#880044" ALINK="#000000" LINK="#0000FF">
<DIV ALIGN="CENTER">
<FORM ENCTYPE="multipart/form-data" METHOD="POST" NAME="queryForm" ACTION="Query.cgi">
<TABLE WIDTH="600" BORDER="0" CELLPADDING="3" CELLSPACING="5">

	<TR>
		<TH BGCOLOR="FF3030" COLSPAN="3"><FONT SIZE="5" COLOR=WHITE FACE="ARIAL,HELVETICA">Search \@UNT</FONT></TH>
	</TR>

	<TR>
	        <TD COLSPAN="3"><FONT SIZE="-1" FACE="ARIAL,HELVETICA"> </FONT></TD>
	</TR>

	<TR>
		<TD COLSPAN="3"><FONT SIZE="-1" FACE="ARIAL,HELVETICA">	<B>Your query:</B><BR>
			<INPUT NAME="QUERY" SIZE="50" MAXLENGTH="100" VALUE="$myQuery">
			<INPUT TYPE="SUBMIT" VALUE="Submit"></TD>
		<BR><BR>		
	</TR>

	<TR>
		<TD COLSPAN="3" ALIGN="RIGHT"><FONT SIZE="-1" FACE="ARIAL,HELVETICA"> <FONT SiZE="1">$numResults results ($time_diff seconds)</FONT> </TD>
	</TR>

END_HTML_A

	my $i=0;
	my $items = @myResults;
	while ($i < $items){
		my $url = $myResults[$i];
		my $score = sprintf("%.3f", $myResults[$i+1]);
		my $title = $myResults[$i+2];

		my $lenURL = length($url);
		my $lenTitle = length($title);
		if ($lenURL>50){
			$url = substr($url,0, 25)." ... ".substr($url,$lenURL-25,25);
		}
		if ($lenTitle>70){
			$title = substr($title, 0, 35)." ... ".substr($title,$lenTitle-35,35);
		}

		print "<TR>\n";
			print "<TD>$score</TD>\n";
			print "<TD COLSPAN=\"2\"><a href=\"$url\" target=\"_blank\">$title</a><BR><FONT SIZE=\"2\">$url</FONT></TD>\n";
		print "</TR>\n";
		$i = $i + 3;
	}

print <<END_HTML_B;
	<TR>
		<TD COLSPAN="3" ALIGN="CENTER">
			<FONT SIZE="-1" FACE="ARIAL,HELVETICA">
				<HR SIZE="1" NOSHADE>
				<P ALIGN="CENTER">
				<A HREF="http://www.cse.unt.edu/~rada/CSCE5200/">CSCE 5200 Information Retieval and Web Search</A> </P> 
			</FONT>
		</TD>
	</TR>
</TABLE>
</FORM>
</DIV>
</BODY>
</HTML> 

END_HTML_B
