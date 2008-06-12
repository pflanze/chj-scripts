

my %adresse = (
	       chris=> 'Christian Jaeger, christian at jaeger mine nu',
	      );


sub copy {
    my $adr= $adresse{$ENV{USER}} or die "Kenne Dich ($ENV{USER}) nicht. Bitte Christian sagen.\n";
    my $year= (localtime)[5]+1900;
    my $nameonly=$adr; $nameonly=~ s/,.*//s;
	"# ".localtime()."  ".$adr."\n".
	"#\n".
	"# Copyright $year by $nameonly\n".
	"# Published under the same terms as perl itself"
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

1;
