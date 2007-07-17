# cj  Wed Sep  5 17:39:12 CEST 2001 (ursprünglich von /home/programmer/infrastruktur/backupper/htdocs)

# This calls cpbk, and filters the output of the latter so that only relevant
# stuff gets through.
# Note: this has been written for cpbk 4.1.0

use strict;

use constant PRIO_PROCESS=> 0; #ç wo könnt ich das holen?


sub backup {
	die unless @_==4 or @_==5 or @_==6 or @_==7;
	my ($source,$target,$trashdir,$log, $do_write_on_stdout, $excludesref, $simulate)=@_;
	
	setpriority PRIO_PROCESS,$$,20; # or die $!;
	
	open LOG,">>$log" or warn "Kann logfile $log nicht öffnen: $!";
	
	if ($simulate) {
		print LOG "(backup_with.cpbk.pm) WARNING: simulating only..\n";
		print "(backup_with.cpbk.pm) WARNING: simulating only..\n" if $do_write_on_stdout;
	}
	
	pipe READ,WRITE;

	my $pid=fork; defined $pid or die $!;
	#my $changed;
	if ($pid) {
		close WRITE;
		while (<READ>) {
			chomp;
			next unless length($_);
			next if /Searching (?:source|destination) files and building /;
			next if /Comparing files and generating order lists/;
			next if /Trash bin directory .* does not exist. Making it./;
			next if /will be used as the trash bin/;
			next if $> and /Owner of .* is changed/;
			next if $> and /But there is no permission to change the owner/;
			next if /^Done$/;
			next if /^..2K$/;
			print LOG localtime()." $_\n";
			print "$_\n" if $do_write_on_stdout;
			#$changed=1;
		}
		wait;
		if ($?) {
			print LOG localtime()." Return value from cpbk is $? !\n";
			print "Return value from cpbk is $? !\n" if $do_write_on_stdout;
		}
		close LOG;
		rmdir $trashdir # unless $changed;  no, try anyway (maybe just a new file was added to the repos)
		or chmod 0750,$trashdir;
	}
	else {
		close READ;
		open STDOUT,">&WRITE" or die;
		open STDERR,">&WRITE" or die;
		exec qw"
			cpbk --ignore-minor-error --verbose --suppress-progress  ",($simulate? "--simulate":()),
				"-t",$trashdir, ($excludesref && @$excludesref ? "--exclude=".join(",",@$excludesref):()),
				$source,$target;
		die "could not exec"
	}

}

1;

# --verbose ist nötig um überhaupt copy/remove/... messages zu sehen.
# --ignore-minor-error ist nötig damits nicht abbricht bloss weils user nicht setzen kann
# Filter ist nötig um all den Müll rauszunehmen.
# Hmmmm, aha?, wäre --suppress-progress dazu da? Nein, gar keine Aenderung??

#cpbk --version
#Backup Copy 4.1.0
#Copyright (C) 1998 Kevin Lindsay <klindsay@mkintraweb.com>
#Copyright (C) 2001 Yuuki NINOMIYA <gm@debian.or.jp>
