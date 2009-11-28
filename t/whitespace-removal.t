#!/usr/bin/env perl

use strict;
use warnings;

use Test::More skip_all => 'Not yet implemented';

use Text::Haml;

my $haml = Text::Haml->new;

my $output = $haml->render(<<'EOF');
%blockquote<
  %div
    Foo!
EOF
is($output, <<'EOF');
<blockquote><div>
    Foo!
</div></blockquote>
EOF

$output = $haml->render(<<'EOF');
%img
%img>
%img
EOF
is($output, <<'EOF');
<img /><img /><img />
EOF

$output = $haml->render(<<'EOF');
%p<= "Foo\nBar"
EOF
is($output, <<'EOF');
<p>Foo
Bar</p>
EOF

$output = $haml->render(<<'EOF');
%img
%pre><
  foo
  bar
%img
EOF
is($output, <<'EOF');
<img /><pre>foo
bar</pre><img />
EOF
