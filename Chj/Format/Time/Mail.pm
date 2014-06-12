# Tue Jun 29 23:16:51 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Format::Time::Mail

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Format::Time::Mail;
@EXPORT=qw(format_time_mail_date);
use base "Exporter";
use strict;

sub format_time_mail_date {
    my ($time)=@_;
    $time||=time;
    use Time::Local;
    {
	use integer;
	my $diff= timegm(localtime($time))-$time;
	#print "$diff seconds diff\n";
	my $sign= $diff >=0 ? "+" : "-";
	$diff/= 60;
	my ($u_wdy, $u_mon, $u_mdy, $u_time, $u_y4) = 
	  split /\s+/, localtime($time)."";
	my $Diff= sprintf('%02d%02d',$diff/60,$diff % 60);
	"$u_wdy, $u_mdy $u_mon $u_y4 $u_time $sign$Diff";
    }
}

1
