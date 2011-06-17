#!/usr/bin/env perl
use strict;
use warnings;
use opts;
use FindBin;
use lib "$FindBin::Bin/lib";
use Kindlenap::Document;

binmode STDOUT, ':utf8';

opts my $out_dir => { isa => 'Str', default => 'out', comment => 'output directroy' },
     my $verbose => { isa => 'Bool', default => 0, comment => 'set verbose' };

my $url = shift or die 'url required';

my $document = -e $url ? Kindlenap::Document->from_local_file($url) : Kindlenap::Document->from_url($url);
$document->out_dir($out_dir);
$document->verbose($verbose);
$document->scrape;

my $html_file = $document->write;
print $html_file, "\n";

__END__

=head1 NAME

kindlenap.pl - Extract web pages (for kindlenap)

=head1 SYNOPSIS

kindlenap.pl [--dir dir] url
