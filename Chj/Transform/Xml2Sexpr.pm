# Mon Jun 12 02:50:56 2006  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004-2021 by Christian Jaeger
# Published under the same terms as perl itself
#

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
use Chj::xtmpfile;
use Chj::schemestring;

my $parser= XML::LibXML->new;
# Try to avoid loading DTD, does not help?
$parser->load_ext_dtd(0);
$parser->validation(0);


sub walk_element {
    my ($node,$o)=@_;
    $o->xprint("(");
    my $elname= $node->nodeName;
    $o->xprint($elname);
    if (my @attrs=$node->attributes) {
	$o->xprint("(@");
	for my $attr (@attrs) {
	    $o->xprint("(".($attr->name)." ".schemestring($attr->value).")");
	}
	$o->xprint(")");
    }
    for my $child ($node->childNodes) {
	if ($child->isa("XML::LibXML::Element")) {
	    walk_element( $child,$o);
	} elsif ($child->isa("XML::LibXML::Comment")) {
	    $o->xprint("(*COMMENT*", schemestring( $child->data) , ")");
	} elsif ($child->isa("XML::LibXML::Text")){
	    $o->xprint(schemestring( $child->data));
	} else {
	    die "unknown child type: $child" ##
	}
    }
    $o->xprint(")");
}

sub file_xml_to_sexpr {
    my ($filepath)=@_;
    my $out= $filepath;
    $out=~ s/\.xml$//;
    $out.= ".scm";

    my $tree= $parser->parse_file($filepath);##or die ?

    my $o= xtmpfile $out;
    binmode($o,":utf8") or die "binmode: $!";
    my $top= $tree->documentElement  or die;
    walk_element $top,$o;
    $o->xclose;
    $o->xputback(0666);
}

sub STRING_OR_PORT_xml_to_sexpr {
    my ($method, $string_or_port, $opt_outport)=@_;
    my $o= $opt_outport || do {
	my $o= bless *STDOUT{IO},"Chj::IO::File";
        binmode($o,":utf8") or die "binmode: $!";
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
