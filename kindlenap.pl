#!/usr/bin/env perl
use strict;
use warnings;
use autodie;
use FindBin;
use lib "$FindBin::Bin/lib";

use Class::Load qw(load_class);
use List::MoreUtils qw(first_value);

my $url = shift or die;
my $local = -e $url;

my $document_class = first_value {
    s<^lib/><>;
    s<\.pm$><>;
    s</><::>g;
    load_class $_;
    $_->config->matching($url);
} $local ? () : glob 'lib/Kindlenap/Document/*.pm';

$document_class ||= do { require Kindlenap::Document; 'Kindlenap::Document' };

my $novel = $local ? $document_class->from_local_file($url) : $document_class->new(url => $url);

$novel->scrape unless $novel->content;

my $html_file = $novel->title . $novel->suffix . '.html';

open my $fh, '>', $html_file;
print $fh $novel->format_as_html;
close $fh;

system 'kindlegen', $html_file;
