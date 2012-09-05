package Kindlenap::Document::PixivNovel;
use utf8;
use Mouse;
use HTML::TreeBuilder::XPath;
use URI;
use URI::QueryParam;
use JSON::XS;

extends 'Kindlenap::Document';

has id => (
    is  => 'rw',
    isa => 'Int',
    default => sub {
        my $self = shift;
        return $self->url->query_param('id');
    }
);

has user_id => (
    is  => 'rw',
    isa => 'Int',
);

sub _build_suffix {
    my $self = shift;
    return '.pn' . $self->id;
}

sub setup_config {
    my ($class, $config) = @_;
    $config->add(m_host => 'www.pixiv.net', m_path => '/novel/show.php');
}

sub scrape {
    my $self = shift;
    my $res = $self->ua->get($self->url);
    die $res->status_line unless $res->is_success;

    my $tree = HTML::TreeBuilder::XPath->new_from_content($res->decoded_content);

    my ($content_elem) = $tree->findnodes(q#id('novel_text')#);
    my $content = join '', map {
        ref $_ ? ( lc $_->tag eq 'br' ? "\n" : $_->as_text ) : $_
    } $content_elem->content_list;

    my $title = $tree->findnodes(q#//div[@class='novel-front-mainHeader']//h1/text()#).q();
       $title =~ s/^\s*|\s*$//g;
    my $author = $tree->findnodes(q#//a[starts-with(@href, '/novel/member.php')][not(img)]/text()#).q();
    my $user_id = $tree->findnodes(q#id('rpc_u_id')/text()#).q();

    $self->content($content);
    $self->title($title);
    $self->author($author);
    $self->user_id($user_id);

    $tree->delete;
}

sub rpc_get_illust {
    my ($self, $illust_id) = @_;

    my $res = $self->ua->post(
        'http://www.pixiv.net/novel/rpc_novel_illust.php', [
            mtime      => 'NaN',
            illust_ids => $illust_id,
            content_id => $self->id,
            user_id    => $self->user_id,
            x_restrict => 0,
            restrict   => 0,
        ],
        Referer => $self->url,
    );
    unless ($res->is_success) {
        warn 'rpc_novel_illust.php: ' . $res->status_line;
        return '';
    }

    my $data = decode_json $res->content;
    my ($illust_url) = $data->[0]->{html} =~ /<img[^>]+src="([^"]+)"/ or do {
        warn 'Could not parse: ' . $data->[0]->{html};
        return '';
    };
    $illust_url = URI->new($illust_url);
    $illust_url->path_query($illust_url->path);

    my $illust_file = $self->_download($illust_url, Referer => $self->url);
    return qq(<img src="$illust_file">);
}

sub _format_content_as_html {
    my ($self, $content_ref) = @_;
    $$content_ref =~ s#\[newpage\]#<mbp:pagebreak></mbp:pagebreak>#g;
    $$content_ref =~ s{\[pixivimage:(\d+)\]}{ $self->rpc_get_illust($1) }ge;
}

1;
