package Filepaths;
use utf8;

# FILEPFADE-VERARBEITUNGSSYSTEM (Unabhängig von URI::URL)
# cj 20.9.98
# cj 10.4.00: AddURL so modifiziert, dass es undef liefert wenn 'underrun' auftritt
#			FolderOfThisFile korrigiert, so dass der Folder von 'file.xyz' wirklich '' wird
# cj 17.8.00: AddURL checked if it really works correctly, it does, one little exception, corrected: now 'return $base.$path_separator' if relurl is "".
#			Note: URLDiff is (still) not consitent yet! I should work out an exact interpretation scheme
# cj 17.8.00: Changed AddURL again to NEVER RETURN ENDING SLASHES.
# cj 2001/07/01: AddURL: Adding a '..' should mean the same as '../'. Attempt to strip /./.
# cj 2001/11/21 (militär): changed AddURL to accept a flag so "" && "some/path.html" gives "/some/path.html"  (yes hacky i know)
#							^-  SHOULD REALLY BE CLEANED UP
# cj 2001/11/21 (militär): URLDiff("/", "/samba.htm") and URLDiff("", "/samba.htm") gave both "/samba.html"

=head1 SYNOPSIS

 use Filepaths;	# (import everything)
 -or- 
 use Filepaths qw( AddURL URLDiff Filename FolderOfThisFile 
                   FilesInFolder FoldersInFolder
                   $Mac $Unix $Win $path_separator $path_separator2);
 # (for rest see below)

=head1 DESCRIPTION

These are routines to facilitate the work with file paths and directories
in a plattform independent way (unix, mac, windows) and make calculations
with relative URL adresses.

It's simpler and probably faster than LWP's URL modules. It works with 
pure strings, not with objects.

There are two types of path strings: 

a) paths of the local filesystem (either 
absolute or relativ to the current working directory). They are represented
just as in the file system of the current plattform.  
Folders are represented exactly as files, they don't have a trailing path separator
 - so pay attention to distinguish between folder and file paths yourself.

b) relative URL style paths (using '/' as separator)

Additionally the variables $Mac, $Unix, $Win are exported, which are true if
running under the respective system. The variable $path_separator contains the 
character that's used on the current system (you
may use it for $folder.$path_separator.$filename constructs).

