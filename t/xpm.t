#!/usr/bin/perl -w

# $Id$

# Copyright (c) 2000 Mark Summerfield. All Rights Reserved.
# May be used/distributed under the GPL.


use strict ;

use vars qw( $Loaded $Count $DEBUG $TRIMWIDTH %File ) ;

BEGIN { 
    $| = 1 ; 
    my $count = 13 ;
    %File = (
        '/usr/lib/perl5/Tk/Camel.xpm'       => 1,
        '/usr/lib/perl5/Tk/ColorEdit.xpm'   => 1,
        '/usr/lib/perl5/Tk/act_folder.xpm'  => 1,
        '/usr/lib/perl5/Tk/file.xpm'        => 1,
        '/usr/lib/perl5/Tk/folder.xpm'      => 1,
        '/usr/lib/perl5/Tk/openfolder.xpm'  => 1,
        '/usr/lib/perl5/Tk/srcfile.xpm'     => 1,
        '/usr/lib/perl5/Tk/textfile.xpm'    => 1,
        '/usr/lib/perl5/Tk/winfolder.xpm'   => 1,
        '/usr/lib/perl5/Tk/wintext.xpm'     => 1,
        ) ;
    if( -e '/usr/lib/perl5/Tk' ) {
        foreach my $file ( keys %File ) {
            $count += $File{$file} = -r $file ? 1 : 0 ;
        }
    }
    print "1..$count\n" 
}
END   { print "not ok 1\n" unless $Loaded ; }

use Image::Xpm ;
$Loaded = 1 ;

$DEBUG = 1,  shift if @ARGV and $ARGV[0] eq '-d' ;
$TRIMWIDTH = @ARGV ? shift : 60 ;

report( "loaded module ", 0, '', __LINE__ ) ;

my( $i, $j, $k ) ;
my $fp = "/tmp/image-xpm" ;
 

eval {
    $i = Image::Xpm->new( -width => 4, -height => 5 ) ;
    for( my $x = 0 ; $x < 4 ; $x++ ) {
        for( my $y = 0 ; $y < 5 ; $y++ ) {
            $i->xy( $x, $y, sprintf "#%06x", $x * $y + 0xf000 * $y ) ;
        }
    }
    die "Failed to create image correctly"
    unless $i->get( -pixels ) eq '!!!!#(,0$)-1%*.2&+/3' ;
} ;
report( "new()", 0, $@, __LINE__ ) ;

eval {
    $j = $i->new ;
    die "Failed to create image correctly" unless
    $j->get( -pixels ) eq '!!!!#(,0$)-1%*.2&+/3' ;
} ;
report( "new()", 0, $@, __LINE__ ) ;

eval {
    $i->save( "$fp-test1.xbm" ) ;
    die "Failed to save image" unless -e "$fp-test1.xbm" ;
} ;
report( "save()", 0, $@, __LINE__ ) ;

eval {
    $i = undef ;
    die "Failed to destroy image" if defined $i ;
    $i = Image::Xpm->new( -file => "$fp-test1.xbm" ) ;
    die "Failed to load image correctly" 
    unless $i->get( -pixels ) eq '!!!!#(,0$)-1%*.2&+/3' ;
} ;
report( "load()", 0, $@, __LINE__ ) ;

eval {
    die unless $i->get( -file ) eq "$fp-test1.xbm" ;
} ;
report( "get()", 0, $@, __LINE__ ) ;

eval {
    die unless $i->get( -width ) == 4 ;
} ;
report( "get()", 0, $@, __LINE__ ) ;

eval {
    die unless $i->get( -height ) == 5 ;
} ;
report( "get()", 0, $@, __LINE__ ) ;

eval {
    die "xy(0,0) ne #000000" unless $i->xy( 0, 0 ) eq '#000000';
} ;
report( "xy() - get", 0, $@, __LINE__ ) ;

eval {
    die "xy(1,2) ne #01e002" unless $i->xy( 1, 2 ) eq '#01e002';
} ;
report( "xy() - get", 0, $@, __LINE__ ) ;

eval {
    die "xy(3,1) ne #00f003" unless $i->xy( 3, 1 ) eq '#00f003';
} ;
report( "xy() - get", 0, $@, __LINE__ ) ;

eval {
    die "xy(3,1,'violet') ne 4" unless $i->xy( 3, 1, 'violet' ) eq '4';
} ;
report( "xy() - set", 0, $@, __LINE__ ) ;



foreach my $file ( keys %File ) {
    next unless $File{$file} ;
    eval {
        $j = Image::Xpm->new( -file => $file ) ;
        my $pixels = $j->get( -pixels ) ;
        $file =~ s/\.xpm$/.test.xpm/o ;
        $file =~ s,.*/,/tmp/,o ;
        $j->save( $file ) ;
        $j->load ;
        die "Failed to new/save/load correctly" 
        unless $j->get( -pixels ) eq $pixels ;
        unlink $file ;
    } ;
    report( "new()", 0, $@, __LINE__ ) ;
}

# Tests for Image::Base

eval {
    my $q = $i->new_from_image( ref $i, -cpp => 2 ) ;
    my $pixels = $q->get( -pixels ) ;
    $pixels =~ s/ //go ;
    $pixels =~ s/0/4/go ; # One colour was in the palette but unused (overwritten)
    die unless $pixels eq $i->get( -pixels ) ;
} ;
report( "new_from_image", 0, $@, __LINE__ ) ;



unlink "$fp-test1.xbm" unless $DEBUG ;


sub report {
    my $test = shift ;
    my $flag = shift ;
    my $e    = shift ;
    my $line = shift ;

    ++$Count ;
    printf "[%03d~%04d] $test(): ", $Count, $line if $DEBUG ;

    if( $flag == 0 and not $e ) {
        print "ok $Count\n" ;
    }
    elsif( $flag == 0 and $e ) {
        $e =~ tr/\n/ / ;
        if( length $e > $TRIMWIDTH ) { $e = substr( $e, 0, $TRIMWIDTH ) . '...' } 
        print "not ok $Count" ;
        print " \a($e)" if $DEBUG ;
        print "\n" ;
    }
    elsif( $flag ==1 and not $e ) {
        print "not ok $Count" ;
        print " \a(error undetected)" if $DEBUG ;
        print "\n" ;
    }
    elsif( $flag ==1 and $e ) {
        $e =~ tr/\n/ / ;
        if( length $e > $TRIMWIDTH ) { $e = substr( $e, 0, $TRIMWIDTH ) . '...' } 
        print "ok $Count" ;
        print " ($e)" if $DEBUG ;
        print "\n" ;
    }
}


