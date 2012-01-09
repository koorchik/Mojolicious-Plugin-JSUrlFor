package Mojolicious::Plugin::JSUrlFor;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.07';
use Mojo::ByteStream qw/b/;
use Data::Dumper;
use v5.10;

sub register {
    my ( $self, $app ) = @_;
    $app->helper(
        js_url_for => sub {
            my $c      = shift;
            state $b_js; # bytestream for $js
            
            if ( $b_js && $app->mode eq 'production' ) {
                return $b_js;
            }
            
            my $js = $app->_js_url_for_code_only;
            
            $b_js = b('<script type="text/javascript">'.$js.'</script>');
            return $b_js;           
        }
    );
    
    $app->helper(
        _js_url_for_code_only => sub {
            my $c      = shift;
            my $routes = [];

            foreach my $node ( @{ $app->routes->children } ) {
                $self->_walk( $node, '', $routes );
            }

            my %names2patterns;
            foreach my $r (@$routes) {
                my $pattern = $r->[0];
                my $name = $r->[1]->name;
                next unless $name;
                
                $pattern =~ s{^/*}{/}g; # TODO remove this quickfix
                $names2patterns{$name} = $pattern; 
            }
            
            my $json_routes = $c->render_json( \%names2patterns, partial=>1 );
            utf8::decode( $json_routes );

            my $js = <<"JS";
var mojolicious_routes = $json_routes;
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
JS
            return $js;
        } );
}

sub _walk {
    my ( $self, $node, $parent_pattern, $routes ) = @_;

    my $pattern = ( $parent_pattern . ($node->pattern->pattern//'') ) || '/';
    push @$routes, [ $pattern, $node ];

    foreach my $subnode ( @{ $node->children } ) {
        $self->_walk( $subnode, $pattern, $routes );
    }
}

1;
__END__

=head1 NAME

Mojolicious::Plugin::JSUrlFor - "url_for" for javascript

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('JSUrlFor');

  # Mojolicious::Lite
  plugin 'JSUrlFor';
  
  # In you application
  my $r = $self->routes;
  $r->get('/messages/:message_id')->to('messages#show')->name('messages_show');

  # In your layout template
  <head>
  <%= js_url_for%>
  </head>

  # In your javascript
  $.getJSON( url_for( 'messages_show', {message_id: 123} ), params, function() { ... } )
  

  # Instead of helper you can use generator for generating static file
  ./your_app.pl generate js_url_for public/static/url_for.js
  
   # And then in your layout template
  <head>
    <script type="text/javascript" src='/static/url_for.js'> </script>
  </head>

=head1 DESCRIPTION

I like Mojlicious routes. And one feature that I like most is that you can name your routes. 
So, you can change your routes without rewriting a single line of dependent code. Of course this works if you
use routes names in all of your code. You can use routes name everywhere except... javascript.
But with <LMojolicious::Plugin::JSUrlFor> you can use routes names really everywhere.

L<Mojolicious::Plugin::JSUrlFor> contains only one helper that add ulr_for function to your client side javascript.

=head1 HELPERS

=head2 C<js_url_for>

In templates <%= js_url_for %>

This helper will add url_for function to your client side javascript.

In "production" mode this helper will cache generated code for javascript "url_for" function

=head1 GENERATORS

=head2 C<js_url_for>

./your_app.pl generate js_url_for $relative_file_name

This command will create $relative_file_name file with the same content as "js_url_for" helper creates.
Then you should include this file into your layout template with "script" tag. 

=head1 METHODS

L<Mojolicious::Plugin::JSUrlFor> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 C<register>

  $plugin->register;

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
