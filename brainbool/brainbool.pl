#!/usr/bin/perl -w

use Getopt::Long;
use strict;
use warnings;
use integer;

Getopt::Long::Configure ("bundling");

my $help =<<EOH;
brainbool.pl - Brainbool interpreter in perl

 Usage:
  perl brainbool.pl [ opts ] program
  cat program | perl brainbool.pl [ opts ]

 Mode Options:
 There are several modes of operation. Some modes can be combined in one call
 the --interpret mode is the default mode

 -i
 --interpret
           The default mode of operation; interpret a brainbool program.

 -n
 --input   Convert a stream of characters to a stream of '0's and '1's
           (inputs on STDIN & outputs on STDOUT)
           Can be combined with --interpret if brainbool source is in
            a file and input stream is on STDIN
           Can be combined with --to-brainbool and --interpret if
            brainfuck source is in a file and input stream is on STDIN
           Brainfuck/Brainbool source can be on STDIN if --bang is used

 -o
 --output  Convert a stream of '0's and '1's to a stream of characters
           (inputs on STDIN & outputs on STDOUT)
           '0' and '1' characters may each be on their own line
           Can be combined with --interpret

 -g
 --3digit  3 digit binary code mode
           As a standalone mode, --3digit converts standard brainbool
           As a standalone mode, --no3digit converts 3 digit binary to
            standard brainbool
           Can be combined with --to-brainfuck
           Can be combined with --to-brainbool to output converted brainfuck
            instructions as 3 digit binary code
           Can be combined with --interpret to interpret 3 digit binary code
            instructions

 -c
 --to-brainbool
 --bb      Convert a brainfuck program to brainbool
           Can be combined with --interpret and --3digit

 -f
 --to-brainfuck
 --bf      Convert a  brainboolprogram to brainfuck
           Assumes 8-bit non-wrapping cells and left-terminated tape
           Can be combined with --3digit

 Supporting options:
 -b
 --bang    Read program on STDIN and stop at the first "!" character.
           Everything following the first "!" is input to the program.
           In --to-brainbool or --to-brainfuck mode, append a "!" after
           the program is output
           When --3digit is specified, use "000" instead of "!"

 --inl     Each input character is followed by a newline

 --onl     Follow each output character by a newline

 -w
 --wrap    For use with --to-brainbool
           Source brainfuck code uses 8-bit "wraparound" + and -

 -d
 --debug   Valid only in --interpret mode
           Print the operation and tape with every step

--order STRING
           For use with --3digit only. Applies a custom numerical order
            to the 3 digit instructions.
           E.g. --order '+.,<>[]' assigns 011 (binary for 3) to the
            instruction ',' and 110 (binary for 6) to the instruction '['

--little-endian
          For use with --3digit only. The first digit read or output is
           the least significant bit of the operand.

 -h
 --help    This help

 see http://esolangs.org/wiki/Brainbool for more information on Brainbool

 license: Public Domain

EOH

my $interpret;
my $proc_inp;
my $proc_out;
my $digit;
my $from_bf;
my $to_bf;
my $bang;
my $inl;
my $onl;
my $wrap;
my $debug;

my @toks = split("", "><+,.[]");
my %tok;
@tok{@toks} = @toks;
if ($digit) {
  $tok{$toks[$_]} = reverse(sprintf("%03b", $_)) for (1..7);
  $tok{reverse(sprintf("%03b", $_))} = $toks[$_] for (1..7);
}

GetOptions ('help|h' => sub {
             print "$help";
             exit 0; },
            'interpret|i' => \$interpret,
            'input|n' => \$proc_inp,
            'output|o' => \$proc_out,
            '3digit|g!' => \$digit,
            'to-brainbool|bb|c' => \$from_bf,
            'to-brainfuck|bf|f' => \$to_bf,
            'bang|b' => \$bang,
            'inl' => \$inl,
            'onl' => \$onl,
            'wrap|w' => \$wrap,
            'debug|d' => \$debug);

my $bang_str = $digit ? "000" : "!";

# read in brainbool
sub read_bb {
  my $source = "";
  my($ch, $tri);
  if ($bang) {
    # if --bang was specified, the source is on STDIN and we only want to
    #  read as far as the "!" & leave the rest for the program
    if ($digit) {
      while (1) {
        $tri = "";
        for (1..3) {
          die "no \"000\" ever found on STDIN\n"
            unless defined($ch = nextchar());
          redo if $ch !~ /[01]/;
          $tri .= $ch;
        }
        last if $tri eq $bang_str;
        $source .= $tok{$tri};
      }
    } else {
      my $ch;
      while (1) {
        $ch = nextchar();
        die "no \"!\" ever found on STDIN\n" unless defined $ch;
        last if $ch eq $bang_str;
        $source .= $ch;
      }
    }
  } else {
    $source = join('', map { chomp } <>);
    $source =~ s/\s//sg;
    while ($digit && $source =~ s/^[^01]*([01]{3})/$tok{$1}/) { };
  }
  $source =~ s/[^-+\[\]<>,\.]//sg;
  return $source;
}

