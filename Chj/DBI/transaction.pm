# Tue Aug 30 21:05:09 2005  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2002-2005 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::DBI::transaction

=head1 SYNOPSIS

 use Chj::DBI::transaction;
 transaction sub {
    blablabla
 };
 # our $DB is expected.
 # or:
 transaction sub {
    blablabla
 }, $dbhandle;

 # if you give even more arguments, those will be in @_ when the callback is called.

=head1 DESCRIPTION

(Almost-identical) Copy from the routine in EL::DB from ETH Life cms.
The only differences are:

 - $db->begin_work is issued before running the wrapped code. (Idea: do not switch off single transaction mode ehr whatever it is called; but what's about the case where you want to run queries in the same transaction and only later decide to run a failure-protected loop with commit over the rest? but that would be exotic, right?)
 - confess is called instead of croak in case of nested transaction calls.
 - the prototype has been removed, so as to make "transaction $work,$DB;" work.

and (Thu, 23 Mar 2006 00:10:35 +0100):

 - calls real_begin_work, real_commit, real_rollback instead of begin_work, commit, rollback if the $DB handle supports those. This is for making it possible to let the original methods die as safety measure ('inspiration' came during dev of Chj::DBI::subtransaction).


=head1 NO QUESTION

that subclassing DBI for adding a transaction method would be a possible alternative.

und übrigens: use Chj::DBI::transaction $DB; (+ currying) wäre doch cleaner als der caller lese trick.

=head1 PROBLEM

weil $db handle nicht reconnect von mir hat  eben.  ja subclassing wäre das richtige./richtiger.
HACK nun: $Chj::DBI::transaction::reconnect;  auf eine sub setzen bitte.

ps es scheint tonnen probleme zu geben wenn man nicht alles OO macht. destructor kann ich nicht registern hier: denn geht in perl nur über DESTROY und wie soll ich das  wenn  klasse  fremd ist. (Ok weak table könnte problem insofern lösen dass ich keinen destructor mehr bräuchte)

=cut


package Chj::DBI::transaction;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(transaction transaction_check_exception);

use strict;
use Carp;

our $reconnect= sub { confess "\$Chj::DBI::transaction::reconnect has not been set, thus cannot reconnect" };


# ("was nicht alles nötig ist, bloss weil man OO umgeht": )
our $begin_work= sub {
    my ($db)=@_;
    if (my $c= UNIVERSAL::can($db,"real_begin_work")) {
	$c->($db)
    } else {
	$db->begin_work
    }
};
our $rollback= sub {
    my ($db)=@_;
    if (my $c= UNIVERSAL::can($db,"real_rollback")) {
	$c->($db)
    } else {
	$db->rollback
    }
};
our $debug_spoilt=1;
our $commit= sub {
    my ($db)=@_;
    # only commit if there isn't a spoilt method returning true:
    if (my $spoilt= UNIVERSAL::can($db,"spoilt")) {
	if ($spoilt->($db)) {
	    ## also unset it here (?! was da alles schreg)
	    $db->set_spoilt(0);
	    warn "(note: issuing a rollback instead of a commit, because db handle has been marked as spoilt" if $debug_spoilt;
	    return $rollback->($db)
	}
    }
    if (my $c= UNIVERSAL::can($db,"real_commit")) {
	$c->($db)
    } else {
	$db->commit
    }
};



our %running_transactions;

#sub exception_is_transaction_related {

sub exception_warrants_retry {
    my ($e)=@_;
    if (UNIVERSAL::isa($e,'EL::Exception::TemporaryFailure')) { ## doesn't make so much sense here. ##
	1
    } elsif (do {
	my $estr= "$e";
	(($estr=~ /DB[ID]/ and ! $estr=~ /sql\s+syntax/i)  ##
	 #or $estr=~ /rollback ineffective .* AutoCommit/i #well, shouldn't happen in the first place -- we shouldn't do rollback    ah: machen wir selber unten; nun dort abgefangen.
	 or
	 $estr=~ /DBD driver has not implemented the AutoCommit attribute/i # happens on begin_work if mysql went away. ugly?.
	 #^- ah der sollte von der ersten regex eh aufgefangen worden sein!
	)
    }) {
	1
    } else {
	0
    }
}

sub exception_warrants_reconnect {
    my ($e)=@_;
    my $estr= "$e";
    (($estr=~ /DB[ID]/ and ! $estr=~ /sql\s+syntax/i)  ##
     or
     $estr=~ /DBD driver has not implemented the AutoCommit attribute/i # happens on begin_work\ if mysql went away. ugly?.
    )
}

# dann evtl. solche exceptions die abbruch wollen? rollback.  wenn code n rollback will,  muss auch fluss abgebrochen werden, damit keine neuen sachen auf db ausgeführt werden und am ende hier wieder commit. ODER?
# Zuerst dachte ich, ich nenne es:  rethrow_if_transaction_related($@);
# doch evtl. ist dies besserer name: transaction_check_exception($@);

sub exception_means_rollback {
    my ($e)=@_;
    ## currently never?
    0
}
sub exception_means_abort {
    my ($e)=@_;
    ## currently never?
    0
}

sub transaction_check_exception {
    my ($e)=@_;
    # hier hätte ich eine stored continuation.
    # Wann will ich abbrechen?
    # - wenn exception_warrants_retry? direkt. ja vielleicht gut.
    if (exception_warrants_retry($e)) {
	carp "transaction_check_exception($e): warrants retry, so we rethrow it to let 'transaction' handle it,";
	die $e;
    } elsif (exception_means_rollback($e)) {
	## hm eben, will ich das wirklich, also, abbruch exception, oder so.
	carp "transaction_check_exception($e): wants rollback, so we rethrow it to let 'transaction' handle it,";
	die $e;
    } elsif (exception_means_abort($e)) {
	carp "transaction_check_exception($e): warrants abortion, so we rethrow it to let 'transaction' handle it,";
	die $e;
    }
    # else silently return
}



sub rethrow {
    my ($e,$additionalmessage)=@_;
    #"### todo: damit aufgetretene exception proberly angezeigt werden kann, n objekt sein lassn. ODER: eben exception recorder objekte machen somehow. "additionally an xxx exception happened". list of problems.  AH hatte im objekt falle ja rethrow.  jaja, rethrow, possibly with annotation, ist wohl der richtige eine weg. sonstige errors anders noch ?. ."
    ####possibly auch carp, damit im server log definitiv sichtbar.  auch ne eternal question.
    if (ref $e) {
	if ($e->can("rethrow")) { rethrow $e }
	elsif ($e->can("throw")) {throw $e }
	else { die $e }
    } else {
	croak $@."\t".$additionalmessage
    }
}


#this replaces '$db->rollback; ### [hopefully that won't throw an exception?] -- doch tut es.'
sub safe_rollback {
    my ($db,$e)=@_;#the $db argument will be overwritten nach aussen ! on reconnect.
    #local $@; nein will man nicht weil  will die folge exception sehen ?. oder will man eigentlich exceptions eben SAMMELN?.("additionally,... while ..")    AHAAA: das eigentliche problem ist dass ich keine scope darum herum gemacht habe und daher das local noch aktiv war als ich unten in catch zweig weiterrechne.
    # nun umgeschrieben dass in ne lexical umkopiert wird.
    {
	my $e2;
	{
	    local $@;
	    eval {
		$rollback->($db);
	    };
	    $e2= $@;
	}
	if ($e2) {
	    if ($e2=~ /rollback ineffective .* AutoCommit/i
		# ah, and here too check for this weird 'DBD driver has not implemented the AutoCommit attribute' exception, since it happens again right away if it happened on begin_work.
		or
		$e2=~ /DBD driver has not implemented the AutoCommit attribute/i
		#exception_warrants_retry($e2)
	       ) {
		# ok, 'no problem'
		# well ja, mach hier den reconnect.
		#$DB::single=1;
		#todo: dies hier removen, right?, weil nun unten reconnected wird.  well, klar es kann weiterhin error geben hier WENN rollback nicht so gemacht ist dass er nicht ausgeführt wird wenn nicht inside transaction.
		warn "transaction: reconnecting (old: '$db')";
		$_[0]= $reconnect->($db);# or throw an exception otherwise.pleas.
		warn "transaction: done, after reconnect: '$_[0]'";
		#(Wed, 03 May 2006 16:55:25 +0200  undef $@; nein nicht nötig. problem liegt woanders.)
	    } else {
		my $e2str="$e2"; chomp $e2str;
		my $estr= "$e"; chomp $estr;
		croak "error '$e2str' while processing '$estr'";
	    }
	}
    }
}

#grr and since we are getting 'DBD driver has not implemented the AutoCommit attribute' from begin_work after mysql went away, we need this:
# sub safe_begin_work {
#     my ($db)=@_;
#     eval {
# 	$db->begin_work;
#     };
#     if ($@) {
# 	my $e2= $@;
# 	if ($e2=~ //i) {
# 	    # ok, no problem
# 	} else {
# 	    my $e2str="$e2"; chomp $e2str;
# 	    my $estr= "$e"; chomp $estr;
# 	    croak "error '$e2str' while processing '$estr'";
# 	}
#     }
# }
# EH  hier brauchen wir kein exception catch. sondern der muss aussen rum  für retry sorgen.

sub running_transaction {
    my ($db)=@_;
    $running_transactions{$db}
}

sub transaction {
    my $dbref= \ $_[1];
    my ($coderf,$db)=(shift,shift);
    unless ($db) {
	no strict 'refs';
	$db= ${caller()."::DB"} or croak "transaction called without 2nd argument and without \$DB in caller package";
    }
    if ($running_transactions{$db}) {
	confess "transaction: there is already a transaction running for db handle $db";
    }
    #local $running_transactions{$db}= 1;#[ (caller)[0..2] ];  nein muss unten sein, weil $db ändern kann.
    my $tries=3;

    my $wantarray= wantarray;
    my @rv;
  TRY:{
	local $running_transactions{$db}= 1;#[ (caller)[0..2] ];
	eval {
	    $begin_work->($db);
	    @rv= $wantarray ? &$coderf : scalar &$coderf;
	    $commit->($db);
	};
	if (ref $@ or $@) {
	    my $e=$@;
	    safe_rollback($db,$e); #$$dbref=$db; nein dumm hier. safe_rollback ist eigentlich nicht gemeint dass das reconnected. well, genauer gesagt: nicht mehr. das war komische idee von mir. Heute, wo EiD::DBI::db real_rollback nur dann rollback macht wenn inside transaction um warning zu verhindern, gibts dort keine exception mehr, hence kein merken dass dies grund für failure ist und kein reconnect. neu hier:
	    if (exception_warrants_reconnect($e)) {
		my $olddb=$db;
		$$dbref= $db= $reconnect->($db);# or throw an exception otherwise.pleas.
		# wird das hacky...:
		#delete $running_transactions{$olddb}; # nützt das überhaupt, wenn local ja noch ist ?? to do might leave a leak behind. -> nein, funktionniert richtig offenbar. ehr  mensch kann ich eh weg lassen! denn neu ist local ja innerhalb. und local entfernt gleich den ganzen key, was kool ist.
	    }
	    if (exception_warrants_retry($e)) {# sollte immer wahr sein wenn exception_warrants_reconnect wahr ist. right?
		if (--$tries > 0) {
		    carp $e."\t$tries tries left by 'transaction'";
		    redo TRY;
		} else {
		    rethrow($e,"database rolled back and error propagated by 'transaction'");
		}
	    } else {
		rethrow($e,"database rolled back and error propagated by 'transaction'");
	    }
	}
    }#/TRY
    $wantarray ? @rv : $rv[0]
}

1


__END__
  RATIONALE:

*OLD* SYNOPSIS:

 use Chj::DBI::transaction;
 transaction {
    blablabla
 };
 # or:
 #transaction {
 #  blablabla
 #}, $dbhandle;
 # NO!!!! doesn't work. Perl doesn't offer the necessary precedencemakinng prototype decls, right?
 # This does:
 transaction(sub {
    blablabla
 }, $dbhandle);
 # This does as well:
 transaction sub {
    blablabla
 }, $dbhandle;
 #argh.

 ## btw if you give even more arguments, those will be in @_ when the closure is called, right?.

aber, muss auf prototypes doch eh verzichten denn:
absolut p3rl schrott:
transaction $work,$DB;
-> Type of arg 1 to Chj::DBI::transaction::transaction must be block or sub {} (not private variable) at EiD/DBLayer/User.pm line 107, near "$DB;"
