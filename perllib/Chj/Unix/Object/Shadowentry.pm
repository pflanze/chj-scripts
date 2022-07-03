# Thu Mar  8 15:01:30 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Unix::Object::Shadowentry

=head1 SYNOPSIS

=head1 DESCRIPTION

Parse /etc/shadow, since there is no other way to get e.g. at expiry information.

=head1 SEE ALSO

L<Chj::Unix::Authenticate>

=cut


package Chj::Unix::Object::Shadowentry;

use strict;
use Chj::xopen 'xopen_read';

use Class::Array -fields=>
  # man 5 shadow
  -publica=>
  (
   'nam', # login name
   'passwd', # encrypted password
   'lastchanged', # days since Jan 1, 1970 that password was last changed
   'daysbeforechange', # days before password may be changed
   'daysmustchange', # days after which password must be changed
   'dayswarnexpiry', # days before password is to expire that user is warned
   'daysdisable', # days after password expires that account is disabled
   'disabled', # days since Jan 1, 1970 that account is disabled
   'reserved', # a reserved field
  )
  ;

my $Mk= sub {
    my ($searchfield)=@_;
    sub {
	my $class=shift;
	@_==1 or die "expecting 1 argument";
	my ($searchval)=@_;
	my $f= xopen_read "/etc/shadow";
	while (<$f>) {
	    if (my @f= split /:/) {
		my $s= bless \@f, $class;
		if ($s->$searchfield eq $searchval) {
		    return $s
		}
	    }
	}
	return
    }
};

*get_by_nam= $Mk->("nam");
#*get_by_uid= $Mk->(  ehr. not exist!

sub Curday {
    my ($time)=@_;
    $time / (24*60*60)
}

sub is_expired {
    my $s=shift;
    my ($opt_time)=@_;
    ($s->disabled #correct?
     or do {
	 my $time= $opt_time||time;
	 my $curday= Curday($time); # a float. okay? or should we truncate it?
	 my $valid_until= $s->lastchanged + $s->daysmustchange; # + $s->daysdisable nope, that is for removing the account, yeah?
	 #print STDERR $s->dump_publica;
	 #warn "curday= $curday, valid_until= $valid_until";
	 not($curday <= $valid_until)
     })
}

end Class::Array;
