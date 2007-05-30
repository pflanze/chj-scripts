# Mon May 28 14:24:25 2007  Christian Jaeger, christian at jaeger mine nu
# 
# Copyright 2007 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Mail::Popsmtp

=head1 SYNOPSIS

=head1 DESCRIPTION

Use an account on a service like gmx for sending mail from there.
(Usually can only use that account's normal address as From address,
but is useful for testing your incoming-smtp hosts from an external
place.)

=cut

# extracted from pflanze's bin/checkmail

package Chj::Mail::Popsmtp;
#@ISA="Exporter"; require Exporter;
#@EXPORT_OK=qw();
#%EXPORT_TAGS=(all=>\@EXPORT_OK);

use strict;

use Class::Array -fields=>
  -publica=>
  'pophost',
  'user',
  'pass',
  'senderaddress',
  'maybe_smtphost', # use pophost if undef
  '_last_pop3_time', # undef for none
  ;


sub new {
    my $class=shift;
    my $s= $class->SUPER::new;
    (@$s[Pophost,User,Pass,Senderaddress,Maybe_smtphost])=@_;
    $s
}

use Net::POP3;
use Net::SMTP;
use HTTP::Date; # only used for Date: header which is not important.
#load these lazily? or not?:
use Chj::xtmpfile;
#use Chj::Hostname "checked_hostname";
#our $hostname= checked_hostname;
#ah war eh nur für forwarding gewesen.  ps subclassing  hehe  tmpfiel hehe  huh.  maybe? maybenot?. wissen aus welcher klasse ne methode kommt. automatisch methoden erben  jojo.schweisnidiges.
#/lazyload

sub pop3_fetchmail {
    my $s=shift;
    my ($recvbase)=@_;

    my $pop = Net::POP3->new($s->pophost, Timeout => 60) or die;
    my @mails;
    eval {
        my $cnt= $pop->apop($s->user,$s->pass) or die;
        ##ps. könnte auch per Net::Netrc passwort abfragen lassen ?

        $|=1;

        if ($cnt>0) {
            print "There are $cnt messages in the mailbox.\n";
            my $list= $pop->list or die;
            for my $id (keys %$list){
		my $bytes= $$list{$id};
                warn "Fetching message $id ($bytes bytes)..";
                my $tmpfile= xtmpfile $recvbase;
		my $tmpnam= $tmpfile->path;
                $pop->get($id,$tmpfile) or die;##
                $tmpfile->xflush;
                warn "got it. Looking at From: address..";
                my $verwerf;
                eval {
                    $tmpfile->xrewind;
                    local $_; #!don't forget!
                    while (<$tmpfile>) {
                        if (/^$/) { # end of head
                            last;
                        }
                        if (/^From: GMX Magazin </) {
                            $verwerf=1;
                            last;
                        }
                    }
                    close IN;
                };
                warn $@ if $@;

                if ($verwerf) {
                    warn "verwerfe das Mail da uninteressant";
                } else {
		    $tmpfile->autoclean(0);
		    $tmpfile->xrewind;
		    push @mails,$tmpfile;
                }
                print "done. Deleting..";
                undef $@;
                $pop->delete($id) or die "Died for id $id";#
                print "done.\n";
            }
        }
        $pop->quit;
    };
    if ($@){
        if ($@=~s/^Died//){
            die "error in pop3 part: ".$pop->message.$@
        } else {
            die
        }
    }
    $$s[_Last_pop3_time]= time;
    @mails
}

sub smtphost {
    my $s=shift;
    $$s[Maybe_smtphost] || $$s[Pophost]
}

sub smtp_sendmailstring_to {
    my $s=shift;
    my ($mailstring,@adresses)=@_;
    my $smtp = Net::SMTP->new($s->smtphost) or die;
    eval {
        $smtp->auth($s->user,$s->pass) or die;## gmx requires this today; huh, plaintext.
	$smtp->mail($s->senderaddress) or die;
	for my $adr (@adresses) {
            $smtp->to($adr) or die;
	    #loggen?..
	}
	$smtp->data or die;
	$smtp->datasend($mailstring) or die;
	$smtp->dataend or die;
        $smtp->quit or die;
    };
    if ($@){
        if ($@=~ s/^Died//){
            die "error in smtp part: ".$smtp->message.$@
        } else {
            die
        }
    }
}



end Class::Array;
