# Sun Jan 25 01:53:38 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Parse::Apache::Accesslog

=head1 SYNOPSIS

 use Chj::Parse::Apache::Accesslog -importprefix=>"AL";
 my $parser= new Chj::Parse::Apache::Accesslog;
 while(<STDIN>){
     $parser->parseline($_)  # or ->parseline_time if you always want the unixtime
       or do { warn "error parsing: ".$parser->errmsg.": $_"; next };
     if ($parser->[ALReferrer]) {
         print "referrer '$$parser[ALReferrer]' at: ".localtime($parser->xunixtime)."\n";
     }
 }

=head1 DESCRIPTION


Outputs undef for "-" referrers or useragents, as well as for the Bytes (sent length) field.

=head1 BUGS

Time zone is not supported grr

=cut


package Chj::Parse::Apache::Accesslog;

use strict;
our @IMPORTABLE;
BEGIN {
    @IMPORTABLE=(
		 'Error',# result of last parsing step
		 'Mday','Monname','Year','Hour','Min','Sec','TZone',
		 'Mon',
		 'Method', 'Location',
		 # now the 'real public' fields (well, not much difference)
		 'Unixtime',
		 'Host','Unknown1','Unknown2',
		 'Requeststr','Status','Bytes','Referrer','Useragent',
		);
}
use Carp;

sub import { ###temporary hack until the real thing is in class array
    my $class=shift;
    my ($cmd,$prefix)=@_;
    if ($cmd eq '-importprefix') {
	$class->import_constants($prefix,1);
    } else {
	$class->SUPER::import(@_);
    }
}
sub import_constants {
    my $class=shift;
    my ($prefix,$callerno)=@_;
    $prefix="" unless defined $prefix;
    my $caller=caller($callerno);
    no strict 'refs';
    for my $fieldname (@IMPORTABLE) {
	if (defined *{"${caller}::$prefix$fieldname"}{CODE}) {
	    carp __PACKAGE__.": conflict importing '$prefix$fieldname' into $caller (please use another prefix)";
	} else {
	    *{"${caller}::$prefix$fieldname"}= *{"${class}::$fieldname"}{CODE};
	}
    }
}

use constant +{
	       E_success=> 0,
	       E_invalidformat=> 1,
	       E_invalidmonthname=> 2,
	       E_dateoutofrange=> 3,
	      };
our @errmsgs; #  hm schon wieder das gleiche wie in Chj/Parse/Date/Syslog
$errmsgs[E_invalidformat]= "invalid log line format";
$errmsgs[E_invalidmonthname]= "invalid month name";
$errmsgs[E_dateoutofrange]= "date out of range";

use Chj::Parse::Date::months;
use POSIX "strftime";

use Class::Array
  -fields=> (
	     @IMPORTABLE
	     );



# my ($mday,$monname,$year,$hour,$min,$sec); nope: will die zeit gar nicht immer!

sub parseline {
    my($self,$line)=@_; #don't destroy @_!
#old:    unless ($line=~ m#^(\S+) (\S+) (\S+) \[(\d+)/(\w+)/(\d+):(\d+):(\d+):(\d+) ([+-]\d+)\] "(.*?)" (\d+) (?:-|(\d+)) "(?:-|(.*?))" "(?:-|(.*?))"$#
    unless ($line=~ m#^(\S+) (\S+) (\S+) \[(\d+)/(\w+)/(\d+):(\d+):(\d+):(\d+) ([+-]\d+)\] "(.*?)" (\d+) (?:-|(\d+))(?: "(?:-|(.*?))" "(?:-|(.*?))")?$#
	   ) {
	$$self[Error]= E_invalidformat;
	return;
    }
    @$self[Host,Unknown1,Unknown2,
	   Mday,Monname,Year,Hour,Min,Sec,TZone,
	   Requeststr,Status,Bytes,Referrer,Useragent]= ($1,$2,$3,
							 $4,$5,$6,$7,$8,$9,$10,
							 $11,$12,$13,$14,$15);
    1;
}

sub parseline_time {
    &parseline or return;
    return &unixtime;
}

sub unixtime {
    my($self)=@_;
    $$self[Mon]= $Chj::Parse::Date::months::short_english_month{$$self[Monname]}
      or do{ $$self[Error]=E_invalidmonthname; return };
    my $rv=strftime('%s',@$self[Sec,Min,Hour,Mday],$$self[Mon]-1,$$self[Year]-1900,
		    #$$self[TZone] HMMMM  GRRRRR scheint gar nicht unterstützt zu sein.
		   );
    if ($rv<0) { $$self[Error]=E_dateoutofrange; return };
    return $$self[Unixtime]=$rv;
}

sub errortext {
    my $self=shift;
    $errmsgs[$$self[Error]]
}
*errmsg= \&errortext;

sub xunixtime {
    my($self)=@_;
    &unixtime or croak $self->errmsg;
}

sub location {
    my $s=shift;
    #$$s[Location]||= do {
    if ($s->[Requeststr]=~ m%^\s*(\S+)\s+(\S+)%) {
	$2
    } else {
	undef
    }
}

sub method {
    my $s=shift;
    #$$s[Location]||= do {
    if ($s->[Requeststr]=~ m%^\s*(\S+)\s+(\S+)%) {
	$1
    } else {
	undef
    }
}

1;
