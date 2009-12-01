#!/usr/bin/env perl

use strict;
use warnings;

use Text::Haml;

use Test::More tests => 16;

my $haml = Text::Haml->new;

$haml->parse();
is_deeply($haml->tape, []);

$haml->parse('');
is_deeply($haml->tape, []);

$haml->parse('   ');
is_deeply(
    $haml->tape,
    [   {   'level' => 3,
            'type'  => 'text',
            'line'  => ''
        }
    ]
);

$haml->parse("\n");
is_deeply($haml->tape,
    [{type => 'text', level => 0, line => ''}]);

$haml->parse("\n");
is_deeply($haml->tape,
    [{type => 'text', level => 0, line => ''}]);

$haml->parse(<<'EOF');
%gee
  %whiz.class.class2#id{foo => 'bar'}
    %baz= 1 + 2
      Wow this is cool!
      %a{href => 'foo', name => helper} Link
      %a(href="foo" name=helper) Link
EOF
is_deeply(
    $haml->tape,
    [   {type => 'tag', level => 0, name => 'gee', line => '%gee'},
        {   type  => 'tag',
            level => 2,
            name  => 'whiz',
            class => [qw/class class2/],
            id    => 'id',
            attrs => [foo => {type => 'text', text => 'bar'}],
            line  => "%whiz.class.class2#id{foo => 'bar'}"
        },
        {   type  => 'tag',
            level => 4,
            name  => 'baz',
            expr  => 1,
            text  => '1 + 2',
            line  => '%baz= 1 + 2'
        },
        {   type  => 'text',
            level => 6,
            text  => 'Wow this is cool!',
            line  => 'Wow this is cool!'
        },
        {   type  => 'tag',
            level => 6,
            name  => 'a',
            attrs => [
                href => {type => 'text', text => 'foo'},
                name => {
                    type => 'expr',
                    text => 'helper'
                }
            ],
            text => 'Link',
            line => "%a{href => 'foo', name => helper} Link"
        },
        {   type  => 'tag',
            level => 6,
            name  => 'a',
            attrs => [
                href => {type => 'text', text => 'foo'},
                name => {
                    type => 'expr',
                    text => 'helper'
                }
            ],
            text => 'Link',
            line => q/%a(href="foo" name=helper) Link/
        },
        {   type  => 'text',
            level => 0,
            line  => ''
        }
    ]
);

$haml->parse(<<'EOF');
%blockquote<
  %foo
  %bar> trim out
EOF
is_deeply(
    $haml->tape,
    [   {   type    => 'tag',
            level   => 0,
            name    => 'blockquote',
            trim_in => 1,
            line    => '%blockquote<'
        },
        {   type    => 'tag',
            level   => 2,
            name    => 'foo',
            line    => '%foo'
        },
        {   type     => 'tag',
            level    => 2,
            name     => 'bar',
            trim_out => 1,
            text     => 'trim out',
            line     => '%bar> trim out'
        },
        {   type  => 'text',
            level => 0,
            line  => ''
        }
    ]
);

$haml->parse(<<'EOF');
-# haml comment
  \= "just text"
  / html comment
  /[if IE] if html comment
EOF
is_deeply(
    $haml->tape,
    [   {   type  => 'comment',
            level => 0,
            text  => 'haml comment',
            line  => '-# haml comment'
        },
        {   type  => 'text',
            level => 2,
            text  => '= "just text"',
            line  => '\= "just text"'
        },
        {   type  => 'html_comment',
            level => 2,
            text  => 'html comment',
            line  => '/ html comment'
        },
        {   type  => 'html_comment',
            level => 2,
            if    => 'IE',
            text  => 'if html comment',
            line  => '/[if IE] if html comment'
        },
        {   type  => 'text',
            level => 0,
            line  => ''
        }
    ]
);

$haml->parse(<<'EOF');
multiline |
comment   |
parsing
normal
EOF
is_deeply(
    $haml->tape,
    [   {   type  => 'text',
            level => 0,
            text  => 'multiline comment parsing',
            line  => "multiline |\ncomment   |\nparsing"
        },
        {   type  => 'text',
            level => 0,
            text  => 'normal',
            line  => 'normal'
        },
        {   type  => 'text',
            level => 0,
            line  => ''
        }
    ]
);

