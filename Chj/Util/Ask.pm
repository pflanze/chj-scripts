# Fri, 19 Mar 2004 20:55:57 +0100  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by ethlife renovation project people
# Published under the terms of the GNU General Public License
#
# $Id$

=head1 NAME

Chj::Util::Ask

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::Util::Ask;
@ISA="Exporter"; require Exporter;
@EXPORT_OK= qw(
	       ask_string
	      );

use strict;
use Carp;

eval {
    require Term::ReadLine;
};
my $have_readline= !$@;

my $term; ##experimental: reuse history.  **dafür ev probleme mit offengehaltenen filehandles?**

sub ask_string {
    my ($promptbegin,$value)=@_;
    my $prompt=
      defined $promptbegin ?
	defined( $value)&&length($value) ? "$promptbegin ($value): "
	  : "$promptbegin: "
	    : "" ;#$value?
    my $ans= do {
	if ($have_readline) {
	    $term||= new Term::ReadLine "";
	    $term->ornaments(0);
	    $term->readline($prompt);
	} else {
	    local $|=1;
	    print $prompt;
	    <STDIN>;
	}
    };
    return unless defined $ans; # oder eine exception? does this warrant an exception?
    chomp $ans;
    if (!length $ans){
	return $value;# wenn das undef ist, gibts halt erneut undef.hmm.
    } else {
	return $ans;
    }
}
sub xask_string {
    my $res= &ask_string;
    return $res if defined $res;
    #require Chj::Exception
    # was will ich alles sagen? EOF, undefvalueexception, und einen eigenen text natürlich.
    # mehrtextigkeit in perl: sowohl sowieso im programmtext  immer wenn ich von programm aus was ausgebe   .
    # Ein Format für verschiedene Strings?
    # Ein Kontext für die Sprache? funktion oder variable? WELCHE Sprache erlaubt schon wieder ne seamless solche gleichgültigkeit? hey in perl was machen auf xs ebene?
    # oder na einfach "constants" die ev keine solchen sind.  geht aber nur global, nicht im kontext eines objektes; ebengerade weil sonst erst zu runtime ausführbar  (effizient Wert abholen isch etwas was perl auf var ebene kann ...)
}

1;
__END__
  "
chris@lombi chris > aptsearch perl i18n

libi18n-charset-perl - Perl module for mapping character set names to IANA names
libi18n-langtags-perl - Perl module for dealing with RFC3066-style language tags
libintl-perl - Uniforum message translations system compatible i18n library
libtext-wrapi18n-perl - internationalized substitute of Text::Wrap
perl-modules - Core Perl modules.
  ->provides libi18n-langtags-perl


chris@lombi chris > apropos i18n|grep 3p
1 *** 3 WARNING: starting from the Perl version 5.003_06 the I18N::Collate interface for comparing 8-bit scalar data according to the current locale 1 HAS BEEN DEPRECATED 4 That is (3perl) [I18N::Collate] - compare 8-bit scalar data according to the current locale
I18N::Collate (3perl) - compare 8-bit scalar data according to the current locale
I18N::LangTags (3pm) - functions for dealing with RFC3066-style language tags
 -> ok helferfunktionen immerhin dies:
	bei start:
                       $greetings{
                                   encode_language_tag($lang)
                                 } = $expr;
	dann:
                     $greetings{encode_language_tag($wanted)}


