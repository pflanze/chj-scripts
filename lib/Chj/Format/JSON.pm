#
# Copyright 2013 by Christian Jaeger, ch at christianjaeger ch
# This is free software, offered under the terms of the MIT License.
# See the file COPYING that came bundled with this file.
#

=head1 NAME

Chj::Format::JSON

=head1 SYNOPSIS

 use Chj::Format::JSON 'print2json';
 print2json(*STDOUT{IO}, $data, 0);

 #or:
 use Chj::Format::JSON;
 my $out= Chj::Format::JSON::Continuous->new($fh);
 stream_for_each sub {
    $out->print($_[0]);
 }, $somestream;
 $out->end;
 #$fh->xclose;

=head1 DESCRIPTION

Supports only hashes, arrays, strings, and undef. Numbers (and
booleans, whatever is used for them) are printed as strings.


=cut


package Chj::Format::JSON;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(print2json);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;


sub pr {
    my $fh=shift;
    print $fh @_ or die $!
}

sub prln {
    my $fh=shift;
    print $fh @_,"\n" or die $!
}

sub pri {
    my $fh=shift;
    my $indent=shift;
    print $fh "    "x$indent, @_ or die $!
}

sub priln {
    my $fh=shift;
    my $indent=shift;
    print $fh "    "x$indent, @_,"\n" or die $!
}

sub jsquote {
    my ($str)=@_;
    $str=~ s/\\/\\\\/sg;
    $str=~ s/"/\\"/sg;
    $str=~ s/([\0-\x1f])/sprintf("\\u%04x", ord $1)/sge;
    qq{"$str"}
}

sub _print2json {
    @_==3 or die;
    my ($fh,$v,$indent)=@_;
    if (my $ref= ref $v) {
	if ($ref eq "HASH") {
	    prln $fh, "{";
	    my $indent2= $indent+1;
	    my @keys= sort keys %$v;
	    for (my $i=0; $i<@keys; $i++) {
		my $key= $keys[$i];
		pri $fh, $indent2, jsquote ($key),": ";
		_print2json ($fh, $$v{$key}, $indent2);
		prln $fh, ($i<$#keys) ? "," : "";
	    }
	    pri $fh, $indent, "}";
	} elsif ($ref eq "ARRAY") {
	    prln $fh, "[";
	    my $indent2= $indent+1;
	    for (my $i=0; $i<@$v; $i++) {
		pri $fh, $indent2;
		_print2json ($fh, $$v[$i], $indent2);
		prln $fh, (($i<$#$v) ? "," : "");
	    }
	    pri $fh, $indent, "]";
	} else {
	    die "unknown reference: $ref";
	}
    } else {
	pr $fh, defined $v ? jsquote($v) : "null";
    }
}

sub print2json {
    @_==2 or die;
    my ($fh,$v)=@_;
    _print2json ($fh,$v,0);
}

# ------------------------------------------------------------------
{
    package Chj::Format::JSON::Continuous;
    use Chj::Struct ["fh"];
    # and private "_not_first", and "_ended"
}

sub Chj::Format::JSON::Continuous::print {
    my $s=shift;
    @_==1 or die;
    my ($v)=@_;
    my $fh= $$s{fh};
    if ($$s{_not_first}) {
	prln $fh, ",";
    } else {
	prln $fh, "[";
	$$s{_not_first}=1;
    }
    pri $fh, 1;
    _print2json($$s{fh}, $v, 1);
}
sub Chj::Format::JSON::Continuous::end {
    my $s=shift;
    return if $$s{_ended};

    my $fh= $$s{fh};
    if ($$s{_not_first}) {
	prln $fh;
    } else {
	prln $fh, "[";
    }
    prln $fh, "]";
    $$s{_ended}=1;
}

{
    package Chj::Format::JSON::Continuous;
    *DESTROY=*end; # should call end explicitely, though
    _END_;
}
