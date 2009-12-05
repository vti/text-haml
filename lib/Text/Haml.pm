package Text::Haml;

use strict;
use warnings;

use IO::File;
use Scalar::Util qw/weaken/;
use Encode qw/decode/;

our $VERSION = '0.010201';

use constant CHUNK_SIZE => 4096;

sub new {
    my $class = shift;

    # Default attributes
    my $attrs = {};
    $attrs->{tape}        = [];
    $attrs->{encoding}    = 'utf-8';
    $attrs->{escape_html} = 1;
    $attrs->{helpers}     = {};
    $attrs->{format}      = 'xhtml';
    $attrs->{prepend}     = '';
    $attrs->{append}      = '';
    $attrs->{namespace}   = '';
    $attrs->{vars}        = {};
    $attrs->{escape}      = <<'EOF';
    my $s = shift;
    $s =~ s/&/&amp;/g;
    $s =~ s/</&lt;/g;
    $s =~ s/>/&gt;/g;
    $s =~ s/"/&quot;/g;
    $s =~ s/'/&apos;/g;
    return $s;
EOF

    $attrs->{filters} = {
        plain    => sub { $_[0] =~ s/\n*$//; $_[0] },
        escaped  => sub { $_[0] },
        preserve => sub { $_[0] =~ s/\n/&#x000A;/g; $_[0] },
        javascript => sub {
            "<script type='text/javascript'>\n"
              . "  //<![CDATA[\n"
              . "    $_[0]\n"
              . "  //]]>\n"
              . "</script>";
        },
    };

    my $self = {%$attrs, @_};
    bless $self, $class;

    $self->{helpers_arg} ||= $self;
    weaken $self->{helpers_arg};

    return $self;
}

# Yes, i know!
sub format   { @_ > 1 ? $_[0]->{format}   = $_[1] : $_[0]->{format} }
sub tape     { @_ > 1 ? $_[0]->{tape}     = $_[1] : $_[0]->{tape} }
sub encoding { @_ > 1 ? $_[0]->{encoding} = $_[1] : $_[0]->{encoding} }

sub escape_html {
    @_ > 1
      ? $_[0]->{escape_html} = $_[1]
      : $_[0]->{escape_html};
}
sub code     { @_ > 1 ? $_[0]->{code}     = $_[1] : $_[0]->{code} }
sub compiled { @_ > 1 ? $_[0]->{compiled} = $_[1] : $_[0]->{compiled} }
sub helpers  { @_ > 1 ? $_[0]->{helpers}  = $_[1] : $_[0]->{helpers} }
sub helpers_arg  { @_ > 1 ? $_[0]->{helpers_arg}  = $_[1] :
    $_[0]->{helpers_arg} }
sub filters  { @_ > 1 ? $_[0]->{filters}  = $_[1] : $_[0]->{filters} }
sub prepend  { @_ > 1 ? $_[0]->{prepend}  = $_[1] : $_[0]->{prepend} }
sub append   { @_ > 1 ? $_[0]->{append}   = $_[1] : $_[0]->{append} }
sub escape   { @_ > 1 ? $_[0]->{escape}   = $_[1] : $_[0]->{escape} }
sub vars   { @_ > 1 ? $_[0]->{vars}   = $_[1] : $_[0]->{vars} }

sub namespace {
    @_ > 1
      ? $_[0]->{namespace} = $_[1]
      : $_[0]->{namespace};
}
sub error { @_ > 1 ? $_[0]->{error} = $_[1] : $_[0]->{error} }

our @AUTOCLOSE = (qw/meta img link br hr input area param col base/);

sub add_helper {
    my $self = shift;
    my ($name, $code) = @_;

    $self->helpers->{$name} = $code;
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

    my $level_token      = quotemeta ' ';
    my $escape_token     = quotemeta '&';
    my $unescape_token   = quotemeta '!';
    my $expr_token       = quotemeta '=';
    my $tag_start        = quotemeta '%';
    my $class_start      = quotemeta '.';
    my $id_start         = quotemeta '#';
    my $attributes_start = quotemeta '{';
    my $attributes_end   = quotemeta '}';
    my $attributes_start2= quotemeta '(';
    my $attributes_end2  = quotemeta ')';
    my $filter_token     = quotemeta ':';
    my $quote            = "'";
    my $comment_token    = quotemeta '-#';
    my $trim_in          = quotemeta '<';
    my $trim_out         = quotemeta '>';

    my $tape = $self->tape;

    my $level;
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

        my $el = {level => $level, type => 'text', line => $line};

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
            if ($prev->{level} < $el->{level} || ($i + 1 < @lines && $line eq ''))
            {
                $prev->{text} .= "\n" if $prev->{text};
                $prev->{text} .= $line;
                $prev->{line} .= "\n" . (' ' x $el->{level}) . $el->{line};
                next;
            }
        }

        # Filter
        if ($line =~ m/^:(.*)/) {
            $el->{type} = 'filter';
            $el->{name} = $1;
            $el->{text} = '';
            push @$tape, $el;
            next;
        }

        # Doctype
        if ($line =~ m/^!!!(?: ([^ ]+)(?: (.*))?)?$/) {
            $el->{type} = 'text';
            $el->{text} = $self->_doctype($1, $2);
            push @$tape, $el;
            next;
        }

        # HTML comment
        if ($line =~ m/^\/(?:\[if (.*)?\])?(?: (.*))?/) {
            $el->{type} = 'html_comment';
            $el->{if} = $1 if $1;
            $el->{text} = $2 if $2;
            push @$tape, $el;
            next;
        }

        # Escaping, everything after is a text
        if ($line =~ s/^\\//) {
            $el->{type} = 'text',
            $el->{text} = $line;
            push @$tape, $el;
            next;
        }

        # Block
        if ($line =~ s/^- \s*(.*)//) {
            $el->{type} = 'block';
            $el->{text} = $1;
            push @$tape, $el;
            next;
        }

        # Preserve whitespace
        if ($line =~ s/^~ \s*(.*)//) {
            $el->{type} = 'text';
            $el->{text} = $1;
            $el->{expr} = 1;
            $el->{preserve_whitespace} = 1;
            push @$tape, $el;
            next;
        }

        # Tag
        if ($line =~ m/^(?:$tag_start
            |$class_start
            |$id_start
            |$attributes_start
            |$attributes_start2
            |$escape_token
            |$unescape_token
            )/x
          )
        {
            if ($line =~ s/^$tag_start([^ \({.<>#!&=\/]+)//) {
                $el->{type} = 'tag';
                $el->{name} = $1;
            }

            while (1) {
                if ($line =~ s/^\.([^ \({#\.!&=<>\/]+)//) {
                    my $class = join(' ', split(/\./, $1));

                    $el->{type} = 'tag';
                    $el->{name} ||= 'div';
                    $el->{class} ||= [];
                    push @{$el->{class}},$class;
                }
                elsif ($line =~ s/^\#([^ \({#\.!&=<>\/]+)//) {
                    my $id = $1;

                    $el->{type} = 'tag';
                    $el->{name} ||= 'div';
                    $el->{id} = $id;
                }
                else {
                    last;
                }
            }

            if ($line =~ s/$attributes_start(.*?)$attributes_end//) {
                my $attrs = $1;

                my @attr = split(/\s*,\s*/, $attrs);
                $attrs = [];
                foreach my $attr (@attr) {
                    my $name;
                    if ($attr =~ s/^\s*('|")(.*?)\1\s*=>//x) {
                        $name = $2;
                    }
                    elsif ($attr =~ s/^\s*:?([^ ]+)\s*=>//x) {
                        $name = $1;
                    }
                    else {
                        next;
                    }

                    if ($attr =~ s/^\s*('|")(.*?)\1\s*$//x) {
                        push @$attrs, $name => {type => 'text', text => $2};
                    }
                    elsif ($attr =~ s/^\s*([^ ]+)\s*$//x) {
                        push @$attrs, $name => {type => 'expr', text => $1};
                    }
                    else {
                        next;
                    }
                }

                $el->{type} = 'tag';
                $el->{attrs} = $attrs if @$attrs;
            }

            if ($line =~ s/$attributes_start2(.*?)$attributes_end2//) {
                my $list = $1;

                my $attrs = [];
                while (1) {
                    if ($list =~ s/^\s*(.*?)\s*=\s*('|")(.*?)\2\s*//) {
                        push @$attrs, $1 => {type => 'text', text => $3};
                    }
                    elsif ($list =~ s/^\s*(.*?)\s*=\s*([^ ]+)\s*//) {
                        push @$attrs, $1 => {type => 'expr', text => $2};
                    }
                    else {
                        last;
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
            && ($line =~ s/\/$// || grep { $el->{name} eq $_ } @AUTOCLOSE))
        {
            $el->{autoclose} = 1;
        }

        $line =~ s/^ // if $line;

        # Multiline
        if ($line && $line =~ s/(\s*)\|$//) {

            # For the first time
            if (!$tape->[-1] || ref $tape->[-1]->{text} ne 'ARRAY') {
                $el->{text} = [$line];
                $el->{line} = $el->{line} . "\n" || $line . "$1|\n";

                push @$tape, $el;
            }

            # Continue concatenation
            else {
                my $prev_el = $tape->[-1];
                push @{$prev_el->{text}}, $line;
                $prev_el->{line} .= $line . "$1|\n";
            }
        }

        # For the last time
        elsif ($tape->[-1] && ref $tape->[-1]->{text} eq 'ARRAY') {
            $tape->[-1]->{text} = join(" ", @{$tape->[-1]->{text}}, $line);
            $tape->[-1]->{line} .= $line;
        }

        # Normal text
        else {
            $el->{text} = $line if $line;

            push @$tape, $el;
        }
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

    my $namespace = $self->namespace || ref($self) . '::template';
    $code .= qq/package $namespace; $ESCAPE; sub { my \$_H = ''; /;

    # Embed variables
    foreach my $var (sort keys %vars) {
        $code .= qq/my \$$var = \$self->vars->{$var};/;
    }

    $code .= $self->prepend;

    # Install helpers
    for my $name (sort keys %{$self->helpers}) {
        next unless $name =~ m/^\w+$/;

        $code .= "sub $name;";
        $code .= " *$name = sub { \$self";
        $code .= "->helpers->{'$name'}->(\$self->helpers_arg, \@_) };";
    }

    my $stack = [];

    my @lines;
    my $count = 0;
    for my $el (@{$self->tape}) {
        my $offset = '';
        $offset .= ' ' x $el->{level};

        my $prev_el = $stack->[-1];

        if ($prev_el && $prev_el->{type} eq 'comment') {
            if ($prev_el->{level} == $el->{level}) {
                pop @$stack;
            }
            else {
                next;
            }
        }

        if ($el->{line} && $prev_el && $prev_el->{level} >= $el->{level}) {
            while (my $poped = pop @$stack) {
                my $poped_offset = ' ' x $poped->{level};

                my $ending = '';
                if ($poped->{type} eq 'tag') {
                    $ending .= "</$poped->{name}>";
                }
                elsif ($poped->{type} eq 'html_comment') {
                    $ending .= "<![endif]" if $poped->{if};
                    $ending .= "-->";
                }
                push @lines, qq|\$_H .= "$poped_offset$ending\n";|;

                last if $poped->{level} == $el->{level};
            }
        }

        my $output = '';
        if ($el->{type} eq 'tag') {
            my $ending =
              $el->{autoclose} && $self->format eq 'xhtml' ? ' /' : '';

            my $attrs = '';
            if ($el->{attrs}) {
                for (my $i = 0; $i < @{$el->{attrs}}; $i += 2) {
                    if ($el->{attrs}->[$i] eq 'class') {
                        $el->{class} ||= [];
                        push @{$el->{class}}, $el->{attrs}->[$i + 1]->{text};
                        next;
                    }
                    elsif ($el->{attrs}->[$i] eq 'id') {
                        $el->{id} ||= '';
                        $el->{id} = $el->{id} . '_' if $el->{id};
                        $el->{id} .= $el->{attrs}->[$i + 1]->{text};
                        next;
                    }

                    $attrs .= ' ';
                    $attrs .= $el->{attrs}->[$i];
                    $attrs .= '=';
                    my $text = $el->{attrs}->[$i + 1]->{text};
                    if ($el->{attrs}->[$i + 1]->{type} eq 'text') {
                        $attrs .= "'$text'";
                    }
                    else {
                        $attrs .= qq/'" . $text . "'/;
                    }
                }
            }

            my $tail = '';
            if ($el->{class}) {
                $tail .= qq/ class='/;
                $tail .= join(' ', sort @{$el->{class}});
                $tail .= qq/'/;
            }

            if ($el->{id}) {
                $tail .= qq/ id='$el->{id}'/;
            }

            $output .= qq|"$offset<$el->{name}$tail$attrs$ending>"|;

            if ($el->{text} && $el->{expr}) {
                $output .= '. ' . $el->{text};
                $output .= qq| . "</$el->{name}>"|;
            }
            elsif ($el->{text}) {
                $output .= '. "' . quotemeta($el->{text}) . '"';
                $output .= qq|. "</$el->{name}>"| unless $el->{autoclose};
            }
            elsif (
                !$self->tape->[$count + 1]
                || (   $self->tape->[$count + 1]
                    && $self->tape->[$count + 1]->{level} == $el->{level})
              )
            {
                $output .= qq|. "</$el->{name}>"| unless $el->{autoclose};
            }
            elsif (!$el->{autoclose}) {
                push @$stack, $el;
            }

            $output .= qq|. "\n"|;
            $output .= qq|;|;
        }
        elsif ($el->{type} eq 'text') {
            $output = qq/"$offset"/;

            $el->{text} = '' unless defined $el->{text};

            if ($el->{expr}) {
                my $escape = '';
                if ((!exists $el->{escape} && $self->escape_html) || (exists
                        $el->{escape} && $el->{escape} == 1)) {
                    $escape = 'escape';
                }

                $output .= qq/. $escape / . +$el->{text};
                $output .= qq/;\$_H .= "\n"/;
            }
            elsif ($el->{text}) {
                $output .= qq/. "/ . quotemeta($el->{text}) . '"';
                $output .= qq/. "\n"/;
            }

            $output .= qq/;/;
        }
        elsif ($el->{type} eq 'block') {
            push @lines, $el->{text};
        }
        elsif ($el->{type} eq 'html_comment') {
            $output = qq/"$offset"/;

            $output .= qq/ . "<!--"/;
            $output .= qq/ . "[if $el->{if}]>"/ if $el->{if};

            if ($el->{text}) {
                $output .= qq/. " $el->{text} -->\n"/;
            }
            else {
                $output .= qq/. "\n"/;
                push @$stack, $el;
            }

            $output .= qq/;/;
        }
        elsif ($el->{type} eq 'comment') {
            push @$stack, $el;
        }
        elsif ($el->{type} eq 'filter') {
            my $filter = $self->filters->{$el->{name}};
            die "unknown filter: $el->{name}" unless $filter;

            if ($el->{name} eq 'escaped') {
                $output = qq/escape "/ . quotemeta($el->{text}) . qq/\n";/;
            }
            else {
                $el->{text} = $filter->($el->{text});

                my $text = quotemeta($el->{text});
                $text =~ s/\\\n/\\n/g;
                $output = qq/"/ . $text . qq/\n";/;
            }
        }
        else {
            die "unknown type=" . $el->{type};
        }

        push @lines, '$_H .= ' . $output if $output;

        $count++;
    }

    my $last_empty_line = 0;
    $last_empty_line = 1
      if $self->tape->[-1] && $self->tape->[-1]->{line} eq '';

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

        push @lines, qq|\$_H .= "$offset$ending\n";|;
    }

    if ($lines[-1]) {
        $lines[-1] =~ s/\n";$/";/ unless $last_empty_line;
    }

    $code .= join("\n", @lines);

    $code .= $self->append;

    $code .= q/return $_H; };/;

    $self->code($code);
    return $self;
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

    $self->vars({@_});

    my $compiled = $self->compiled;

    my $output = eval { $compiled->() };

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

sub render_file {
    my $self = shift;
    my $path = shift;

    # Open file
    my $file = IO::File->new;
    $file->open("< $path") or die "Can't open template '$path': $!";
    binmode $file, ':utf8';

    # Slurp file
    my $tmpl = '';
    while ($file->sysread(my $buffer, CHUNK_SIZE, 0)) {
        $tmpl .= $buffer;
    }

    # Encoding
    $tmpl = decode($self->encoding, $tmpl) if $self->encoding;

    # Render
    return $self->render($tmpl, @_);
}

sub _doctype {
    my $self = shift;
    my ($type, $encoding) = @_;

    $type ||= '';
    $encoding ||= 'utf-8';

    $type = lc $type;

    if ($type eq 'xml') {
        return '' if $self->format eq 'html5';
        return '' if $self->format eq 'html4';

        return qq|<?xml version='1.0' encoding='$encoding' ?>|;
    }

    if ($self->format eq 'xhtml') {
        if ($type eq 'strict') {
            return q|<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">|;
        }
        elsif ($type eq 'frameset') {
            return q|<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Frameset//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-frameset.dtd">|;
        }
        elsif ($type eq '5') {
            return '<!DOCTYPE html>';
        }
        elsif ($type eq '1.1') {
            return q|<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">|;
        }
        elsif ($type eq 'basic') {
            return q|<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML Basic 1.1//EN" "http://www.w3.org/TR/xhtml-basic/xhtml-basic11.dtd">|;
        }
        elsif ($type eq 'mobile') {
            return q|<!DOCTYPE html PUBLIC "-//WAPFORUM//DTD XHTML Mobile 1.2//EN" "http://www.openmobilealliance.org/tech/DTD/xhtml-mobile12.dtd">|;
        }
        else {
            return q|<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">|;
        }
    }
    elsif ($self->format eq 'html4') {
        if ($type eq 'strict') {
            return q|<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">|;
        }
        elsif ($type eq 'frameset') {
            return q|<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Frameset//EN" "http://www.w3.org/TR/html4/frameset.dtd">|;
        }
        else {
            return q|<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">|;
        }
    }
    elsif ($self->format eq 'html5') {
        return '<!DOCTYPE html>';
    }

    return '';
}

1;
