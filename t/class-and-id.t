#!/usr/bin/env perl

use strict;
use warnings;

use Text::Haml;

use Test::More tests => 4;

my $haml = Text::Haml->new;

my $output = $haml->render(<<'EOF');
%div#things
  %span#rice Chicken Fried
  %p.beans{ :food => 'true' } The magical fruit
  %h1.class.otherclass#id La La La
EOF
is($output, <<'EOF');
<div id='things'>
  <span id='rice'>Chicken Fried</span>
  <p class='beans' food='true'>The magical fruit</p>
  <h1 class='class otherclass' id='id'>La La La</h1>
</div>
EOF

$output = $haml->render(<<'EOF');
#content
  .articles
    .article.title Doogie Howser Comes Out
    .article.date 2006-11-05
    .article.entry
      Neil Patrick Harris would like to dispel any rumors that he is straight
EOF
is($output, <<'EOF');
<div id='content'>
  <div class='articles'>
    <div class='article title'>Doogie Howser Comes Out</div>
    <div class='article date'>2006-11-05</div>
    <div class='article entry'>
      Neil Patrick Harris would like to dispel any rumors that he is straight
    </div>
  </div>
</div>
EOF

$output = $haml->render(<<'EOF');
%foo{id=>'bar'}
%bar#baz{id=>'1'}
EOF
is($output, <<'EOF');
<foo id='bar'></foo>
<bar id='baz_1'></bar>
EOF

$output = $haml->render(<<'EOF', bar => 'bar');
%foo{class=>bar}
%bar.baz{class=>'bar'}
EOF
is($output, <<'EOF');
<foo class='bar'></foo>
<bar class='bar baz'></bar>
EOF
