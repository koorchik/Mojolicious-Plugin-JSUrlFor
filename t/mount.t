#!/usr/bin/env perl
use Mojo::Base -strict;

use Mojolicious::Lite;
use Test::Mojo;
use Test::More;
use lib 'lib';

use FindBin;

plugin 'Mount' => { '/mounted_app' => "$FindBin::Bin/mounted_app.pl" };

get '/js_url_for';

my $t = Test::Mojo->new;

my @patterns = (
    '"js_url_for":"/mounted_app/js_url_for"',
    '"two_placeholder":"/mounted_app/tests/:my_id/:my_id2"',
    '"get_route_with_placeholder":"/mounted_app/tests/:my_id/qwer"',
    '"post_route_with_placeholder":"/mounted_app/tests/:my_id/qwer"',
    '"simple_route":"/mounted_app/get_test_route"',
    '"relaxed_placeholder":"/mounted_app/tests/:my_id/qwer/*relaxed"',
    '"nested":"/mounted_app/parent/nested/:nested_id"',
    'function url_for(route_name, captures)'
);

foreach my $p ( @patterns ) {
    $t->get_ok('/mounted_app/js_url_for')
      ->status_is(200)
      ->content_like(qr/\Q$p\E/, "Pattern [$p] should exist") ;
}

done_testing;
