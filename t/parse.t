#!/usr/bin/env perl

use strict;
use warnings;

use Text::Haml;

use Test::More tests => 19;

my $haml = Text::Haml->new;

$haml->parse();
is_deeply($haml->tape, []);

$haml->parse('');
is_deeply($haml->tape, []);

$haml->parse('   ');
is_deeply(
    $haml->tape,
    [   {   'level'  => 3,
            'type'   => 'text',
            'line'   => '',
            'lineno' => 1,
        }
    ]
);

$haml->parse("\n");
is_deeply($haml->tape, [{type => 'text', level => 0, line => '', lineno => 1}]);

$haml->parse(<<'EOF');
%a{href => 'foo', target => "_blank", title => help_me, do => true}
%script{:type => "text/javascript",
        :src  => "javascripts/script.js"}
EOF
is_deeply(
    $haml->tape,
    [   {   type   => 'tag',
            level  => 0,
            name   => 'a',
            attrs  => [
                href   => {type => 'text',    text => 'foo'},
                target => {type => 'text',    text => '_blank'},
                title  => {type => 'expr',    text => 'help_me'},
                do     => {type => 'boolean', text => 1}
            ],
            line   =>
              qq/%a{href => 'foo', target => "_blank", title => help_me, do => true}/,
            lineno => 1,
        },
        {   type   => 'tag',
            level  => 0,
            name   => 'script',
            attrs  => [
                type => {type => 'text', text => 'text/javascript'},
                src  => {type => 'text', text => 'javascripts/script.js'}
            ],
            line   =>
              qq|%script{:type => "text/javascript",\n        :src  => "javascripts/script.js"}|,
            lineno => '2-3',
        },
        {type => 'text', level => 0, line => '', lineno => 4}
    ]
);

$haml->parse(<<'EOF');
%a(href = 'foo' target = "_blank" title = help_me do = true)
%script(type = "text/javascript"
        src  = "javascripts/script.js")
EOF
is_deeply(
    $haml->tape,
    [   {   type   => 'tag',
            level  => 0,
            name   => 'a',
            attrs  => [
                href   => {type => 'text',    text => 'foo'},
                target => {type => 'text',    text => '_blank'},
                title  => {type => 'expr',    text => 'help_me'},
                do     => {type => 'boolean', text => 1}
            ],
            line   =>
              qq/%a(href = 'foo' target = "_blank" title = help_me do = true)/,
            lineno => 1,
        },
        {   type   => 'tag',
            level  => 0,
            name   => 'script',
            attrs  => [
                type => {type => 'text', text => 'text/javascript'},
                src  => {type => 'text', text => 'javascripts/script.js'}
            ],
            line   =>
              qq|%script(type = "text/javascript"\n        src  = "javascripts/script.js")|,
            lineno => '2-3',
        },
        {type => 'text', level => 0, line => '', lineno => 4}
    ]
);

