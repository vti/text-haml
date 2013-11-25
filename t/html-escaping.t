#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 10;

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

$output = $haml->render(<<'EOF');
%div= "<h1>text</h1>"
EOF
is($output, <<'EOF');
<div>&lt;h1&gt;text&lt;/h1&gt;</div>
EOF

$output = $haml->render(<<'EOF');
= "<h1>text</h1>"
EOF
is($output, <<'EOF');
&lt;h1&gt;text&lt;/h1&gt;
EOF

$output = $haml->render(<<'EOF');
%div!= "<h1 id=\"A > B\">text</h1>"
EOF
is($output, <<'EOF');
<div><h1 id="A > B">text</h1></div>
EOF

$haml->escape_html(0);

$output = $haml->render(<<'EOF');
%div= "<h1 id=\"A > B\">text</h1>"
EOF
is($output, <<'EOF');
<div><h1 id="A > B">text</h1></div>
EOF

$output = $haml->render(<<'EOF');
- my $text = '<h1>text</h1>';
%div= $text
EOF
is($output, <<'EOF');
<div><h1>text</h1></div>
EOF

$haml->escape_html(1);

$output = $haml->render(<<'EOF');
- my $text = '<h1>text</h1>';
%div!= $text
EOF
is($output, <<'EOF');
<div><h1>text</h1></div>
EOF
