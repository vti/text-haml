#!/usr/bin/env perl

use strict;
use warnings;

use Text::Haml;

use Test::More skip_all => 'Not yet implemented';

##Filters
##
##The colon character designates a filter. This allows you to pass an indented block of text as input to another filtering program and add the result to the output of Text::Haml. The syntax is simply a colon followed by the name of the filter. For example,
##
##%p
##  :markdown
##    Textile
##    =======
##
##    Hello, *World*
##
##is compiled to
##
##<p>
##  <h1>Textile</h1>
##
##  <p>Hello, <em>World</em></p>
##</p>
##
##Filters can have Ruby code interpolated with #{}. For example,
##
##- flavor = "raspberry"
###content
##  :textile
##    I *really* prefer _#{h flavor}_ jam.
##
##is compiled to
##
##<div id='content'>
##  <p>I <strong>really</strong> prefer <em>raspberry</em> jam.</p>
##</div>
##
##Currently, filters ignore the :escape_html option. This means that #{} interpolation within filters is never HTML-escaped.
##
##Text::Haml has the following filters defined:
##:plain
##
##Does not parse the filtered text. This is useful for large blocks of text without HTML tags, when you don’t want lines starting with . or - to be parsed.
##:javascript
##
##Surrounds the filtered text with <script> and CDATA tags. Useful for including inline Javascript.
##:cdata
##
##Surrounds the filtered text with CDATA tags.
##:escaped
##
##Works the same as plain, but HTML-escapes the text before placing it in the document.
##:ruby
##
##Parses the filtered text with the normal Ruby interpreter. All output sent to $stdout, like with puts, is output into the Text::Haml document. Not available if the :suppress_eval option is set to true. The Ruby code is evaluated in the same context as the Text::Haml template.
##:preserve
##
##Inserts the filtered text into the template with whitespace preserved. preserved blocks of text aren’t indented, and newlines are replaced with the HTML escape code for newlines, to preserve nice-looking output. See also Whitespace Preservation.
##:erb
##
##Parses the filtered text with ERB, like an RHTML template. Not available if the :suppress_eval option is set to true. Embedded Ruby code is evaluated in the same context as the Text::Haml template.
##:sass
##
##Parses the filtered text with Sass to produce CSS output.
##:textile
##
##Parses the filtered text with Textile. Only works if RedCloth is installed.
##:markdown
##
##Parses the filtered text with Markdown. Only works if RDiscount, RPeg-Markdown, Maruku, or BlueCloth are installed.
##:maruku
##
##Parses the filtered text with Maruku, which has some non-standard extensions to Markdown.
##Custom Filters
##
##You can also define your own filters. See Text::Haml::Filters for details.
