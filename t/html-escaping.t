#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 4;

use Text::Haml;

my $haml = Text::Haml->new;

$haml->escape_html(0);

my $output = $haml->render(<<'EOF');
&= "I like cheese & crackers"
EOF
is($output, <<'EOF');
I like cheese &amp; crackers
EOF

$haml->escape_html(1);

$output = $haml->render(<<'EOF');
1 > 2
EOF
is($output, <<'EOF');
1 &gt; 2
EOF

$output = $haml->render(<<'EOF');
%foo 1 > 2
EOF
is($output, <<'EOF');
<foo>1 &gt; 2</foo>
EOF

$output = $haml->render(<<'EOF');
&= "I like cheese & crackers"
EOF
is($output, <<'EOF');
I like cheese &amp; crackers
EOF

#& can also be used on its own so that #{} interpolation is escaped. For example,
#
#& I like #{"cheese & crackers"}
#
#compiles to
#
#I like cheese &amp; crackers
