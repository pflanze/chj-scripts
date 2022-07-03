use strict; 
use warnings FATAL => 'uninitialized';


sub email_full {
    my $email_full= `EMAIL_FULL_CLEAN=1 email-full`; chomp $email_full;
    $email_full
}

sub shebang {
    "#!/usr/bin/env perl\n"
}

my $is_FunctionalPerl_project;
sub is_FunctionalPerl_project {
    $is_FunctionalPerl_project //= do {
        `pwd`=~ /functional-perl/
    }
}

sub copy {
    my ($email_full)= @_;
    $email_full //= email_full;
    my $year= (localtime)[5]+1900;
    if (is_FunctionalPerl_project) {
        my $str= <<'END';
#
# Copyright (c) 2021 Christian Jaeger, copying@christianjaeger.ch
#
# This is free software, offered under either the same terms as perl 5
# or the terms of the Artistic License version 2 or the terms of the
# MIT License (Expat version). See the file COPYING.md that came
# bundled with this file.
#
END
        $str=~ s/2021/$year/;
        my $m= q{Christian Jaeger, copying@christianjaeger.ch};
        $str=~ s/\Q$m\E/$email_full/ unless $email_full=~ /Christian Jaeger/;
        chomp $str;
        $str
    } else {
        (# "#\n".
         "# Copyright $year by $email_full\n".
         "# Published under the same terms as perl itself")
    }
}

sub edit {
	my $line=shift;
	my $additionaloptions=shift;
	if (@_) {
		my $ed= do{ 
			#$ENV{USER} eq 'chris' ? 'nc' :
			$ENV{EDITOR}||$ENV{VISUAL}
		};
		if ($ed) {
			if ($ed eq 'nc' or $ed eq 'nedit') {
				exec 'nc','-line', $line, @_;
			} else {
				exec $ed, @$additionaloptions, @_;
			}
		}
	}
}

{
    package CHJ::Newperl::Path;
    sub new {
	my $cl=shift;
	my ($path_or_ns)=@_;
	# welches ist der pfad, welches der Namespace?
	if ($path_or_ns=~ /(.*?)((?:\w+::)*\w+)(?:\.pm)?$/ ) {
	    my ($path,$ns)=($1,$2);
	    $path.=join("/",split(/::/,$ns));
	    if ($ns!~ /::/ and $path!~ /^\//) {
		# Benutzer hat wohl slashes statt :: verwendet.
		$ns= $path;
		$ns=~ s|^\./||;
		# Assume that classes *always* start with an uppercase initial, remove lowercase path parts first:
		$ns=~ s|^(?:[^A-Z/][^/]*/)+||s;
		# Turn remaining path to namespace syntax
		$ns=~ s|/|::|g;
	    }
	    $path.=".pm";
	    bless {
		   path=> $path,
		   namespace=> $ns,
		  }, $cl;
	} else {
	    #warn
	    die "don't understand path or namespace '$path_or_ns'"; #can this happen at all? except with the empty string?
	    #undef
	}
    }
    sub path { $_[0]{path} }
    sub namespace { $_[0]{namespace} }
}


1;
