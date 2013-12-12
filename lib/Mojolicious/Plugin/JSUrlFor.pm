package Mojolicious::Plugin::JSUrlFor;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.11';
use Mojo::ByteStream qw/b/;
use Data::Dumper;
use v5.10;

sub register {
    my ( $self, $app , $config) = @_;
    my %config = %$config;
    $config{route} ||= '/js/url_for.js';
    $app->routes()->get($config{route} => \&_javascript_file)->name('js_url_for');
        
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
        js_url_for_tag => sub {
            my $c      = shift;
            return $c->javascript($c->url_for('js_url_for'));
        }
    );
    
    $app->helper(
        _js_url_for_code_only => sub {
            my $c      = shift;
            my $endpoint_routes = $self->_collect_endpoint_routes( $app->routes );

            my %names2paths;
            foreach my $route (@$endpoint_routes) {
                next unless $route->name;

                my $path = $self->_get_path_for_route($route);
                $path =~ s{^/*}{/}g; # TODO remove this quickfix

                $names2paths{$route->name} = $path;
            }
            
            my $json_routes = $c->render( json => \%names2paths, partial=>1 );
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

sub _collect_endpoint_routes {
    my ( $self, $route ) = @_;
    my @endpoint_routes;

    foreach my $child_route ( @{ $route->children } ) {
        if ( $child_route->is_endpoint ) {
            push @endpoint_routes, $child_route;
        } else {
            push @endpoint_routes, @{ $self->_collect_endpoint_routes($child_route) }; 
        }
    }
    return \@endpoint_routes
}

sub _get_path_for_route {
    my ( $self, $parent ) = @_;

    my $path = $parent->pattern->pattern // '';

    while ( $parent = $parent->parent ) {
        $path = ($parent->pattern->pattern//'') . $path;
    } 

    return $path;
}

sub _javascript_file {
    my $self = shift;
    my $code = $self->app->_js_url_for_code_only();
    $self->render(inline => $code, format => 'js');
}


1;
__END__

=head1 NAME

Mojolicious::Plugin::JSUrlFor - Mojolicious "url_for" helper for javascript

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
  
  # Or let it generate on the fly
  $self->plugin('JSUrlFor', {route => '/javascripts/url.js'});
  <head>
    <%= js_url_for_tag %>
    <!-- generates <script type="text/javascript" src='/javascripts/url.js'> </script> -->
  </head>

=head1 DESCRIPTION

I like Mojlicious routes. And one feature that I like most is that you can name your routes. 
So, you can change your routes without rewriting a single line of dependent code. Of course this works if you
use routes names in all of your code. You can use routes name everywhere except... javascript.
But with <LMojolicious::Plugin::JSUrlFor> you can use routes names really everywhere. 
This plugin support mounted (see <LMojolicious::Plugin::Mount> ) apps too.

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

=head1 AUTHOR

Viktor Turskyi <koorchik@cpan.org>

=head1 BUGS

Please report any bugs or feature requests to Github L<https://github.com/koorchik/Mojolicious-Plugin-JSUrlFor/>

Also you can report bugs to CPAN RT

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
