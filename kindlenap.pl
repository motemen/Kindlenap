#!/usr/bin/env perl
use strict;
use warnings;
use opts;
use FindBin;
use lib "$FindBin::Bin/lib";

use Class::Load qw(load_class);
use Kindlenap::Document;

binmode STDOUT, ':utf8';

opts my $dir => { isa => 'Str', default => 'out', comment => 'output directroy' };

my $url = shift or die;
my $local = -e $url;

my $document_class = 'Kindlenap::Document';
unless ($local) {
    foreach (glob "$FindBin::Bin/lib/Kindlenap/Document/*.pm") {
        s<^$FindBin::Bin/lib/><>;
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
$document->outdir($dir);

$document->scrape unless $document->content;

my $html_file = $document->write;
print $html_file, "\n";

__END__

=head1 NAME

kindlenap.pl - Extract web pages to generate .mobi

=head1 SYNOPSIS

kindlenap.pl [--dir dir] [--out filename] url
