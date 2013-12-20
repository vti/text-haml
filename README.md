# NAME

Text::Haml - Haml Perl implementation

# SYNOPSIS

    use Text::Haml;

    my $haml = Text::Haml->new;

    my $html = $haml->render('%p foo'); # <p>foo</p>

    $html = $haml->render('= $user', user => 'friend'); # <div>friend</div>

    # Use Haml file
    $html = $haml->render_file('tmpl/index.haml', user => 'friend');

# DESCRIPTION

[Text::Haml](http://search.cpan.org/perldoc?Text::Haml) implements Haml
[http://haml-lang.com/docs/yardoc/file.HAML\_REFERENCE.html](http://haml-lang.com/docs/yardoc/file.HAML\_REFERENCE.html) specification.

[Text::Haml](http://search.cpan.org/perldoc?Text::Haml) passes specification tests written by Norman Clarke
http://github.com/norman/haml-spec and supports only cross-language Haml
features. Do not expect Ruby specific things to work.

# ATTRIBUTES

[Text::Haml](http://search.cpan.org/perldoc?Text::Haml) implements the following attributes:

## `append`

Holds the string of code that is appended to the generated Perl code.

## `code`

Holds the Perl code.

## `compiled`

Holds compiled code.

## `encoding`

    $haml->encoding('utf-8');

Default is utf-8.

## `escape`

Escape subroutine presented as string.

Default is

    $haml->escape(<<'EOF');
        my $s = shift;
        return unless defined $s;
        $s =~ s/&/&amp;/g;
        $s =~ s/</&lt;/g;
        $s =~ s/>/&gt;/g;
        $s =~ s/"/&quot;/g;
        $s =~ s/'/&apos;/g;
        return $s;
    EOF

## `escape_html`

    $haml->escape_html(0);

Switch on/off Haml output html escaping. Default is on.

## `filters`

Holds filters.

## `format`

    $haml->format('xhtml');

Supported formats: xhtml, html, html5.

Default is xhtml.

## `namespace`

Holds the namespace under which the Perl package is generated.

## `prepend`

Holds the string of code that is prepended to the generated Perl code.

## `vars`

Holds the variables that are passed during the rendering.

## `vars_as_subs`

When options is __NOT SET__ (by default) passed variables are normal Perl
variables and are used with `$` prefix.

    $haml->render('%p $var', var => 'hello');

When this option is __SET__ passed variables are Perl lvalue
subroutines and are used without `$` prefix.

    $haml->render('%p var', var => 'hello');

But if you declare Perl variable in a block, it must be used with `$`
prefix.

    $haml->render('<<EOF')
        - my $foo;
        %p= $foo
    EOF

## `helpers`

    helpers => {
        foo => sub {
            my $self   = shift;
            my $string = shift;

            $string =~ s/r/z/;

            return $string;
        }
    }

Holds helpers subroutines. Helpers can be called in Haml text as normal Perl
functions. See also add\_helper.

## `helpers_arg`

    $haml->helpers_args($my_context);

First argument passed to the helper ([Text::Haml](http://search.cpan.org/perldoc?Text::Haml) instance by default).

## `error`

    $haml->error;

Holds the last error.

## `tape`

Holds parsed haml elements.

## `path`

Holds path of Haml templates. Current directory is a default.
If you want to set several paths, arrayref can also be set up.
This way is the same as [Text::Xslate](http://search.cpan.org/perldoc?Text::Xslate).

## `cache`

Holds cache level of Haml templates. 1 is a default.
0 means "Not cached", 1 means "Checked template mtime" and 2 means "Used always cached".
This way is the same as [Text::Xslate](http://search.cpan.org/perldoc?Text::Xslate).

## `cache_dir`

Holds cache directory of Haml templates. $ENV{HOME}/.text\_haml\_cache is a default.
Unless $ENV{HOME}, File::Spec->tempdir was used.
This way is the same as [Text::Xslate](http://search.cpan.org/perldoc?Text::Xslate).

# METHODS

## `new`

    my $haml = Text::Haml->new;

## `add_helper`

    $haml->add_helper(current_time => sub { time });

Adds a new helper.

## `add_filter`

    $haml->add_filter(compress => sub { $_[0] =~ s/\s+/ /g; $_[0]});

Adds a new filter.

## `build`

    $haml->build(@_);

Builds the Perl code.

## `compile`

    $haml->compile;

Compiles parsed code.

## `interpret`

    $haml->interpret(@_);

Interprets compiled code.

## `parse`

    $haml->parse('%p foo');

Parses Haml string building a tree.

## `render`

    my $text = $haml->render('%p foo');

    my $text = $haml->render('%p var', var => 'hello');

Renders Haml string. Returns undef on error. See error attribute.

## `render_file`

    my $text = $haml->render_file('foo.haml', var => 'hello');

A helper method that loads a file and passes it to the render method.
Since "%\_\_\_\_vars" is used internally, you cannot use this as parameter name.

# PERL SPECIFIC IMPLEMENTATION ISSUES

## String interpolation

Despite of existing string interpolation in Perl, Ruby interpolation is also
supported.

$haml->render('%p Hello \#{user}', user => 'foo')

## Hash keys

When declaring tag attributes `:` symbol can be used.

$haml->render("%a{:href => 'bar'}");

Perl-style is supported but not recommented, since your Haml template won't
work with Ruby Haml implementation parser.

$haml->render("%a{href => 'bar'}");

# DEVELOPMENT

## Repository

    http://github.com/vti/text-haml

# AUTHOR

Viacheslav Tykhanovskyi, `vti@cpan.org`.

# CREDITS

In order of appearance:

Nick Ragouzis

Norman Clarke

rightgo09

Breno G. de Oliveira (garu)

Yuya Tanaka

Wanradt Koell (wanradt)

Keedi Kim

Carlos Lima

Jason Younker

TheAthlete

# COPYRIGHT AND LICENSE

Copyright (C) 2009-2013, Viacheslav Tykhanovskyi.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.
