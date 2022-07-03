# cj Wed, 20 Feb 2002 04:54:55 +0100

package checkdate;

require Exporter;
@ISA='Exporter';
@EXPORT=('checkdate');

use Time::Local;

=item $rv= checkdate(y,m,d[,\$errbuffer])

Checks the given date for existance, and returns the unix timestamp if ok.
Otherwise returns undef and sets the errbuffer to a message.

=cut

sub checkdate {
	my ($y,$m,$d,$errbuf)=@_;
	if ($y<=36) {
		$y+=2000;
	} elsif ($y<200) {
		$y+=1900;
	}
	if ($y<1970 or $y>2036) { # well real boundaries are somewhat different, esp. since they depent on your time zone
		$$errbuf="invalid year" if $errbuf;
		return
	}
	if ($m<1 or $m>12) {
		$$errbuf="invalid month" if $errbuf;
		return
	}
	if ($d<1 or $d>31) {
		$$errbuf="invalid day" if $errbuf;
		return
	}
	my $shortyear=$y-1900;
	my $tmp=timelocal(0,0,0,$d,$m-1,$shortyear);
	# begin of next month: 
	my $mplus= $m+1; my $jplus=$shortyear;
	if ($mplus>12) { $mplus=1; $jplus++};
	my $tmp1=timelocal(0,0,0,1,$mplus-1,$jplus);
	if ($tmp<$tmp1) {
		$tmp='0E0' if $tmp==0; # 1.1.1970
		return $tmp;
	} else {
		$$errbuf="inexistent date" if $errbuf;
		return
	}
}


=head1 AUTHOR

Christian Jaeger ( jaeger@sl.ethz.ch ).
This program is free software; you can redistribute it 
and/or modify it under the same terms as perl itself.

=cut

