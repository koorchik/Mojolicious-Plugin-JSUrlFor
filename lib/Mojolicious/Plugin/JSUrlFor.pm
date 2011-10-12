package Mojolicious::Plugin::JSUrlFor;
use Mojo::Base 'Mojolicious::Plugin';

our $VERSION = '0.01';
use Mojo::ByteStream qw/b/;
use Data::Dumper;

sub register {
    my ( $self, $app ) = @_;
    $app->helper(
        js_url_for => sub {
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
<script type="text/javascript">
var mojolicious_routes = $json_routes;
function url_for(route_name, captures) {
    var pattern = mojolicious_routes[route_name];
    if(!pattern) return route_name;
     
    // Fill placeholders with values
    if (!captures) captures = {};
    for (var placeholder in captures) { // TODO order placeholders from longest to shortest
        var re = new RegExp(':' + placeholder, 'g');
        pattern = pattern.replace(re, captures[placeholder]);
    }
    
    // Clean not replaces placeholders
    pattern = pattern.replace(/:[^/.]+/g, '');
    
    return pattern;
}
</script>        
JS
            b($js);
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

Mojolicious::Plugin::JSUrlFor - Mojolicious Plugin

=head1 SYNOPSIS

  # Mojolicious
  $self->plugin('JSUrlFor');

  # Mojolicious::Lite
  plugin 'JSUrlFor';

=head1 DESCRIPTION

L<Mojolicious::Plugin::JSUrlFor> is a L<Mojolicious> plugin.

=head1 METHODS

L<Mojolicious::Plugin::JSUrlFor> inherits all methods from
L<Mojolicious::Plugin> and implements the following new ones.

=head2 C<register>

  $plugin->register;

Register plugin in L<Mojolicious> application.

=head1 SEE ALSO

L<Mojolicious>, L<Mojolicious::Guides>, L<http://mojolicio.us>.

=cut
