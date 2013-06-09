package Chj::Sendmail;

# Sun Nov 10 04:24:41 2002  Christian Jaeger, pflanze@gmx.ch
# 
# Copyright 2001 by ethlife renovation project people
# Published under the terms of the GNU General Public License
#
# $Id: Sendmail.pm,v 1.4 2003/02/07 13:40:23 chris Exp $

=head1 NAME

Chj::Sendmail

=head1 SYNOPSIS

 use Chj::Sendmail 'sendmail';
 my @args= From=> "me@foo", To=> "you@too", Subject=> "yummy", Data=> "Hi";
 sendmail @args;
 # or:
 my $mail= preparemail @args;
 # $mail->as_string can be piped to the sendmail -t command, or better:
 send_mailasstring ($mail->as_string);


=head1 DESCRIPTION

Send email simply while (hopefully) taking care of encoding issues.

=cut


@ISA='Exporter'; require Exporter;
@EXPORT='sendmail';
@EXPORT_OK=qw(preparemail prepare_mailasstring send_mailasstring);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;


use MIME::Lite;
use MIME::QuotedPrint;
use HTTP::Date;
use Mail::Address;
use Encode 'encode';
use Chj::singlequote;#debug only


BEGIN {
    eval( ($] >= 5.008) ?
#	  'sub has_hibit { Encode::is_utf8($_[0]) # && has some non ascii chars, how to check?
#                            or $_[0] =~ /[\x80-\xFF]/s }'
	  'sub has_hibit { my $len= length $_[0]; for (my $i=0; $i<$len; $i++) { if (ord(substr $_[0],$i,1) > 127) { return 1 }} 0 }'
	  : 'use encoding "latin1";#(necessary for perl 5.6 legacy?)  (HMM will 5.6 only work with ISO-8859-1 anyway because of all that?)
             sub has_hibit { $_[0] =~ /[\x80-\xFF]/s }');
    die $@ if $@;
}

#MIME::Lite->send('sendmail');

use Carp;

our $PermanentError= sub {
    #require EL::Exception::Newsletter::PermanentError;
    #throw EL::Exception::Newsletter::PermanentError $Mail::Sendmail::error;
    croak @_;
};
our $TemporaryError= sub {
    #require EL::Exception::Newsletter::TemporaryError;
    croak @_;
};
our $Syserror= sub {
    #require EL::Exception::Syserror;
    croak @_;
};

#use Data::Dumper;

sub sendmail {
#    warn "sendmail: ".Dumper(\@_);
    my $msg= &preparemail;
    if ($msg->send) {
	#ok
    } else {
#     if ($Mail::Sendmail::error=~ /\bno recipient\b/i) {
#         $PermanentError->();
#     } else {
# 	$TemporaryError->();
#     }
	#ahh: hatte obiges schon länger auskommentiert  ? grr. "##kann keine genauere Meldung kriegen? Wenn qmail failure gibt: hat's was auf stderr gegeben? sigh."
	$PermanentError->("Some error occured sending mail");
    }
}

sub preparemail {
    my @realargs;# array of references
    #my $Encoding= nein das meint quoted-printable o.ä.
    my $Charset= 'ISO-8859-1'; # unless overridden
    my ($flag_Data,$flag_Encoding,$flag_ContentType);
    my $Data;
    for (my $i=0; $i<$#_; $i+=2) {
	local $_= \ $_[$i];
	if ($$_ eq 'Data') {
	    $flag_Data=1;
	    $Data= encode($Charset,$_[$i+1]);
	    # Fri, 12 May 2006 20:17:53 +0200: Text::Wrap seems to make crlf into the text, so..:
	    $Data=~ s/\015\012/\n/sg;
	    push @realargs, $_, \ $Data;
	} elsif ($$_ eq 'Encoding') {
	    $flag_Encoding=1;
	    push @realargs, $_, \ $_[$i+1];
	} elsif (lc($$_) eq 'content-type') {
	    $flag_ContentType=1;
	    push @realargs, $_, \ $_[$i+1];
	} elsif (lc($$_) eq 'charset') {
	    $Charset= $_[$i+1];
	} elsif (lc($$_) eq 'subject') {
	    if (has_hibit($_[$i+1])) {
		# Must split subject on words, because whitespace is encoded as well.
		# or maybe because MIME::QuotedPrint::encode does not encode '?' ? Sigh.
		# Yeah it seams it's primary because of the ? sign which is not encoded.
		# (This is true for Eudora\MacOS)
		my $str= $_[$i+1];
		$str=~ s/([^\s?]+)/
		  my $word= $1;
		if (has_hibit($word)) { # need to also replace those =
		    # must encode it
		    #my $v="=?$Charset?Q?".MIME::QuotedPrint::encode(encode($Charset,$word))."?=";
		    #warn "subject v=".singlequote($v);
		    #$v
		    # ----
		    #warn "word=".singlequote($word);
		    my $_word= encode($Charset,$word);
		    #warn "_word=".singlequote($_word);
		    my $_q= MIME::QuotedPrint::encode($_word);
		    #warn "_q=".singlequote($_q);
		    $_q=~ s{=\n\z}{}s;# correct some strange fault of MIME::QuotedPrint ?
		    #warn "now _q=".singlequote($_q);
		    "=?$Charset?Q?$_q?="
		} else {
		    $word
		}
		/sge;
		push @realargs, $_, \ $str;
		# Oh well, MIME::Lite does not check the line width of the subject, too.
		# Is this a problem?. (todo)
	    } else {
		push @realargs, $_, \ $_[$i+1];
	    }
	} else {
	    push @realargs, $_, \ $_[$i+1];
	}
    }
    if (!$flag_Data) {
	$Syserror->("Missing 'Data' part");
    }
    if (!$flag_Encoding) {
	unshift @realargs, \ ("Encoding","quoted-printable");
    }
    #use Data::Dumper; warn __PACKAGE__.": realargs= ".Dumper( \@realargs);
    my $msg= MIME::Lite->new(map { $$_} @realargs) or $Syserror->("Error creating mailer object");
    if (!$flag_ContentType) {#(FRAGE vom 12.4.06: warum auf ContentType schauen für charset?. hm ja wohl: normalerweise gibt man es nicht; dann müssen wir hier; aber eigentlich müssten wir nur, wenn eben encoding wirklich passiert ist, right? todo)
	#unshift @args, \ ("Content-Type","text/plain; charset=ISO-8859-1");
	$msg->attr('content-type.charset' => $Charset);
	#warn "HABE es auf iso gesetzt!";
	#use Data::Dumper;
	#warn Dumper($msg);  alles normal  was ist los
    }
    $msg
}

