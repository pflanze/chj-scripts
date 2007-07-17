# Wed Jun 11 19:24:31 2003  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2001 by ethlife renovation project people
# Published under the terms of the GNU General Public License
#
# $Id$

=head1 NAME

Chj::Filetype::Compressionrate::LZO

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Filetype::Compressionrate::LZO;
#@EXPORT_OK=qw(%Factors
use strict;

use Chj::Filetype -extend=> ();


our %compressionrate=  # compressed/uncompressed
  (
   # compressed:
   gz=> 1.037, # 3986060/3841293
   zip=>0.998, # 1542866/1545664
   lzo=>1,
   gif=>1.12, # 113057/100764
   jpg=>0.977, # 333161/340997
   jpeg=> 0.977,
   tgz=> 0.9995, # 71802432/71833893
   # not measured:
   png=> 1,
   mp3=> 1,

   # uncompressed:

   pdf=>0.668, # 2777216/4156934
   ps=> 0.5129, # 587196/1144803
   txt=>0.445, # 291613/653875
   html=>0.4229, # 234755/555089
   xml=>0.400, # 165627/413938
   xsl=>0.4,

   o=> 0.409, # 738359/1803787
   so=>0.485, # 1945622/4004907
   a=> 0.5119, # 3844431/7508922
   c=> 0.3987, # 555474/1393000
   h=>0.495, # 198584/401124

   log=>0.140, # 1756900/12531110
   sql=>0.381,  # 18987/49827  ## hmm nicht eben repräsentativ, waren alles kleine files
   iso=>0.887, # 172641822/194543616 ## kommt natürli aufs iso draufan
   rm=>0.987, # movie,  5251800/5316553

   # not measured:!
   cc=> 0.4,
   java=>0.4,
   pm=> 0.4,
   pl=> 0.4,
  );
# na, sollte halt ne statistik machen  ganzes fs durch nach suffix sortieren ..
# find  2>/dev/null |perl -wne 'if (/\w+\.(\w+)$/) { chomp; $tot{$1}+= (stat $_)[7]} END{ print map{"$_ => $tot{$_}\n"} sort { $tot{$a}<=>$tot{$b}} keys %tot}' |less


our $DEFAULTRATE = 0.7;

sub estimated_compressionrate {
    my $self=shift;
    my $rate=
      defined $$self[Suffix] ?
	$compressionrate{$$self[Suffix]}
	  : undef;
    defined $rate ? $rate : $DEFAULTRATE
}
sub compressionrate {
    my $self=shift;
    defined $$self[Suffix] ?
      $compressionrate{$$self[Suffix]} #||do{ warn "$$self[Suffix] has unknown compression rate"; undef}
	: do {
	    #warn "$$self[Path] has no suffix";
	    undef};
}

1;
__END__

  Heh, ethlife-a: find  2>/dev/null |perl -wne 'if (/\w+\.(\w+)$/) { chomp; $tot{$1}+= (stat $_)[7]} END{ print map{"$_ => $tot{$_}\n"} sort { $tot{$a}<=>$tot{$b}} keys %tot}' |less

...
jar => 26957979
mo => 27593823
antibot => 27752977
txt => 28809059
zip => 29223622
deb => 29336468
pm => 33714129
mov => 37337511
gtar => 39244121
Hqx => 43223947
exe => 43617592
a => 49337211
mp3 => 58695030
xml => 61258169
0 => 62644259   ----> hmmmmmm, muss ma ausklammern!
so => 73363464
sort => 73797315
o => 79956405
log => 134227354
h => 150203824
pdf => 179251196
rm => 191418597
iso => 194543616
sql => 246135884
tgz => 287464713
c => 389794656
html => 410891144
jpg => 500350908
jpeg => 800743452
gz => 979124618
