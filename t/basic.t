#!/usr/bin/env perl
use Mojo::Base -strict;

use Mojolicious::Lite;
use Test::Mojo;
use Test::More;
use lib 'lib';

plugin 'JSUrlFor';

get '/js_url_for';

get '/get_test_route'             => sub { } => 'my_route-1';
get '/tests/:my_id/qwer'          => sub { } => 'my_route-2';
post '/tests/:my_id/qwer/'        => sub { } => 'my_route-3';
any '/tests/:my_id/qwer/*relaxed' => sub { } => 'my_route-4';
any '/tests/:my_id/:my_id2'       => sub { } => 'my_route-5';

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
    '"my_route-5":"\/tests\/:my_id\/:my_id2"',
    '"js_url_for":"\/js_url_for"',
    '"my_route-2":"\/tests\/:my_id\/qwer"',
    '"my_route-3":"\/tests\/:my_id\/qwer\/"',
    '"my_route-1":"\/get_test_route"',
    '"my_route-4":"\/tests\/:my_id\/qwer\/*relaxed"',
    $js_url_for_function
);

$t->get_ok('/js_url_for')->status_is(200)->content_like(qr/\Q$_\E/) for @patterns;

done_testing;

__DATA__;

@@ js_url_for.html.ep
<%= js_url_for %>