sub prepare_mailasstring {
    my $msg= &preparemail;
    $msg->as_string
}

sub send_mailasstring {  # code borrowed from MIME::Lite
    my $stringrf= \ $_[0];
    shift;
    my %p = @_; # parameters

    $p{Sendmail} ||= "/usr/lib/sendmail";

    # Start with the command and basic args:
    my @cmd = ($p{Sendmail}, @{$p{BaseArgs} || ['-t', '-oi', '-oem']});

    # See if we are forcibly setting the sender:
    $p{SetSender} = 1 if defined($p{FromSender});

    # Add the -f argument, unless we're explicitly told NOT to:
    unless (exists $p{SetSender} and !$p{SetSender}) {
	my $from = $p{FromSender};# || ($self->get('From'))[0]; ##hmm, don't have access to Outmail.pm object here.
	if ($from) {
	    my ($from_addr) = map { $_->address } Mail::Address->parse($from);
	    push @cmd, "-f$from_addr"       if $from_addr;
	}
    }

    my $pid = open SENDMAIL, "|-";
    defined($pid) or $TemporaryError->("open of pipe failed: $!");
    if (!$pid) {
	exec(@cmd) or $Syserror->("can't exec $p{Sendmail}: $!");
    }
    else {
	print SENDMAIL $$stringrf  or $Syserror->("Error writing to sendmail pipe: $!");
	#warn "Habe folgendes an @cmd geschickt:\n$$stringrf";##debug
	close SENDMAIL or $Syserror->("Error closing sendmail pipe: $! (exit $?)");
	return 1;
    }
}


1;
__END__

=head1 BUGS

MIME handling of Subject line is murksy:

- if no 8 bit chars are present, then it is left unchanged. This means that if the given subject string contains +-correct encoded word mime markup (RFC 2047) then the mail reader will decode it. The plus of this behaviour is that one can pass a string from an incoming mail without decoding it first, i.e. "Re: $origsubject".

- if however there is an 8 bit char, then everything is encoded, so if the subject contained some encoding it will be escaped and appear at the client's end as such.

(Maybe there should be a flag/setting somewhere to switch between those two manually.)

=cut

# --------------------------------
use Class::Array -fields=> qw(
	
); 

#use vars qw();

sub new {
	my $class=shift;
	my $self= $class->SUPER::new(@_);
	# (Alternativ, wenn diese Klasse die Basisklasse ist und bleiben soll:)
	# my $self = bless [], $class;
	# çç wenn hier keine speziellen Aktionen nötig sind, das ganze new rauskippen.
	$self
}


1;

__END__

Thu, 19 Dec 2002 02:18:25 +0100

Shit, die mimelite version von send hat ein problem (links): bei local delivery, oder delivery an den sms gateway. Die lib nimmt From Wert als Argument fur sendmail irgendwie oder wie kommt das???:
< Return-Path: <"Christian Jaeger <christian.jaeger"@ethlife.ethz.ch>>
---
> Return-Path: <chris@ethlife-b.ethz.ch>

 Aha:

        unless (exists($p{SetSender}) and !$p{SetSender}) {
            my $from = $p{FromSender} || ($self->get('From'))[0];
            if ($from) {
                my ($from_addr) = extract_addrs($from);
                push @cmd, "-f$from_addr"       if $from_addr;
            }
        }

und
  if (eval "require Mail::Address") {
    push @Uses, "A$Mail::Address::VERSION";
    eval q{
        sub extract_addrs {
            return map { $_->format } Mail::Address->parse($_[0]);
        }
    }; ### q

PS. andrere bug ja eben :  

---

  Workaround: ?.nee, besser library patchen.
  Ah hem. Hier nun auch noch korrigiert. Komisch dass vorher nich fehler? From wohl nie mit <> gewesen?.
  
