#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;

use Text::Haml;

my $haml = Text::Haml->new;

my $output = $haml->render(<<'EOF', foo => 'bar', baz => {key => 1});
- my $var = 2;
= $foo
= $baz->{key}
= $var
EOF
is($output, <<'EOF');
bar
1
2
EOF

$haml = Text::Haml->new(vars_as_subs => 1);

$output = $haml->render(<<'EOF', foo => 'bar', baz => {key => 1});
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
