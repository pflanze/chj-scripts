package Chj::PackageData;

# Sun Mar  9 16:07:52 2003  Christian Jaeger
# $Id$

=head1 NAME

Chj::PackageData 

=head1 SYNOPSIS

 use Chj::PackageData 'packagedata';
 my $hashref= packagedata("some::package");
 use Storable 'nstore_fd';
 nstore_fd($hashref,\*STDOUT);

=head1 DESCRIPTION

Extracts all data variables (SCALAR, HASH, ARRAY) from given package
and returns it in a hash structure which follows this format:

  $hashref= {
     'some::package::Foo'=> {
            HASH=> {  .... },
            SCALAR=> \'....',
     },
     'some::package::Foo'=> {
            ...
     },
  }

=head1 BUGS

Does not store undef scalars. This is because perl does not make it
possible to find out whether a glob contains a scalar or not. So we
assume that it does not if it is undef.

Tries to ignore some common "meta" kind of vars in main:: namespace
but can't do well. Thus do not use this for "main" namespace.

Probably more.

=head1 AUTHOR

Christian Jaeger <christian.jaeger@ethlife.ethz.ch>

=cut

#sub BEGIN {
#}# [x]emacs shit.

require Exporter;
@ISA="Exporter";
@EXPORT_OK=qw(packagedata);
use strict;
use Devel::Symdump;

my @symkind= ( ['$', "scalars","SCALAR"],
               ['%', "hashes","HASH"],
               ['@', "arrays","ARRAY"],
             ); #');

sub packagedata {
    my ($package)=@_;
    my $collection={};
    my ($symkind,$symm);
    #for (($symkind,$symm)= each %symkind){   GEHT NICHT!!!!! irgendwie einfach nicht. Das ist scheisse. Bug. Scheiss.
#    my %ignore;
#    $ignore{$_}=1 for Devel::Symdump->packages($package);
#    warn "IGNROE: ".Dumper(\%ignore);
# Nein das war gar nicht das Problem. Kooooomisch.
    #my %ignore;
    #$ignore{$_}=1 for Devel::Symdump->functions($package);
    #warn "IGNORE: ".Dumper(\%ignore);
    ## DER SCHEISS IST: GLAUBS EBEN WEGEN SCHEISS PERL LIMITATIONS  kann er gar nicht rausfinden ob ein skalar wirklich da ist oder nicht.  (Ohne xs?)  SCHEISSSSSSSSSE.  XS programmieren.
    for (@symkind){
	my ($symkind,$symmethod,$symname)= @$_;##sirgil sowas sollt mans erste nennen
	#warn "kind: $symkind, method: $symmethod, name: $symname\n";
	for (Devel::Symdump->$symmethod($package)) {
	    next if $_ eq 'main::ENV' or $_ eq 'main::INC' or $_ eq 'main::SIG'
	      or $_ eq 'main::@' or $_ eq 'main::_' or $_ eq '_'; ##beides nötog?
	    next if /\:$/s; ##ARGGH.
	    #next if $_ eq 'main:'; #ARGGGGGGGGGGGGGGGG?????????????
	    #?????????????????????????????????????
	    #next if $ignore{$_};
	    next if /:BEGIN$/s;

	    #warn "hehe: '$_'\n";
	    my $symref= do{
		no strict 'refs';
		#\ "$symkind$_"
		#my $r=eval '\\'.$symkind.'{'.$_.'}';  #gefahrlich eyey
		#die if $@;
		#$r
		$symname eq 'SCALAR' ? *{$_}{SCALAR} :
		  $symname eq 'HASH' ? *{$_}{HASH} :
		   $symname eq 'ARRAY' ? *{$_}{ARRAY} :
		     die "BUG"
		 };
	    #warn "symref=$symref\n";
	    #warn "\\ undef ist: ".(\ undef)."\n";
	    #warn "\$\$symref ist '$$symref'\n";
	    #next if $symname eq 'SCALAR' and $symref == \ undef;
	    # geht auch nicht. Jetzt fragt man sich langsam wirklich.
	    next if  $symname eq 'SCALAR' and ! defined $$symref;
	    $collection->{$_}{$symname}=$symref;
	    #if ($symname ne 'SCALAR' and $collection->{$_}{SCALAR} == $symref){
	    #   # remove it again. workaround for perl limitation.   ##ps das könnt man ev noch weiterziehen. Sigh aber.
	    #   delete $collection->{$_}{SCALAR}
	    #}
	    # Does not work since scalar will be ref to undef. ja blöd wird nimmer dasselbe sein  also  als SCALAR wirds nie die hashref liefern oder so.
	}
    }
    $collection
}


1;
