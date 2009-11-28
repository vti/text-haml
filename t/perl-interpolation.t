#!/usr/bin/env perl

use strict;
use warnings;

use Test::More skip_all => 'Not yet implemented';

use Text::Haml;

my $haml = Text::Haml->new;

##Ruby Interpolation: #{}
##
##Ruby code can also be interpolated within plain text using #{}, similarly to Ruby string interpolation. For example,
##
##%p This is #{h quality} cake!
##
##is the same as
##
##%p= "This is the #{h quality} cake!"
##
##and might compile to
##
##<p>This is scrumptious cake!</p>
##
##Backslashes can be used to escape #{ strings, but they don’t act as escapes anywhere else in the string. For example:
##
##%p
##  Look at \\#{h word} lack of backslash: \#{foo}
##  And yon presence thereof: \{foo}
##
##might compile to
##
##<p>
##  Look at \yon lack of backslash: #{foo}
##  And yon presence thereof: \{foo}
##</p>
##
##Interpolation can also be used within filters. For example:
##
##:javascript
##  $(document).ready(function() {
##    alert(#{@message.to_json});
##  });
##
##might compile to
##
##<script type='text/javascript'>
##  //<![CDATA[
##    $(document).ready(function() {
##      alert("Hi there!");
##    });
##  //]]>
##</script>
