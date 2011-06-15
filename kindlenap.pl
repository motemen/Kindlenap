#!/usr/bin/env perl
use strict;
use warnings;
use opts;
use FindBin;
use lib "$FindBin::Bin/lib";

use Class::Load qw(load_class);
use Kindlenap::Document;

opts my $outdir => { isa => 'Str', default => 'out' };

my $url = shift or die;
my $local = -e $url;

my $document_class = 'Kindlenap::Document';
unless ($local) {
    foreach (glob 'lib/Kindlenap/Document/*.pm') {
        s<^lib/><>;
        s<\.pm$><>;
        s</><::>g;
        load_class $_;
        if ($_->config->matching($url)) {
            $document_class = $_;
            last;
        }
    }
}

my $document = $local ? $document_class->from_local_file($url) : $document_class->new(url => $url);
$document->outdir($outdir);

$document->scrape unless $document->content;

my $html_file = $document->write;
warn "==> $html_file\n";

system 'kindlegen', $html_file;

print $novel->title . $novel->suffix . '.mobi', "\n";
