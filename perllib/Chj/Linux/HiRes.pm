#
# Copyright 2014 by Christian Jaeger, ch at christianjaeger ch
# Published under the same terms as perl itself
#

=head1 NAME

Chj::Linux::HiRes

=head1 SYNOPSIS

 use Chj::Linux::HiRes 'lstat';
 lstat(...)

=head1 DESCRIPTION

 Same as core lstat except returning times as floating point strings
 (just like Time::HiRes' stat is a replacement for core stat).

 See also:
 http://stackoverflow.com/questions/2470465/how-can-i-get-the-high-res-mtime-for-a-symbolic-link-in-perl

=cut


package Chj::Linux::HiRes;
@ISA="Exporter"; require Exporter;
@EXPORT=qw();
@EXPORT_OK=qw(lstat);
%EXPORT_TAGS=(all=>[@EXPORT,@EXPORT_OK]);

use strict;

use Inline C => <<'EOC';

#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

#define STATRET_iv(i,field) av_store(res, i, newSViv(st.st_ ## field))
#define STATRET_uv(i,field) av_store(res, i, newSVuv(st.st_ ## field))
#define STATRET(i,expr) av_store(res, i, expr)

/* Time::HiRes::stat returns strings, not floats, so let's do
   the same here. Oddly, Time::HiRes::stat returns the string
   rounded to the width of floating point numbers, how  come?
   Just ignoring that difference for now, really.
*/
#define STATRET_TM(i, field) \
  STATRET(i, newSVpvf("%ld.%09ld", st.st_##field.tv_sec, st.st_##field.tv_nsec));


SV* hires_lstat(char* fname)
{
    Inline_Stack_Vars;
    struct stat st;
    if (-1 == lstat(fname, &st))
        return &PL_sv_undef;
    {
        AV* res= newAV();
        av_extend(res, 13);
        STATRET_uv( 0,dev);
        STATRET_uv( 1,ino);
        STATRET_uv( 2,mode);
        STATRET_uv( 3,nlink);
        STATRET_uv( 4,uid);
        STATRET_uv( 5,gid);
        STATRET_uv( 6,rdev);
        STATRET_uv( 7,size);
        STATRET_TM( 8, atim);
        STATRET_TM( 9, mtim);
        STATRET_TM(10, ctim);
        STATRET_uv(11,blksize);
        STATRET_uv(12,blocks);
        return newRV_noinc(res);
    }
}
EOC

sub lstat ($) {
    my ($path)=@_;
    my $res= hires_lstat($path);
    (defined $res) ? (wantarray ? @$res : 1 ) : ()
}

1
