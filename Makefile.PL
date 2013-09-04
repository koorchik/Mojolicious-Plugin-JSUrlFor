#!/usr/bin/env perl

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'Mojolicious::Plugin::JSUrlFor',
    VERSION_FROM  => 'lib/Mojolicious/Plugin/JSUrlFor.pm',
    ABSTRACT_FROM => 'lib/Mojolicious/Plugin/JSUrlFor.pm',
    AUTHOR        => 'Viktor Turskyi <koorchik@cpan.org>',
    PREREQ_PM     => { 'Mojolicious' => '1.90' },
    META_MERGE    => {
        resources => {
            repository => 'https://github.com/koorchik/Mojolicious-Plugin-JSUrlFor',
        },
    },
    test      => { TESTS => 't/*.t' },
    dist      => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean => { FILES => 'Mojolicious-Plugin-JSUrlFor-*' },
);