sub nextchar {
  # wrap getc() in case --inl is specified
  my $ch = getc();
  if ($inl) {
    my $c2 = getc();
    die "no newline after input character\n"
      if defined($ch) and (!defined $c2 || $c2 ne "\n");
  }
  return $ch;
}

# --interpret is the default mode
$interpret = $interpret || (!$from_bf && !$to_bf &&
                            !$proc_inp && !$proc_out && !$digit);

if ($to_bf) {
  # --to-brainfuck specified
  die "--to-brainfuck cannot be combined with any mode other than --3digit\n"
    if $interpret || $from_bf || $proc_out || $proc_inp;

  # --bang here only applies to output
  my $b2 = $bang;
  $bang = 0;
  read_bb();
  $bang = $b2;
  die "not implemented";
} elsif ($from_bf) {
  if ($interpret) {
    interpret(proc_bf());
  } else {
    my $source = proc_bf();
    $source = 
    print $source;
  }
  exit 0;
} elsif ($interpret) {
  my $source = "";
  if ($bang) {
    if ($digit) {
      my $tri;
      my $ch;
      while (1) {
        $tri = "";
        for (1..3) {
          die "no \"000\" ever found on STDIN\n" unless defined($ch = getc());
          $tri .= $ch;
        }
        last if $tri eq $bang_str;
        $source .= $tri;
      }
    } else {
      my $ch;
      while (($ch = getc()) ne $bang_str) {
        die "no \"!\" ever found on STDIN\n" unless defined $ch;
        $source .= $ch;
      }
    }
  } else {
    $source = join('', <>);
  }
  interpret($source, "");
  exit 0;
} elsif ($proc_inp) {
  print proc_inp();
  exit 0;
} elsif ($proc_out) {
  proc_out();
} else {
  die "how are we here\n";
}

