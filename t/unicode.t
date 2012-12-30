#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More tests => 3;

use Text::Haml;

my $haml = Text::Haml->new(cache => 0);

my $output = $haml->render(<<'EOF');
%foo привет
EOF
is($output, <<'EOF');
<foo>привет</foo>
EOF

$output = $haml->render_file('t/template.haml');
is($output, <<'EOF');
<foo>привет</foo>
EOF

$output = $haml->render_file('t/template-with-vars.haml', foo => 'привет');
is($output, <<'EOF');
<foo>привет</foo>
привет
EOF
