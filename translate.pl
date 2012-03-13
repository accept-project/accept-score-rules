#!/usr/bin/perl
use warnings;
use FileHandle;
use IPC::Open3;
use Encode;
use XMLRPC::Lite;
use utf8;

if ($#ARGV < 2) {
    print "$0 <subfolder-input> <subfolder-output> <mosesserver:port>\n";
    exit -1;
}

$foldersrc = $ARGV[0];
$foldertgt = $ARGV[1];
$server = $ARGV[2];

@files = <$foldersrc/*>;

$url = "http://$server/RPC2";
$proxy = XMLRPC::Lite->proxy($url);

foreach $file (@files) {
    next unless ($file =~ /^$foldersrc\/(.*)$/);
    print "reading $file, writing $foldertgt/$1\n";
    open INFILE, "$file";
    open OUTFILE, ">$foldertgt/$1";
    while ($input = <INFILE>) {
	$encoded = SOAP::Data->type(string => Encode::encode("utf8",$input));
	my %param = ("text" => $encoded, "align" => "false", "report-all-factors" => "false");
	$result = $proxy->call("translate",\%param)->result;
	$output = $result->{'text'};
        print OUTFILE "$output\n";
    }
    close INFILE;
    close OUTFILE;
}

