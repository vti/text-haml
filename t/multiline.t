#!/usr/bin/env perl

use strict;
use warnings;

use Text::Haml;

use Test::More tests => 2;

my $haml = Text::Haml->new;

my $output = $haml->render(<<'EOF');
%whoo
  %hoo I think this might get |
    pretty long so I should   |
    probably make it          |
    multiline so it does not  |
    look awful.
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
    look awful.
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
