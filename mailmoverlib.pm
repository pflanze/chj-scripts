use strict;
use Chj::xopen qw(xopen_read);
use Chj::xperlfunc;
use Chj::FileStore::MIndex;
use Chj::FileStore::PIndex;
use Chj::oerr;
#use Chj::FileStore::MIndex::NonsortedIterator; well den brauch ich gar ned.
# wann will ich eigentlich msgid recorden wirklich?, wann will ich double elimination/checks? normalerweise ja nicht?. (doubleelim bloss wenn sie im gleichen folder landen)

# ach und wegen f* "too late to run CHECK block" auch diese unnütz-immer-laden:
use elcms_general_settings;
use EL::Util::Date;
use EL::Util::Sendmail;
our ($DEBUG,$verbose);

#####these here are shared with the 'x-sms-sendpending' script !!!.
my $HOME= do {# untaint it.
    $ENV{HOME}=~ m|^(/.*)|s or die "invalid \$HOME";##Hm, really trust it that far? but should be ok.
    $1
};
my $xsms_base="$HOME/.mailmover_x-sms";
my $msgid_base="$HOME/.mailmover_msgids";# msgid->filenames.
my $ownmsgid_base="$HOME/.mailmover_ownmsgids";
my $ownsubjects_base="$HOME/.mailmover_ownsubjects";
####/shared
mkdir $msgid_base,0700;
mkdir $ownmsgid_base,0700;
mkdir $ownsubjects_base,0700;
our $opt_leaveinbox;

my $BUFSIZE=50000;

# virus stuff:
my $badext = join "|",
  grep {length and ! /^zip$/i }
  split /\|/,
  "386|adt|bat|bin|cbt|cla|com|cpl|dll|drv|eml|exe|hta|htt|js|lnk|mdb|mso|ov.|pif|pot|scr|shs|sys|vbs|zip" # list from http://hico.fphil.uniba.sk/change-attachment-ext, but without zip
  ;
$badext= qr/$badext/i;
my @badsig_re= do {
    my $f= eval {
	xopen_read "$HOME/.mailmoverlib_virus_sigs"
    } || eval {
	xopen_read "/opt/chj/bin/mailmoverlib_signatures.txt"  ;
    };
    if (ref$@ or $@) {
	warn "could not read virus signatures: $@";#
	()
    } else {
	map {
	    /(\S+)/ or die;#
	    qr/$1/
	} grep {
	    ! /^\s*#/
	      and
		! /^\s*\z/ ;
	} <$f>
    }
};
sub one_of ( & @ ) {
    my ($code,@data)=@_; #komisch dass @ nötig.?
    for (@data) {
	my $rv= &$code; return $rv if $rv;
    }
    return;
}


{
    package MailUtil;
    our @EXPORT_OK=qw(pick_out_of_anglebrackets
		      oerr_pick_out_of_anglebrackets
		     );
    use base "Exporter";
    use Carp;
    #our ($verbose,$raiseerrors)=(1,0);#  (sowieso: wohl doch besser mit x-versionen der funktionen.!)
    our ($verbose,$raiseerrors)=(0,0);
    sub pick_out_of_anglebrackets {
	my ($str)=@_;
	unless (defined $str) {
	    return wantarray ? () : undef;
	}
	my @res= $str=~ /<([^>]*)>/g;
	if (wantarray){
	    @res
	} elsif (@res>1) {
	    my $msg= "multiple angle brackets found but only one expected";
	    if ($verbose) {
		warn $msg
	    }#naja, DBI like doppelwarn behaviour. is this liked?
	    if ($raiseerrors){
		croak $msg
	    } else {
		$res[0]
	    }
	} else {
	    $res[0]
	}
    }
    sub oerr_pick_out_of_anglebrackets {
	my ($str)=@_;
	if (wantarray) {
	    my @res= pick_out_of_anglebrackets $str;
	    @res ? @res : ($str)
	} else {
	    my $res= pick_out_of_anglebrackets $str;
	    defined($res) ? $res : $str
	}
    }
}
#*pick_out_of_anglebrackets= \&MailUtil::pick_out_of_anglebrackets;
import MailUtil qw(pick_out_of_anglebrackets oerr_pick_out_of_anglebrackets);

