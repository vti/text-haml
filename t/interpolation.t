#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 3;

use Text::Haml;

my $haml = Text::Haml->new;

my $output = $haml->render(<<'EOF', quality => 'scrumptious');
%p This is #{$quality} cake!
EOF
is($output, <<'EOF');
<p>This is scrumptious cake!</p>
EOF

#$output = $haml->render(<<'EOF', quality => 'scrumptious');
#%p= "This is #{quality} cake!"
#EOF
#is($output, <<'EOF');
#<p>This is scrumptious cake!</p>
#EOF

$output = $haml->render(<<'EOF', var => 'foo');
%p \#{$var}
%p \\#{$var}
EOF
is($output, <<'EOF');
<p>#{$var}</p>
<p>\foo</p>
EOF

$output = $haml->render(<<'EOF', word => 'yon');
%p
  Look at \\#{$word} lack of backslash: \#{$foo}
  And yon presence thereof: \{$foo}
EOF
is($output, <<'EOF');
<p>
  Look at \yon lack of backslash: #{$foo}
  And yon presence thereof: \{$foo}
</p>
EOF
#
#Interpolation can also be used within filters. For example:
#
#:javascript
#  $(document).ready(function() {
#    alert(#{@message.to_json});
#  });
#
#might compile to
#
#<script type='text/javascript'>
#  //<![CDATA[
#    $(document).ready(function() {
#      alert("Hi there!");
#    });
#  //]]>
#</script>
