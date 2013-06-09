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

sub sendmail {
    my $msg= &preparemail;
    if ($msg->send) {
	#ok
    } else {
	$PermanentError->("Some error occured sending mail");
    }
}

sub preparemail {
    my @realargs;# array of references
    my $Charset= 'ISO-8859-1'; # unless overridden
    my ($flag_Data,$flag_Encoding,$flag_ContentType);
    my $Data;
    for (my $i=0; $i<$#_; $i+=2) {
	local $_= \ $_[$i];
	if ($$_ eq 'Data') {
	    $flag_Data=1;
	    $Data= encode($Charset,$_[$i+1]);
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
    my $msg= MIME::Lite->new(map { $$_} @realargs)
      or $Syserror->("Error creating mailer object");
    if (!$flag_ContentType) {
	#(why look at ContentType for charset?. (see githistory?))
	$msg->attr('content-type.charset' => $Charset);
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


1
