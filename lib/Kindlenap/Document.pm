package Kindlenap::Document;
use utf8;
use autodie;
use Mouse;
use MouseX::Types::Path::Class;
use LWP::UserAgent;
use HTML::Entities;
use HTTP::Config;
use Encode;
use Encode::Guess qw(euc-jp shiftjis);
use Encode::Locale;
use File::Util qw(escape_filename);
use Path::Class;

has ua => (
    is  => 'rw',
    isa => 'LWP::UserAgent',
    default => sub { LWP::UserAgent->new },
);

has outdir => (
    is  => 'rw',
    isa => 'Path::Class::Dir',
    coerce => 1,
    default => sub {
        require FindBin;
        return  dir($FindBin::Bin)->subdir('out');
    },
);

has content => (
    is  => 'rw',
    isa => 'Str'
);

has title => (
    is  => 'rw',
    isa => 'Str',
);

has author => (
    is  => 'rw',
    isa => 'Str',
);

has suffix => (
    is  => 'rw',
    isa => 'Str',
    lazy_build => 1,
);

sub _build_suffix { '' }

sub config {
    my $class = shift;

    no strict 'refs';
    return ${"$class\::Config"} ||= do {
        use strict;
        my $config = HTTP::Config->new;
        $class->setup_config($config);
        $config;
    };
}

sub setup_config {
    my ($class, $config) = @_;
}

sub from_local_file {
    my ($class, $file) = @_;

    my ($title) = file($file)->basename =~ /^([^\.]+)/;
    open my $fh, '<', $file;
    return $class->new(
        content => decode(guess => do { local $/; scalar <$fh> }),
        title   => decode(locale => $title),
    );
}

sub _format_content_as_html {
    my ($self, $content_ref) = @_;
}

sub format_as_html {
    my $self = shift;

    my $content = encode_entities $self->content, q("&<>);
       $content =~ s/\r?\n/<br>\n/g;
    $self->_format_content_as_html(\$content);

    my $title  = encode_entities $self->title, q("&<>);
    my $author = encode_entities $self->author, q("&<>);

    return <<__HTML__
<html>
  <head>
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
    <meta name="author" content="$author" />
    <title>$title</title>
  </head>
  <body>$content</body>
</html>
__HTML__
}

sub html_file {
    my $self = shift;
    $self->outdir->file($self->title . $self->suffix . '.html');
}

sub write {
    my $self = shift;
    my $html_file = $self->html_file;

    open my $fh, '>:utf8', $html_file;
    print $fh $self->format_as_html;
    close $fh;

    return $html_file;
}

sub _download {
    my ($self, $url, %args) = @_;

    my $file = $self->outdir->file(escape_filename($url->host . $url->path)); # remove query string
    unless (-e $file) {
        $self->outdir->mkpath;

        my $res = $self->ua->get($url, %args);
        warn "$url " . $res->status_line and return if $res->is_error;

        open my $fh, '>', $file;
        print $fh $res->content;
    }

    return $file;
}

1;
