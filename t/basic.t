#!/usr/bin/env perl
use Mojo::Base -strict;

use Test::More tests => 3;

use Mojolicious::Lite;
use Test::Mojo;

plugin 'JSUrlFor';

get '/' => sub {
  my $self = shift;
  say $self->js_url_for();
  $self->render_text('Hello Mojo!');
};


get '/tests/qwer' => sub {
  
};

get '/tests/:my_id/qwer' => sub {
  
};

post '/tests/:my_id/qwer/' => sub {
  
};

my $t = Test::Mojo->new;
$t->get_ok('/')->status_is(200)->content_is('Hello Mojo!');
