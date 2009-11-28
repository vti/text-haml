#!/usr/bin/env perl

use strict;
use warnings;

use Text::Haml;

use Test::More tests => 5;

my $haml = Text::Haml->new;

# HTML Comments: /

my $output = $haml->render(<<'EOF');
%peanutbutterjelly
  / This is the peanutbutterjelly element
  I like sandwiches!
EOF
is($output, <<'EOF');
<peanutbutterjelly>
  <!-- This is the peanutbutterjelly element -->
  I like sandwiches!
</peanutbutterjelly>
EOF

$output = $haml->render(<<'EOF');
/
  %p This doesn't render...
  %div
    %h1 Because it's commented out!
EOF
is($output, <<'EOF');
<!--
  <p>This doesn't render...</p>
  <div>
    <h1>Because it's commented out!</h1>
  </div>
-->
EOF

# Conditional Comments: /[]
$output = $haml->render(<<'EOF');
/[if IE]
  %a{ :href => 'http://www.mozilla.com/en-US/firefox/' }
    %h1 Get Firefox
EOF
is($output, <<'EOF');
<!--[if IE]>
  <a href='http://www.mozilla.com/en-US/firefox/'>
    <h1>Get Firefox</h1>
  </a>
<![endif]-->
EOF

# Text::Haml Comments: -#
$output = $haml->render(<<'EOF');
%p foo
-# This is a comment
%p bar
EOF
is($output, <<'EOF');
<p>foo</p>
<p>bar</p>
EOF

$output = $haml->render(<<'EOF');
%p foo
-#
  This won't be displayed
    Nor will this
%p bar
EOF
is($output, <<'EOF');
<p>foo</p>
<p>bar</p>
EOF
