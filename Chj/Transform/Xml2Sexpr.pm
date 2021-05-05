# Mon Jun 12 02:50:56 2006  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004-2021 by Christian Jaeger
# Published under the same terms as perl itself
#

=head1 NAME

Chj::Transform::Xml2Sexpr

=head1 SYNOPSIS

    use Chj::Transform::Xml2Sexpr;
    my $expect_html = 1;
    my $transformer = Chj::Transform::Xml2Sexpr->new(html=> $expect_html);

    # reads from $path, writes to $path with suffix replaced by ".scm"
    $transformer->file_to_sexpr($path)

    # these print to $outfh or stdout
    $transformer->string_to_sexpr($str, [$outfh])
    $transformer->port_to_sexpr($fh, [$outfh])

    # returns a string:
    $transformer->string_to_sexpr_string($str)

=head1 SEE ALSO

xml-to-sexpr script

=cut


package Chj::Transform::Xml2Sexpr;

use strict;
use utf8;

use XML::LibXML;
use Chj::xtmpfile;
use Chj::schemestring;

sub new {
    my $class= shift;
    my $self = {@_};
    bless $self, $class;
    $self->{parser} //= do {
        my $parser= XML::LibXML->new;
        # Try to avoid loading DTD, does not help?
        $parser->load_ext_dtd(0);
        $parser->validation(0);
        $parser
    };
    $self
}

sub walk_element {
    my ($self, $node, $o)=@_;
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
	    $self->walk_element($child, $o);
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

sub file_to_sexpr {
    my ($self, $filepath)=@_;
    my $out= $filepath;
    $out=~ s/\.(?:xml|x?html)$//i;
    $out.= ".scm";

    my $tree= $self->{parser}->parse_file($filepath);##or die ?

    my $o= xtmpfile $out;
    binmode($o,":utf8") or die "binmode: $!";
    my $top= $tree->documentElement  or die;
    $self->walk_element($top, $o);
    $o->xclose;
    $o->xputback(0666);
}

sub STRING_OR_PORT_to_sexpr {
    my ($self, $method, $string_or_port, $opt_outport)=@_;
    my $o= $opt_outport || do {
	my $o= bless *STDOUT{IO},"Chj::IO::File";
        binmode($o,":utf8") or die "binmode: $!";
	$o
    };
    my $tree= $self->{parser}->$method($string_or_port);##or die ?
    my $top= $tree->documentElement  or die;
    $self->walk_element($top, $o);
    $o->xclose;
}

sub string_to_sexpr {
    my ($self, $string, $opt_outport)=@_;
    $self->STRING_OR_PORT_to_sexpr("parse_string", $string, $opt_outport)
}

sub port_to_sexpr {
    my ($self, $inport, $opt_outport)=@_;
    $self->STRING_OR_PORT_to_sexpr("parse_fh", $inport, $opt_outport)
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

sub string_to_sexpr_string {
    my $self = shift;
    $self->string_to_sexpr($_[0], new Chj::Transform::Xml2Sexpr::StringPort)
}

1
