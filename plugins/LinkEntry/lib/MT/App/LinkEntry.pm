package MT::App::LinkEntry;

use strict;
use base qw( MT::App );
use MT;
use MT::App;
use MT::Entry;

# See Also: http://www.ark-web.jp/sandbox/wiki/306.html
@MT::App::LinkEntry = qw( MT::App );

sub init_request {
    my $app = shift;
    $app->SUPER::init_request(@_) or return;
    # $app->add_methods( DispEntryByCode => \&_DispEntryByCode );
    # $app->mode('DispEntryByCode');

    $app;
}

sub _DispEntryByCode {
    my $app = shift;
    my $class = MT->model('entry');
    my $code = $app->param( 'code' );
    my $blog_id = $app->param( 'blog_id' );
    my $col = MT->config( 'LinkEntryCodeField' );
    my $type = MT::Meta->metadata_by_name($class, 'field.' . $col);

    my @entries = MT::Entry->load(
        {
            blog_id => $blog_id,
            status => MT::Entry::RELEASE()
        },
        {
            join => [
                $class->meta_pkg,
                undef,
                {
                    'entry_id' => \'= entry_id',
                    type => 'field.' . $col,
                    $type->{type} => $code
                }
            ]
        }
    );

    my $location;
    my $count = 0;
    for my $entry ( @entries ) {
        $location = $entry->permalink;
        $count += 1;
    }

    if ( defined $location && $count == 1 ) {
        $app->response_code( 302 );
        $app->set_header( 'Location' => $location );
        $app->send_http_header();
        return 1;
    }

    $app->{plugin_template_path} = 'plugins/LinkEntry/tmpl';
    my %param = (
        'count' => $count,
    );
    return $app->build_page('error.tmpl', \%param);
}

1;
