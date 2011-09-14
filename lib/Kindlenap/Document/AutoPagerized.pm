package Kindlenap::Document::AutoPagerized;
use Mouse;
use WWW::Mechanize::AutoPager;

extends 'Kindlenap::Document';

sub extract_html_content_from_res {
    my ($self, $res) = @_;
    if (my $pe = $self->ua->page_element) {
        $self->html_content(join '', map { $_->as_HTML } $pe->get_nodelist);
    } else {
        $self->SUPER::extract_html_content_from_res($res);
    }
}

sub scrape {
    my $self = shift;
    $self->ua->autopager->load_siteinfo;

    my @pages;
    $self->SUPER::scrape;
    push @pages, delete $self->{html_content};

    while (my $link = $self->ua->next_link) {
        sleep 1;
        $self->url($link);
        $self->SUPER::scrape;
        push @pages, delete $self->{html_content};
    }

    $self->html_content(join '<mbp:pagebreak></mbp:pagebreak>', @pages);
}

1;
