package Kindlenap::Document;
use utf8;
use autodie;
use Mouse;
use MouseX::Types::URI;
use MouseX::Types::Path::Class;
use Class::Load qw(load_class);
use URI;
use LWP::UserAgent;
use HTML::Entities;
use HTTP::Config;
use Encode;
use Encode::Guess qw(euc-jp shiftjis);
use Encode::Locale;
use Path::Class;
use File::Util qw(escape_filename);

has url => (
    is  => 'rw',
    isa => 'URI',
    coerce   => 1,
);

has ua => (
    is  => 'rw',
    isa => 'LWP::UserAgent',
    lazy    => 1,
    default => sub { LWP::UserAgent->new },
);

has out_dir => (
    is  => 'rw',
    isa => 'Path::Class::Dir',
    coerce  => 1,
    lazy    => 1,
    default => sub {
        require FindBin;
        return  dir($FindBin::Bin)->subdir('out');
    },
);

has verbose => (
    is  => 'rw',
    isa => 'Bool',
    default => 0,
);

has with_media => (
    is  => 'rw',
    isa => 'Bool',
    default => 1,
);

has content => (
    is  => 'rw',
    isa => 'Str'
);

has html_content => (
    is  => 'rw',
    isa => 'Str',
);

has title => (
    is  => 'rw',
    isa => 'Str',
);

has author => (
    is  => 'rw',
    isa => 'Maybe[Str]',
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

sub from_url {
    my ($class, $url, %args) = @_;

    my $libdir = file(__FILE__)->dir->parent;
    foreach ($libdir->subdir('Kindlenap', 'Document')->children) {
        my $pkg = $_->relative($libdir);
        $pkg =~ s<\.pm$><> or next;
        $pkg =~ s</><::>g;
        load_class $pkg;
        if ($pkg->config->matching($url)) {
            $class = $pkg;
            last;
        }
    }

    return $class->new(url => $url);
}

sub from_local_file {
    my ($class, $file, %args) = @_;

    my ($title) = file($file)->basename =~ /^([^\.]+)/;
    open my $fh, '<', $file;
    return $class->new(
        content => decode(guess => do { local $/; scalar <$fh> }),
        title   => decode(locale => $title),
    );
}

sub scrape {
    my $self = shift;

    return if $self->html_content || $self->content;

    my $res = $self->ua->get($self->url);
    die $res->status_line if $res->is_error;

    require HTML::HeadParser;
    my $parser = HTML::HeadParser->new;
    $parser->parse($res->decoded_content);

    $self->title($parser->header('Title') || $self->url.q());
    $self->author($parser->header('X-Meta-Author'));

    if ($res->content_type =~ m(^text/plain\b)) {
        $self->content($res->decoded_content);
    } else {
        require HTML::ExtractContent;

        my $extractor  = HTML::ExtractContent->new;
        $extractor->extract($res->decoded_content);
        $self->html_content($extractor->as_html);

        if ($self->with_media) {
            require HTML::TreeBuilder::XPath;
            my $tree = HTML::TreeBuilder::XPath->new_from_content($self->html_content);
            foreach ($tree->findnodes('//img[@src]')) {
                my $href = $_->attr('src');
                my $url = URI->new_abs($href, $res->base);
                my $path = $self->_download($url);
                $_->attr(src => $path);
            }
            $self->html_content($tree->as_HTML);
            $tree->delete;
        }
    }
}

sub content_as_html {
    my $self = shift;

    my $content = encode_entities $self->content, q("&<>);
       $content =~ s/\r?\n/<br>\n/g;
    $self->_format_content_as_html(\$content);
    return $content;
}

sub _format_content_as_html {
    my ($self, $content_ref) = @_;
    # override
}

sub format_as_html {
    my $self = shift;

    my $content = $self->html_content || $self->content_as_html;
    my $title   = encode_entities($self->title,  q("&<>)) || '';
    my $author  = encode_entities($self->author, q("&<>)) || '';

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

sub basename {
    my $self = shift;
    return escape_filename($self->title . $self->suffix);
}

sub html_file {
    my $self = shift;
    return $self->out_dir->file($self->basename . '.html');
}

sub download_dir {
    my ($self, %args) = @_;
    return $self->out_dir->subdir($self->basename . '.files');
}

sub write {
    my $self = shift;
    my $html_file = $self->html_file;

    $html_file->dir->mkpath;

    open my $fh, '>:utf8', $html_file;
    print $fh $self->format_as_html;
    close $fh;

    return $html_file;
}

# returns relative path
sub _download {
    my ($self, $url, %args) = @_;

    my $file = $self->download_dir->file(escape_filename($url->host . $url->path)); # remove query string
    unless (-e $file) {
        $file->dir->mkpath;

        my $res = $self->ua->get($url, %args);
        warn "$url " . $res->status_line and return if $res->is_error;

        open my $fh, '>', $file;
        print $fh $res->content;

        warn "$url => $file\n" if $self->verbose;
    }

    return $file->relative($self->out_dir);
}

1;
