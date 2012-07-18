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

if ($#ARGV < 2) {
    print "$0 <subfolder-input> <subfolder-output> <mosesserver:port>\n";
    exit -1;
}

$foldersrc = $ARGV[0];
$foldertgt = $ARGV[1];
$server = $ARGV[2];

@files = <$foldersrc/*>;

File::Path->make_path($foldertgt);

$url = "http://$server/RPC2";
$proxy = XMLRPC::Lite->proxy($url);

foreach $file (@files) {
    $file =~ /^$foldersrc\/(.*)$/;
    print "reading $file, writing $foldertgt/$1\n";
    open INFILE, "$file";
    open OUTFILE, ">$foldertgt/$1";
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
}

