#!/usr/bin/perl
#
# Translate files in a folder using a Moses server (via its XML-RPC interface),
# and write the translation into an output folder with the same file names.
# 

use warnings;
use FileHandle;
use Encode;
use XMLRPC::Lite;
use utf8;
use File::Path;

if (scalar(@ARGV) < 3) {
    print "$0 <inputfile> <outputfile> <mosesserver:port>\n";
    exit -1;
}

$srcfile = $ARGV[0];
$tgtfile = $ARGV[1];
$server = $ARGV[2];

$url = "http://$server/RPC2";
$proxy = XMLRPC::Lite->proxy($url);

print "reading $srcfile, writing $tgtfile/$1\n";
open INFILE, "$srcfile";
open OUTFILE, ">$tgtfile";
binmode(OUTFILE, ":utf8");
while ($input = <INFILE>) {
    $encoded = SOAP::Data->type(string => Encode::encode("utf8",$input));
    my %param = ("text" => $encoded, "align" => "false", "report-all-factors" => "false");
    $result = $proxy->call("translate",\%param)->result;
    $output = $result->{'text'};
    $output =~ s/\|UNK\|UNK\|UNK//g;
    print OUTFILE "$output\n";
}
close INFILE;
close OUTFILE;


