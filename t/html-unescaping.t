#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 2;

use Text::Haml;

my $haml = Text::Haml->new;

$haml->escape_html(0);
my $output = $haml->render(<<'EOF');
= "I feel <strong>!"
!= "Me <too>!"
EOF
is($output, <<'EOF');
I feel <strong>!
Me <too>!
EOF

$haml->escape_html(1);
$output = $haml->render(<<'EOF');
= "I feel <strong>!"
!= "Me <too>!"
EOF
is($output, <<'EOF');
I feel &lt;strong&gt;!
Me <too>!
EOF
