#!/usr/bin/env perl

use strict;
use warnings;

use Text::Haml;

use Test::More tests => 12;

my $haml = Text::Haml->new;

my $output = $haml->render(<<'EOF');
!!! XML
!!!
%html
  %head
    %title Myspace
  %body
    %h1 I am the international space station
    %p Sign my guestbook
EOF
is($output, <<'EOF');
<?xml version='1.0' encoding='utf-8' ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html>
  <head>
    <title>Myspace</title>
  </head>
  <body>
    <h1>I am the international space station</h1>
    <p>Sign my guestbook</p>
  </body>
</html>
EOF

$output = $haml->render('!!! Strict');
is($output, q|<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">|);
$output = $haml->render('!!! Frameset');
is($output, q|<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">|);
$output = $haml->render('!!! 5');
is($output, '<!DOCTYPE html>');
$output = $haml->render('!!! 1.1');
is($output, q|<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">|);
$output = $haml->render('!!! Basic');
is($output, q|<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML Basic 1.1//EN" "http://www.w3.org/TR/xhtml-basic/xhtml-basic11.dtd">|);
$output = $haml->render('!!! Mobile');
is($output, q|<!DOCTYPE html PUBLIC "-//WAPFORUM//DTD XHTML Mobile 1.2//EN" "http://www.openmobilealliance.org/tech/DTD/xhtml-mobile12.dtd">|);

$haml->format('html4');
$output = $haml->render('!!!');
is($output, q|<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">|);
$output = $haml->render('!!! Strict');
is($output, q|<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">|);
$output = $haml->render('!!! Frameset');
is($output, q|<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd">|);

$haml->format('html5');
$output = $haml->render('!!!');
is($output, '<!DOCTYPE html>');

# Encoding
$haml->format('xhtml');
$output = $haml->render('!!! XML iso-8859-1');
is($output, q|<?xml version='1.0' encoding='iso-8859-1' ?>|);
