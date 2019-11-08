# 
# Copyright 2004-2019 by Christian Jaeger, copying@christianjaeger.ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::Random::Formatted

=head1 SYNOPSIS

 random_hex_string(5); #=> 871378cf23
 random_passwd_string(5); #=> e5gs78y2
 # both are 40 bit internally.

=head1 DESCRIPTION


=cut


package Chj::Random::Formatted;
@ISA="Exporter"; require Exporter;
@EXPORT_OK=qw(
                 random_hex_string
                 random_u32
                 random_i32
                 random_digit
                 random_digits
                 random_digit_string
                 random_passwd_string
            );
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

# We'll be lazy and request fresh seeds for everything
use Chj::Random 'seed';

sub random_hex_string ($) {
    my $bin= &seed;
    unpack('H*',$bin)
}

sub random_u32 () {
    my $bin= seed(4);
    unpack('L*', $bin)
}

sub random_i32 () {
    my $bin= seed(4);
    unpack('l*', $bin)
}

sub random_digit() {
  LP: {
        my $n= ord(seed(1)) & 15;
        if ($n < 10) {
            return $n
        } else {
            redo LP;
        }
    }
}

sub random_digits($) {
    my ($n)= @_;
    wantarray or die "can only be used in list context";
    my @digits;
    for (1..$n) {
        push @digits, random_digit
    }
    @digits
}

sub random_digit_string($) {
    my ($len)= @_;
    join("", random_digits $len)
}


our @chars= ("a".."k","m","n","p".."z","2".."9"); # 32 chars
sub _binary2text {
    my ($b)=@_;
    # Shift 5 bits at a time.
    my $text="";
    use integer;
    for (my $bit=0; $bit< (length($b)*8-1); $bit+=5 ) {
	my $byte= $bit / 8;
	my $shift= $bit % 8;
	#warn "Bit $bit: Byteno=$byte, bitshift=$shift\n";
	my $I= unpack("v",substr($b,$byte,2))||ord(substr($b,$byte,1));
	#warn "I=$I; relevant part: ".(($I >> $shift) & 31)."\n";
	$text.= $chars[($I >> $shift) & 31];
    }
    $text
}

sub random_passwd_string ($) {
    my ($seedlength)=@_;
    my $bin= seed($seedlength);
    _binary2text($bin)
}


1
