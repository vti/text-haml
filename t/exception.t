#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 6;

use Text::Haml;

my $haml = Text::Haml->new;

my $output;

# Haml syntax error
#$output = $haml->render(<<'EOF');
#%foo{ inline
#EOF
#ok(not defined $output);
#is($haml->error, '');

# Perl strict
$output = $haml->render(<<'EOF');
= $foo
EOF
ok(not defined $output);
like($haml->error, qr/^Global symbol "\$foo" requires/);

# Perl compile time error
$output = $haml->render(<<'EOF');
= 1 + {
EOF
ok(not defined $output);
like($haml->error, qr/^syntax error at/);

# Perl execution time error
$output = $haml->render(<<'EOF');
- die 'foo';
EOF
ok(not defined $output);
like($haml->error, qr/^foo/);
