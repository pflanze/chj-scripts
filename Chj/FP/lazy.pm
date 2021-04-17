# Tue Apr 25 00:36:05 2006  Christian Jaeger, christian.jaeger@ethlife.ethz.ch
# 
# Copyright 2004 by Christian Jaeger
# Published under the same terms as perl itself
#
# $Id$

=head1 NAME

Chj::FP::lazy

=head1 SYNOPSIS

=head1 DESCRIPTION


=cut


package Chj::FP::lazy;
@ISA="Exporter"; require Exporter;
@EXPORT=qw(
	   Delay
	   Force
	   $EmptyList
	   Cons
	   StreamOfPort
	   StringOfStream
	   ListOfStream
	   LengthOfStream
	  );## hmm $EmptyList und so gehört doch in sep modul ?

use strict;

use Chj::FP::Promise;
use Chj::FP::Pair; # for $Chj::FP::EmptyList

sub Delay ( & ) {
    Chj::FP::Promise->new($_[0])
}

sub Force ( $ ) {
    $_[0]->force
}


## in sep lcmodul machen ?

#*EmptyList = *Chj::FP::EmptyList;
our $EmptyList = $Chj::FP::EmptyList;

sub Cons ( $ $ ) {
    Chj::FP::Pair->new(@_);
}


## stream library:  ev auch in anderes modul?

# (define (port->stream port)
#   (if (@port? port)
#       (let lp ()
# 	(delay/trace "port->stream"
# 		     (let ((ch (@read-char port)))
# 		       (if (@eof-object? ch) '()
# 			   (@cons ch
# 				  (lp))))))
#       (error* "port->stream: " "not a port:" port)))

sub StreamOfPort ( * ) {#lustig dass kein prototype too early kommt hier, shceint dass * generell enough ist?
    my ($port)=@_;
    Delay {
	my $ch;
	my $count= read $port,$ch,1;
	my $port2=$port; undef $port;#doch es half nicht.
	defined $count or die "StreamOfPort: error reading from $port: $!";#
	 ($count==0) ? #eof
	   $EmptyList
	     : Cons $ch, StreamOfPort($port2); # "t odo tail calls" ehr nein ist ja gar keiner.
    };
}


# (define (stream->string strm)
#   (let* ((len (stream-length-and-typecheck strm @char? error))
# 	 (str (@make-string len)))
#     (let iter ((strm strm)
# 	       (pos 0))
#       (if (##fixnum.>= pos len) str
# 	  (let ((p (stream-force strm)))
# 	    (if (##pair? p)
# 		(let ((ch (##car p)))
# 		  ;;(if (@char? ch)  not necessary anymore since stream-length-and-typecheck is used.
# 		  (begin
# 		    (@string-set! str pos ch)
# 		    (iter (##cdr p)
# 			  (##fixnum.+ pos 1))))
# 		(error "stream->string: assertion failed, not a pair:" p)))))))

sub StringOfStream ( $ ) {
    my ($strm)=@_;
    my $out="";
    while (1) {
	my $p= $strm->force;
	if (UNIVERSAL::isa($p,"Chj::FP::Pair")) {
	    my $ch= $p->car;
	    #[todo: typecheck for being a char?!]
	    $out.=$ch;
	    $strm= $p->cdr;#!!, vergass ich. jojo so ist das mit den super argumentlosen loops.
	} elsif ($p eq $EmptyList) {
	    return $out
	} else {
	    die "StringOfStream: not a pair: $p";
	}
    }
}


# (define (stream->list strm)
#   (let recur ((strm strm))
#     (let ((p (stream-force strm)))
#       (if (##null? p) '()
# 	  (if (##pair? p)
# 	      (@cons (##car p)
# 		     (recur (##cdr p)))
# 	      (error* "stream->list: " "improper stream:" p))))))