Under windows, the path separator (backslashes) is interpreted as 
meta character in some places, so you have to
put '\\' rather than a single '\'. This is i.e. true for regular expression
patterns (if you don't put \Q and \E around the string). For such uses
there is also $path_separator2 which contains two path_separator's unter
windows and only one on the other systems.

=cut

#'
use Carp;

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw ( $Mac $Unix $Win $path_separator $path_separator2
				AddURL URLDiff Filename FolderOfThisFile 
				FilesInFolder FoldersInFolder );
@EXPORT_OK= qw/ $DEBUG/;

$DEBUG=0;
# ----------------------------------------
# Environment:

$Mac = ($^O=~/Mac/i);
$Win = ($^O=~/Win/i);
$Unix = (($^O=~/Unix/i) or ($^O=~/dec_os/i) or ($^O=~/linux/i)) ;	## Has eventually to be changed on other systems than Dec OS!
if ($Mac) {
	$path_separator = ":"; 
} elsif ($Win) {	
	$path_separator = "\\"; 
	$path_separator2 = "\\\\";
} elsif ($Unix ) {
	$path_separator = "/"; 
} else {
	die "This Operating System is unknown! You have to adapt the source code.\n"
}
$path_separator2 = $path_separator unless $path_separator2;


=head1 FUNCTIONS

=item $abs_filepath = AddURL ($abs_folderpath, $relURLpathtoadd); 

Adds a relative URL style path to a local filesystem style folder path.

=cut

sub AddURL
{
	my ($base, $add ,$flag_picky) = @_;

	unless (defined($add) and ($add ne "")) {
		carp "AddURL: relative URL is empty" if $DEBUG;
		return $base; ## return $base.$path_separator if you want (consistent) endslashes in case of empty filenames in addpath
	};
	if ($add=~ m|^\./?$|s) {
		carp "AddURL: relative URL is '$add'" if $DEBUG>1;
		return $base;
	}
	
	croak "AddURL: Relpath '$add' is absolute, not relative!" if $add=~ m|^/|s;
		# should we only carp and accept '/' as relative './'?  No probably no reason, usually '../' are in blocks for one up, if none up -> nothing, not '/'. (Take this as a rule)
	croak "AddURL: Basepath '$base' ends with '$path_separator'" if $base=~ m|$path_separator2$|o;

# Rather UGLY HACK 21.11.01:
if ($flag_picky and $base eq "") {
	$base="/"
}

	my $basebase='';
	if ($Unix) {
		$base=~ s|^/|| 
		and $basebase="/";
	} else {
		warn "AddURL: not yet fully adapted for this operating system";
		# Win: 'A:\'; Mac: ?
	}
	
	# remove ./ occurences
	while ($add=~ s|^\./||s) {};
	# correct uplinks so that they have a trailing / and thus are recognized by the following regex; the same with '.'
	$add.="/" if $add eq '..' or $add eq '.' or $add=~ m|/..?$|s;
	
	while ($add=~ m|^\.\.\/|) {
		substr $add,0,3,'';
		$base =~ s|$path_separator2?[^$path_separator2]+$||o or return undef;
	}
	
	$add =~ s|/|$path_separator|go unless $Unix;
	$base.=$path_separator if length($base) && length($add); ## comment out '&& length($add);' if you want ending slashes in case of empty filenames in addpath
#	print "\$basebase='$basebase', \$base='$base', \$add='$add'\n";
	my $total=$basebase.$base.$add;
	while ($total=~ s|/\./|/|s) {}; # repeat until no occurences
	$total=~ s|/+|/|sg;
	$total;
}


sub _samename
{ 
	if ($Unix) {
		# case sensitive
		return $_[0] eq $_[1];
	} else {
		# case insensitive on Mac and Windows
		return lc($_[0]) eq lc($_[1]);
	}
}


=item $relURLpath = URLDiff ( $base_folder, $target_file)

Calculates the relative difference (in URL style) between a (filesystem style)
base folder and a target file.

=cut

sub URLDiff
{
	my ($base,$file) = @_;
	my $out = "";
	
	my (@File) = split (m#$path_separator2#o, $file);
	my (@Base) = split (m#$path_separator2#o, $base);
	unless (@Base){  # Bugfix(?) from 2001/11/21. Half of the problem seems like coming from a perl inconsistency.
		push @Base,"" if $File[0] eq "";
	}
	my ($Base,$File);
	while (defined($Base=shift @Base) and defined($File=shift @File) and _samename($File ,$Base) ) {
		#debug:	print "Schritt... -> Base = $Base, File = $File\n";
	};
	
	if ($Base) {
		# Abbruch weil unterschiedlicher Folder
		my $Anzahlzurueck = @Base + 1;
		$out = "../"x$Anzahlzurueck; 
		if (defined($File)) {
			$out.= $File
		} else {
			# it's finished, nothing to go down again
			# so remove the slash at the end:
			chop $out;
			return $out;
		}
	}
	if (@File) {
		$out.="/" if $out; 
		$out.= join ("/", @File);
	}
	
	$out;
}

=item $folder_path = FolderOfThisFile ( $file_path )

Return the folder of a local file (simply cut off last part of file_path).

=cut

sub FolderOfThisFile
{
	croak "FolderOfThisFile: no file path given" unless my $file = shift;
	carp "FolderOfThisFile: File path ends with a '$path_separator'!" if $file=~ m#$path_separator2$#o;
	$file =~ s#$path_separator2[^$path_separator2]*$##o or $file='';
	$file;
}

=item $filename = Filename ( $file_path )

The contrary of FolderOfThisFile: returns the last part of file_path.

=cut

sub Filename
{
	my $file = shift;
	carp "FolderOfThisFile: File path ends with a '$path_separator'!" if $file=~ m#$path_separator2$#o;
	$file =~ m#$path_separator2?([^$path_separator2]*?)$#o;
	$1;
}


# -----------------------------------------------------------------------------

=item @filenames =  FilesInFolder ( $folder_path [, 'pattern'] );

Plattform independent (*) way to get a directory listing
[of files matching the pattern].
Returns a list of [matched] filenames (without path!). No folder names are
returned.
The pattern is a perl pattern string. Example: '(?i)\.html?$' lists only
HTML files.

*) on Unix (Dec) and Mac. (It doesnt use file globbing on the mac and doesn't
use readdir on the perl version available on the digital unix station I have access to, 
since they dont work correctly). NOTE: currently for each scan a process is forked, so
it will be quite slow! NOTE2: Files starting with a dot are ignored currently.

The pattern is really a string, not a qr// pattern. This is only because I didn't know
about the qr operator at the time I wrote the module.

=cut

sub FilesInFolder 	# In: path&Foldername [, pattern to be matched]; 
					# Out: List of filenames (without path!)
{
	_xInFolder (1, @_);
}


=item @foldernames =  FoldersInFolder ( $folder_path [, 'pattern'] );

The same as FilesInFolder, but returns list of folder names, not files.

=cut

sub FoldersInFolder
{
	_xInFolder (0, @_);
}


sub _xInFolder 
# called by FilesInFolder and FoldersInFolder;
# In: (1 for files | 0 for folders), path&Foldername [, pattern to be matched];
{	
	my $not = shift;
	my $folder = shift;
#	if (ref ($folder)) { $folder = $folder->local_path };
	unless ($folder) {
		if ($mac) {
			$folder = "." 
		} else {
			$folder = "." ; # WinNT and Unix
		}
	}

	my $pattern = shift;
	my @files;

	if ($Mac) {		##??? neu funktionnierts doch wieder für dec?? #nee doch nicht, zeigt nur ORDNER an??!
		# ($Mac or $Win) würd auch gehen, ausser dass wegen Win dann noch "." und ".." dirs rausgefiltert werden müssten
		unless (opendir DIR, $folder) { warn "Filepaths: Did not find folder '$folder'!\n"; return };
	
		while (defined ($filename = readdir DIR )) {
			push (@files, "$filename") if (($not xor -d "$folder$path_separator$filename")
					and (not defined $pattern or $filename=~ /$pattern/));
		}
		closedir DIR;

	} else {	# for MSWindows here's defined a second way (perhaps useful on some systems..)
		my @files1;
		if (-d $folder) {
			if ($Win) {
				@files1 = `dir /b $folder`;	##xxx how to detect errors?
			} elsif ($Unix) {
				@files1 = `ls $folder`;		##xxx how to detect errors?
			} else {
				die "Not implemented for this OS"
			}
		
			foreach $filename (@files1) {
				chomp $filename;
				push (@files, "$filename") if (($not xor -d "$folder$path_separator$filename") 
						and (not defined $pattern or $filename=~ /$pattern/));
			}
		} else { 
			warn "Filepaths Dir: '$folder' does not exist or is not a folder!\n";
		}
	}

	return @files;
}

=back

=head1 BUGS

Sure. 

 - at least URLDiff is not really consistent with handling folder vs. file cases.
   There will be cases when using the output in other calculations 
   where the folder vs. file inconsistencies lead to wrong results.
   There should be some scheme for this, but it's complicated.
   (How to say if something is a folder or not if you can't test it?
   When does it matter?->not fully thought out)
   
   (An ending slash should only appended to outputs, if these are expected
   to deliver files. (So these represent a special case of empty *file*names).)
   (Hmmm, NO, should probably NEVER return ending slashes.?)

 - The variables Mac,Win,Unix should be constants. (Now it's a bit too late for myself..)

=head1 AUTHOR

Christian Jaeger ( jaeger@sl.ethz.ch ).
This program is free software; you can redistribute it 
and/or modify it under the same terms as perl itself.

=cut

# Other addresses: pflanze@gmx.ch; Christian Jaeger, Burgstr. 26, CH-8037 Zürich

__END__

#  for Testsuite: see file "TestFilepaths.pl"

alternative systemsettingstuff, from CGI.pm
# ----------------------------------------
# FIGURE OUT THE OS WE'RE RUNNING UNDER
# Some systems support the $^O variable.  If not
# available then require() the Config library
unless ($OS) {
    unless ($OS = $^O) {
	require Config;
	$OS = $Config::Config{'osname'};
    }
}
if ($OS=~/Win/i) {
    $OS = 'WINDOWS';
} elsif ($OS=~/vms/i) {
    $OS = 'VMS';
} elsif ($OS=~/Mac/i) {
    $OS = 'MACINTOSH';
} elsif ($OS=~/os2/i) {
    $OS = 'OS2';
} else {
    $OS = 'UNIX';
}

# The path separator is a slash, backslash or semicolon, depending on the paltform.
$SL = {
    UNIX=>'/',
    OS2=>'\\',
    WINDOWS=>'\\',
    MACINTOSH=>':',
    VMS=>'\\'
    }->{$OS};
