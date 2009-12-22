#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 7;

use Text::Haml;

my $haml = Text::Haml->new;

# Attributes: {} or ()

my $output = $haml->render(<<'EOF');
%html{xmlns => "http://www.w3.org/1999/xhtml", "xml:lang" => "en", lang => "en"}
EOF
is($output, <<'EOF');
<html xmlns='http://www.w3.org/1999/xhtml' xml:lang='en' lang='en'></html>
EOF

$output = $haml->render(<<'EOF');
- my $link = 'http://foo.bar';
%a{href => $link} FooBar
EOF
is($output, <<'EOF');
<a href='http://foo.bar'>FooBar</a>
EOF

$output = $haml->render(<<'EOF');
%script{:src  => "javascripts/script.js",
        :type => "text/javascript"}
EOF
is($output, <<'EOF');
<script src='javascripts/script.js' type='text/javascript'></script>
EOF

# HTML-style Attributes: ()
$output = $haml->render(<<'EOF', var => 'bar');
%html(xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en")
.hello(class=var)
EOF
is($output, <<'EOF');
<html xmlns='http://www.w3.org/1999/xhtml' xml:lang='en' lang='en'></html>
<div class='bar hello'></div>
EOF
#
## Attribute Methods
#
##def html_attrs(lang = 'en-US')
##  {:xmlns => "http://www.w3.org/1999/xhtml", 'xml:lang' => lang, :lang => lang}
##end
##
##This can then be used in Text::Haml, like so:
##
##$output = $haml->render(<<'EOF');
##%html{html_attrs('fr-fr')}
##
##This is compiled to:
##
##<html lang='fr-fr' xml:lang='fr-fr' xmlns='http://www.w3.org/1999/xhtml'>
##</html>
#
##You can use as many such attribute methods as you want by separating them with commas, like a Ruby argument list. All the hashes will me merged together, from left to right. For example, if you defined
##
##def hash1
##  {:bread => 'white', :filling => 'peanut butter and jelly'}
##end
##
##def hash2
##  {:bread => 'whole wheat'}
##end
##
##then
##
##$output = $haml->render(<<'EOF');
##%sandwich{hash1, hash2, :delicious => true}/
##
##would compile to:
##
##<sandwich bread='whole wheat' delicious='true' filling='peanut butter and jelly' />
##
#

# Boolean Attributes

# XHTML
$haml->format('xhtml');
$output = $haml->render(<<'EOF');
%input{:selected => true}
EOF
is($output, <<'EOF');
<input selected='selected' />
EOF

# HTML
$haml->format('html');
$output = $haml->render(<<'EOF');
%input{:selected => false}
EOF
is($output, <<'EOF');
<input>
EOF

# HTML
$haml->format('html');
$output = $haml->render(<<'EOF');
%input(selected=true)
EOF
is($output, <<'EOF');
<input selected>
EOF
