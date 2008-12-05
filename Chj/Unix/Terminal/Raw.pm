# Tue Jul 20 19:32:20 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Unix::Terminal::Raw

=head1 SYNOPSIS

 use Chj::Unix::Terminal::Raw;
 my $obj=Chj::Unix::Terminal::Raw->new;
 # we are still cooked now.
 $obj->raw;
 # raw now.
 $obj->cooked;
 # or just wait until object destruction, it'll call cooked then, unless
 # you override that by calling $obj->set_is_raw(0) before destruction.
 $obj->alwaysraw;
 # always leave it raw, no set_is_raw(0) needed.

 my $o= Chj::Unix::Terminal::Raw->raw;
 # we are immediately raw now. rest stays the same.

 my $p= Chj::Unix::Terminal::Raw->raw(*SOMEOTHERFHTHANSTDIN{IO});

=head1 DESCRIPTION


=cut


package Chj::Unix::Terminal::Raw;

use strict;

use POSIX qw(:termios_h);

my $echo     = ECHO | ECHOK | ICANON;

sub new {
    my $class=shift;
    my ($fh)=@_;
    $fh||=*STDIN{IO};

    my $s= bless {},$class;

    $$s{fd_stdin} = fileno($fh);
    $$s{term}     = POSIX::Termios->new();
    $$s{term}->getattr($$s{fd_stdin});
    $$s{oterm}     = $$s{term}->getlflag();

    $$s{noecho}   = $$s{oterm} & ~$echo;

    $s
}

sub raw {
    #warn "raw called with: @_";
    my $s=shift;
    if (ref$s) {
	return if $$s{is_raw};# well. sure?
	$$s{term}->setlflag($$s{noecho});
	$$s{term}->setcc(VTIME, 1);
	$$s{term}->setattr($$s{fd_stdin}, TCSANOW);
	#warn "habe auf raw gesetzt hoffichdoch";
	$$s{is_raw}=1;
    } else {
	#$s->new(@_)->raw  ich tubel
	my $s=$s->new(@_);
	$s->raw;
	$s
    }
}

*cbreak=\&raw; #dunno why it was called cbreak. maybe i'm missing something. like multiple raw modes. so be it ?

#use Carp;
sub cooked {
    #warn "cooked called with: @_";
    my $s=shift;
    if (ref$s) {
	return if $$s{alwaysraw};
	return if not $$s{is_raw};# well. sure?
	$$s{term}->setlflag($$s{oterm});
	$$s{term}->setcc(VTIME, 0);
	$$s{term}->setattr($$s{fd_stdin}, TCSANOW);
	#confess "habe auf cooked gesetzt hoffichdoch";
	$$s{is_raw}=0;
    } else {
	$s= $s->new(@_);
	$s->cooked;
	$s
    }
}

sub set_is_raw {
    my $s=shift;
    ($$s{is_raw})=@_;
}

sub alwaysraw {
    my $s=shift;
    if (ref$s) {
	$s->raw unless $$s{is_raw};
	$$s{alwaysraw}=1;
    }else {
	$s->new(@_)->alwaysraw
    }
}

sub DESTROY {
    my $s=shift;
    local ($@,$!,$?);
    $s->cooked if $$s{is_raw}
}



1;
