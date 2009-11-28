#!/usr/bin/env perl

use strict;
use warnings;

use Test::More skip_all => 'Not yet implemented';

use Text::Haml;

my $haml = Text::Haml->new;

#my $output = $haml->render(<<'EOF');
#~ "Foo\n<pre>Bar\nBaz</pre>"
#EOF
#is($output, <<'EOF');
#Foo
#<pre>Bar&#x000A;Baz</pre>
#EOF

#my $output = $haml->render(<<'EOF');
#%code
#  foo
#  bar
#
#  baz
#EOF
#is($output, <<'EOF');
#<code>
#  foo
#  bar
#
#  baz
#</code>
#EOF
