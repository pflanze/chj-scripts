# Sat May 17 15:48:21 2003  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2003 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Linux::mdstat

=head1 SYNOPSIS

=head1 DESCRIPTION


=head1 FIELDS

status:  active / inactive



=cut


package Chj::Linux::mdstat;

use strict;

#use Class::Array -fields=> ();

use Chj::xopen;

our $DEBUG=1;

sub new {
    my $class=shift;

    my $c;
    {
	my $mds= xopen "/proc/mdstat";
	$c= $mds->xcontent;
    }

    my @mds;
    
    # first get whole entries: md\d+ at the start of a line (or maybe the file, or after
    # the last match), then lines up to a line only containing whitespace, or the end of the file.
    # we are quite vorsichtig you know.
    while ($c=~ /\G(?:|.*?\n)md(\d+)\b\s*:\s*(.*?)(?:\s+\z|\n[ \t]*(?:\n|\z))/sgc) {
	my ($num,$values)=($1,$2); # hier komme ich um $1,$2 nicht herum. darf oben keinen listenkontext haben.
	#print "Status von $num:\n$values\n\n";
	$values=~ /(\w+)\s+(\(read-only\)\s+)?(\w+)\s+/sgc or die "invalid /proc/mdstat format";
	my ($status,$ro,$type)= ($1,$2,$3);
	my (@devices)= $values=~ /\G(\S+) */sgc;
	# 	my @devices;
	# 	print "pos=".pos($values),"\n";
	# 	while ($values=~ /\G(\S+) */sgc) {
	# 	    print "  pos=".pos($values),"\n";
	# 	    push @devices,$1;
	# 	}
	# nein obiges geht schon war bloss mein space+ fehler.
	$values=~ /\G.*?(\d+)\s+blocks/sgc and my $blocks=$1;
	$values=~ /\G.*?\[([^\]]+)\]/sgc and my $uprelation=$1; # is it this?
	#  stau tschau
	$values=~ /\G.*?\[([^\]]+)\]/sgc and my $uplist=$1;     # is it this?
	#print "$num: $blocks blcks\n",join("\n",@devices),"\n\n";
	push @mds, Chj::Linux::mdstat::md->new(
					       blocks=> $blocks,
					       status=> $status,
					       type=> $type,
					       devices=> \@devices,
					       num=> $num,
					       uprelation=> $uprelation,
					       uplist=> $uplist,
					       ro=> $ro,
					      );
	# christoph engel is en attraktive und mues drum e frundin ha
    }
    my $self={ mds=> \@mds };
    bless $self,$class
}

sub check {
    my $self=shift;
    for my $md (@{$$self{mds}}) {
	if ($md->{status} ne 'active') {
	    die "ETWAS NICHT GUT: md$$md{num} hat status '$$md{status}'"; ## throw
	}
	if ($md->{uplist} !~ /^U*\z/) {
	    die "NICHT GUT: nicht alle up: md$$md{num} hat uplist '$$md{uplist}'"; ##
	}
	print STDERR "md$$md{num} seems ok\n" if $DEBUG;
    }
}

sub mds {
    my $self=shift;
    @{$$self{mds}}
}

package Chj::Linux::mdstat::md;

sub new {
    my $class=shift;
    bless {@_},$class
}

sub blocks {
    my $self=shift;
    $$self{blocks}
}
sub num {
    my $self=shift;
    $$self{num}
}
sub status {
    my $self=shift;
    $$self{status}
}
sub type {
    my $self=shift;
    $$self{type}
}
sub devices {
    my $self=shift;
    $$self{devices}
}

1;



__END__
chris@ethlife-a chris > cat /proc/mdstat 
Personalities : [raid1] 
read_ahead 1024 sectors
md2 : active raid1 scsi/host0/bus0/target1/lun0/part2[1] scsi/host0/bus0/target0/lun0/part2[0]
      9767424 blocks [2/2] [UU]
      
md5 : active raid1 scsi/host0/bus0/target1/lun0/part5[1] scsi/host0/bus0/target0/lun0/part5[0]
      1951744 blocks [2/2] [UU]
      
md6 : active raid1 scsi/host0/bus0/target1/lun0/part6[1] scsi/host0/bus0/target0/lun0/part6[0]
      1951744 blocks [2/2] [UU]
      
md12 : active raid1 scsi/host0/bus0/target1/lun0/part12[1] scsi/host0/bus0/target0/lun0/part12[0]
      1951744 blocks [2/2] [UU]
      
unused devices: <none>

  sz += sprintf(page + sz, "md%d : %sactive", mdidx(mddev),
		mddev->pers ? "" : "in");

if (mddev->ro)
  sz += sprintf(page + sz, " (read-only)");
sz += sprintf(page + sz, " %s", mddev->pers->name);


----
  ;
root@pflanze root# cat /proc/mdstat
  Personalities : [raid5]
  read_ahead 1024 sectors
  md0 : active raid5 [dev 07:07][7] [dev 07:06][6] [dev 07:05][5] [dev 07:04][4] [dev 07:03][3] [dev 07:02][2] [dev 07:01][1] [dev 07:00][0]
  4658752 blocks level 5, 64k chunk, algorithm 2 [8/8] [UUUUUUUU]
  							       ^- dieses letzte U war ein _ währenddem es am Aufbau des Arrays war nachdem ichs neu gemacht hab.
  unused devices: <none>
  