$haml->parse(<<'EOF');
%p multiline |
   comment   |
   parsing
normal
EOF
is_deeply(
    $haml->tape,
    [   {   type  => 'tag',
            level => 0,
            name  => 'p',
            text  => 'multiline comment parsing',
            line  => "%p multiline |\ncomment   |\nparsing"
        },
        {   type  => 'text',
            level => 0,
            text  => 'normal',
            line  => 'normal'
        },
        {   type  => 'text',
            level => 0,
            line  => ''
        }
    ]
);

$haml->parse(<<'EOF');
%img
%a/
EOF
is_deeply(
    $haml->tape,
    [   {   type      => 'tag',
            level     => 0,
            name      => 'img',
            autoclose => 1,
            line      => '%img'
        },
        {   type      => 'tag',
            level     => 0,
            name      => 'a',
            autoclose => 1,
            line      => '%a/'
        },
        {   type  => 'text',
            level => 0,
            line  => ''
        }
    ]
);

$haml->parse(<<'EOF');
= 1 + 2
- "foo"
= $foo->{bar}
%p= $i
EOF
is_deeply(
    $haml->tape,
    [   {   type  => 'text',
            level => 0,
            expr  => 1,
            text  => '1 + 2',
            line  => '= 1 + 2'
        },
        {   type  => 'block',
            level => 0,
            text  => '"foo"',
            line  => '- "foo"'
        },
        {   type  => 'text',
            level => 0,
            expr  => 1,
            text  => '$foo->{bar}',
            line  => '= $foo->{bar}'
        },
        {   type  => 'tag',
            level => 0,
            name => 'p',
            expr  => 1,
            text  => '$i',
            line  => '%p= $i'
        },
        {   type  => 'text',
            level => 0,
            line  => ''
        }
    ]
);

$haml->parse(<<'EOF');
= 'foo' if 1
&= '<escape>'
!= '<noescape>'
EOF
is_deeply(
    $haml->tape,
    [   {   type  => 'text',
            level => 0,
            expr  => 1,
            text  => "'foo' if 1",
            line  => "= 'foo' if 1"
        },
        {   type  => 'text',
            level => 0,
            expr  => 1,
            escape => 1,
            text  => "'<escape>'",
            line  => "&= '<escape>'"
        },
        {   type  => 'text',
            level => 0,
            expr  => 1,
            escape => 0,
            text  => "'<noescape>'",
            line  => "!= '<noescape>'"
        },
        {   type  => 'text',
            level => 0,
            line  => ''
        }
    ]
);

$haml->parse(<<'EOF');
%foo

%bar
EOF
is_deeply(
    $haml->tape,
    [   {type => 'tag', level => 0, name => 'foo', line => '%foo'},
        {   type  => 'text',
            level => 0,
            line  => ''
        },
        {type => 'tag', level => 0, name => 'bar', line => '%bar'},
        {   type  => 'text',
            level => 0,
            line  => ''
        }
    ]
);

$haml->parse(<<'EOF');
~ "Foo\n<pre>Bar\nBaz</pre>"
EOF
is_deeply(
    $haml->tape,
    [   {   type                => 'text',
            level               => 0,
            text                => '"Foo\n<pre>Bar\nBaz</pre>"',
            expr                => 1,
            preserve_whitespace => 1,
            line                => '~ "Foo\n<pre>Bar\nBaz</pre>"'
        },
        {   type  => 'text',
            level => 0,
            line  => ''
        }
    ]
);

$haml->parse(<<'EOF');
:escaped
  <foo>
:preserve
  Hello

  there.
EOF
is_deeply(
    $haml->tape,
    [   {   type  => 'filter',
            level => 0,
            name  => 'escaped',
            text  => '<foo>',
            line  => ":escaped\n  <foo>"
        },
        {   type  => 'filter',
            level => 0,
            name  => 'preserve',
            text  => "Hello\n\nthere.",
            line  => ":preserve\n  Hello\n\n  there."
        },
        {   type  => 'text',
            level => 0,
            line  => ''
        }
    ]
);