$haml->parse(<<'EOF');
%a{:foo => "#{bar}"}
%a{:bar => "b'az"}
%a{:bar => "b\"az"}
%a{:bar => "baz\"}
EOF
is_deeply(
    $haml->tape,
    [   {   type   => 'tag',
            level  => 0,
            name   => 'a',
            attrs  => [foo => {type => 'text', text => '#{bar}'}],
            line   => '%a{:foo => "#{bar}"}',
            lineno => 1,
        },
        {   type   => 'tag',
            level  => 0,
            name   => 'a',
            attrs  => [bar => {type => 'text', text => "b'az"}],
            line   => q/%a{:bar => "b'az"}/,
            lineno => 2,
        },
        {   type   => 'tag',
            level  => 0,
            name   => 'a',
            attrs  => [bar => {type => 'text', text => 'b"az'}],
            line   => q/%a{:bar => "b\"az"}/,
            lineno => 3,
        },
        {   type   => 'tag',
            level  => 0,
            name   => 'a',
            attrs  => [bar => {type => 'text', text => 'baz\\'}],
            line   => q/%a{:bar => "baz\\"}/,
            lineno => 4,
        },
        {type => 'text', level => 0, line => '', lineno => 5}
    ]
);

$haml->parse(<<'EOF');
%gee
  .class.class2#id{foo => 'bar'}
    %baz= 1 + 2
      Wow this is cool!
      %a{href => 'foo', name => helper} Link
      %a(href="foo" name=helper) Link
EOF
is_deeply(
    $haml->tape,
    [   {type => 'tag', level => 0, name => 'gee', line => '%gee', lineno => 1},
        {   type   => 'tag',
            level  => 2,
            name   => 'div',
            class  => [qw/class class2/],
            id     => 'id',
            attrs  => [foo => {type => 'text', text => 'bar'}],
            line   => ".class.class2#id{foo => 'bar'}",
            lineno => 2,
        },
        {   type   => 'tag',
            level  => 4,
            name   => 'baz',
            expr   => 1,
            text   => '1 + 2',
            line   => '%baz= 1 + 2',
            lineno => 3,
        },
        {   type   => 'text',
            level  => 6,
            text   => 'Wow this is cool!',
            line   => 'Wow this is cool!',
            lineno => 4,
        },
        {   type   => 'tag',
            level  => 6,
            name   => 'a',
            attrs  => [
                href => {type => 'text', text => 'foo'},
                name => {
                    type => 'expr',
                    text => 'helper'
                }
            ],
            text   => 'Link',
            line   => "%a{href => 'foo', name => helper} Link",
            lineno => 5,
        },
        {   type   => 'tag',
            level  => 6,
            name   => 'a',
            attrs  => [
                href => {type => 'text', text => 'foo'},
                name => {
                    type => 'expr',
                    text => 'helper'
                }
            ],
            text   => 'Link',
            line   => q/%a(href="foo" name=helper) Link/,
            lineno => 6,
        },
        {   type   => 'text',
            level  => 0,
            line   => '',
            lineno => 7,
        }
    ]
);

$haml->parse(<<'EOF');
%b(foo=true)
%b{:foo=>false}
EOF
is_deeply(
    $haml->tape,
    [   {   type   => 'tag',
            level  => 0,
            name   => 'b',
            attrs  => [foo => {type => 'boolean', text => 1}],
            line   => q/%b(foo=true)/,
            lineno => 1,
        },
        {   type   => 'tag',
            level  => 0,
            name   => 'b',
            attrs  => [foo => {type => 'boolean', text => 0}],
            line   => q/%b{:foo=>false}/,
            lineno => 2,
        },
        {   type   => 'text',
            level  => 0,
            line   => '',
            lineno => 3,
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
    [   {   type     => 'tag',
            level    => 0,
            name     => 'blockquote',
            trim_in  => 1,
            line     => '%blockquote<',
            lineno   => 1,
        },
        {   type     => 'tag',
            level    => 2,
            name     => 'foo',
            line     => '%foo',
            lineno   => 2,
        },
        {   type     => 'tag',
            level    => 2,
            name     => 'bar',
            trim_out => 1,
            text     => 'trim out',
            line     => '%bar> trim out',
            lineno   => 3,
        },
        {   type     => 'text',
            level    => 0,
            line     => '',
            lineno   => 4,
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
    [   {   type   => 'comment',
            level  => 0,
            text   => 'haml comment',
            line   => '-# haml comment',
            lineno => 1,
        },
        {   type   => 'text',
            level  => 2,
            text   => '= "just text"',
            line   => '\= "just text"',
            lineno => 2,
        },
        {   type   => 'html_comment',
            level  => 2,
            text   => 'html comment',
            line   => '/ html comment',
            lineno => 3,
        },
        {   type   => 'html_comment',
            level  => 2,
            if     => 'IE',
            text   => 'if html comment',
            line   => '/[if IE] if html comment',
            lineno => 4,
        },
        {   type   => 'text',
            level  => 0,
            line   => '',
            lineno => 5,
        }
    ]
);

$haml->parse(<<'EOF');
multiline |
comment   |
parsing   |
normal
EOF
is_deeply(
    $haml->tape,
    [   {   type   => 'text',
            level  => 0,
            text   => 'multiline comment parsing',
            line   => "multiline |\ncomment   |\nparsing   |",
            lineno => '1-3',
        },
        {   type   => 'text',
            level  => 0,
            text   => 'normal',
            line   => 'normal',
            lineno => 4,
        },
        {   type   => 'text',
            level  => 0,
            line   => '',
            lineno => 5,
        }
    ]
);

$haml->parse(<<'EOF');
%p multiline |
   comment   |
   parsing   |
normal
EOF
is_deeply(
    $haml->tape,
    [   {   type   => 'tag',
            level  => 0,
            name   => 'p',
            text   => 'multiline comment parsing',
            line   => "%p multiline |\ncomment   |\nparsing   |",
            lineno => '1-3',
        },
        {   type   => 'text',
            level  => 0,
            text   => 'normal',
            line   => 'normal',
            lineno => 4,
        },
        {   type   => 'text',
            level  => 0,
            line   => '',
            lineno => 5,
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
            line      => '%img',
            lineno    => 1,
        },
        {   type      => 'tag',
            level     => 0,
            name      => 'a',
            autoclose => 1,
            line      => '%a/',
            lineno    => 2,
        },
        {   type      => 'text',
            level     => 0,
            line      => '',
            lineno    => 3,
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
    [   {   type   => 'text',
            level  => 0,
            expr   => 1,
            text   => '1 + 2',
            line   => '= 1 + 2',
            lineno => 1,
        },
        {   type   => 'block',
            level  => 0,
            text   => '"foo"',
            line   => '- "foo"',
            lineno => 2,
        },
        {   type   => 'text',
            level  => 0,
            expr   => 1,
            text   => '$foo->{bar}',
            line   => '= $foo->{bar}',
            lineno => 3,
        },
        {   type   => 'tag',
            level  => 0,
            name   => 'p',
            expr   => 1,
            text   => '$i',
            line   => '%p= $i',
            lineno => 4,
        },
        {   type   => 'text',
            level  => 0,
            line   => '',
            lineno => 5,
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
    [   {   type   => 'text',
            level  => 0,
            expr   => 1,
            text   => "'foo' if 1",
            line   => "= 'foo' if 1",
            lineno => 1,
        },
        {   type   => 'text',
            level  => 0,
            expr   => 1,
            escape => 1,
            text   => "'<escape>'",
            line   => "&= '<escape>'",
            lineno => 2,
        },
        {   type   => 'text',
            level  => 0,
            expr   => 1,
            escape => 0,
            text   => "'<noescape>'",
            line   => "!= '<noescape>'",
            lineno => 3,
        },
        {   type   => 'text',
            level  => 0,
            line   => '',
            lineno => 4,
        }
    ]
);

$haml->parse(<<'EOF');
%foo

%bar
EOF
is_deeply(
    $haml->tape,
    [   {type => 'tag', level => 0, name => 'foo', line => '%foo', lineno => 1},
        {   type   => 'text',
            level  => 0,
            line   => '',
            lineno => 2,
        },
        {type => 'tag', level => 0, name => 'bar', line => '%bar', lineno => 3},
        {   type   => 'text',
            level  => 0,
            line   => '',
            lineno => 4,
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
            line                => '~ "Foo\n<pre>Bar\nBaz</pre>"',
            lineno              => 1,
        },
        {   type  => 'text',
            level => 0,
            line  => '',
            lineno=> 2,
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
    [   {   type   => 'filter',
            level  => 0,
            name   => 'escaped',
            text   => '<foo>',
            line   => ":escaped\n  <foo>",
            lineno => '1-2',
        },
        {   type   => 'filter',
            level  => 0,
            name   => 'preserve',
            text   => "Hello\n\nthere.",
            line   => ":preserve\n  Hello\n\n  there.",
            lineno => '3-6',
        },
        {   type   => 'text',
            level  => 0,
            line   => '',
            lineno => 7,
        }
    ]
);
