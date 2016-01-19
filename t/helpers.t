#!/usr/bin/env perl

use strict;
use warnings;

use Test::More tests => 3;

use Text::Haml;

my $haml = Text::Haml->new(
    helpers => {
        foo => sub {
            my $self   = shift;
            my $string = shift;

            $string =~ s/r/z/;

            return $string;
          }
    }
);

$haml->add_helper(bar => sub {
        my $self = shift;
        my $string = shift;

        return 'hello';
    });

my $output = $haml->render(<<'EOF');
= foo('bar')
= bar()
EOF
is($output, <<'EOF');
baz
hello
EOF

# helper that captures child block
$haml->add_helper(block1 => sub {
                      my $self = shift;
                      my $block = shift;

                      $block->();
                      $block->();
                      $block->();
                  },
                  prototype => '&',
              );

$output = $haml->render(<<'EOF');
- block1
  foo
EOF
is($output, <<'EOF');
foo
foo
foo
EOF

# standard-ish helpers
$haml->add_helper(precede => sub {
                      my ($self, $text, $block) = @_;

                      $self->namespace->outs($text);
                      $block->();
                  },
                  prototype => '$&',
                  arg_force_self => 1,
              );

$haml->add_helper(succeed => sub {
                      my ($self, $text, $block) = @_;

                      $block->();
                      my $needs_newline = $self->namespace->out_chomp();
                      $self->namespace->outs($text);
                      $self->namespace->outs("\n") if $needs_newline;
                      
                  },
                  prototype => '$&',
                  arg_force_self => 1,
              );

$haml->add_helper(surround => sub {
                      my ($self, $precede, $succeed, $block) = @_;

                      $self->namespace->outs($precede);
                      $block->();
                      my $needs_newline = $self->namespace->out_chomp();
                      $self->namespace->outs($succeed);
                      $self->namespace->outs("\n") if $needs_newline;
                  });

$output = $haml->render(<<'EOF');
- precede '*', sub
  foo
- succeed '*', sub
  bar
- surround '(', ')', sub
  foobar
EOF
is($output, "*foo
bar*
(foobar)
");

