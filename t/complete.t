#!/usr/bin/env perl

use strict;
use warnings;

use Text::Haml;

use Test::More tests => 1;

my $haml = Text::Haml->new;

my $output = $haml->render(<<'EOF');
!!!
#main
  .note
    %h2 Quick Notes
    %ul
      %li
        Text::Haml is usually indented with two spaces,
        although more than two is allowed.
        You have to be consistent, though.
      %li
        The first character of any line is called
        the "control character" - it says "make a tag"
        or "run Ruby code" or all sorts of things.
      %li
        Text::Haml takes care of nicely indenting your HTML.
      %li 
        Text::Haml allows Ruby code and blocks.
        But not in this example.
        We turned it off for security.

  .note
    You can get more information by reading the
    %a{:href => "/docs/yardoc/HAML_REFERENCE.md.html"}
      Official Text::Haml Reference

  .note
    %p
      This example doesn't allow Ruby to be executed,
      but real Text::Haml does.
    %p
      Ruby code is included by using = at the
      beginning of a line.
    %p
      Read the tutorial for more information.
EOF
is($output, <<'EOF');
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<div id='main'>
  <div class='note'>
    <h2>Quick Notes</h2>
    <ul>
      <li>
        Text::Haml is usually indented with two spaces,
        although more than two is allowed.
        You have to be consistent, though.
      </li>
      <li>
        The first character of any line is called
        the "control character" - it says "make a tag"
        or "run Ruby code" or all sorts of things.
      </li>
      <li>
        Text::Haml takes care of nicely indenting your HTML.
      </li>
      <li>
        Text::Haml allows Ruby code and blocks.
        But not in this example.
        We turned it off for security.
      </li>
    </ul>
  </div>
  <div class='note'>
    You can get more information by reading the
    <a href='/docs/yardoc/HAML_REFERENCE.md.html'>
      Official Text::Haml Reference
    </a>
  </div>
  <div class='note'>
    <p>
      This example doesn't allow Ruby to be executed,
      but real Text::Haml does.
    </p>
    <p>
      Ruby code is included by using = at the
      beginning of a line.
    </p>
    <p>
      Read the tutorial for more information.
    </p>
  </div>
</div>
EOF
