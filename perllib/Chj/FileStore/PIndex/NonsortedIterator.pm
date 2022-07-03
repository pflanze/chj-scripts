# Tue Aug 24 03:13:19 2004  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::FileStore::PIndex::NonsortedIterator

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut

# von MIndex::NonsortedIterator kopiert-und-modifiziert.  VIELZUVIEL ist hier Kopie.

package Chj::FileStore::PIndex::NonsortedIterator;

use strict;
use Chj::xopendir;

use Class::Array -fields=> (
			    'Parent',
			    'Criterion',
			    'MainDirfh',
			    #'SubDirfh',grr no
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

sub next_val {######EHR? next_key? wenn er $rv gibt! gaga. bishernicht beutzt scheint wenn get_iter falsch war? -> todo umbenennen wohl (Wed, 31 Jan 2007 10:59:21 +0100)
    #my $s=shift;
    my ($s)=@_;
    return unless $$s[MainDirfh];#murksy
  AGAIN:
    my $item= $$s[MainDirfh]->xnread;
    defined $item or do{
	undef $$s[MainDirfh];
	return;
    };
    goto AGAIN if substr($item,0,1) eq 't';# tmp path.
    my $rv= Chj::FileStore::PIndex::_unescape($item);
    if (!$$s[Criterion] or $$s[Criterion]->($rv)) {
	return $rv;
    } else {
	goto &next_val;
    }
}

sub next {
    my ($s)=@_;
    return unless $$s[MainDirfh];#murksy
  AGAIN:
    my $item= $$s[MainDirfh]->xnread;
    defined $item or do{
	undef $$s[MainDirfh];
	return;
    };
    goto AGAIN if substr($item,0,1) eq 't';# tmp path.
    my $key= Chj::FileStore::PIndex::_unescape($item);
    if (!$$s[Criterion] or $$s[Criterion]->($key)) {
	my $val= $$s[Parent]->get($key);
	return ($key,$val);
    } else {
	goto AGAIN;
    }
}


1;