sub proc_bf {
  my $source;

  if ($bang && $proc_inp && ($#ARGV < 0 || ($ARGV[0] eq "-"))) {
    my $ch;
    while (($ch = getc()) ne "!") {
      die "no \"!\" ever found on STDIN\n" unless defined $ch;
      $source .= $ch;
    }
  } else {
    $source = join('', <>);
  }

  $source =~ s/[^-+\[\]<>,\.]//gs;

  $source =~ s/-/A/g;
  $source =~ s/\+/B/g;
  $source =~ s/\[/C/g;
  $source =~ s/\]/D/g;
  $source =~ s/</E/g;
  $source =~ s/>/F/g;
  $source =~ s/,/G/g;
  $source =~ s/\./H/g;

  while ($source =~ s/AB//g || $source =~ s/BA//g ||
         $source =~ s/EF//g || $source =~ s/FE//g ||
         (!$wrap && $source =~ s/AA/IA/g) ||
         (!$wrap && $source =~ s/AI/IA/g) ||
         (!$wrap && $source =~ s/BB/JB/g) ||
         (!$wrap && $source =~ s/BJ/JB/g)) { }

  $source =~ s/A/>>>>>>>>>+<<<<<<<<+[>+]<[<]>>>>>>>>>[+]<<<<<<<<</g;
  $source =~ s/B/>[>]+<[+<]>>>>>>>>>[+]<<<<<<<<</g;
  $source =~ s/C/>>>>>>>>>+<<<<<<<<+[>+]<[<]>>>>>>>>>[+<<<<<<<<[>]+<[+<]/g;
  $source =~ s/D/>>>>>>>>>+<<<<<<<<+[>+]<[<]>>>>>>>>>]<[+<]/g;
  $source =~ s/E/<<<<<<<<</g;
  $source =~ s/F/>>>>>>>>>/g;
  $source =~ s/G/>,>,>,>,>,>,>,>,<<<<<<<</g;
  $source =~ s/H/>.>.>.>.>.>.>.>.<<<<<<<</g;
  $source =~ s/I/>>>>>>>>>+<<<<<<<<+[>+]<[<]/g;
  $source =~ s/J/>[>]+<[+<]/g;

  while ($source =~ s/><//g || $source =~ s/<>//g) { }

  if ($digit) {
    $source =~ s/\Q$_\E/$tok{$_}/g for @toks;
  }
  $source .= $bang_str if $bang;
  $source = join("\n", split(//, $source), "") if $onl;

  return $source;
}

sub proc_inp {
  my $out = "";
  while (<>) {
    while (length($_) >= 1) {
      $out .= reverse(sprintf('%08b', ord(substr($_, 0, 1, ""))));
    }
  }
  $out = join("\n", split(//, $out), "") if $inl;
  return $out;
}

sub proc_out {
  my $bits = "";
  while (<>) {
    s/\n//gs;
    $bits .= $_;
    while (length($bits) >= 8) {
      print chr(eval("0b" . reverse(substr($bits, 0, 8, ""))));
    }
  }
  exit 0
}

sub interpret {
  my $source = shift;
  my $input = shift;

  my @bracket;
  my @tape = (0);
  my $t_ptr = 0;
  my @prog;

  my $prog_i;
  my $bits = "";

  while (length($source)) {
    my $i2 = $prog_i++;
    my $tok = substr($source, 0, $digit ? 3 : 1, "");
    if ($tok eq $tok{">"}) {
      push @prog, $debug ?
        sub { debug($i2, ">", $t_ptr, @tape);
              $t_ptr++; $tape[$t_ptr] = 0 if $t_ptr > $#tape; } :
        sub { $t_ptr++; $tape[$t_ptr] = 0 if $t_ptr > $#tape; };
    } elsif ($tok eq $tok{"<"}) {
      push @prog, $debug ?
        sub { debug($i2, "<", $t_ptr, @tape); $t_ptr--; } :
        sub { $t_ptr--; };
    } elsif ($tok eq $tok{"+"}) {
      push @prog, $debug ?
        sub { debug($i2, "+", $t_ptr, @tape);
              $tape[$t_ptr] = !$tape[$t_ptr]; } :
        sub { $tape[$t_ptr] = !$tape[$t_ptr]; };
    } elsif ($tok eq $tok{","}) {
      push @prog, $debug ?
        sub { debug($i2, ",", $t_ptr, @tape);
              my $ch;
              if ($proc_inp && !length($input)) {
                $ch = getc();
                $input = defined($ch) ?
                  reverse(sprintf('%08b', ord($ch))) : "0";
              }
              $ch = length($input) ? substr($input, 0, 1, "") : getc();
              $tape[$t_ptr] = defined($ch) ? $ch + 0 : 0; } :
        $proc_inp ?
          sub {
            if ($input eq "") {
              my $ch = getc();
              $input = defined($ch) ? reverse(sprintf('%08b', ord($ch))) : "0";
            }
            $tape[$t_ptr] = substr($input, 0, 1, "") + 0; 
          } :
          sub { my $ch = length($input) ? substr($input, 0, 1, "") : getc();
                $tape[$t_ptr] = defined($ch) ? $ch + 0 : 0; };
    } elsif ($tok eq $tok{"."}) {
      push @prog, $debug ?
        sub { debug($i2, ".", $t_ptr, @tape);
              print("output: ", $tape[$t_ptr] ? "1\n" : "0\n"); } :
        $proc_out ?
          sub { $bits .= $tape[$t_ptr] ? "1" : "0";
                print chr(eval("0b" . reverse(substr($bits, 0, 8, ""))))
                  if (length($bits) >= 8); } :
          sub { print($tape[$t_ptr] ? "1" : "0"); };
    } elsif ($tok eq $tok{"["}) {
      push @prog, sub { debug($i2, "[", $t_ptr, @tape); } if $debug;
      push @bracket, $#prog+1;
    } elsif ($tok eq $tok{"]"}) {
      do {
        my @p2 = splice @prog, pop(@bracket);
        push @prog, $debug ?
          sub { debug($i2, "]", $t_ptr, @tape);
                @prog = (@p2, shift, @prog) if $tape[$t_ptr] } :
          sub { @prog = (@p2, shift, @prog) if $tape[$t_ptr] };
      };
    } else {
      $prog_i--;
    }
  }

  while (scalar @prog) {
    print join(" ", map { $_ ? 1 : 0 } @tape[0 .. $t_ptr]), "@",
      join(" ", map { $_ ? 1 : 0 } @tape[$t_ptr+1 .. $#tape]), "\n" if $debug;
    my $i = shift @prog;
    $i->($i);
  }
}

sub debug {
  my $i = shift;
  printf '%5d  %s: ', $i, shift;
  $i = shift;
  print join(" ", map { $_ ? 1 : 0 } @_[0 .. $i]), "@",
    join(" ", map { $_ ? 1 : 0 } @_[$i+1 .. $#_]), "\n";

}
