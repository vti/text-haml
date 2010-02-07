#!/usr/bin/env perl

use strict;
use warnings;

use Text::Haml;

use Test::More tests => 9;

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
%a= 0 || 1
EOF
is($output, <<'EOF');
<a>1</a>
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
%ul
- for my $i (42..47) {
  %li= $i
- }
%p See, I can count!
EOF
is($output, <<'EOF');
<ul>
  <li>42</li>
  <li>43</li>
  <li>44</li>
  <li>45</li>
  <li>46</li>
  <li>47</li>
</ul>
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
  %foo
EOF
is($output, <<'EOF');
<p>
  1!
  <b>bonus</b>
  <foo>
  </foo>
</p>
EOF

# Inserting variables without a $
$output = $haml->render(<<'EOF', foo => 1, bar => 2);
= $foo + $bar
- $foo = 2;
= $foo
EOF
is($output, <<'EOF');
3
2
EOF
