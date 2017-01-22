package Text::Haml;

use strict;
use warnings;

use IO::File;
use Scalar::Util qw/weaken/;
use Encode qw/decode/;
use Carp ();
use File::Spec;
use File::Basename ();
use URI::Escape ();
use Digest::MD5;

our $VERSION = '0.990118';

use constant CHUNK_SIZE => 4096;
use constant _DEFAULT_CACHE_DIR => '.text_haml_cache';
my $cache_dir;

BEGIN {
    for my $dir ($ENV{HOME}, File::Spec->tmpdir) {
        if (defined($dir) && -d $dir && -w _) {
            $cache_dir = File::Spec->catdir($dir, _DEFAULT_CACHE_DIR);
            last;
        }
    }
}

my $ESCAPE = {
    '\"'   => "\x22",
    "\'"   => "\x27",
    '\\'   => "\x5c",
    '\/'   => "\x2f",
    '\b'   => "\x8",
    '\f'   => "\xC",
    '\n'   => "\xA",
    '\r'   => "\xD",
    '\t'   => "\x9",
    '\\\\' => "\x5c\x5c"
};

my $UNESCAPE_RE = qr/
    \\[\"\'\/\\bfnrt]
/x;

my $STRING_DOUBLE_QUOTES_RE = qr/
    \"
    (?:
    $UNESCAPE_RE
    |
    [\x20-\x21\x23-\x5b\x5b-\x{10ffff}]
    )*
    \"
/x;

my $STRING_SINGLE_QUOTES_RE = qr/
    \'
    (?:
    $UNESCAPE_RE
    |
    [\x20-\x26\x28-\x5b\x5b-\x{10ffff}]
    )*
    \'
/x;

my $STRING_RE = qr/
    $STRING_SINGLE_QUOTES_RE
    |
    $STRING_DOUBLE_QUOTES_RE
/x;

sub new {
    my $class = shift;

    # Default attributes
    my $attrs = {};
    $attrs->{vars_as_subs} = 0;
    $attrs->{tape}         = [];
    $attrs->{encoding}     = 'utf-8';
    $attrs->{escape_html}  = 1;
    $attrs->{helpers}      = {};
    $attrs->{helpers_options} = {};
    $attrs->{format}       = 'xhtml';
    $attrs->{prepend}      = '';
    $attrs->{append}       = '';
    $attrs->{namespace}    = '';
    $attrs->{path}         = ['.'];
    $attrs->{cache}        = 1; # 0: not cached, 1: checks mtime, 2: always cached
    $attrs->{cache_dir}    = _DEFAULT_CACHE_DIR;

    $attrs->{escape}       = <<'EOF';
    my $s = shift;
    return unless defined $s;
    $s =~ s/&/&amp;/g;
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;
    $s =~ s/"/&quot;/g;
    $s =~ s/'/&apos;/g;
    return $s;
EOF

    $attrs->{filters} = {
        plain => sub { $_[0] =~ s/\n*$//; $_[0] },
        escaped  => sub { $_[0] },
        preserve => sub { $_[0] =~ s/\n/&#x000A;/g; $_[0] },
        javascript => sub {
            "<script type='text/javascript'>\n"
              . "  //<![CDATA[\n"
              . "    $_[0]\n"
              . "  //]]>\n"
              . "</script>";
        },
        css => sub {
            "<style type='text/css'>\n"
              . "  /*<![CDATA[*/\n"
              . "    $_[0]\n"
              . "  /*]]>*/\n"
              . "</style>";
        },
    };

    my $self = {%$attrs, @_};
    bless $self, $class;

    # Convert to template fullpath
    $self->path([
        map { ref($_) ? $_ : File::Spec->rel2abs($_) }
            ref($self->path) eq 'ARRAY' ? @{$self->path} : $self->path
    ]);

    $self->{helpers_arg} ||= $self;
    weaken $self->{helpers_arg};

    return $self;
}

# Yes, i know!
sub vars_as_subs  { @_ > 1 ? $_[0]->{vars_as_subs}  = $_[1] : $_[0]->{vars_as_subs}; }
sub format        { @_ > 1 ? $_[0]->{format}        = $_[1] : $_[0]->{format} }
sub encoding      { @_ > 1 ? $_[0]->{encoding}      = $_[1] : $_[0]->{encoding} }
sub escape_html   { @_ > 1 ? $_[0]->{escape_html}   = $_[1] : $_[0]->{escape_html}; }
sub code          { @_ > 1 ? $_[0]->{code}          = $_[1] : $_[0]->{code} }
sub compiled      { @_ > 1 ? $_[0]->{compiled}      = $_[1] : $_[0]->{compiled} }
sub helpers       { @_ > 1 ? $_[0]->{helpers}       = $_[1] : $_[0]->{helpers} }
sub helpers_options { @_ > 1 ? $_[0]->{helpers_options} = $_[1] : $_[0]->{helpers_options} }
sub filters       { @_ > 1 ? $_[0]->{filters}       = $_[1] : $_[0]->{filters} }
sub prepend       { @_ > 1 ? $_[0]->{prepend}       = $_[1] : $_[0]->{prepend} }
sub append        { @_ > 1 ? $_[0]->{append}        = $_[1] : $_[0]->{append} }
sub escape        { @_ > 1 ? $_[0]->{escape}        = $_[1] : $_[0]->{escape} }
sub tape          { @_ > 1 ? $_[0]->{tape}          = $_[1] : $_[0]->{tape} }
sub path          { @_ > 1 ? $_[0]->{path}          = $_[1] : $_[0]->{path} }
sub cache         { @_ > 1 ? $_[0]->{cache}         = $_[1] : $_[0]->{cache} }
sub fullpath      { @_ > 1 ? $_[0]->{fullpath}      = $_[1] : $_[0]->{fullpath}; }
sub cache_dir     { @_ > 1 ? $_[0]->{cache_dir}     = $_[1] : $_[0]->{cache_dir}; }
sub cache_path    { @_ > 1 ? $_[0]->{cache_path}    = $_[1] : $_[0]->{cache_path}; }
sub namespace     { @_ > 1 ? $_[0]->{namespace}     = $_[1] : $_[0]->{namespace}; }
sub error         { @_ > 1 ? $_[0]->{error}         = $_[1] : $_[0]->{error} }

sub helpers_arg {
    if (@_ > 1) {
        $_[0]->{helpers_arg} = $_[1];
        weaken $_[0]->{helpers_arg};
    }
    else {
        return $_[0]->{helpers_arg};
    }
}


our @AUTOCLOSE = (qw/meta img link br hr input area param col base/);

sub add_helper {
    my $self = shift;
    my ($name, $code, %options) = @_;

    $self->helpers->{$name} = $code;
    $self->helpers_options->{$name} = \%options;
}

sub add_filter {
    my $self = shift;
    my ($name, $code) = @_;

    $self->filters->{$name} = $code;
}

sub parse {
    my $self = shift;
    my $tmpl = shift;

    $tmpl = '' unless defined $tmpl;

    $self->tape([]);

    my $level_token    = quotemeta ' ';
    my $escape_token   = quotemeta '&';
    my $unescape_token = quotemeta '!';
    my $expr_token     = quotemeta '=';
    my $tag_start      = quotemeta '%';
    my $class_start    = quotemeta '.';
    my $id_start       = quotemeta '#';

    my $attributes_start = quotemeta '{';
    my $attributes_end   = quotemeta '}';
    my $attribute_arrow  = quotemeta '=>';
    my $attributes_sep   = quotemeta ',';
    my $attribute_prefix = quotemeta ':';
    my $attribute_name   = qr/(?:$STRING_RE|.*?(?= |$attribute_arrow))/;
    my $attribute_value =
      qr/(?:$STRING_RE|[^ $attributes_sep$attributes_end]+)/x;

    my $attributes_start2 = quotemeta '(';
    my $attributes_end2   = quotemeta ')';
    my $attribute_arrow2  = quotemeta '=';
    my $attributes_sep2   = ' ';
    my $attribute_name2   = qr/(?:$STRING_RE|.*?(?= |$attribute_arrow2))/;
    my $attribute_value2 =
      qr/(?:$STRING_RE|[^ $attributes_sep2$attributes_end2]+)/;

    my $filter_token    = quotemeta ':';
    my $quote           = "'";
    my $comment_token   = quotemeta '-#';
    my $trim_in         = quotemeta '<';
    my $trim_out        = quotemeta '>';
    my $autoclose_token = quotemeta '/';
    my $multiline_token = quotemeta '|';

    my $tag_name = qr/([^
        $level_token
        $attributes_start
        $attributes_start2
        $class_start
        $id_start
        $trim_in
        $trim_out
        $unescape_token
        $escape_token
        $expr_token
        $autoclose_token]+)/;

    my $tape = $self->tape;

    my $level;
    my @multiline_el_queue;
    my $multiline_code_el = undef;
    my @lines = split /\n/, $tmpl;
    push @lines, '' if $tmpl =~ m/\n$/;
    @lines = ('') if $tmpl eq "\n";
    for (my $i = 0; $i < @lines; $i++) {
        my $line = $lines[$i];

        if ($line =~ s/^($level_token+)//) {
            $level = length $1;
        }
        else {
            $level = 0;
        }

        my $el = {level => $level, type => 'text', line => $line, lineno => $i+1};

        if (defined $multiline_code_el && $line =~ /^[-!=%#.:]/) {
            push @$tape, $multiline_code_el;
            undef $multiline_code_el;
        }

        # Haml comment
        if ($line =~ m/^$comment_token(?: (.*))?/) {
            $el->{type} = 'comment';
            $el->{text} = $1 if $1;
            push @$tape, $el;
            next;
        }

        # Inside a filter
        my $prev = $tape->[-1];
        if ($prev && $prev->{type} eq 'filter') {
            if ($prev->{level} < $el->{level}
                || ($i + 1 < @lines && $line eq ''))
            {
                $prev->{text} .= "\n" if $prev->{text};
                $prev->{text} .= $line;
                $prev->{line} .= "\n" . (' ' x $el->{level}) . $el->{line};
                _update_lineno($prev, $i);
                next;
            }
        }

        # Filter
        if ($line =~ m/^:(\w+)/) {
            $el->{type} = 'filter';
            $el->{name} = $1;
            $el->{text} = '';
            push @$tape, $el;
            next;
        }

        # Doctype
        if ($line =~ m/^!!!(?: ([^ ]+)(?: (.*))?)?$/) {
            $el->{type}   = 'text';
            $el->{escape} = 0;
            $el->{text}   = $self->_doctype($1, $2);
            push @$tape, $el;
            next;
        }

        # HTML comment
        if ($line =~ m/^\/(?:\[if (.*)?\])?(?: *(.*))?/) {
            $el->{type} = 'html_comment';
            $el->{if}   = $1 if $1;
            $el->{text} = $2 if $2;
            push @$tape, $el;
            next;
        }

        # Escaping, everything after is a text
        if ($line =~ s/^\\//) {
            $el->{type} = 'text', $el->{text} = $line;
            push @$tape, $el;
            next;
        }

        # Block (note even the final multiline block must end in |)
        if ($line =~ s/^- \s*(.*)(\s\|\s*)$// ||
            $line =~ s/^- \s*(.*)// ||
                (defined $multiline_code_el && $line =~ s/^(.*)(\s\|\s*)$//)) {

            $el->{type} = 'block';
            
            if ($2) {
                $multiline_code_el ||= $el;
                $multiline_code_el->{text} ||= '';
                $multiline_code_el->{text} .= $1;

                next;
            }
            
            $el->{text} = $1;
            push @$tape, $el;
            next;
            
        }

        # Preserve whitespace
        if ($line =~ s/^~ \s*(.*)//) {
            $el->{type}                = 'text';
            $el->{text}                = $1;
            $el->{expr}                = 1;
            $el->{preserve_whitespace} = 1;
            push @$tape, $el;
            next;
        }

        # Tag
        if ($line =~ m/^(?:$tag_start
            |$class_start
            |$id_start
            )/x
          )
        {
            $el->{type} = 'tag';
            $el->{name} = '';

            if ($line =~ s/^$tag_start$tag_name//) {
                $el->{name} = $1;
            }

            while (1) {
                if ($line =~ s/^$class_start$tag_name//) {
                    my $class = join(' ', split(/\./, $1));

                    $el->{name}  ||= 'div';
                    $el->{class} ||= [];
                    push @{$el->{class}}, $class;
                }
                elsif ($line =~ s/^$id_start$tag_name//) {
                    my $id = $1;

                    $el->{name} ||= 'div';
                    $el->{id} = $id;
                }
                else {
                    last;
                }
            }

            if ($line =~ m/^
                (?:
                    $attributes_start\s*
                    $attribute_prefix?
                    $attribute_name\s*
                    $attribute_arrow\s*
                    $attribute_value
                    |
                    $attributes_start2\s*
                    $attribute_name2\s*
                    $attribute_arrow2\s*
                    $attribute_value2
                )
                /x
              )
            {
                my $attrs = [];

                my $type = 'html';
                if ($line =~ s/^$attributes_start//) {
                    $type = 'perl';
                }
                else {
                    $line =~ s/^$attributes_start2//;
                }

                while (1) {
                    if (!$line) {
                        $line = $lines[++$i] || last;
                        $el->{line} .= "\n$line";
                        _update_lineno($el, $i);
                    }
                    elsif ($type eq 'perl' && $line =~ s/^$attributes_end//) {
                        last;
                    }
                    elsif ($type eq 'html' && $line =~ s/^$attributes_end2//)
                    {
                        last;
                    }
                    else {
                        my ($name, $value);

                        if ($line =~ s/^\s*$attribute_prefix?
                                    ($attribute_name)\s*
                                    $attribute_arrow\s*
                                    ($attribute_value)\s*
                                    (?:$attributes_sep\s*)?//x
                          )
                        {
                            $name  = $1;
                            $value = $2;
                        }
                        elsif (
                            $line =~ s/^\s*
                                    ($attribute_name2)\s*
                                    $attribute_arrow2\s*
                                    ($attribute_value2)\s*
                                    (?:$attributes_sep2\s*)?//x
                          )
                        {
                            $name  = $1;
                            $value = $2;
                        }
                        else {
                            $self->error('Tag attributes parsing error');
                            return;
                        }

                        if ($name =~ s/^(?:'|")//) {
                            $name =~ s/(?:'|")$//;
                            $name =~ s/($UNESCAPE_RE)/$ESCAPE->{$1}/g;
                        }

                        if ($value =~ s/^(?:'|")//) {
                            $value =~ s/(?:'|")$//;
                            $value =~ s/($UNESCAPE_RE)/$ESCAPE->{$1}/g;
                            push @$attrs,
                              $name => {type => 'text', text => $value};
                        }
                        elsif ($value eq 'true' || $value eq 'false') {
                            push @$attrs, $name => {
                                type => 'boolean',
                                text => $value eq 'true' ? 1 : 0
                            };
                        }
                        else {
                            push @$attrs,
                              $name => {type => 'expr', text => $value};
                        }
                    }
                }

                $el->{type} = 'tag';
                $el->{attrs} = $attrs if @$attrs;
            }

            if ($line =~ s/^$trim_out ?//) {
                $el->{trim_out} = 1;
            }

            if ($line =~ s/^$trim_in ?//) {
                $el->{trim_in} = 1;
            }
        }

        if ($line =~ s/^($escape_token|$unescape_token)?$expr_token //) {
            $el->{expr} = 1;
            if ($1) {
                $el->{escape} = quotemeta($1) eq $escape_token ? 1 : 0;
            }
        }

        if ($el->{type} eq 'tag'
            && ($line =~ s/$autoclose_token$//
                || grep { $el->{name} eq $_ } @AUTOCLOSE)
          )
        {
            $el->{autoclose} = 1;
        }

        $line =~ s/^ // if $line;

        # Multiline
        if ($line && $line =~ s/(\s*)$multiline_token$//) {

            # For the first time
            if (!$tape->[-1] || ref $tape->[-1]->{text} ne 'ARRAY') {
                $el->{text} = [$line];
                $el->{line} ||= $line . "$1|"; # XXX: is this really necessary?

                push @$tape, $el;
                push @multiline_el_queue, $el;
            }

            # Continue concatenation
            else {
                my $prev_stack_el = $tape->[-1];
                push @{$prev_stack_el->{text}}, $line;
                $prev_stack_el->{line} .= "\n" . $line . "$1|";
                _update_lineno($prev_stack_el, $i);
            }
        }

        # Normal text
        else {
            $el->{text} = $line if $line;

            push @$tape, $el;
        }
    }

    # Finalize multilines
    for my $el (@multiline_el_queue) {
        $el->{text} = join(" ", @{$el->{text}});
    }
}

# Updates lineno entry on the tape element
# for itens spanning more than one line
sub _update_lineno {
    my ($el, $lineno) = @_;
    $lineno++;    # report line numbers starting at 1 instead of 0
    $el->{lineno} =~ s/^(\d+)(?:-\d+)?/$1-$lineno/;
    return;
}

sub _open_implicit_brace {
    my ($lines) = @_;
        if (scalar(@$lines) && $lines->[-1] eq '}') {
        pop @$lines;
    } else {
        push @$lines, '{';
    }
}

sub _close_implicit_brace {
    my ($lines) = @_;
    if (scalar(@$lines) && $lines->[-1] eq '{') {
        pop @$lines;
    } else {
        push @$lines, '}';
    }
}

sub build {
    my $self = shift;
    my %vars = @_;

    my $code;

    my $ESCAPE = $self->escape;
    $ESCAPE = <<"EOF";
no strict 'refs'; no warnings 'redefine';
sub escape;
*escape = sub {
    $ESCAPE
};
use strict; use warnings;
EOF

    $ESCAPE =~ s/\n//g;

    # ensure namespace is set so that (for now) helpers
    # can access outs & outs_raw (until we correctly allow
    # helpers in `=` lines to capture their blocks eg. for `surrounds`
    
    if (! $self->namespace) {
        $self->namespace(ref($self) . '::template');
    }

    my $namespace = $self->namespace;
    $code .= qq/package $namespace;/;

    $code .= qq/sub { my \$_H = ''; $ESCAPE; /;

    $code .= qq/my \$self = shift;/;
    $code .= qq/\$${namespace}::__self = \$self;/;

    $code .= qq/my \%____vars = \@_;/;

    $code .= qq/no strict 'refs'; no warnings 'redefine';/;

    # using [1] since when called with arrow from namespace, [0] will be the namespace
    $code .= qq/*${namespace}::outs = sub { \$_H .= escape(\$_[1]) };/;
    $code .= qq/*${namespace}::outs_raw = sub { \$_H .= \$_[1] };/;
    $code .= qq/*${namespace}::out_chomp = sub { chomp \$_H };/;

    # Install helpers
    for my $name (sort keys %{$self->helpers}) {
        next unless $name =~ m/^\w+$/;

        my $options = $self->{helpers_options}{$name} || {};

        # allow bareword helpers and block capturing with optional helper prototypes
        my $prototype = $options->{prototype};
        $prototype = defined $prototype ? "($prototype)" : '';

        # this option allows per-helper overriding of the helper_arg, important for builtin
        # helpers to be safe in assuming the arg is self
        my $helper_arg_code = $options->{arg_force_self} ? "\$${namespace}::__self" : "\$${namespace}::__self->helpers_arg";

        # sub must be defined inside BEGIN {} for the prototype to be ready before main helper code is
        # compiled
        $code .= "BEGIN { \*${namespace}::${name} = sub $prototype { ";
        $code .= "\$${namespace}::__self->helpers->{'$name'}->($helper_arg_code, \@_) }; } ";
    }

    # Install variables
    foreach my $var (sort keys %vars) {
        next unless $var =~ m/^\w+$/;
        if ($self->vars_as_subs) {
            next if $self->helpers->{$var};
            $code
                .= qq/sub $var() : lvalue; *$var = sub () : lvalue {\$____vars{'$var'}};/;
        }
        else {
            $code .= qq/my \$$var = \$____vars{'$var'};/;
        }
    }

    $code .= qq/use strict; use warnings;/;

    $code .= $self->prepend;

    my $stack = [];

    my $output = '';
    my @lines;
    my $count    = 0;
    my $in_block = 0;
  ELEM:
    for my $el (@{$self->tape}) {
        my $level = $el->{level};
        $level -= 2 * $in_block if $in_block;

        my $offset = '';
        $offset .= ' ' x $level if $level > 0;

        my $escape = '';
        if (   (!exists $el->{escape} && $self->escape_html)
            || (exists $el->{escape} && $el->{escape} == 1))
        {
            $escape = 'escape';
        }

        my $prev_el = $self->tape->[$count - 1];
        my $next_el = $self->tape->[$count + 1];

        my $prev_stack_el = $stack->[-1];

        if ($prev_stack_el && $prev_stack_el->{type} eq 'comment') {
            if (   $el->{line}
                && $prev_stack_el->{level} >= $el->{level})
            {
                pop @$stack;
                undef $prev_stack_el;
                _close_implicit_brace(\@lines);
            }
            else {
                next ELEM;
            }
        }

        if (   $el->{line}
            && $prev_stack_el
            && $prev_stack_el->{level} >= $el->{level})
        {
          STACKEDBLK:
            while (my $poped = pop @$stack) {
                my $level = $poped->{level};
                $level -= 2 * $in_block if $in_block;
                my $poped_offset = $level > 0 ? ' ' x $level : '';

                my $ending = '';
                if ($poped->{type} eq 'tag') {
                    $ending .= "</$poped->{name}>";
                }
                elsif ($poped->{type} eq 'html_comment') {
                    $ending .= "<![endif]" if $poped->{if};
                    $ending .= "-->";
                }

                if ($poped->{type} ne 'block') {
                    push @lines, qq|\$_H .= "$poped_offset$ending\n";|;
                }

                _close_implicit_brace(\@lines);
                
                if ($poped->{type} eq 'block') {
                    _close_implicit_brace(\@lines);
                }

                last STACKEDBLK if $poped->{level} == $el->{level};
            }
        }


      SWITCH: {

            if ($el->{type} eq 'tag') {
                my $ending =
                  $el->{autoclose} && $self->format eq 'xhtml' ? ' /' : '';

                my $attrs = '';
                if ($el->{attrs}) {
                  ATTR:
                    for (my $i = 0; $i < @{$el->{attrs}}; $i += 2) {
                        my $name  = $el->{attrs}->[$i];
                        my $value = $el->{attrs}->[$i + 1];
                        my $text  = $value->{text};

                        if ($name eq 'class') {
                            $el->{class} ||= [];
                            if ($value->{type} eq 'text') {
                                push @{$el->{class}}, $self->_parse_text($text);
                            }
                            else {
                                push @{$el->{class}}, qq/" . $text . "/;
                            }
                            next ATTR;
                        }
                        elsif ($name eq 'id') {
                            $el->{id} ||= '';
                            $el->{id} = $el->{id} . '_' if $el->{id};
                            $el->{id} .= $self->_parse_text($value->{text});
                            next ATTR;
                        }

                        if (   $value->{type} eq 'text'
                            || $value->{type} eq 'expr')
                        {
                            $attrs .= ' ';
                            $attrs .= $name;
                            $attrs .= '=';

                            if ($value->{type} eq 'text') {
                                $attrs
                                  .= "'" . $self->_parse_text($text) . "'";
                            }
                            else {
                                $attrs .= qq/'" . $text . "'/;
                            }
                        }
                        elsif ($value->{type} eq 'boolean' && $value->{text})
                        {
                            $attrs .= ' ';
                            $attrs .= $name;
                            if ($self->format eq 'xhtml') {
                                $attrs .= '=';
                                $attrs .= qq/'$name'/;
                            }
                        }
                    }    #end:for ATTR
                }

                my $tail = '';
                if ($el->{class}) {
                    $tail .= qq/ class='"./;
                    $tail .= qq/join(' ', sort(/;
                    $tail .= join(',', map {"\"$_\""} @{$el->{class}});
                    $tail .= qq/))/;
                    $tail .= qq/."'/;
                }

                if ($el->{id}) {
                    $tail .= qq/ id='$el->{id}'/;
                }

                $output .= qq|"$offset<$el->{name}$tail$attrs$ending>"|;

                if ($el->{text} && $el->{expr}) {
                  if ($escape eq 'escape') {
                    $output .= '. ( do { my $ret = ' .  qq/ $escape( do { $el->{text} } )/ . '; defined($ret) ? $ret : "" } )';
                    $output .= qq| . "</$el->{name}>"|;
                  } else {
                    $output .= '. ( do {' . $el->{text} . '} || "")';
                    $output .= qq| . "</$el->{name}>"|;
                  }
                }
                elsif ($el->{text}) {
                    $output .= qq/. $escape(/ . '"' 
                      . $self->_parse_text($el->{text}) . '");';
                    $output .= qq|\$_H .= "</$el->{name}>"|
                      unless $el->{autoclose};
                }
                elsif (
                    !$next_el
                    || (   $next_el
                        && $next_el->{level} <= $el->{level})
                  )
                {
                    $output .= qq|. "</$el->{name}>"| unless $el->{autoclose};
                }
                elsif (!$el->{autoclose}) {
                    push @$stack, $el;
                    _open_implicit_brace(\@lines);
                }

                $output .= qq|. "\n"|;
                $output .= qq|;|;
                last SWITCH;
            }

            if ($el->{line} && $el->{type} eq 'text') {
                $output = qq/"$offset"/;

                $el->{text} = '' unless defined $el->{text};

                if ($el->{expr}) {
                    $output .= '. ( do { my $ret = ' .  qq/ $escape( do { $el->{text} } )/ . '; defined($ret) ? $ret : "" } )';
                    $output .= qq/;\$_H .= "\n"/;
                }
                elsif ($el->{text}) {
                    $output
                      .= '.'
                      . qq/$escape / . '"'
                      . $self->_parse_text($el->{text}) . '"';
                    $output .= qq/. "\n"/;
                }

                $output .= qq/;/;
                last SWITCH;
            }

            if ($el->{type} eq 'block') {
                _open_implicit_brace(\@lines);
                push @lines,  ';' . $el->{text};
                push @$stack, $el;
                _open_implicit_brace(\@lines);

                if ($prev_el && $prev_el->{level} > $el->{level}) {
                    $in_block--;
                }

                if ($next_el && $next_el->{level} > $el->{level}) {
                    $in_block++;
                }
                last SWITCH;
            }

            if ($el->{type} eq 'html_comment') {
                $output = qq/"$offset"/;

                $output .= qq/ . "<!--"/;
                $output .= qq/ . "[if $el->{if}]>"/ if $el->{if};

                if ($el->{text}) {
                    $output .= '." ' . quotemeta($el->{text}) . ' ".'; 
                    $output .= qq/"-->\n"/;
                }
                else {
                    $output .= qq/. "\n"/;
                    push @$stack, $el;
                    _open_implicit_brace(\@lines);
                }

                $output .= qq/;/;
                last SWITCH;
            }

            if ($el->{type} eq 'comment') {
                push @$stack, $el;
                _open_implicit_brace(\@lines);
                last SWITCH;
            }

            if ($el->{type} eq 'filter') {
                my $filter = $self->filters->{$el->{name}};
                die "unknown filter: $el->{name}" unless $filter;

                if ($el->{name} eq 'escaped') {
                    $output =
                        qq/escape "/
                      . $self->_parse_text($el->{text})
                      . qq/\n";/;
                }
                else {
                    $el->{text} = $filter->($el->{text});

                    my $text = $self->_parse_text($el->{text});
                    $text =~ s/\\\n/\\n/g;
                    $output = qq/"/ . $text . qq/\n";/;
                }
                last SWITCH;
            }

            unless ($el->{text}) {
                last SWITCH;
            }

            die "unknown type=" . $el->{type};

        }    #end:SWITCH
    }    #end:ELEM
    continue {

        # by bracing the content blocks, we will continue any existing block at the same level.
        # this is important eg. if previously at this level the template has declared a `my`
        # variable.
        
        _open_implicit_brace(\@lines);
        push @lines, '$_H .= ' . $output if $output;
        _close_implicit_brace(\@lines);
        $output = '';
        $count++;
    }    #ELEM

    my $last_empty_line = 0;
    $last_empty_line = 1
      if $self->tape->[-1] && $self->tape->[-1]->{line} eq '';

    # Close remaining conten tblocks, last-seen first
    foreach my $el (reverse @$stack) {
        my $offset = ' ' x $el->{level};
        my $ending = '';
        if ($el->{type} eq 'tag') {
            $ending = "</$el->{name}>";
        }
        elsif ($el->{type} eq 'html_comment') {
            $ending .= '<![endif]' if $el->{if};
            $ending .= "-->";
        }

        push @lines, qq|\$_H .= "$offset$ending\n";| if $ending;

        _close_implicit_brace(\@lines);
        if ($el->{type} eq 'block') {
            _close_implicit_brace(\@lines);
        }

    }

    if ($lines[-1] && !$last_empty_line) {
        # usually (always?) there will be a closing '}' after the actual last .=
        if ($lines[-2] && $lines[-1] eq '}') {
            $lines[-2] =~ s/\n";$/";/;
        } else {
            $lines[-1] =~ s/\n";$/";/;
        }
    }

    $code .= join("\n", @lines);

    $code .= $self->append;

    $code .= q/return $_H; };/;

    $self->code($code);

    return $self;
}

sub _parse_text {
    my $self = shift;
    my $text = shift;

    my $expr = 0;
    if ($text =~ m/^\"/ && $text =~ m/\"$/) {
        $text =~ s/^"//;
        $text =~ s/"$//;
        $expr = 1;
    }

    $text =~ s/($UNESCAPE_RE)/$ESCAPE->{$1}/g;

    my $output = '';
    while (1) {
        my $t;
        my $escape = 0;
        my $found  = 0;
        my $variable;

        our $curly_brace_n;
        $curly_brace_n = qr/ (?> [^{}]+ | \{ (??{ $curly_brace_n }) \} )* /x;

        if ($text =~ s/^(.*?)?(?<!\\)(\#\{$curly_brace_n\})//xms) {
            $found    = 1;
            $t        = $1;
            $variable = $2;
        }
        elsif ($text =~ s/^(.*?)?\\\\(\#\{$curly_brace_n\})//xms) {
            $found    = 1;
            $t        = $1;
            $variable = $2;
            $escape   = 1;
        }

        if ($t) {
            $t =~ s/\\\#/\#/g;
            $output .= $expr ? $t : quotemeta($t);
        }

        if ($found) {
            $variable =~ s/\#\{(.*)\}/$1/;

            my $prefix = $escape ? quotemeta("\\") : '';
            $output .= qq/$prefix".do { $variable }."/;
        }
        else {
            $text = $self->_parse_interpolation($text);
            $output .= $text;
            last;
        }
    }

    return $expr ? qq/$output/ : $output;
}

sub _parse_interpolation {
    my $self = shift;
    my ($text) = @_;

    my @parts;

    my $start_tag = qr{(?<!\\)\#\{};
    my $end_tag   = qr{\}};

    pos $text = 0;
    while (pos $text < length $text) {
        if ($text =~ m/\G $start_tag (.*?) $end_tag/xgcms) {
            push @parts, 'do {' . $1 . '}';
        }
        elsif ($text =~ m/\G (.*?) (?=$start_tag)/xgcms) {
            push @parts, 'qq{' . quotemeta($1) . '}';
        }
        else {
            my $leftover = substr($text, pos($text));
            push @parts, 'qq{' . quotemeta($leftover) . '}';
            last;
        }
    }

    return '' unless @parts;

    return '" . ' . join('.', map {s/\\\\#\\\{/#\\\{/; $_} @parts) . '."';
}

sub compile {
    my $self = shift;

    my $code = $self->code;
    return unless $code;

    my $compiled = eval $code;

    if ($@) {
        $self->error($@);
        return undef;
    }

    $self->compiled($compiled);

    return $self;
}

sub interpret {
    my $self = shift;

    my $compiled = $self->compiled;

    my $output = eval { $compiled->($self, @_) };

    if ($@) {
        $self->error($@);
        return undef;
    }

    return $output;
}

sub render {
    my $self = shift;
    my $tmpl = shift;

    # Parse
    $self->parse($tmpl);

    # Build
    return unless defined $self->build(@_);

    # Compile
    $self->compile || return undef;

    # Interpret
    return $self->interpret(@_);
}

# For templates in __DATA__ section
sub _eq_checksum {
  my $self = shift;

  # Exit if not virtual path
  return 0 unless ref $self->fullpath eq 'SCALAR';

  return 1 if $self->cache == 2;
  return 0 if $self->cache == 0;

  my $fullpath = $self->fullpath;
  $fullpath = $$fullpath;

  my $file = IO::File->new;
  $file->open($self->cache_path, 'r') or return;
  $file->sysread(my $cache_md5_checksum, 33); # 33 = # + hashsum
  $file->close;

  my $orig_md5_checksum = '#'.$self->_digest($fullpath);

  return $cache_md5_checksum eq $orig_md5_checksum;
}

sub _digest {
    my ($self, $content) = @_;

    my $md5 = Digest::MD5->new();
    $content = decode($self->encoding, $content) if $self->encoding;
    $md5->add($content);
    return $md5->hexdigest();
}

sub render_file {
    my $self = shift;
    my $path = shift;

    # Set file fullpath
    $self->_fullpath($path);

    if ($self->cache >= 1) {
        # Make cache directory
        my $cache_dir = $self->_cache_dir;
        # Set cache path
        $self->_cache_path($path, $cache_dir);

        # Exists same cache file?
        if (-e $self->cache_path && ($self->_eq_mtime || $self->_eq_checksum)) {
          return $self->_interpret_cached(@_);
        }
    }

    my $content = '';
    my $file = IO::File->new;
    if (ref $self->fullpath eq 'SCALAR') { # virtual path
      $content = $self->fullpath;
      $content = $$content;
    } else {
      # Open file
      $file->open($self->fullpath, 'r') or die "Can't open template '$path': $!";

      # Slurp file
      while ($file->sysread(my $buffer, CHUNK_SIZE, 0)) {
          $content .= $buffer;
      }
      $file->close;
    }

    $content =~ s/\r//g;

    # Encoding
    $content = decode($self->encoding, $content) if $self->encoding;

    # Render
    my $output;
    if ($output = $self->render($content, @_)) {
        if ($self->cache >= 1) {
            # Create cache
            if ($file->open($self->cache_path, 'w')) {
                binmode $file, ':utf8';

                if (ref $self->fullpath eq 'SCALAR') {
                  my $md5_checksum = $self->_digest($content);
                  print $file '#'.$md5_checksum."\n".$self->code; # Write with file checksum (virtual path)
                } else {
                  my $mtime = (stat($self->fullpath))[9];
                  print $file '#'.$mtime."\n".$self->code; # Write with file mtime
                }

                $file->close;
            }
        }
    }

    return $output;
}

sub _fullpath {
    my $self = shift;
    my $path = shift;

    if (File::Spec->file_name_is_absolute($path) and -r $path) {
        $self->fullpath($path);
        return;
    }

    for my $p (@{$self->path}) {
      if (ref $p eq 'HASH') { # virtual path
        if (defined(my $content = $p->{$path})) {
          $self->fullpath(\$content);
          return;
        }
      } else {
        my $fullpath = File::Spec->catfile($p, $path);
        if (-r $fullpath) { # is readable ?
          $self->fullpath($fullpath);
          return;
        }
      }
    }

    Carp::croak("Can't find template '$path'");
}

sub _cache_dir {
    my $self = shift;

    my $cache_prefix = (ref $self->fullpath eq 'SCALAR') 
      ? 'HASH' 
      : URI::Escape::uri_escape( 
          File::Basename::dirname($self->fullpath) 
        );

    my $cache_dir = File::Spec->catdir(
        $self->cache_dir,
        $cache_prefix,
    );

    if (not -e $cache_dir) {
        require File::Path;
        eval { File::Path::mkpath($cache_dir) };
        Carp::carp("Can't mkpath '$cache_dir': $@") if $@;
    }

    return $cache_dir;
}

sub _cache_path {
    my $self = shift;
    my $path = shift;
    my $cache_dir = shift;

    $self->cache_path(File::Spec->catfile(
        $cache_dir,
        File::Basename::basename($path).'.pl',
    ));
}

sub _eq_mtime {
    my $self = shift;

    # Exit if virtual path
    return 0 if ref $self->fullpath eq 'SCALAR';

    return 1 if $self->cache == 2;
    return 0 if $self->cache == 0;

    my $file = IO::File->new;
    $file->open($self->cache_path, 'r') or return;
    $file->sysread(my $cache_mtime, length('#xxxxxxxxxx'));
    $file->close;
    my $orig_mtime = '#'.(stat($self->fullpath))[9];

    return $cache_mtime eq $orig_mtime;
}

sub _interpret_cached {
    my $self = shift;

    my $compiled = do $self->cache_path;
    $self->compiled($compiled);
    return $self->interpret(@_);
}

sub _doctype {
    my $self = shift;
    my ($type, $encoding) = @_;

    $type     ||= '';
    $encoding ||= 'utf-8';

    $type = lc $type;

    if ($type eq 'xml') {
        return '' if $self->format eq 'html5';
        return '' if $self->format eq 'html4';

        return qq|<?xml version='1.0' encoding='$encoding' ?>|;
    }

    if ($self->format eq 'xhtml') {
        if ($type eq 'strict') {
            return
              q|<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">|;
        }
        elsif ($type eq 'frameset') {
            return
              q|<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">|;
        }
        elsif ($type eq '5') {
            return '<!DOCTYPE html>';
        }
        elsif ($type eq '1.1') {
            return
              q|<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">|;
        }
        elsif ($type eq 'basic') {
            return
              q|<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML Basic 1.1//EN" "http://www.w3.org/TR/xhtml-basic/xhtml-basic11.dtd">|;
        }
        elsif ($type eq 'mobile') {
            return
              q|<!DOCTYPE html PUBLIC "-//WAPFORUM//DTD XHTML Mobile 1.2//EN" "http://www.openmobilealliance.org/tech/DTD/xhtml-mobile12.dtd">|;
        }
        else {
            return
              q|<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">|;
        }
    }
    elsif ($self->format eq 'html4') {
        if ($type eq 'strict') {
            return
              q|<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">|;
        }
        elsif ($type eq 'frameset') {
            return
              q|<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd">|;
        }
        else {
            return
              q|<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">|;
        }
    }
    elsif ($self->format eq 'html5') {
        return '<!DOCTYPE html>';
    }

    return '';
}

1;
__END__

=encoding utf-8

=head1 NAME

Text::Haml - Haml Perl implementation

=head1 SYNOPSIS

    use Text::Haml;

    my $haml = Text::Haml->new;

    my $html = $haml->render('%p foo'); # <p>foo</p>

    $html = $haml->render('= $user', user => 'friend'); # <div>friend</div>

    # Use Haml file
    $html = $haml->render_file('tmpl/index.haml', user => 'friend');

=head1 DESCRIPTION

L<Text::Haml> implements Haml
L<http://haml.info/docs/yardoc/file.REFERENCE.html> specification.

L<Text::Haml> passes specification tests written by Norman Clarke
https://github.com/haml/haml-spec and supports only cross-language Haml
features. Do not expect ruby or Rails specific extensions to work.

=head1 ATTRIBUTES

L<Text::Haml> implements the following attributes:

=head2 C<append>

Holds the string of code that is appended to the generated Perl code.

=head2 C<code>

Holds the Perl code.

=head2 C<compiled>

Holds compiled code.

=head2 C<encoding>

    $haml->encoding('utf-8');

Default is utf-8.

=head2 C<escape>

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

=head2 C<escape_html>

    $haml->escape_html(0);

Switch on/off Haml output html escaping. Default is on.

=head2 C<filters>

Holds filters.

=head2 C<format>

    $haml->format('xhtml');

Supported formats: xhtml, html, html5.

Default is xhtml.

=head2 C<namespace>

Holds the namespace under which the Perl package is generated.

=head2 C<prepend>

Holds the string of code that is prepended to the generated Perl code.

=head2 C<vars>

Holds the variables that are passed during the rendering.

=head2 C<vars_as_subs>

When options is B<NOT SET> (by default) passed variables are normal Perl
variables and are used with C<$> prefix.

    $haml->render('%p $var', var => 'hello');

When this option is B<SET> passed variables are Perl lvalue
subroutines and are used without C<$> prefix.

    $haml->render('%p var', var => 'hello');

But if you declare Perl variable in a block, it must be used with C<$>
prefix.

    $haml->render('<<EOF')
        - my $foo;
        %p= $foo
    EOF

=head2 C<helpers>

    helpers => {
        foo => sub {
            my $self   = shift;
            my $string = shift;

            $string =~ s/r/z/;

            return $string;
        }
    }

Holds helpers subroutines. Helpers can be called in Haml text as normal Perl
functions. See also add_helper.

=head2 C<helpers_arg>

    $haml->helpers_args($my_context);

First argument passed to the helper (L<Text::Haml> instance by default).

=head2 C<error>

    $haml->error;

Holds the last error.

=head2 C<tape>

Holds parsed haml elements.

=head2 C<path>

Holds path of Haml templates. Current directory is a default.
If you want to set several paths, arrayref can also be set up.
This way is the same as L<Text::Xslate>.

=head2 C<cache>

Holds cache level of Haml templates. 1 is a default.
0 means "Not cached", 1 means "Checked template mtime" and 2 means "Used always cached".
This way is the same as L<Text::Xslate>.

=head2 C<cache_dir>

Holds cache directory of Haml templates. $ENV{HOME}/.text_haml_cache is a default.
Unless $ENV{HOME}, File::Spec->tempdir was used.
This way is the same as L<Text::Xslate>.

=head1 METHODS

=head2 C<new>

    my $haml = Text::Haml->new;

=head2 C<add_helper>

    $haml->add_helper(current_time => sub { time });

Adds a new helper.

=head2 C<add_filter>

    $haml->add_filter(compress => sub { $_[0] =~ s/\s+/ /g; $_[0]});

Adds a new filter.

=head2 C<build>

    $haml->build(@_);

Builds the Perl code.

=head2 C<compile>

    $haml->compile;

Compiles parsed code.

=head2 C<interpret>

    $haml->interpret(@_);

Interprets compiled code.

=head2 C<parse>

    $haml->parse('%p foo');

Parses Haml string building a tree.

=head2 C<render>

$haml->render(Haml_string: Str [, %vars: Hash]): Str

    my $text = $haml->render('%p foo'); # <p>foo</p>

    my $text = $haml->render('%p= $var', var => 'hello'); # <p>hello</p>

    my %foo = ( bar => 'hello', baz => 'world', );
    my $text = $haml->render('%p= "$bar $baz"', %foo); # <p>hello world</p>

    my %foo = ( bar => 'hello', baz => 'world', );
    my $text = $haml->render('%p= "$var->{bar} $var->{baz}"', var => \%foo); # <p>hello world</p>

    my %foo = (var => { bar => 'hello', baz => 'world' });
    my $text = $haml->render('%p= $var->{bar} ." ". $var->{baz}', %foo); # <p>hello world</p>

    my %foo = (var => [ qw/hello world/ ]);
    my $page = $haml->render('%p= "$var->[0] $var->[1]"', %foo); # <p>hello world</p>

Gets Haml string and optional variables. Returns undef on error. See error attribute.

=head2 C<render_file>

$haml->render_file(filename: Str [, %vars: Hash]): Str

The file name can be a file on disk (the default path is the current directory) or virtual path to the file (if you use the module Data::Section::Simple). 
The file path specified in the constructor of a template engine in attribute 'path'

    # Current directory is a default.
    my $haml = Text::Haml->new;
    my %foo = ( bar => 'hello', baz => 'world', );
    my $page = $haml->render_file('foo.haml', var => \%foo); # <p>hello world</p>

    # Set directory 'template'
    my $haml = Text::Haml->new(path => 'template');
    my %foo = ( bar => 'hello', baz => 'world', );
    my $page = $haml->render_file('foo.haml', var => \%foo); # <p>hello world</p>

    # Set virtual path (with Data::Section::Simple)
    use Data::Section::Simple qw/get_data_section/;

    my $vpath = get_data_section;

    my $haml = Text::Haml->new(path => [$vpath]);
    my %foo = ( bar => 'hello', baz => 'world', );
    my $page = $haml->render_file('foo.haml', var => \%foo); # <p>hello world</p>

    __DATA__

    @@ foo.haml
    %p= "$var->{bar} $var->{baz}"

For more examples with variables see render method

A helper method that loads a file and passes it to the render method.
Since "%____vars" is used internally, you cannot use this as parameter name.

=head1 PERL SPECIFIC IMPLEMENTATION ISSUES

=head2 String interpolation

Despite of existing string interpolation in Perl, Ruby interpolation is also
supported.

$haml->render('%p Hello #{user}', user => 'foo')

=head2 Hash keys

When declaring tag attributes C<:> symbol can be used.

$haml->render("%a{:href => 'bar'}");

Perl-style is supported but not recommented, since your Haml template won't
work with Ruby Haml implementation parser.

$haml->render("%a{href => 'bar'}");

=head2 Using with Data::Section::Simple

When using the Data::Section::Simple, you need to unset the variable C<encoding> in the constructor or using the C<encoding> attribute of the Text::Haml:

    use Data::Section::Simple qw/get_data_section/;
    my $vpath = get_data_section;

    my $haml = Text::Haml->new(cache => 0, path => $vpath, encoding => '');
    # or
    #my $haml = Text::Haml->new(cache => 0, path => $vpath);
    #$haml->encoding(''); # encoding attribute

    my $index = $haml->render_file('index.haml');
    say $index;

    __DATA__

    @@ index.haml
    %strong текст

see L<https://metacpan.org/pod/Data::Section::Simple#utf8-pragma>

=head1 DEVELOPMENT

=head2 Repository

    http://github.com/vti/text-haml

=head1 AUTHOR

Viacheslav Tykhanovskyi, C<vti@cpan.org>.

=head1 CREDITS

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

Mark Aufflick (aufflick)

Graham Todd (grtodd)

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009-2017, Viacheslav Tykhanovskyi.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut
