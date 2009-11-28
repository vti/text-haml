#!/usr/bin/env perl

use strict;
use warnings;

use Text::Haml;

use Test::More tests => 1;

my $haml = Text::Haml->new;

my $output = $haml->render(<<'EOF');
%one
  %two
    %three Hey there
EOF
is($output, <<'EOF');
<one>
  <two>
    <three>Hey there</three>
  </two>
</one>
EOF
