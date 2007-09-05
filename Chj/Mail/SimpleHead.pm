# Wed Sep  5 11:34:58 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Mail::SimpleHead

=head1 SYNOPSIS

 my $m= xopen_read 'Maildir/....';
 my $h= Chj::Mail::SimpleHead->new_from_fh ($m);
 my $body= $m->xcontent;
 $m->xrewind;
 my $cnt= $m->xcontent
 join("\n", @{$h->headersArray },"",$body) eq $cnt
   # => yields true (at least if there are no CRLF problems)

=head1 DESCRIPTION

Simple mail head parser, with line number keeping (not yet done) to be
able to cut heads apart precisely.

Originally copy of code from mailmoverlib.pm


=cut


package Chj::Mail::SimpleHead;

use strict;

use Chj::chompspace;
use Chj::Mail::SimpleHead::Header;


use Class::Array -fields=>
  -publica=>
  (
   # "ps warum's Inmail class gibt in elcms: weil es inder db es ja auch so gross will wie es eben ist i.e. ram grösse.  (chunking?)"
   # "enum? wie schon machte ich jenes, zahlen versus db."

   'Errors',       # array
   'Warnings',     # array
   'HeadersHash',  # hash, lowercase key to a
                   # Chj::Mail::SimpleHead::Header object of the last
                   # occurrence in the head from top down
   'HeaderSHash',  # hash, lowercase key to [ multiple
                   # Chj::Mail::SimpleHead::Header objects ]
   'HeadersArray', # array, all headers in the order of occurrence,
                   # each as one string (not split into key and
                   # value); join("\n", @{$s->headersArray}) does
                   # recreate the original head (But what has been the
                   # real usage for this, if ever?)
   #'Fh', # the fh passed into new_from_fh method; for the case where we'd want the body. hm or leave that to the user?
  );

