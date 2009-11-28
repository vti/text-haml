#!/usr/bin/env perl

use strict;
use warnings;

use Text::Haml;

use Test::More tests => 2;

my $haml = Text::Haml->new;

# Implicit Div Elements

my $output = $haml->render(<<'EOF');
%div#collection
  %div.item
    %div.description What a cool item!
EOF
is($output, <<'EOF');
<div id='collection'>
  <div class='item'>
    <div class='description'>What a cool item!</div>
  </div>
</div>
EOF

$output = $haml->render(<<'EOF');
#collection
  .item
    .description What a cool item!
EOF
is($output, <<'EOF');
<div id='collection'>
  <div class='item'>
    <div class='description'>What a cool item!</div>
  </div>
</div>
EOF
