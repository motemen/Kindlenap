#!/usr/bin/env perl
use strict;
use warnings;
use opts;
use FindBin;
use Encode::Locale;

use lib "$FindBin::Bin/lib";
use Kindlenap::Document;

binmode STDIN,  ':encoding(console_in)';
binmode STDOUT, ':encoding(console_out)';

Encode::Locale::decode_argv;

opts my $out_dir => { isa => 'Str',  comment => 'output directroy [out]', default => 'out', },
     my $title   => { isa => 'Str',  comment => 'set title' },
     my $author  => { isa => 'Str',  comment => 'set author' },
     my $verbose => { isa => 'Bool', comment => 'set verbosity', default => 0 },
     my $xpath   => { isa => 'Str',  comment => 'specify xpath for extract'  },
     my $document_class => { isa => 'Str', comment => 'set document class' };

my $url = shift;

my $document;

if (not defined $url) {
    $document = Kindlenap::Document->new(suffix => '.stdin', content => do { local $/; <STDIN> });
} elsif (-e $url) {
    $document = Kindlenap::Document->from_local_file($url);
} else {
    if ($document_class) {
        $document_class = Kindlenap::Document->load_document_class($document_class);
    } else {
        $document_class = Kindlenap::Document->class_from_url($url);
    }
    $document = $document_class->new(url => $url);
}

$document->out_dir($out_dir);
$document->title($title)   if defined $title;
$document->author($author) if defined $author;
$document->xpath($xpath)   if defined $xpath;
$document->verbose($verbose);
$document->scrape;

my $html_file = $document->write;
print $html_file, "\n";

__END__

=head1 NAME

kindlenap.pl - Extract web pages (for kindlenap)

=head1 SYNOPSIS

kindlenap.pl [--out-dir dir] [--title title] [--author author] [--verbose] url
