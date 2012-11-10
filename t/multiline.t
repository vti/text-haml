#!/usr/bin/env perl

use strict;
use warnings;

use Text::Haml;

use Test::More tests => 4;

my $haml = Text::Haml->new;

my $output = $haml->render(<<'EOF');
%whoo
  %hoo I think this might get |
    pretty long so I should   |
    probably make it          |
    multiline so it does not  |
    look awful.               |
  %p This is short.
EOF
is($output, <<'EOF');
<whoo>
  <hoo>I think this might get pretty long so I should probably make it multiline so it does not look awful.</hoo>
  <p>This is short.</p>
</whoo>
EOF

$output = $haml->render(<<'EOF');
%whoo
  %hoo
    I think this might get    |
    pretty long so I should   |
    probably make it          |
    multiline so it does not  |
    look awful.               |
  %p This is short.
EOF
is($output, <<'EOF');
<whoo>
  <hoo>
    I think this might get pretty long so I should probably make it multiline so it does not look awful.
  </hoo>
  <p>This is short.</p>
</whoo>
EOF

$output = $haml->render(<<'EOF');
%body
  test
  Wow.|
  - my $bar = 17;
  test2
EOF
is($output, <<'EOF');
<body>
  test
  Wow.
  test2
</body>
EOF

$output = $haml->render(<<'EOF');
%body
  this is
  a test for      |
  multiline token |
  on last line.   |
EOF
is($output, <<'EOF');
<body>
  this is
  a test for multiline token on last line.
</body>
EOF
