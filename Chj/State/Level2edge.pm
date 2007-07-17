# Wed Dec  1 16:25:58 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::State::Level2edge

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::State::Level2edge;

use strict;

use Class::Array -fields=>
  -publica=>
  'last', # last data, Chj::State::Data obj
  #'new'  heh  get_new  and so.
  #'cur', # hash with new data.  but why not write back right to the 'last' data pool?
  ;

our $START_ALARMSTATE=0; # 0 = ok ,  1 = alarm

sub new {
    my $class=shift;
    my $s= $class->SUPER::new;
    ($$s[Last])=@_;
    $s
}

sub samebool {
    #shift;# auch dies ne methode  für overrid? forged
    ($_[0] and $_[1]) or (!$_[0] and !$_[1])
}

#sub last_get {
#sub new_set {

sub set_new {#why not write back to same pool.
    my $s=shift;
    my ($id, $alarmstate,$laststate,$n) = @_;
    $$s[Last]->set($id, $alarmstate,$laststate,$n)
}

sub setalarm {
    my $s=shift;
    # noop.
}

sub setlevel { # absichtlich nicht set_level weil mehr als access
    # returns undef / 0 / 1 for the edge
    my $s=shift; @_==3 or die;
    my ($id,$state,$nneeded)=@_;

    if (my ($alarmstate,$laststate,$n) =  $s->last->get($id)) {

	my $edge; # undef / 0 / 1
	my $new_alarmstate= do {
	    if (samebool($state,$alarmstate)) {
		# (but be careful: could only be vorübergehend gleich, laststate unterschiedlich - aber das berechnen wir unten bei new_n)
		$alarmstate # or $state heh
	    } else {
		if ($nneeded <= 1  # in which case we don't need to look at old state
		    or
		    (samebool($state,$laststate)
		     and
		     ($n+1) >= $nneeded)) {
		    $s->setalarm($state); #btw does not actually call set_new!
		    $edge=$state  # both returned and set.
		} else {
		    $alarmstate
		}
	    }
	};

	my $new_n = do {
	    if (samebool($state,$laststate)) {
		$n+1
	    } else {
		1
	    }
	};
	#my $new_   and set//store the new state  oh kann ich oben einfügen  so isch imperativ.
	#if (samebool($state,$laststate)){
	#} else {
	# EH  dubel ebe will ja alles zusammen setzen.

	$s->set_new($id, $new_alarmstate,$state,$new_n);

	$edge
    } else {
	$s->set_new($id, $START_ALARMSTATE,$state,1);
	undef # no edge of a change yet. btw we will miss alarm if state is 1 from the beginning and nneeded is <=1 . AH no we won't!:) since we don't set alarmstate to state yet.
    }
}


end Chj::State::Level2edge;
