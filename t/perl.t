#!/usr/bin/env perl

use strict;
use warnings;

use Text::Haml;

use Test::More tests => 15;

my $haml = Text::Haml->new;
my $output;

# Inserting Perl: =
$output = $haml->render(<<'EOF');
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

$output = $haml->render(<<'EOF');
%div= undef || 0
EOF
is($output, <<'EOF');
<div>0</div>
EOF

$output = $haml->render(<<'EOF');
%div
  = undef || 0
EOF
is($output, <<'EOF');
<div>
  0
</div>
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
%ul
 - foreach (1..3) {
   %li
     %foo
 - }
%p End
EOF
is($output, <<'EOF');
<ul>
 <li>
   <foo></foo>
 </li>
 <li>
   <foo></foo>
 </li>
 <li>
   <foo></foo>
 </li>
</ul>
<p>End</p>
EOF

$output = $haml->render(<<'EOF');
%ul
  - foreach (1..1) {
    %li
      - my $i = 0;
      - my $j = 1;
      %a(href="#")= $i || $j
      %form(method="post")
        - if (1) {
          %button Foo
        - } else {
          %button Bar
        - }
  - }
%p End
EOF
is($output, <<'EOF');
<ul>
  <li>
    <a href='#'>1</a>
    <form method='post'>
      <button>Foo</button>
    </form>
  </li>
</ul>
<p>End</p>
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
 <foo></foo>
</p>
EOF

$output = $haml->render(<<'EOF', errors => {});
%foo= 1 if 1
%bar= 1 if 0
%baz= 1 if undef
= "1" if 1
= "0" if 0
= "0" if undef
EOF
is($output, <<'EOF');
<foo>1</foo>
<bar>0</bar>
<baz></baz>
1
0

EOF

#warn $haml->code;

# Inserting variables
$output = $haml->render(<<'EOF', foo => 1, bar => 2);
= $foo + $bar
- $foo = 2;
= $foo
EOF
is($output, <<'EOF');
3
2
EOF

# Inserting variables with special symbols
$output = $haml->render(<<'EOF', 'foo.bar' => 1);
Nothing is exported
EOF
is($output, <<'EOF');
Nothing is exported
EOF