sub ListOfStream ( $ );
sub ListOfStream ( $ ) {
    my ($strm)=@_;
    my $p= $strm->force;
    ($p eq $EmptyList) ?
      $EmptyList
	: UNIVERSAL::isa($p,"Chj::FP::Pair") ?
	  Cons($p->car, ListOfStream($p->cdr))
# 	  do {
# 	      @_=($p->car, ListOfStream($p->cdr));
# 	      goto \&ListOfStream;
# 	  } ehr mensch, ist gar kein tail call !!!
	    : die "ListOfStream: improper stream: $p";
}

# (define (stream-length strm)
#   (let iter ((strm strm)
# 	     (len 0))
#     (let ((p (stream-force strm)))
#       (if (##null? p) len
# 	  (if (##pair? p)
# 	      (iter (##cdr p)
# 		    (##fixnum.+ len 1))
# 	      (error* "stream length: " "improper stream:" p))))))

sub LengthOfStream ( $ ) { #funny  feiner Name. "typisierter integer"
    my ($strm)=@_;
    my $len=0;
    while (1) {
	my $p= $strm->force;##ps, zusammenhang mit typcheck, uns fehlt die noop force methode in Pair Klasse noch. well in allen andern klassen als Promise klasse sollte es dann so eine haben.
	if (UNIVERSAL::isa($p,"Chj::FP::Pair")) {
	    $len++;
	    $strm= $p->cdr; ##hm ps da fehlt typcheck auf strm (oben schon)...
	} elsif ($p eq $EmptyList) {
	    return $len;
	} else {
	    die "LengthOfStream: improper stream: $p";
	}
    }
}


# (define (stream->list-take strm k)  ;; returns a list, not a stream.
#   (if (and (##fixnum? k) (##fixnum.>= k 0))
#       (if (##fixnum.= k 0)
#           '()
#           (or (and (##not (null-stream? strm))
#                    (let ((res (##cons (stream-car strm) '())))
#                      (let iter ((res-tail res)
#                                 (strm (stream-cdr strm))
#                                 (k (##fixnum.- k 1)))
#                        (if (##fixnum.zero? k) res
# 			   (let ((p (stream-force strm)))
# 			     (and (##pair? p)
# 				  (let ((res-next (##cons (##car p) '())))
# 				    (##set-cdr! res-tail res-next)
# 				    (iter res-next
# 					  (##cdr p)
# 					  (##fixnum.- k 1)))))))))
# 	      (error* "stream->list-take: " "stream too short")))
#       (error* "stream->list-take: k is " "not a positive fixnum:" k)))

# (define (stream-take strm k) ;; (returns a stream -- thus 'recursive')
#   (if (and (##fixnum? k) (##fixnum.>= k 0))
#       (let recur ((strm strm) (k k))
# 	(delay/trace "stream-take"
# 		     (if (##fixnum.= k 0)
# 			 '()
# 			 (let ((p (stream-force strm)))	;;;ps stream-force sollte dann ausgeben "in stream-take:..." (croak eben)(ahdasistjaso,inetwa)
# 			   (if (##pair? p)
# 			       (##cons (##car p)
# 				       (recur (##cdr p)
# 					      (##fixnum.- k 1)))
# 			       (if (##null? p)
# 				   '()
# 				   (error* "stream-take: " "improper stream:" p)))))))
#       (error* "stream-take: k is " "not a positive fixnum:" k)))

# (define (stream-drop strm k #!optional (error error))
#   (if (and (##fixnum? k) (##fixnum.>= k 0))
#       (let iter ((strm strm) (k k))
# 	(if (##fixnum.zero? k) strm
#             (let ((p (stream-force strm)))
#               (if (##pair? p)
#                   (iter (##cdr p)
#                         (##fixnum.- k 1))
#                   (error (error*-append "stream-drop: " "stream too short"))))))
#       (error (error*-append "stream-drop: k is " "not a positive fixnum:" ) k)))

# (define (stream-ref strm i)
#   (let ((p (stream-force (stream-drop strm i))))
#     (if (@pair? p)
# 	(@car p)
# 	(error "stream too short"))))


1
