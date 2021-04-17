# Fri Jul  9 15:28:28 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::FileStore::MIndex::NonsortedIterator

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::FileStore::MIndex::NonsortedIterator;

use strict;
use utf8;
use Chj::xopendir;

use Class::Array -fields=> (
			    'Parent',
			    'Criterion',
			    'MainDirfh',
			    'SubDirfh',
			    'Basedircopy',
			    'RawCurrentKey',
			   );


sub new {
    my $class=shift;
    my $self= $class->SUPER::new;
    @$self[Parent,Criterion]=@_;

    $$self[Basedircopy]= $$self[Parent]->basedir;
    $$self[MainDirfh]=xopendir $$self[Basedircopy];#nananajajaja
    $self
}


# sub next_val {
#     #my $s=shift;
#     my ($s)=@_;
#     my $nextmain=sub{
# 	my $item= $$s[MainDirfh]->xnread;
# 	defined $item or do {
# 	    undef $$s[MainDirfh];
# 	    return;####ç outer
# 	};
# 	$$s[SubDirfh]= xopendir "$$s[Basedircopy]/$item";
#     };
#     my $nextinner=sub{
# 	return unless $$s[SubDirfh];#murksy
# 	my $item= $$s[SubDirfh]->xnread;
# 	defined $item or do{
# 	    undef $$s[SubDirfh];
# 	    return;
# 	};
# 	$item
#     };
#     my $rv;
#     defined($rv=&$nextinner)
#       or do{ &$nextmain ? defined($rv=&$nextinner)|| return : return};
#     my $v=Chj::FileStore::MIndex::_unescape($rv);
#     if ($$s[Criterion]){
# 	if ($$s[Criterion]->($v)) {
# 	    $v
# 	} else {
# 	    goto &next_val
# 	}
#     } else {
# 	$v
#     }
# }
#^- ist verschwenderisch mit Criterion, macht subiteration wo unnötig.  und war escht no falsch, criterion checkte value statt key

sub next_val {
    #my $s=shift;
    my ($s)=@_;
    my $nextmain=sub{ # scho no "unsinn" dass closure creation wenn gar ned sicher ob benötigt. na mit context per argument liefern wärs anderschmöglich. frage: kann scheme/lisp/ocaml lazy closure creation machen?
	my $item;
	do {
	    $item= $$s[RawCurrentKey]= $$s[MainDirfh]->xnread;
	    defined $item or do {
		undef $$s[MainDirfh];
		return;
	    };
	} until (!$$s[Criterion] or $$s[Criterion]->(Chj::FileStore::MIndex::_unescape($item)));
	$$s[SubDirfh]= xopendir "$$s[Basedircopy]/$item";
    };
    my $nextinner=sub{
	return unless $$s[SubDirfh];#murksy
	my $item= $$s[SubDirfh]->xnread;
	defined $item or do{
	    undef $$s[SubDirfh];
	    return;
	};
	$item
    };
    my $rv;
    defined($rv=&$nextinner)
      or do{ &$nextmain ? defined($rv=&$nextinner)|| return : return};
    Chj::FileStore::MIndex::_unescape($rv);
}

sub next_key {
    my ($s)=@_;
    # TJA. nun hier doch key next machen,  das implizite subdirfh=xopendir aber NICHT machen. murksy
    my $k=$$s[MainDirfh]->xnread;
    defined $k or return;
    Chj::FileStore::MIndex::_unescape($k);
}

sub current_key {#only tracked when using next_val !!
    my ($s)=@_;
    return unless defined $$s[RawCurrentKey];# oerr wäre so hilfreich echt
    Chj::FileStore::MIndex::_unescape $$s[RawCurrentKey]
}

1;
