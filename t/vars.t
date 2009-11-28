#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 1;

use Text::Haml;

my $haml = Text::Haml->new;

my $output = $haml->render(<<'EOF', foo => 'bar');
= $foo
EOF
is($output, <<'EOF');
bar
EOF
