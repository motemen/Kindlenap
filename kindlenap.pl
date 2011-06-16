#!/usr/bin/env perl
use strict;
use warnings;
use opts;
use FindBin;
use lib "$FindBin::Bin/lib";
use Kindlenap::Document;

binmode STDOUT, ':utf8';

opts my $dir => { isa => 'Str', default => 'out', comment => 'output directroy' };

my $url = shift or die;

my $document = -e $url ? Kindlenap::Document->from_local_file($url) : Kindlenap::Document->from_url($url);
$document->outdir($dir);
$document->scrape;

my $html_file = $document->write;
print $html_file, "\n";

__END__

=head1 NAME

kindlenap.pl - Extract web pages (for kindlenap)

=head1 SYNOPSIS

kindlenap.pl [--dir dir] url
