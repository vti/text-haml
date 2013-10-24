#!/usr/bin/env perl

use 5.008007;

use strict;
use warnings;

use ExtUtils::MakeMaker;

my ($mm) = $ExtUtils::MakeMaker::VERSION =~ /^([^_]+)/;

WriteMakefile(
    NAME         => 'Text::Haml',
    VERSION_FROM => 'lib/Text/Haml.pm',
    ABSTRACT     => 'Haml parser',
    AUTHOR       => 'Viacheslav Tykhanovskyi <vti@cpan.org>',

    ($mm < 6.3002 ? () : ('LICENSE' => 'artistic_2')),

    (   $mm < 6.46
        ? ()
        : ( META_MERGE => {
                requires  => {perl => '5.008007'},
                resources => {
                    license    => 'http://dev.perl.org/licenses/',
                    repository => 'http://github.com/vti/text-haml'
                },
                no_index => {directory => [qw/t/]}
            },
            META_ADD => {
                build_requires     => {},
                configure_requires => {}
            },
        )
    ),

    PREREQ_PM => {
        'IO::File'       => '0',
        'Scalar::Util'   => '0',
        'Encode'         => '0',
        'Carp'           => '0',
        'File::Spec'     => '0',
        'File::Basename' => '0',
        'URI::Escape'    => '0',
    },
    TEST_REQUIRES => {
        'Data::Section::Simple' => '0',
    },
    test => {TESTS => 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t'}
);
