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
    #following two lines stolen from MIME::Lite.  HMMMMMMMMMMM das isch das hässliche UT format. ??habe ich denn gerade darum nicht bereist schon mal eine loesung erarbeitet?  // aber isch ja egal. ?.
#    my ($u_wdy, $u_mon, $u_mdy, $u_time, $u_y4) = 
#      split /\s+/, gmtime($time)."";   ### should be non-locale-dependent
    #my $date = "$u_wdy, $u_mdy $u_mon $u_y4 $u_time UT";
    #cj:
#     {
# # 	my $gen= sub {
# # 	    my ($func)=@_;
# # 	    my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday) =
# # 	      &$func;
# # 	    sub {
# # 		$hour
# # 	    }
# # 	};
# # 	my $gm= $gen->(sub{gmtime($time)});
# # 	my $lo= $gen->(sub{localtime($time)});
# # 	#&$gm- &$lo
# 	my @gm= gmtime($time);
# 	my @lo= localtime($time);
# 	#"dann halt eben by index". nakönnt janoch enum machen?.  returntyp selbiger also
# 	my $hour_d= $lo[2]-$gm[2];
# 	my $min_d= $lo[1]-$gm[1];
# 	# und wie genau nun?
#     }
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

1;
