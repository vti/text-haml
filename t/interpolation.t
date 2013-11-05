#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 10;

use Text::Haml;

my $haml = Text::Haml->new;

my $output;

$output = $haml->render(<<'EOF', quality => 'scrumptious');
%p This is #{$quality} cake!
EOF
is($output, <<'EOF');
<p>This is scrumptious cake!</p>
EOF

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

$output = $haml->render(<<'EOF');
:javascript
  $(document).ready(function() {
    alert(#{1 + 1});
  });
EOF
is($output, <<'EOF');
<script type='text/javascript'>
  //<![CDATA[
    $(document).ready(function() {
alert(2);
});
  //]]>
</script>
EOF

$output = $haml->render(<<'EOF', foo => 'bar');
:javascript
  $(document).ready(function() {
    alert('#{$foo}');
  });
EOF
is($output, <<'EOF');
<script type='text/javascript'>
  //<![CDATA[
    $(document).ready(function() {
alert('bar');
});
  //]]>
</script>
EOF

$output = $haml->render(<<'EOF');
- my $prefix = 'test';
%input.span2{ :type => 'text', :idx => '#{$prefix}-username', :name => '#{$prefix}-username' }
%input.span2{ :type => 'text', :id => '#{$prefix}-username', :name => '#{$prefix}-username' }
EOF
is($output, <<'EOF');
<input class='span2' type='text' idx='test-username' name='test-username' />
<input class='span2' id='test-username' type='text' name='test-username' />
EOF

# Arrayref interpolation
$output = $haml->render(<<'EOF');
- my $names = [qw( Alice Bob )];
%p The first person is #{$names->[0]}. The second person is #{$names->[1]}.
%p The second person is #{$names->[1]}. The first person is #{$names->[0]}.
EOF
is($output, <<'EOF');
<p>The first person is Alice. The second person is Bob.</p>
<p>The second person is Bob. The first person is Alice.</p>
EOF

# Hashref interpolation
$output = $haml->render(<<'EOF');
- my $people = {
-    Alice => { role => 'sender'    },
-    Bob   => { role => 'recipient' },
- };
%p Alice has the role of #{$people->{Alice}->{role}}. Bob has the role of #{$people->{Bob}->{role}}.
%p Bob has the role of #{$people->{Bob}->{role}}. Alice has the role of #{$people->{Alice}->{role}}.
EOF
is($output, <<'EOF');
<p>Alice has the role of sender. Bob has the role of recipient.</p>
<p>Bob has the role of recipient. Alice has the role of sender.</p>
EOF

# Hashref interpolation inside filters
$output = $haml->render(<<'EOF');
- my $vars = { 
-   settings => { type => 'text/javascript' },
-   request => { uri_base => '/path/to' },
- };
:javascript
  !window.jQuery && document.write('<script type="#{$vars->{settings}->{type}}" src="#{$vars->{request}->{uri_base}}/javascripts/jquery.js"><\/script>')
EOF
is($output, <<'EOF');
<script type='text/javascript'>
  //<![CDATA[
    !window.jQuery && document.write('<script type="text/javascript" src="/path/to/javascripts/jquery.js"></script>')
  //]]>
</script>
EOF

# Interpolation custom expression inside #{}
$output = $haml->render(<<'EOF');
%p Number one: #{1+1}. Number two: #{2+3}
EOF
is($output, <<'EOF');
<p>Number one: 2. Number two: 5</p>
EOF
