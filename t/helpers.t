#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;

use Text::Haml;

my $haml = Text::Haml->new(
    helpers => {
        foo => sub {
            my $self   = shift;
            my $string = shift;

            $string =~ s/r/z/;

            return $string;
          }
    }
);

$haml->add_helper(bar => sub {
        my $self = shift;
        my $string = shift;

        return 'hello';
    });

my $output = $haml->render(<<'EOF');
= foo('bar')
= bar()
EOF
is($output, <<'EOF');
baz
hello
EOF