sub new_from_fh {
    my $class=shift;
    my ($fh)=@_; # assume this is blessed to Chj::IO::File? or do it now?
    # assume it is rewinded.!
    my $self= $class->SUPER::new;
    @{$self}[Errors,Warnings]= ([],[]);

    my (%header,@headers,@errors,%headers); # $headers{$key}=[ multiple of same type as $header{$key} ]
    my ($lastheaderkey);
  HEADER:{
	local $_;
	my $lineno=-1;
	while (defined($_=$fh->xreadline)) {
	    chomp;# is this safe enough (i.e. does it strip both cr and lf?)
	    $lineno++;
	    if (length) {
		if (/^(\w[\w.-]+): *(.*)/) {
		    $lastheaderkey=lc($1);
		    push @headers,$_;
		    # "Na: einfach immer der *letzte*mitgleichemkey in %header aufbewahren.
		    # und so isch multilinevervollständigung auch weiterhin korrekt
		    # muss dann bei ->header() methode drauf schauen ob multiple."
		    my $header=
		      Chj::Mail::SimpleHead::Header->new_h_o_v_l($#headers, $1, $2, $lineno);
		    push @{ $headers{$lastheaderkey} }, $header;
		    $header{$lastheaderkey}= $header;
		} elsif (/^\s/) {  #"(naja, ist das alles so wirklich korrekt?)"
		    if ($lastheaderkey) {
			$headers[-1].= "\n$_";
			if (my $header= $header{$lastheaderkey}) {
			    ${$header->valueref} .= "\n$_";
			}
		    } else {
			push @errors, "First header does not start with a key: '$_'";
		    }
		} else {
		    push @errors, "Header of unknown format: '$_'";
		}
	    } else {
		last HEADER;
	    }
	}
	# ran out of data before finishing headers? Well there is no guarantee that a mail has a body at all (not even the empty line inbetween), so it's not an error.
    }
    @{$self}[HeadersHash,HeadersArray,HeaderSHash]= (\%header,\@headers,\%headers);
    $self->[Errors]= \@errors;
    $self
}

sub header {
    my $self=shift;
    my ($key)=@_;
    if (defined(my $header=$$self[HeadersHash]{lc($key)})) {
	if (@{ $$self[HeaderSHash]{lc $key} } > 1) {
	    warn "header method called where multiple headers of key '$key' exists";
	    return undef
	}
	$header
    } else {
	undef
    }
}

sub first_header {
    my $s=shift;
    ($s->headers(@_))[0]
}

sub headers {
    my $self=shift;
    my ($key)=@_;
    if (my $arr= $$self[HeaderSHash]{lc $key}) {
	@$arr
    } else {
	()
    }
}

sub decodedheader {
    my $self=shift;
    my ($key,$as_charset)=@_;
    if (defined(my $h=$$self[HeadersHash]{lc($key)})) {
	$h->decodedvalue ($as_charset)
    } else {
	undef
    }
}

# sub body {
#     my $s=shift;
#     ${ $$s[_Body]||= \ do { $$s[Fh]->xcontent } }
# }
# or better leave that to the user. ?
#calc> :l $m= xopen_read 'Maildir/.Moved.m&APY-glicher spam.NOT spam/cur/1186862437.16013.elvis-mail:2,S'; $h= Chj::Mail::SimpleHead->new_from_fh ($m); $body=$m->xcontent; $m->xrewind ; $cnt= $m->xcontent
# works fine.

# gehört nicht mehr ins base package:
my %known_list_precedences= map {$_=>undef} qw( bulk list );
sub mailinglist_id {
    my $self=shift;
    my ($value,$id);
  SEARCH:{
	if ($value= $self->header("x-mailing-list-name")) {	# cj 15.10.04 damit perl6-all aufgeteilt wird.
	    if ($value=~ /<([^<>]{3,})>/) {##ps da gibts doch pick_out_of_anglebrackets?
		$id=$1;
		last SEARCH;
	    } else {
		#warn "invalid x-mailing-list-name format '$value'";
		$id= chompspace $value;
		last SEARCH; #!
	    }
	}
	# prioritize list-post over list-id since it contains the @ char?
	if ($value= $self->header("List-Post")) {
	    if ($value=~ /<([^<>]{3,})>/) { # just in case
		$id=$1;# hier ist dann bei ssh list noch mailto: dabei
		last SEARCH;
	    } elsif (length $value > 3) {
		warn "even if ssh mailinglist did put List-Post value into <>, this one did not ('$value')";
		$id=$value;
		last SEARCH;
	    } else {
		warn "(almost-)empty List-Post header '$value'";
	    }
	}
	if ($value= $self->header("List-Id")) {
	    if ($value=~ /<([^<>]{3,})>/) {
		$id=$1;
		last SEARCH;
	    } else {
		# warn "invalid list-id format '$value'"; ct: membershipreminders kommen hierhin
	    }
	} #els
	if ($value= $self->header("x-mailing-list")) {
	    if ($value=~ /<([^<>]{3,})>/) {
		$id=$1;
		last SEARCH;
	    } elsif ($value=~ /^\s*(\S.*\S)/) { # cj Tue,  9 May 2006 03:18:14 +0200 for majordomo
		$id= $1;
		last SEARCH;
	    } else {
		warn "invalid x-mailing-list format '$value'";
		# actually hab ich, bei ezmlm, perl6-all, dies gesehen:
		# X-Mailing-List: contact perl6-language-help@perl.org; run by ezmlm
		# X-Mailing-List-Name: perl6-language
		# daher weiter oben nun noch X-Mailing-List-Name anschauen.
	    }
	}
	# Qmail list ist so: Mailing-List: contact qmail-help@list.cr.yp.to; run by ezmlm
	if ($value= $self->header("Mailing-List")) {
	    if ($value=~ /<([^<>]{3,})>/) {
		warn "even if Qmail (yet another ezmlm based, right??) mailing list didn't use <..> format, this list does ('$value')";
		$id=$1;
		last SEARCH;
	    } elsif($value=~ /([^\s\@;:,?]+\@[^\s\@;:,?]+[a-z])/) {
		$id= $1;
		last SEARCH;
	    } else {
		warn "invalid x-mailing-list format '$value'";
	    }
	}
	if (my $precedence= $self->header("precedence")) {
	    $precedence= lc($precedence);
	    $precedence=~ s/^\s+//s;
	    $precedence=~ s/\s+\z//s;
	    if (exists $known_list_precedences{$precedence}) {
	      RESENT:{
		    if ($value= $self->header("Resent-From")) {
			#warn "entered Resent-From check";
			if ($value=~ /<([^<>]{3,})>/) { # just in case
			    #warn "note: even if debian mailinglists do not put resent-from into <>, this mail did it ('$value')"; -> cj14.12.: die neuen Debian BTS Mails tun dies.
			    ##ps. cj 12.12.04 warum tat ich nicht pick_out_of_anglebrackets nehmen? aha: nur optional. // $value also nötig.
			    $id=$1;
			    #warn "id=$id";
			} elsif (length $value > 3) {
			    $id=$value;
			    #warn "id=$id";
			} else {
			    warn "(almost-)empty Resent-From '$value'";
			    last RESENT;
			}
			# cj 12.12.04: weil neuerdings eine email reinkam mit Resent-From: Hideki Yamane <henrich@samba.gr.jp> (== From) vom Debian BTS, und X-Loop: mysql@packages.qa.debian.org (vorsicht mehrere X-Loop headers sind in andern mails möglich), das noch prüfen:
			my $p_from= chompspace MailUtil::oerr_pick_out_of_anglebrackets $self->header("from");
			my $p_id= chompspace MailUtil::oerr_pick_out_of_anglebrackets $id; ##sollte zwar ja eben nicht mehr nötig sein, aber warum oben eigener müll gemacht?.
			if (defined($p_from)
			    and
			    lc($p_from) eq lc($p_id)) {
			    # need alternative value.
			    #if (my @xloop= $self->header   aber das kann ich gar nicht, mehrere abfragen so. mann. schlecht, mal todo besseren head parser machen. auf wantarray schauen um zu sehen ob undef oder multiple geben.
			    #if (my $xloop= $self->header("X-Loop")) { hm dumm ist dass bereits in meinem fall tatsächlich mehrere drin sind.
			    #} else {
			    #	warn "kein X-Loop header (oder mehrere) drin";
			    #}
			    my @xloop= $self->headers("X-Loop");
			    my $xloop= do {
				if (@xloop >=2) {
				    my @xloopn= grep { ! /^[^\@]*\bowner\b/i } @xloop;
				    #warn "xloops ohne owner: ".join(", ",@xloopn);
				    if (@xloopn) {
					@xloop= @xloopn;
					#warn "since we still had one, this is now assigned to xloop";
				    }
				}
				$xloop[-1]
			    };
			    if (defined $xloop) {
				$id= chompspace MailUtil::oerr_pick_out_of_anglebrackets $xloop;
				##Frage: warum hatte compiler nöd reklamiert über undef methode? aber runtime?
				#warn "ok X-Loop header drin: id isch nun $id";
				last SEARCH;
			    } else {
				#warn "kein X-Loop header drin";
			    }
			} else {
			    last SEARCH;##frage gibt das ein warning wegen leave mehrere schritte? nah doch nid
			}
		    }
		    #warn "still in Resent-From check, id is ".(defined($id)? "'$id'": "undef");
		    #warn "id=$id";  wie kann das undef sein????--> mann blind auf beiden Augen
		    # cj 12.12.04: weil neuerdings eine email reinkam mit Resent-From: Hideki Yamane <henrich@samba.gr.jp> (== From) vom Debian BTS, und X-Loop: mysql@packages.qa.debian.org (vorsicht mehrere X-Loop headers sind in andern mails möglich), das noch prüfen:
		    # ----> NACH OBEN
		}#/RESENT
		# lugs: (mail alt dings)
		if ($value= $self->header("sender")
		    and $value=~ /^owner-(.*)/si) {
		    $id=$1;
		    last SEARCH;
		}
	    }
	}
	#warn "not a list mail";
	return;
    }
    #warn "listmail: $id\n";
    $id=~ s/^mailto:\s*//si;
    return $id;
}

sub is_spam {
    my $self=shift;
    if (my $status=$self->first_header("X-Spam-Status")) {
	if ($status=~ /^\s*yes\b/si) {
	    return 1;
	} else {
	    return 0;
	}
    } else {
	return undef
    }
}

sub spamhits {#ps. ebenso wie is_spam: was wenn multiple spamchecks were done?
    my $self=shift;
    if (my $status=$self->first_header("X-Spam-Status")) {
	if ($status=~ /hits=(-?\d+(?:\.\d+)?)/){
	    $1
	} else {
	    warn "spamhits: X-Spam-Status header found but no hits match";
	    undef
	}
    } else {
	undef
    }
}

sub lookslike_autoreply { # cj 10.10.04; sollte 1. wohl eben auch nicht in basisklasse sein und 2. ist sehr heuristisch (nadel im heustack)
    my $self=shift;
    # schau nur inhalt an, denn bulk header wurde schon angekuckt.
    # obwohl: scheint dass precedence junk nur bei autoreplies (und ev spam??) angewendet wird, list mails haben bulk oder list.
    if (my $subject= $self->decodedheader("subject")) {
	return 1 if $subject=~ /Your E-Mail Message will not be read/i;
	return 1 if $subject=~ /Office closed/i;
	return 1 if $subject=~ /Auto.?Reply/i;
	return 1 if $subject=~ /abwesenheitsnotiz/i;
    }
    if (my $xmailer= $self->decodedheader("X-Mailer")) {
	return 1 if $xmailer=~ /vacation/i;
	return 1 if $xmailer=~ /Autoresp/i;
    }
    if (my $autosubmitted= $self->decodedheader("Auto-Submitted")) {
	#return 1 if $autosubmitted=~ /auto/i; # auto-replied
	return 1 if $autosubmitted;
    }
    0
}

end Class::Array;
