#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More tests => 1;

use Text::Haml;

my $haml = Text::Haml->new;

my $output = $haml->render(<<'EOF');
%foo привет
EOF
is($output, <<'EOF');
<foo>привет</foo>
EOF
