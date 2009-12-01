#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 3;

use Text::Haml;

my $haml = Text::Haml->new;

# Self-Closing Tags: /
my $output = $haml->render(<<'EOF');
%br/
%meta{'http-equiv' => 'Content-Type', :content => 'text/html'}/
EOF
is($output, <<'EOF');
<br />
<meta http-equiv='Content-Type' content='text/html' />
EOF

# Automatically closed tags
$output = $haml->render(<<'EOF');
%br
%meta{'http-equiv' => 'Content-Type', :content => 'text/html'}
%hr
%img{src => 'logo.jpg'}
EOF
is($output, <<'EOF');
<br />
<meta http-equiv='Content-Type' content='text/html' />
<hr />
<img src='logo.jpg' />
EOF

# No / in HTML
$haml->format('html');
$output = $haml->render(<<'EOF');
%br
EOF
is($output, <<'EOF');
<br>
EOF
