
# cj Tue, 13 Apr 2004 18:55:55 +0200
# new implementation making use of publicip module

package Chj::Hostname;

@EXPORT_OK=qw(checked_ip_hostname checked_hostname
	      linux_hostname
	      hostname);
require Exporter;
@ISA='Exporter';
use strict;
use Carp;
use Net::Domain;
use Chj::Net::Publicip 'publicip';
use Socket;

sub checked_ip_hostname { ## "sigh!": wenn gefundene ip in /etc/hosts eingetragen ist wird sie dort aufgelöst !!! aufpassenalso
    my $n= Net::Domain::hostfqdn;
    # check it
    if (my $ip= gethostbyname($n)) {
	return $n
    } else {
	# look for ip's and try those
	for my $ip (publicip) {
	    #warn "checked_ip_hostname: checking ip '$ip'";
	    my $r= scalar gethostbyaddr(inet_aton($ip),AF_INET);
	    return $r if $r;#ok?
	}
	return undef;#?
    }
}
*checked_hostname= \&checked_ip_hostname;

sub linux_hostname { # ask kernel. is not fully qualified. but at least fast. (should we check /proc/sys/kernel/domainname too? it's (none) on my boxes)
    open LKHN,"</proc/sys/kernel/hostname" or croak "linux_hostname: could not open /proc/sys/kernel/hostname: $!";
    local $/; my $hn=<LKHN>;
    close LKHN or croak "linux_hostname: close: $!";
    $hn=~ s/\s+\z//s;# chomp does not (seem to) work if $/ is still undef
    $hn
}

sub hostname { # non-qualified hostname
    {
	my $hn= eval { linux_hostname };
	return $hn if $hn;
    }
    {
	my $hn=`hostname`;
	return unless $hn;
	chomp $hn;
	return $hn;
    }
}
# WELL, should we use Sys::Hostname instead of the latter? hehe. (does uname() syscall on linus  ps so funny der erste syscall von perl überhaupt ist auch uname())

__END__
package Chj::Hostname;

@EXPORT_OK=qw(checked_hostname);
require Exporter;
@ISA='Exporter';
use strict;

use Net::Domain;
use is_if_up;## Chj::
use Socket;

sub tryif{
  my $if=shift;
  if (my $ip=is_if_up($if)){
    if ($ip=~ /^192\.168/) {
      return
    } else {
      # reverse lookup
      scalar gethostbyaddr(inet_aton($ip),AF_INET)
    }
  }
}

sub checked_hostname {
  my $n= Net::Domain::hostfqdn;
  # check it
  if (my $ip= gethostbyname($n)) {
    return $n
  } else {
    # try network interfaces
    tryif("eth0") || tryif("eth1")
  }
}

__END__
Und das ist nun immer noch sicher?
(ETOOMANYOPENLOOPHOLEODERSOWAS)

Sollte eigentlich kein Problem sein.
aber
- started diverse subprozesse.  Kann ich wirklich nix da hin senden an signal?. Sollte nicht.
- geht aufs Netz sachen fragen. Naja, sollte theoretisch auch kein problem sein solange libraries nich n hole haben. Was wenn doch?  [Und DoS problematik, well eher wegen prozessestarten?.]

