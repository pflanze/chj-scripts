# cj Wed,  6 Oct 2004 03:56:56 +0200

package autoreply;
use strict;#!!!!!!!!!!!

# email generieren und abschicken: was verwende ich diesmal für eine library?...
use EL::Util::Sendmail ();#(nunja)

use Chj::FileStore::PIndex;

my $lastsent_base= "$ENV{HOME}/.mailmover_autoreply_lastsent";
mkdir $lastsent_base,0700;

my $lastsent= new Chj::FileStore::PIndex $lastsent_base;

#my $TEMPLATE= 
my $MINDELAY= 24*60*60* 0.8;# secs resp.  days

sub undefaware_lc {
    # lachen.  isch wie C: propagieren von fehlern up the stack. ob exceptions halt doch cleaner sind?.
    my ($val)=@_;
    return unless defined $val;
    lc($val)
}

use Mail::Address;
sub clean_mailaddress {##sollte ich irgendwo hin tun. MANN. schon x mal.
    my ($str)=@_;
    return unless defined $str;
    my @addr= Mail::Address->parse($str);
    return unless @addr;
    warn "got string with more than one address" unless @addr==1;
    $addr[0]->address
}

sub send_if_not_already {# returns true if really sent an email.
    my ($replyaddress,$youraddress,$origsubject,$timenow)=@_;
    $timenow||=time;
    my $cleaned_replyaddress= undefaware_lc(clean_mailaddress($replyaddress));
    return unless defined $cleaned_replyaddress;#tja. nich mal melden.(eben, exceptions?..)
    if (defined(my $last=$lastsent->get($cleaned_replyaddress))) {
	if (($timenow-$last) < $MINDELAY) {
	    return
	}
    }
    $lastsent->set($cleaned_replyaddress,$timenow);# setting this already before actually attempting to send the reply is better for anti-loop security
    # encoden des subjects   body encoding   wie schicke ich korrekt email ab?
    ##
    #my $where="momentan testweise abwesend";
    #my $where="bis am 29. Oktober abwesend (Militärdienst)";
    #my $where_e="for testing only";
    #my $where_e="till october 29th (military service)";
    my $body="
Ich bin momentan abwesend und werde evtl. erst wieder am Wochenende Email
lesen.
Für technische Belange rund um ETH Life kontaktieren Sie bitte
christian.tarnutzer\@ethlife.ethz.ch
In dringenden Fällen bin ich evtl. auf dem Natel erreichbar. Christian
Tarnutzer wird genaueres sagen können.

I'm out of office and will only read email at the weekend.
For questions surrounding ETH Life please contact
christian.tarnutzer\@ethlife.ethz.ch

Christian Jaeger.
"; $body=~ s/^\n//s;
    my $subject= "Auto-reply to: ".((defined($origsubject) and length($origsubject)) ? $origsubject : "(no subject)");
    # will email nicht nur generieren sondern wirklich auch raus senden  hat das meine EL::Util::Sendmail library auch?
    # ja hat es. es benutzt MIME::Lite unter der Haube, aber das wusste ich ja schon, und benutzt das auch fur senden
    # hm, benütze aber nicht EL::Util::Sendmail::sendmail funktion weil die throw'd eine PermanentError exception und das
    # wäre nicht gut. Na, oder eval
    eval {
	EL::Util::Sendmail::sendmail(To=>$replyaddress,
				     From=>$youraddress,
				     Subject=>$subject,
				     # sigh, muss : geben an unübliche felder. hass, es hätte bitte wenigstens ein warning abgeben können ab den unbekannten parametern.
				     'Precedence:'=>'junk',
				     'Auto-Submitted:'=>'auto-replied',
				     Data=>$body);
    };
    #warn $@ if ref$@ or $@;
    if (ref$@ or $@) {
	warn $@;
	0
    } else {
	1
    }# warum auch immer es sinn mache hier exceptions zu catchen.  aha siehe oben...
}

1;

__END__
# wie sieht eine autoreply aus:

- kein in-reply-to   obwohl, sollte ich das machen?
- 
vgl. unten.
=>
- In-Reply-To: <lifecms-fsixnwdclxokmgm2jthojt0epa@ethlife.ethz.ch>
- Precedence: junk
- Auto-Submitted: auto-replied
(- Delivered-To: ggminder@bluewin.ch)



X-Mailer: Stalker Internet Mail Server 1.7
Subject: Auto-Reply to: ETH Life Newsletter 5.1.2004
From: susanne.gaeumann@ecos.ch
To: newsletter-request-0du11or0lgtxs33xrjwtvticac@ethlife.ethz.ch
  (freier body text)

#kein X-Mailer.
Subject: away from mail
From: Felix Waldhauser <felixw@ldeo.columbia.edu>
Precedence: junk

X-Mailer: Confixx Autoresponder
Subject: Re: ETH Life Newsletter 5.1.2004
Reply-To: <>
Sender: <>
Precedence: junk

X-Mailer: vacation 1.46
Subject: away from my office
From: Rita Bearth <rita.bearth@agrl.ethz.ch>
Auto-Submitted: auto-replied

X-Mailer: vacation 1.46
Subject: Out of Office
X-Delivered-By-The-Graces-Of: the vacation program
Auto-Submitted: auto-replied

X-Mailer: Novell GroupWise Internet Agent 6.5.1 
Subject: Antw: ETH Life Newsletter 5.1.2004
From: "Markus Arnet" <Markus.Arnet@zug.zg.ch>
Sender: Postmaster@zug.zg.ch
Reply-To: Markus.Arnet@zug.zg.ch
Errors-To: Postmaster@zug.zg.ch
X-Return-Path: Markus.Arnet@zug.zg.ch
# nix precedence aber!

# keine Mailer angabe
Subject: Office closed till 5th of January 2004
To: newsletter@ethlife.ethz.ch
From: Wolfgang Brundiers <Wolfgang.Brundiers@cosanum.ch>
# wow isch das deklariert. zarro referenz.

X-MimeOLE: Produced By Microsoft Exchange V6.0.6487.1
Subject: Your E-Mail Message will not be read 
Thread-Topic: ETH Life International Newsletter 2004/01/08
Thread-Index: AcPVuCuAKTLGNkBZQsCRFwaAKy121QAAAAQk
From: "Fesch, Claudia (F&W)" <claudia.fesch@sl.ethz.ch>
To: <internationalnewsletter-request-hzuyfp4qdrsipemd3amlvcb3cf@ethlife.ethz.ch>
X-OriginalArrivalTime: 08 Jan 2004 07:22:28.0146 (UTC) FILETIME=[2BC3D920:01C3D5B8]
Date: Thu, 8 Jan 2004 08:22:27 +0100
X-local:
# tausend wege und arten. 


(ps scheissgagl: sollte ich echt und wirklich  die newsletter mails  auch mit thread-index verschicken würde dann in-reply to analogon auch bei MS kommen?)

From: ggminder@bluewin.ch
Subject: Re: ETH Life International Newsletter 2004/01/08
To: internationalnewsletter-request-fsixnwdclxokmgm2jthojt0epa@ethlife.ethz.ch
Date: Thu, 8 Jan 2004 07:24:16 +0000
Message-ID: <3FEECA8C00D536A2@mssazhb-int.msg.bluewin.ch>
In-Reply-To: <lifecms-fsixnwdclxokmgm2jthojt0epa@ethlife.ethz.ch>
Precedence: junk
Delivered-To: ggminder@bluewin.ch

