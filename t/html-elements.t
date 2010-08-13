#!/usr/bin/env perl

use strict;
use warnings;

use Text::Haml;

use Test::More tests => 3;

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

$output = $haml->render(<<'EOF');
%one
  %two
    %three
      Hey there
EOF
is($output, <<'EOF');
<one>
  <two>
    <three>
      Hey there
    </three>
  </two>
</one>
EOF

$output = $haml->render(<<'EOF');
%one
  %two
    Hi Ho

    Neighbor

    %three
      Hey there
EOF
is($output, <<'EOF');
<one>
  <two>
    Hi Ho
    Neighbor
    <three>
      Hey there
    </three>
  </two>
</one>
EOF
