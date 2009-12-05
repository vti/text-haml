#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;

use Text::Haml;

my $haml = Text::Haml->new;

my $output = $haml->render(<<'EOF', foo => 'bar', baz => {key => 1});
- my $var = 2;
= foo
= baz->{key}
= $var
EOF
is($output, <<'EOF');
bar
1
2
EOF
