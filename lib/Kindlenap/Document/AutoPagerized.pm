package Kindlenap::Document::AutoPagerized;
use Mouse;
use WWW::Mechanize::AutoPager;

extends 'Kindlenap::Document';

sub extract_html_content_from_res {
    my $self = shift;
    if (my $pe = $self->ua->page_element) {
        $self->html_content(join '', map { $_->as_HTML } $pe->get_nodelist);
    } else {
        $self->SUPER::extract_html_content_from_res;
    }
}

sub scrape {
    my $self = shift;

    $self->ua->autopager->load_siteinfo;

    my $stop = 0;

    local $SIG{INT} = sub {
        if ($stop) {
            die;
        } else {
            print STDERR "\nCaught SIGINT; stop autopager\n";
            $stop = 1;
        }
    };

    my @pages;
    $self->SUPER::scrape;
    push @pages, delete $self->{html_content};

    while (!$stop && (my $link = $self->ua->next_link)) {
        sleep 1;
        $self->url($link);
        $self->SUPER::scrape;
        push @pages, delete $self->{html_content};
    }

    $self->html_content(join '<mbp:pagebreak></mbp:pagebreak>', @pages);
}

1;