I18N::LangTags::List (3pm) - tags and names for human languages
I18N::LangTags::List *( (3pm) [I18N::LangTags::List] - tags and names for human languages
Psh::Locale::Base (3pm) - containing base code for I18N

                eval "use Psh::Locale::$lang";
                #
                # We are reading the locale data simply as perl modules
                # A better way would be to maybe use Locale::PGetText
                # but that would again increase the requirements for
                # psh unnecessarily
und dann, tut es funktionen oder vars in jenem namespace abrufen?
nah, tut hash füllen und den accessen  brr

eben, global, versus  local'ized,  versus per-thread und so   also OO oder so

***context*** programming


hey,
unix_received_strange_sig=Signal SIG%1 wurde empfangen - wird ignoriert
gute idee?, subs mit params.

also: texte auslagern?    och oder vergleiche exceptiontexte

nicht aufruf einer sub mit context  sondern  noch drunterdrüber  sub für textnehmen.

subs sind cool: compiletime mistype check, flexible, optionally importable.


Nun zu den Exceptions:



chris@lombi chris > aptsearch perl locale 
mailreader - Simple, but powerful WWW mail reader system
libdatetime-locale-perl - perl DateTime::Locale - Localization support for DateTime
liblocale-codes-perl - Perl modules for processing various ISO locale codes
liblocale-gettext-perl - Using libc functions for internationalization in Perl
liblocale-maketext-fuzzy-perl - Maketext from already interpolated strings
 This module is a subclass of Locale::Maketext, with additional
 support for localizing messages that already contains interpolated
 variables.  This is most useful when the messages are returned by
 external modules -- for example, to match "dir: command not found"
 against "[_1]: command not found".

liblocale-maketext-lexicon-perl - Lexicon-handling backends for "Locale::Maketext"
 This module provides lexicon-handling modules to read from other
 localization formats, such as Gettext, Msgcat, and so on.
 .
 It also provides lexicon-handling backends, for "Locale::Maketext"
 to read from other localization formats, such as PO files, MO files,
 or from databases via the "Tie" interface.

  -> he ja ha:  gettext PO und so zeug: machs doch wie die andern, englisch und dann die andern sprachen external. ja?

liblocale-maketext-perl - Perl module for supporting l10n and inheritance-based lexicons
 This module is a base class providing a framework for software
 localization and inheritance-based lexicons, as described in an
 article in The Perl Journal #13 (a corrected version of which appears
 in this package).
 .
 This is a complete rewrite from the basically undocumented 0.x
 versions.

  -> hey ja hee, inheritance für fallback mann logo  (well für data ned code aber das isch letzlich ja eben dasselbe ausser die effizienz)

liblocale-subcountry-perl - Perl modules for converting state, province etc names to/from code
libmsgcat-perl - Locale::Msgcat perl module
 This is Msgcat, a small perl module for systems which support the XPG4
 message catalog functions : catopen(3), catgets(3) and catclose(3).

libtime-piece-perl - Perl module for object oriented time objects
perl-modules - Core Perl modules.
sympa - Modern mailing list manager



_("funtext")


Also, 3 Wege:
- language() kontext abrufen und selber hierlokal was damit anfangen.
- einemessage() abrufen, die ist anderswo implementiert und verwendet langugae() oder so
- genericmessagehandler("einemessage") abrufen, ; vorteil: wenn keine translation wird einfach englisch genommen, also einfacher software zu schreiben damit. nachteil: nicht garantiert dass ne übersetzung da isch, also, wenn ich "einemessage" ändere isch connection broken; 'mistyping' isch also wieder möglich.  Texteverwaltungssoftware soll aber dabei helfen das zu merken und isch ja insofern gut dass es reicht englisch anzupassen und dannlazily die übersetzungen. statt bei einemessage() prinzip nur den englischen und die andern werden zwar gefunden sind aber falsch. nunwell, könnt immer noch auch da so n system machen das prüft ob alle angepasst - wär ev sogar besser.
#PS. in C könnte _("xx") ersetzt werden per makrooderso durch n lookup in ner table statt strings zu runtime matchen zu gehen. so a la  messages[currentlanguage][442]. über 3 pointers hab ich dann den string, ohne jeden function call!
#ob eine sprache sowas selber merken kann?
# Und in Perl?
# makros fehlen.  nix compiletime möglich daher.

#hmm perl noch schlimmer:  die bequeme einbettungs philosophie "hallo $blabla" geht nimmer. (sie ginge noch wenn sogar die sprachwahl zu compiletime festgelegt würde (was supereffizient wäre)). NA, zu runtime code für eine language specialized compilieren? (hmm, stringeval only?).  Alternativ: zu compiletime  _"fun $for you"  zerlegen in _("fun ").$for._(" you"). Tja...mein eigener compiler.   Nah eh schlecht dies, besser: zerlegen in sprintf(_('fun $1 you'),) ach, so: _('fun $1 you $2',$for,$na) was dann per sprintf mit %s und reordering der parameter etc aufgelöst werden kann.

bei exceptions isches doch doof, weil runtime overhead für jede exception die auch kein text ausgeben muss.
na, closures?!:
hab ich die echt noch nicht gehabt?

ACH das war doch eh immer so, logo: sOWIESO wird bei throw nur AUFGEZEICHNET nix stringifiziert  erst stringify tut params nehmen und message basteln draus. ok?

das heisst aber wirklich , die meldungen stehen in den exception klassen. eine meldung pro klasse.

das mit ethrow wird sinnlos  bitzli.

#bei speedbedarf kann ja immer noch zugunsten speed zuungunsten memory specialcompilation perlanguage gemacht werden  hehe