{
    package MailHead;
    use MIME::Words 'decode_mimewords';
    use Chj::Encode::Permissive 'encode_permissive';
    use Chj::chompspace;

    use Class::Array -fields=>(
			       # ps warum's Inmail class gibt in elcms: weil es inder db es ja auch so gross will wie es eben ist i.e. ram grösse.  (chunking?)
			       # enum? wie schon machte ich jenes, zahlen versus db.
			       'Errors', #arrayrf
			       'Warnings', #arrayrf
			       'HeadersHash', #hashref, only single headers
			       'HeadersArray', #arrayref, all headers
			       'HeaderSHash', # $headers{$key}=[ multiple of same type as $header{$key} ]  (leider gabs HeadersHash schon drum S)
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
	    while (defined($_=$fh->xreadline)) {
		chomp;# is this safe enough (i.e. does it strip both cr and lf?)
		if (length) {
		    if (/^(\w[\w.-]+): *(.*)/) {
			$lastheaderkey=lc($1);
			push @headers,$_;
			#if (exists $header{$lastheaderkey}) {
			    #push @errors,"encountered header '$lastheaderkey' multiple times, now with '$_'";
			    #undef $header{$lastheaderkey};  #hm. sinnlos weil ich es wiedersetzen muss um es verfollständigen lassen zu können.?.
			    #push @{ $headers{$lastheaderkey} }, $header{$lastheaderkey};
			    # so einfach geht das nicht :/
			    # Na: einfach immer der *letzte*mitgleichemkey in %header aufbewahren.
			    # und so isch multilinevervollständigung auch weiterhin korrekt
			    # muss dann bei ->header() methode drauf schauen ob multiple.
			    push @{ $headers{$lastheaderkey} }, [$#headers,$1,$2];
			    $header{$lastheaderkey}=[$#headers,$1,$2];
			#} else {
			#    $header{$lastheaderkey}=[$#headers,$1,$2];
			#}
		    } elsif (/^\s+(.*)/) {  #(naja, ist das alles so wirklich korrekt?)
			if ($lastheaderkey) {
			    $headers[-1].="\n\t$1";
			    $header{$lastheaderkey}[2].="\n\t$1" if defined $header{$lastheaderkey};
			    if (my $rf= $headers{$lastheaderkey}[-1]) {
				$$rf[2].="\n\t$1"
			    } else { warn "bug?" };
			    #warn "(DEBUG: multiline header)";
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
	if (defined(my $h=$$self[HeadersHash]{lc($key)})) {
	    if (@{ $$self[HeaderSHash]{lc $key} } > 1) {
		warn "header method called where multiple headers of key '$key' exists";
		return undef
	    }
	    #$h->[2]
	    #cj 4.8.04: spaces am ende von headers haben dazu geführt dass folders kreiert wurden welche in squirrelmail/courier-imap nicht subscribebar waren. weil wohl spaces am ende in courierimapsubscribes weggelöscht werden on read supi.
	    # daher wirkli nun hier zentral? isch eigentlich falsch.  aber mal einfcahheitshaltberhier.
	    chompspace($h->[2]);
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
	map {
	    chompspace($_->[2]);
	} @{ $$self[HeaderSHash]{lc $key} }
    }

    sub decodedheader {
	my $self=shift;
	my ($key,$as_charset)=@_;
	if (defined(my $h=$$self[HeadersHash]{lc($key)})) {
	    join("",
		 map{ encode_permissive $_->[0],$_->[1],$as_charset }
		 decode_mimewords(chompspace($h->[2])));
	} else {
	    undef
	}
    }

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
	if (my $status=$self->header("X-Spam-Status")) {
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
	if (my $status=$self->header("X-Spam-Status")) {
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
}


sub analyze_file($ ; $ ) {
    my ($filepath,$optionalfilename)=@_;# optionalfilename is the filename of the file it will get in future in the maildir
    my $filename= $optionalfilename || do {
	my $f=$filepath; $f=~ s{^.*/}{}s;
	$f
    };
    my $f= xopen_read $filepath;
    my $head= MailHead->new_from_fh($f);

    my ($foldername,$type,$important);
    $type="unbekannt";

    my $is_spam= $head->is_spam;
    if ($is_spam) {
	warn "'$filename' is spam\n" if $DEBUG;
	$foldername="spam";
    } elsif (! defined $is_spam) {
	warn "'$filename' is_spam: not scanned\n" if $verbose;
    }

    my $from;my $content;
    my $messageid;
    $messageid=do {
	#my $_messageid;
	sub {
	    my $_messageid= pick_out_of_anglebrackets($head->first_header("message-id"));
	    $messageid=sub {$_messageid};# mich selber eliminieren. harakiri. kamikaze. damit wegen undef von pick dings nicht jedesmal dochneuausgewertet wird.   Und das alles statt einer Methode im head objekt. (Die das Resultat ins objekt speichert, das head objekt.). "wow" (kreuzfeld jakob)
	    $_messageid
	}
    };

    # mails ohne message-id:
    my $spamhits= $head->spamhits;
    if (!$foldername) {
	my $msgid= &$messageid;
	if (!defined $msgid) {
	    if (defined($spamhits)) {
		if ($spamhits > 0) {
		  T:{
			if (my $subject= $head->decodedheader("subject")) {
			    if ($subject=~ /LifeCMS/i) {
				# do NOT filter it, hack because those mails do not have a msgid ://///
				last T;
			    }
			}
			$foldername= "spam-nomsgid";
		    }
		} # else don't risk to loose the mail.
	    } else {
		# still accept it, it might have been injected directly or something
		# (hmwell: merely impossible since we filter it ourselfes before here?)
	    }
	}
    }

    if (!$foldername) {
	my $list= $head->mailinglist_id;
	if (defined $list) {
	    warn "'$filename': mailinglist $list\n" if $DEBUG;
	} else {
	    warn "'$filename': not a list mail\n" if $DEBUG;
	}
	#if (!$list and 0) {
	#use Data::Dumper;
	#print "head for $filepath:",Dumper($head);
	#}
	if ($list) {
	    if ($list=~ /debian-security-announce/i) {
		$important=1;
	    }
	    $foldername=$list; $type="list";
	    $foldername=~ s{/}{--}sg; # well, wird nun eh unten nochmals gemacht.
	}
    }


    # noch gemäss subject einiges filtern:
    if (!$foldername) {
	if (my $subject= $head->header("subject")) {
	    # system mails
	    if ($subject=~ /^([a-zA-Z][\w-]+)\s+\d+.*\d system check\s*\z/) {
		$foldername="systemcheck-$1";$type="system";
		##ps.punkte dürfen in maildir foldernamen dann nicht vorkommen. weils separatoren sind. quoting möglich? in meiner library dann.
	    } elsif ($subject eq 'DEBUG') {
		$foldername= "DEBUG";$type="system";
	    } else {
		$from= $head->header("from");
		if ($subject=~ /^\[LifeCMS\]/
		    and ( $from eq 'alias@ethlife.ethz.ch'
			  or $from eq 'newsletter@ethlife.ethz.ch') ) {
		    $foldername= $subject;$type="system";#gefährlich? jaaaa war es!!! jetzt hab ich unten geflickt.
		} elsif ($subject=~ /^Cron/ and $from=~ /Cron Daemon/) {
		    $foldername= $subject;$type="system";
# 		} elsif ($subject=~ /out of office autoreply/i
# 			 #or
# 			) {
# 		    $foldername= "AUTOREPLY";
		} elsif ($subject=~ /^Delivery Status Notification/
			 and $from=~ /^postmaster/) {
		    $foldername= "BOUNCE";
		} elsif (#$subject=~ /failure notice/ and
			 ($from=~ /\bMAILER[_-]DAEMON\@/i
			  or
			  $from=~ /\bpostmaster\@/i
			 )
			 #and $content=~ /ETH Life Newsletter/
			 #and $messageid=~ /\@ethlife.ethz.ch/  # dann kam sie von hier. ; eh1: ist im content. eh2: muss auch lifecms enthalten. aber alte nl tun dies nicht.
			 and do {
			     $f->xread($content,$BUFSIZE);
			     if ($content=~ /From: ETH Life/) {
				 $foldername= "newslettermanuell..$from";$type="system";
				 1
			     } elsif ($content=~ /Message-[Ii]d:[^\n]+lifecms/) {
				 $foldername= "lifecms..$from";$type="system";
				 1
			     } else {
				 0
			     }
			 }) {
		    # filtered. else go on in other elsifs
		} elsif ($from=~ /GMX Magazin <mailings\@gmx/) {
		    $foldername= "GMX Magazin"; $type="list";
		} elsif ($from=~ /GMX Spamschutz.* <mailings\@gmx/) {
		    $foldername= "GMX Spamschutz"; $type="list";
		}
		# cj 3.12.04 ebay:
		elsif ($from=~ /\Q<newsletter_ch\@ebay.com>\E/) {
		    $foldername="ebay-newsletter";# $type="list"; oder "unbekannt" lassen? frage an ct: welche typen gibt es und wie werden sie sonst gehandhabt, resp. ändere es hier einfach selber ab, ich benutze type derzeit eh nicht.
		}
		# mailinglist reminders
		elsif ($subject=~ /^\S+\s+mailing list memberships reminder\s*$/
			 and
			 $from=~ /^mailman-owner\@/
			) {
		    $foldername= "mailinglistmembershipreminders";#$type="list";oder toplevel
		}
		# !SPAM: angabe von dem mailfilter der informatikdienste eth wenn so konfiguriert dass mail nicht gelöscht wird
		elsif ($subject=~ /^\!SPAM: /
		       and (!defined($spamhits) or $spamhits > -1)
		      ) {
		    $foldername="spam-eth";# $type= ?
		}
		
		# VIREN!:
		elsif ($subject eq 'New Internet Critical Pack'
		       or $subject=~ /^\!VIRUS:/
		       or $subject=~ /^virus found in sent message \"/
		       #or $subject=~ /^ScanMail Message:.*virus/
		       or $subject=~ /^ScanMail Message:/
		       or ($subject=~ /^VIRUS \(/
			   and $from=~/amavis/)
		       or $subject=~ /^Symantec .*detected.*virus/
		      ){
		    $foldername= "VIRUS";
		}
		elsif (my $virusscan= $head->header("X-Virus-Scan-Result")){
		    if ($virusscan=~ /^Repaired/) {
			$foldername= "VIRUS";
		    }
		}
		elsif (do{ $f->xread($content,$BUFSIZE) unless $content; 1 }) {# wofür habe ich da noch das if? cj.
		    if ($content=~ /\"[^\"]+\.exe\"/) {
			$foldername= "VIRUS-exe";
		    } elsif (
		       # cj 3.12.04: (ich kriege solche eigentlich nie direkt sondern immer die failure rückmeldungen wenn einer (virus) ethlife als absenderadresse genommen hat)
		       $content=~ /\nContent-Disposition: *attachment;\s*filename *=\"[^\"]*\.($badext)\"/si
		       or
		       ($content=~ /VIRUS +WARNING/ and
			$content=~ /file(?:name)?[ \t]*[=:]?[ \t]*[\"\']?[^\"\']*\.($badext)/
		       )) {
			$foldername= "VIRUS-badext";
		    } elsif (
			     one_of { $content=~ /$_/ } @badsig_re
			    ) {
			$foldername= "VIRUS-badsig";
		    }
		}
	    }
	}
    }
    if (!$foldername) {
	if (my $to= $head->header("to")) {
	    if ($to=~ /^(postmaster\@[^\@;:,\s]+[a-z])/) {
		$foldername= $1;# "TO DO: gefährlich!!" ne wohl nüme. right? oder was gemeint: dass mails die an "mich" gehen sollten weggemoved werden? doch todo? jup isch neuere notiz!
	    }
	}
    }

    # nichts matchende sonstwohin:
    if (!$foldername) {
	my $s= xstat $filepath;
	if ($s->size > 15000) { #cj: ps. sollte size messung ausserhalb geschehen? weil, wenn per symlink redirected, ja doch wieder die frage ob dann-doch-nicht in die inbox.
	    $foldername="inbox-big";$type="inbox";$important=1;
	} else {
	    $foldername="inbox" unless $opt_leaveinbox;$type="inbox";
	}
	# checken ob SMS versand gewünscht.
	eval {
	    my $smsdatetime;
	    if ($smsdatetime= $head->header("x-sms") || $head->header("x-sms-at")) {
		#oky
		#warn "oky smsdatetime als header, '$smsdatetime'";
	    } else {
		$f->xread($content,$BUFSIZE) unless $content;
		my $htmlfreecontent= $content;
		# remove mimepart stuff
		$htmlfreecontent=~ s%^\s+%%s;
		$htmlfreecontent=~ s%^[^\n]+\ncontent[^\n]+\n.*?\n\n%%si;
		# remove html
		$htmlfreecontent=~ s%<head[^>]*>.*?</head[^>]*>%%sg;
		$htmlfreecontent=~ s/<!--.*?-->//sg;
		$htmlfreecontent=~ s|<br\s*/?\s*>|\n|sgi;
		$htmlfreecontent=~ s|</p>|\n|sgi;
		$htmlfreecontent=~ s|<p\b[^>]*>|\n|sgi;
		$htmlfreecontent=~ s/<[^>]*>//sg;
		#warn "htmlfreecontent= '$htmlfreecontent'";
		#if ($htmlfreecontent=~ /^\s*x-sms(?:-at)?:?([^\n]*)/si) {
		if ($htmlfreecontent=~ /^\s*(?:x-)?sms(?:(?:-|\s+)at)?:?([^\n]*)/si) {
		    $smsdatetime=$1;
		    #warn "oky smsdatetime von body, '$smsdatetime'";
		}
	    }
	    if ($smsdatetime) {
		my $scheduledtime;
		#local $SIG{__DIE__}=sub { print STDERR "SIGDIE sieht: @_" };
		my $is_first;
		## echt erst hier msgid aufzeichnen?
		my $msgidtable= Chj::FileStore::MIndex->new($msgid_base);
		if ($msgidtable->add(&$messageid,$filename)==2) {
		    # first time occurence of message id.
		    $is_first=1;
		}
		eval {
		    #enthält allenfalls auch "at " oder "in ", dann datum/uhrzeit.
		    # eben, todo, die date parser lib erweitern.
		    #warn "nun werd ich: $smsdatetime";
		    $scheduledtime=EL::Util::Date::parsePublicationDatetime($smsdatetime);###echt todo: die isch nicht mal zufrieden mit uhrzeit allein motzt dass datum fehle.
		    #warn "habe, $scheduledtime";
		    if ($is_first) {
			mkdir $xsms_base,0700;#ps. der x-sms-sendpending cronjob croakt wenn das noch ned existirt :~/
			my $smstimetable= Chj::FileStore::MIndex->new($xsms_base);
			$smstimetable->add($scheduledtime,$filename);
			#warn "added $scheduledtime,$filename";#
		    }
		};
		my $E=$@;#"JAAAAAAAAAAAAAA"
		my $subject=singlequote($head->decodedheader("subject"),"(kein subject)");#(hatte oben nich sauber getrennt sigh)
		my $noticesubject= "SMS für $subject";#ps dass für'bla' in eudora erscheint isch offenbar ein bug von eudora, nicht der mime lib, denn in squirrel kommts richtig. (mimelib macht wortweise encoding, ev wär das uberflussig)
		my $noticebody;
		if (ref $E) {
		    if ($E->isa("EL::Exception")) {
			$noticebody="Ihre 'X-SMS:'-Angabe war Fehlerhaft:\n\n".$E->prettytext("de");#hm wenn hier wieder fehler sollte der eben schon n fehler bekommen;  AAABBER HAHAHAHAHA: weil ich hier ein mover bin und ned qmail unterliege macht es gar kein sinn ein fehler exit zu geben, qmail wird ned bouncen.
		    } else {
			die $E;
		    }
		}elsif($E){die $E};
		if ($is_first) {
		    #warn "schicke notice..";#
		    if (!$noticebody) {
			$noticebody="Die ersten 160 Zeichen (inkl. Subject und Absender-emailadresse) Ihrer\n".
				  "Mitteilung werden dem Empfänger zu folgender Zeit per SMS/Alarm\n".
				  "zugestellt, sofern er bis dahin die Email nicht abgerufen hat:\n\n".
				    localtime($scheduledtime);####shit: hier weiss ich aber ned ob das klappt, ob denn cronjob für x-sms-sendpending als auch nachfolgender alarmzustellung läuft!!!!
			if ($scheduledtime < time) {
			    $noticebody.="\n\n(da dies in der Vergangenheit liegt, heisst dies: sogleich)";
			}
		    }
		    #ps hier noch checken ob bulk message? aber egal, auch über bulkmachende verteiler aktiv lassen?
		    my $replyaddress=$head->header("from")
		      or die "no from address found";
		    EL::Util::Sendmail::sendmail(To=>$replyaddress,
						 From=>$replyaddress,#keine From? ##
						 Subject=>$noticesubject,
						 Data=>$noticebody);####grrrrrrData ned data
		    #noch schöner wär wenn eben auch beim senden dann eine notiz geschickt würd.
		} else {
		    #warn "schicke keine notiz.";#
		}
		# evtl mal tun oder so jedenfalls mal notiert hier:
		# scheiss isch neben dem nicht wissen ob sms dann wirklich geschickt wird,  der fehlenden meldung aktion die dann wirklich geschieht,  auch: wenn time in vergangenheit isch meldung bullshit sollte sein "gleich". tja. kann ich ja hier noch reinflicken.
		# ah..und was unschön isch: die x-sms zeile falls in body wird mitgeschickt.haha.
	    }
	};
	warn $@ if $@;##tja wer soll das jemals sehen. Eben und oben schon ungültige time isch eben doch ein inner eval ein nötiges damit dem user reply geschickt werden kann.
	
    } else {
	if ($foldername eq "inbox" or $foldername eq "inbox-big") {
	    die "mail '$filename' somehow managed to get foldername '$foldername'";
	    #sollte nicht passieren vom Ablauf her
	}
    }
    if ($foldername) {
	$foldername=~ s{/}{--}sg;#!wichtig!.. nochmals.
    }
    undef $messageid;
    ($head,$foldername,$type,$important);
}

sub _einstampfen { # testcase siehe lombi:~/perldevelopment/test/mailmoverlib/t1
    my ($str)=@_;
    if (defined $str) {
	#$str=~ s/\s+/ /sg; cj 24.8.04: weil manche mailer wörter in mitte abeinanderbrechen, whitespace ganz raus.
	$str=~ s/\s+//sg;
	#$str=~ s/\s+\z//s;
	#do{} while $str=~ s/^\s*(?:re|aw)\s*://i; cj 24.8.04: auch [vserver] etc weg.
# 	do{# Die Regel soll sein: alles in [ [ ] ] soll vernichtet werden, ausser es sei die äusserste klammer.  ? und auch nur wenn eben [ am anfang steht.
# 	    #warn "vorher: '$str'";
# 	    #$str=~ s/^\[(.*)\]$/$1/s;# inhalt aus drumherumklammern befreien.
# 	    $str=~ s/^\[([^\[\]]*)\]$/$1/s;# inhalt aus drumherumklammern befreien.
# 	    #warn "nachher: '$str'";
# 	} while $str=~ s/^(?:(?:re|aw|fwd):|\[[^\[\]]*\])//i;
	# Also neuer algo:
	# wenn [ am anfang, den zugehörigen ] suchen. Wenn der am Ende steht, innendrin rausnehmen. Sonst wegschneiden.
# 	do {} while $str=~ s/^(?:re|aw|fwd)://i or do {
# 	    if ($str=~ m|^\[|) {
# 		my $p=1;
# 		my $inner=1;
# 		my $len=length$str;
# 		while($p<$len) {
# 		    my $c=substr($str,$p,1);
# 		    if ($c eq '[') {
# 			$inner++;
# 		    }elsif($c eq ']') {
# 			$inner--;
# 			if ($inner==0) {
# 			    if ($p == $len-1) {
# 				# rausnehmen
# 				$str= substr($str,1,$len-2);
# 			    } else {
# 				# wegschneiden.
# 				substr($str,0,$p)="";
# 			    }
# 			    last;#yep, no special exit needed. SCHIT aber wieder das rückgabewertproblem
# 			}
# 		    }
# 		    $p++;
# 		}
# 	    }
	my $stripprefix=sub {
	    $str=~ s/^(?:re|aw|fwd)://i
	};
	my $stripbrackets=sub {
	    if ($str=~ m|^\[|) {
		my $p=1;
		my $inner=1;
		my $len=length$str;
		while($p<$len) {
		    my $c=substr($str,$p,1);
		    if ($c eq '[') {
			$inner++;
		    }elsif($c eq ']') {
			$inner--;
			if ($inner==0) {
			    if ($p == $len-1) {
				# rausnehmen
				$str= substr($str,1,$len-2);
			    } else {
				# wegschneiden.
				#warn "vorwegschneiden '$str'";
				substr($str,0,$p+1)="";
				#warn "weggeschnitten, '$str'";
			    }
			    return 1;
			}
		    }
		    $p++;
		}
		#warn "endslash nicht gefunden";
		$str=substr($str,1);#tja. sosolala  sollte nicht schaden.
		return 1;
	    }
	    0
	};
	do {} while &$stripprefix or &$stripbrackets;

	#$str=~ s/^\s+//s;
	$str= lc($str);
	#if (length($str)>=10) {
        if (length($str)>=8) {
	    $str
	} else {
	    undef
	}
    } else {
	undef
    }
}

sub _eingestampftessubject {
    #my ($str)=@_;# sollte decoded sein nach latin1 oder whatever  ehm. nöh besser ascii mit ?
    #todo: mehrzeilige headers kommen nicht richtig durch, schon gar nicht hier, oder?
    my ($mail)=@_;
    _einstampfen($mail->decodedheader("subject","ascii"));
}

sub is_reply {
    my ($mail) = @_;
    if (my $subj= _eingestampftessubject($mail)) {
	my $ownsubjectstable= Chj::FileStore::PIndex->new($ownsubjects_base);
	return 1 if $ownsubjectstable->exists($subj);
	# ev. todo: hier auch noch mailingliste berücksichtigen? also subject.liste-kombination soll matchen?.
    }
    my $in_reply_to = pick_out_of_anglebrackets($mail->header("In-Reply-To"));
    return unless defined $in_reply_to;
    my $ownmsgidtable= Chj::FileStore::PIndex->new($ownmsgid_base);
#     return 1 if ($ownmsgidtable->exists($in_reply_to));
#     for (pick_out_of_anglebrackets($mail->header("References"))) {
# 	return 1 if ($ownmsgidtable->exists($_));
#     }
    return
      $ownmsgidtable->exists($in_reply_to)
	or
	  sub {
	      for (pick_out_of_anglebrackets($mail->header("References"))) {
		  return 1 if $ownmsgidtable->exists($_);
	      }
	      0;
	  }->();
}

sub save_is_own {
    my ($mail) = @_;
    my $ownmsgidtable= Chj::FileStore::PIndex->new($ownmsgid_base);
    $ownmsgidtable->add(scalar pick_out_of_anglebrackets($mail->first_header("message-id")),"");
    if (my $subj= _eingestampftessubject($mail)) {
	my $ownsubjectstable= Chj::FileStore::PIndex->new($ownsubjects_base);
	$ownsubjectstable->add($subj,"");
    }
}
