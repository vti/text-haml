#!/usr/bin/env perl

use strict;
use warnings;

use Text::Haml;

use Test::More tests => 8;

my $haml = Text::Haml->new;

# Inserting Perl: =
my $output = $haml->render(<<'EOF');
%p
  = join(' ', 'hi', 'there', 'reader!')
  = "yo"
EOF
is($output, <<'EOF');
<p>
  hi there reader!
  yo
</p>
EOF

$output = $haml->render(<<'EOF');
= '<script>alert("I\'m evil!");</script>'
EOF
is($output, <<'EOF');
&lt;script&gt;alert(&quot;I&apos;m evil!&quot;);&lt;/script&gt;
EOF

$output = $haml->render('%p= "hello"');
is($output, '<p>hello</p>');

$output = $haml->render(<<'EOF');
= 'foo' if 1
EOF
is($output, <<'EOF');
foo
EOF

# Running Perl: -
$output = $haml->render(<<'EOF');
- my $foo = "hello";
- $foo .= " there";
- $foo .= " you!";
%p= $foo
EOF
is($output, <<'EOF');
<p>hello there you!</p>
EOF

# Perl Blocks
$output = $haml->render(<<'EOF');
- for my $i (42..47) {
  %p= $i
- }
%p See, I can count!
EOF
is($output, <<'EOF');
  <p>42</p>
  <p>43</p>
  <p>44</p>
  <p>45</p>
  <p>46</p>
  <p>47</p>
<p>See, I can count!</p>
EOF

$output = $haml->render(<<'EOF');
%p
  - if (1) {
    = "1!"
    %b bonus
  - } else {
    = "2?"
  - }
EOF
is($output, <<'EOF');
<p>
    1!
    <b>bonus</b>
</p>
EOF

# Inserting variables without a $
$output = $haml->render(<<'EOF', foo => 1, bar => 2);
= foo + bar
- foo = 2;
= foo
EOF
is($output, <<'EOF');
3
2
EOF
