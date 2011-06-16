package Kindlenap::Document::Fumi23;
use Mouse;
use URI::QueryParam;
use HTML::TreeBuilder::XPath;

extends 'Kindlenap::Document';

has article_id => (
    is  => 'rw',
    isa => 'Int',
    default => sub {
        my $self = shift;
        return $self->url->query_param('article_id');
    },
);

sub setup_config {
    my ($class, $config) = @_;
    $config->add(m_host => 'bbs.fumi23.com', m_path => '/show.php');
}

sub _build_suffix {
    my $self = shift;
    return '.fumi' . $self->article_id;
}

sub scrape {
    my $self = shift;
    my $res = $self->ua->get($self->url);
    die $res->status_line unless $res->is_success;

    my $tree = HTML::TreeBuilder::XPath->new_from_content($res->decoded_content);

    my $title  = $tree->findvalue('//div[@class="detailpost color2"]/h1/text()').q();
    my $author = $tree->findvalue('//p[@class="avatarid"][1]/*[1]/text()').q();
       $author =~ s/\x{fffd}//g;

    my @messages = $tree->findnodes('//div[@class="message"]//p[@class="avatarmes"]');

    $self->title($title);
    $self->author($author);
    $self->html_content(join "\n", map { $_->as_HTML } @messages);

    $tree->delete;
}

1;
