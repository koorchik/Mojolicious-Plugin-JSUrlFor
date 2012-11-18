#!/usr/bin/env perl
use Mojo::Base -strict;

use Mojolicious::Lite;
use Test::Mojo;
use Test::More;
use lib 'lib';

plugin 'JSUrlFor';

get '/js_url_for';

get '/get_test_route'             => sub { } => 'simple_route';
get '/tests/:my_id/qwer'          => sub { } => 'get_route_with_placeholder';
post '/tests/:my_id/qwer/'        => sub { } => 'post_route_with_placeholder';
any '/tests/:my_id/qwer/*relaxed' => sub { } => 'relaxed_placeholder';
any '/tests/:my_id/:my_id2'       => sub { } => 'two_placeholder';

my $routes = app->routes;
my $parent = $routes->route('/parent')->to( controller => 'Dummy' );
$parent->route('/nested/:nested_id')->to('#dummy')->name('nested');

my $t = Test::Mojo->new;

my $js_url_for_function = <<'JS_URL_FOR';
function url_for(route_name, captures) {
    var pattern = mojolicious_routes[route_name];
    if(!pattern) return route_name;
     
    // Fill placeholders with values
    if (!captures) captures = {};
    for (var placeholder in captures) { // TODO order placeholders from longest to shortest
        var re = new RegExp('[:*]' + placeholder, 'g');
        pattern = pattern.replace(re, captures[placeholder]);
    }
    
    // Clean not replaces placeholders
    pattern = pattern.replace(/[:*][^/.]+/g, '');
    
    return pattern;
}
JS_URL_FOR

my @patterns = (
    '"js_url_for":"\/js_url_for"',
    '"two_placeholder":"\/tests\/:my_id\/:my_id2"',
    '"get_route_with_placeholder":"\/tests\/:my_id\/qwer"',
    '"post_route_with_placeholder":"\/tests\/:my_id\/qwer\/"',
    '"simple_route":"\/get_test_route"',
    '"relaxed_placeholder":"\/tests\/:my_id\/qwer\/*relaxed"',
    '"nested":"\/parent\/nested\/:nested_id"',
    $js_url_for_function
);

foreach my $p ( @patterns ) {
    $t->get_ok('/js_url_for')
      ->status_is(200)
      ->content_like(qr/\Q$p\E/, "Pattern [$p] should exist") ;
}

done_testing;

__DATA__;

@@ js_url_for.html.ep
<%= js_url_for %>
