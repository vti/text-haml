#!/usr/bin/env perl

use strict;
use warnings;

use Text::Haml;

use Test::More tests => 15;

my $haml = Text::Haml->new;

# HTML Comments: /

# HTML comment with white space after the forward slash character
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

# HTML comment with double quotes
$output = $haml->render(<<'EOF');
%peanutbutterjelly
  / This is the "peanutbutterjelly" element
  I like sandwiches!
EOF
is($output, <<'EOF');
<peanutbutterjelly>
  <!-- This is the "peanutbutterjelly" element -->
  I like sandwiches!
</peanutbutterjelly>
EOF

# HTML comment without white space after the forward slash character
$output = $haml->render(<<'EOF');
%peanutbutterjelly
  /This is the peanutbutterjelly element
  I like sandwiches!
EOF
is($output, <<'EOF');
<peanutbutterjelly>
  <!-- This is the peanutbutterjelly element -->
  I like sandwiches!
</peanutbutterjelly>
EOF

# HTML comment with more white spaces after the forward slash character
$output = $haml->render(<<'EOF');
%peanutbutterjelly
  /         This is the peanutbutterjelly element
  I like sandwiches!
EOF
is($output, <<'EOF');
<peanutbutterjelly>
  <!-- This is the peanutbutterjelly element -->
  I like sandwiches!
</peanutbutterjelly>
EOF

# HTML comment wrap indented sections of code
$output = $haml->render(<<'EOF');
/
  %p This does not render...
  %div
    %h1 Because it is commented out!
EOF
is($output, <<'EOF');
<!--
  <p>This does not render...</p>
  <div>
    <h1>Because it is commented out!</h1>
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

# Text::Haml Comments: Inline -#
$output = $haml->render(<<'EOF');
%p foo
-# This is a comment
%p bar
EOF
is($output, <<'EOF');
<p>foo</p>
<p>bar</p>
EOF

# Text::Haml Comments: Inline -# inside tag
$output = $haml->render(<<'EOF');
%div#foo
  -# This is a comment
  %p bar
  %strong baz
EOF
is($output, <<'EOF');
<div id='foo'>
  <p>bar</p>
  <strong>baz</strong>
</div>
EOF

# Text::Haml Comments: Inline -# inside tag (does not add newline in last line)
$output = $haml->render(<<'EOF');
%div#foo
  %p bar
  %strong baz
  -# This is a comment
EOF
is($output, <<'EOF');
<div id='foo'>
  <p>bar</p>
  <strong>baz</strong>
</div>
EOF

# Text::Haml Comments: Nested -#
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

# Text::Haml Comments: Nested with Following Nested Tag -#
$output = $haml->render(<<'EOF');
%p foo
-#
  These two lines together
  No space between the two lines or below
%p
  bar
%p
  baz
EOF
is($output, <<'EOF');
<p>foo</p>
<p>
  bar
</p>
<p>
  baz
</p>
EOF

# Text::Haml Comments: Nested with Following Nested Tag -#
$output = $haml->render(<<'EOF');
%p foo
-#
  These two lines together
  No space between the two lines; one+ space below

%p
  bar
%p
  baz
EOF
is($output, <<'EOF');
<p>foo</p>
<p>
  bar
</p>
<p>
  baz
</p>
EOF

# Text::Haml Comments: Nested with Following Nested Tag -#
$output = $haml->render(<<'EOF');
%p foo
-#
  These two lines together

  Space between the two lines; one+ space below

%p
  bar
%p
  baz
EOF
is($output, <<'EOF');
<p>foo</p>
<p>
  bar
</p>
<p>
  baz
</p>
EOF

# Text::Haml Comments: Nested with Following Nested Tag -#
$output = $haml->render(<<'EOF');
%p foo
-#
  These two lines together
  No space between the two lines; one+ space below; space btwn %p

%p
  bar

%p
  baz
EOF
is($output, <<'EOF');
<p>foo</p>
<p>
  bar
</p>
<p>
  baz
</p>
EOF

# Text::Haml Comments: Nested with Following Empty Line then Nested Tag -#
$output = $haml->render(<<'EOF');
%p foo
 -#
   This won't be displayed, even with improper indent
   But the two following nested elements should.
%p
  bar
%p
  baz
EOF
is($output, <<'EOF');
<p>foo</p>
<p>
  bar
</p>
<p>
  baz
</p>
EOF
