# Fri Mar 26 10:48:03 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Parse::Date::Ls

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Parse::Date::Ls;
#@ISA="Exporter"; require Exporter;
#@EXPORT_OK=qw();
use strict;
use utf8;
use Chj::Parse::Date::months;
use Carp;
use POSIX 'strftime';

use enum qw(E_success
	    E_nomatch
	    E_invalidmonthname
	    E_dateoutofrange
	   );#ps. E_invalidparts gibts nicht nur im Sinne dass strftime selben wert geben würd, sondern es gibt gar keinen fehler wenn z.B. stundenangabe >24 ist.
# ^-çç
our @errmsgs;
$errmsgs[E_success]= "success";
$errmsgs[E_nomatch]= "invalid date format";
$errmsgs[E_invalidmonthname]= "invalid month name";
$errmsgs[E_dateoutofrange]= "date out of range";

use Class::Array -fields=> (
			    'Error',
			   );



my $currentyear= (localtime)[5]; ###ç natürli schlecht.  sowieso falsch?.ç

sub _year_normalize {
    my $year=shift;
    #$year > 1900 ? $year :
    # $year < 200 ?

    if ($year > 1900 and $year < 2200) { ## ungefähr naja
	$year
    } elsif ($year > 0 and $year < 200) { ##
	$year+1900
    }
    else {
	#undef
	# ARGHHH
	die "invalid year '$year'";####
    }
}


sub _tag_mon_jahr_h_min {
    my $self=shift;#ach, soviel zu utils?undlokal   closure eher cpu schwenderisch?
#    use Data::Dumper;
#    warn "\@_=".Dumper(\@_);
    my ($mday,$monstr,$year,$hour,$min)=@_;
    my $sec=0;
    $min||=0;
    $hour||=0;
    #$year||=_year_normalize($currentyear);
    $year||=$currentyear;
    $year=_year_normalize($year);
    
    #    defined(my $mon= $Chj::Parse::Date::months::shortmonths_by_locale{de_CH}{$monstr})
    #ACH
    #defined(my $mon= $Chj::Parse::Date::months::shortmonths_by_locale{de_CH}{$monstr})
    defined(my $mon= $Chj::Parse::Date::months::shortmonth_hash_by_locale{de_CH}{$monstr})
      or do{ $$self[Error]=E_invalidmonthname; return };

#    warn "$mday.$mon.$year $hour:$min:$sec";
    ## agly special cae:
    if ($year==1970 and $mon==1 and $mday==1 and $hour==0 and $min==0 and $sec==0) {
#	warn "SPECIALCASE";
	return 0
    }
    
    my $rv=strftime('%s',$sec,$min,$hour,$mday,$mon-1,$year-1900);
    if ($rv<0) { $$self[Error]=E_dateoutofrange; return }; ## hmmm, 1.1.1970 0:0:0 gibt auch dieses. warum nicht 0? todo. scheiss special case oben
    $rv

}

  
sub parse_de_CH {
    my $self=shift;
    my ($str)=@_;
    $str=~ s/^\s*//s;
    $str=~ s/\s*$//s;
    if ($str=~ /^(\d+)\. ([\wäöü]+) (\d+)\:(\d+)\z/s) {    # 20. Jan 06:29
	$self->
	  #_tag_mon_jahr_min_h($1,$2, ,$3,$4); # MANN   listen huere interpolation. muss undef geben.
	  _tag_mon_jahr_h_min($1,$2, undef,$3,$4);
    }
    elsif ($str=~ /^(\d+)\. ([\wäöü]+) (\d+)\z/) { # 11. Mär 2003
	$self->
	  _tag_mon_jahr_h_min($1,$2,$3);
    }
    else {
	$$self[Error]= E_nomatch;
	undef
    }
}

#sub parse {
*parse= *parse_de_CH;

sub xparse {
    my $self=$_[0];
#    &parse or do {
#	croak "xparse: $errmsgs[$$self[Error]]";
    #    };
    my $res=&parse;
    defined $res or do {
	croak "xparse: $errmsgs[$$self[Error]]";
    };
    $res
}

    
1;
__END__


  ach, und noch mehr TODO:

root@ethlife-b tmp# sort_ls_bydate < fulllisting_root  > sorted
 sort_ls_bydate: error in input '-rw-rw-r--    1 root     root         2468  1. Jan 1904  /mnt/md8/chroot-debian-unstable/root/extlib/backup_with_cpbk.pm': xparse: date out of range at /root/bin/sort_ls_bydate line 63

  tja, unix time kann eben negativ sein!   well und sogar noch mehr oder was?

  

  TODO auch:
- FEHLER:   ls tut  Dez  letzten jahres nicht curyear  verwenden

 sowieso: gescheiter grep range    nunja dafür auchgut    oder         find selber machen mit stat
  anst. sort_ls_date skript

  
