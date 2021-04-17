# Mon Jun 12 02:50:56 2006  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::Transform::Xml2Sexpr

=head1 SYNOPSIS

=head1 DESCRIPTION

(moved here from xml-to-sexpr script)

=cut


package Chj::Transform::Xml2Sexpr;
@ISA="Exporter"; require Exporter;
@EXPORT_OK=qw(
	      file_xml_to_sexpr
	      string_xml_to_sexpr
	      port_xml_to_sexpr
	      string_xml_to_sexpr_string
	     );

use strict;
use utf8;

use XML::LibXML;
#use Chj::xopen qw(xopen_
use Chj::xtmpfile;
use Chj::schemestring;

my $new_perl= ($] >= 5.008);
sub outencode {
    @_
#     if ($new_perl) {
# 	@_
#     } else {
# 	map {
# 	    #XML::LibXML::encodeToUTF8($_)  ochnein geht nicht. weil quell encoding unknown.
# 	    die "sh?"
# 	} @_
#     }
      #mensch: war gar nicht hier das problem mit dem alten perl. sondern latin1 *ausgabe* von scheme her. und input auch.grr
}

my $parser= XML::LibXML->new;
$parser->load_ext_dtd(0); # !!!  and they don't even say that it was on by default?
#URGH but STILL NO HELP.
$parser->validation(0); #doesn't help either.


sub walk_element {
    my ($node,$o)=@_;
    xprint $o "(";
    my $elname= $node->nodeName;#?
    xprint $o outencode($elname);#
    #my $attrnode = $node->getAttributeNode ( $aname ); #eeehr  und wie krieg ich die namen ?
    #ah: @attrs =$node->attributes;  von Node Klasse. sowas echt komisches wenn dann doch alle nodes egalwas attribute haben können.  ?.
    if (my @attrs=$node->attributes) {
	xprint $o "(@";
	for my $attr (@attrs) {
	    xprint $o outencode("(".($attr->name)." ".schemestring($attr->value).")");
	}
	xprint $o ")";
    }
    for my $child ($node->childNodes) {
	if ($child->isa("XML::LibXML::Element")) {
	    walk_element( $child,$o);
	} elsif ($child->isa("XML::LibXML::Comment")) {
	    xprint $o "(*COMMENT*" , outencode( schemestring( $child->data)) , ")";
	} elsif ($child->isa("XML::LibXML::Text")){
	    xprint $o outencode( schemestring( $child->data));
	} else {
	    die "unknown child type: $child" ##
	}
    }
    xprint $o ")";
}

sub file_xml_to_sexpr {
    my ($filepath)=@_;
    my $out= $filepath;
    $out=~ s/\.xml$//;
    $out.= ".scm";

    my $tree= $parser->parse_file($filepath);##or die ?

    my $o= xtmpfile $out;
    if ($new_perl) {
	binmode($o,":utf8") or die "binmode: $!";
    } else {
	#
    }
    #walk
    #selber wieder mal ?
    my $top= $tree->documentElement  or die;
    walk_element $top,$o;
    $o->xclose;
    #$o->xputback;##oderso.
    #$o->xreplace_or_withmode  ist für wenn ziel anders ist als eigener path.
    $o->xputback(0666);
}

sub STRING_OR_PORT_xml_to_sexpr {
    my ($method, $string_or_port, $opt_outport)=@_;
    my $o= $opt_outport || do {
	my $o= bless *STDOUT{IO},"Chj::IO::File";
	if ($new_perl) {
	    binmode($o,":utf8") or die "binmode: $!";
	} else {
	    #
	}
	$o
    };
    my $tree= $parser->$method($string_or_port);##or die ?
    my $top= $tree->documentElement  or die;
    walk_element $top,$o;
    $o->xclose;
}

sub string_xml_to_sexpr {
    my ($string, $opt_outport)=@_;
    STRING_OR_PORT_xml_to_sexpr ("parse_string",$string,$opt_outport)
}

sub port_xml_to_sexpr {
    my ($inport,$opt_outport)=@_;
    STRING_OR_PORT_xml_to_sexpr ("parse_fh",$inport,$opt_outport)
}



{
    package Chj::Transform::Xml2Sexpr::StringPort;
    sub new {
	my $class=shift;
	my $self="";
	bless \$self,$class;
    }
    sub xprint {
	my $s=shift;
	$$s.=join("",@_);
    }
    sub xclose {
	my $s=shift;
	$$s
    }
}

sub string_xml_to_sexpr_string ( $ ) {
    string_xml_to_sexpr($_[0], new Chj::Transform::Xml2Sexpr::StringPort)
}

1
