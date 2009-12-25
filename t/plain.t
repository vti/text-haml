#!/usr/bin/env perl

use strict;
use warnings;

use Text::Haml;

use Test::More tests => 6;

my $haml = Text::Haml->new;

my $output = $haml->render(<<'EOF');
%gee
  %whiz
    Wow this is cool!
  %whiz
    Wow this is cool!
    %b bold
EOF
is($output, <<'EOF');
<gee>
  <whiz>
    Wow this is cool!
  </whiz>
  <whiz>
    Wow this is cool!
    <b>bold</b>
  </whiz>
</gee>
EOF

$output = $haml->render(<<'EOF');
%p
  <div id="blah">Blah!</div>
EOF
is($output, <<'EOF');
<p>
  <div id="blah">Blah!</div>
</p>
EOF

$output = $haml->render(<<'EOF');
%p
  %b
  Bar
EOF
is($output, <<'EOF');
<p>
  <b></b>
  Bar
</p>
EOF

$output = $haml->render(<<'EOF');
%p
  %b
    Bar
    Foo
EOF
is($output, <<'EOF');
<p>
  <b>
    Bar
    Foo
  </b>
</p>
EOF

$output = $haml->render(<<'EOF');
%p
  %b Bar
  Foo
EOF
is($output, <<'EOF');
<p>
  <b>Bar</b>
  Foo
</p>
EOF

$output = $haml->render(<<'EOF');
Text \with \nescaped characters.
EOF
is($output, <<'EOF');
Text \with 
escaped characters.
EOF
