package Image::Xpm ;    # Documented at the __END__

# $Id: Xpm.pm,v 1.6 2000/05/03 19:03:39 root Exp root $

use strict ;

use vars qw( $VERSION ) ;
$VERSION = '1.00' ;

use Carp qw( carp croak ) ;
use Symbol () ;

### Data structures
#
# We will call the characters that are used to signify a particular colour the
# cc's.
#
# -palette is a hash keyed by the cc's whose values are hashes of palette
# colours, e.g. key x colour pairs. 
#
# -cindex hash is a hash keyed by colour name ('#ffffff', 'blue' etc) whose
# values are the cc's in the palette that represent that colour. Note that the
# colour names are all lowercased even if they are mixed case in the palette
# itself.
#
# -pixels is a string of cc's which is effectively a vector of 8, 16, 24, 32
# bits, etc. 
#
# -extlines are lines of text used for any extensions; if we read any in we
# hold them with the image and write them out if the image is saved, but we do
# not process them.


# Private class data 

# If you inherit don't clobber these fields!
my @FIELD = qw( -file -width -height -ncolours -cpp -hotx -hoty -cc
                -palette -cindex -pixels 
                -extname -extlines -comments -commentpixel -commentcolour ) ;

use readonly
        # States for parsing an xpm file
        '$STATE_START'      => 0,
        '$STATE_IN_COMMENT' => 1,
        '$STATE_ARRAY'      => 2,
        '$STATE_VALUES'     => 3,
        '$STATE_COLOURS'    => 4,
        '$STATE_PIXELS'     => 5,
        '$STATE_EXTENSIONS' => 6,
        '$STATE_FINISH'     => 7,
        ;

### Private methods
#
# _get          object
# _set          object
# _nextcc       object
# _add_colour   object
# _add_color    object

sub _get { # Object method
    my $self  = shift ;
#    my $class = ref( $self ) || $self ;
   
    $self->{shift()} ;
}


sub _set { # Object method
    my $self  = shift ;
#    my $class = ref( $self ) || $self ;
    
    my $field = shift ;

    $self->{$field} = shift ;
}


sub _nextcc { # Object method
    my $self  = shift ;
#    my $class = ref( $self ) || $self ;

    while( exists $self->{-palette}{$self->{-cc}} ) {
        my @ch    = unpack "C$self->{-cpp}", $self->{-cc} ;
        my $found = 0 ;
        foreach my $i ( reverse 0..$self->{-cpp} - 1 ) {
            if( $ch[$i] < 255 ) {
                $ch[$i]++ ;
                $ch[$i]++ # Skip BS, \, ' and " -- using magic nums for speed
                while $ch[$i] == 127 or $ch[$i] == 92 or
                      $ch[$i] ==  39 or $ch[$i] == 34 ;
                $found++ ;
                last ; # Finish as soon as we've incremented something
            }
            else {
                $ch[$i] = 32 ; # Skip control chars
            }
        }
        croak "_nextcc() ran out of palette characters" unless $found ;
        $self->{-cc} = pack "C$self->{-cpp}", @ch ;
    }    

    croak "_nextcc() cpp is too small" 
    if length( $self->{-cc} ) > $self->{-cpp} ;

    $self->{-cc} ;
}


*_add_color = \&_add_colour ;

sub _add_colour { # Object method
    my $self     = shift ;
#    my $class    = ref( $self ) || $self ;
    my $colour   = shift ;
    my $lccolour = lc $colour ;

    return $self->{-cindex}{$lccolour} if exists $self->{-cindex}{$lccolour} ;

    $self->{-cc} = $self->_nextcc if exists $self->{-palette}{$self->{-cc}} ;
    $self->{-palette}{$self->{-cc}} = { c => $colour } ;
    $self->{-cindex}{$lccolour}     = $self->{-cc} ;
    $self->{-ncolours}++ ;

    $self->{-cc} ;
}



sub DESTROY {
    ; # Save's time
}


### Public methods


sub new { # Class and object method
    my $self  = shift ;
    my $class = ref( $self ) || $self ;
    my $obj   = ref $self ? $self : undef ; 
    my %arg   = @_ ;

    # Defaults
    $self = {
            '-hotx'          => -1, # This is used to signify unset
            '-hoty'          => -1, # This is used to signify unset
            '-cpp'           => 1,
            '-palette'       => {},
            '-cindex'        => {},
            '-pixels'        => '',
            '-comments'      => [],
            '-commentpixel'  => '', # Typically /* pixels */
            '-commentcolour' => '', # Typically /* colors */
            '-extlines'      => [],
        } ;

    bless $self, $class ;

    # If $obj->new copy original object's data
    if( defined $obj ) {
        foreach my $field ( @FIELD ) {
            $self->_set( $field, $obj->_get( $field ) ) ;
        }
    }

    # Any options specified override
    foreach my $field ( @FIELD ) {
        $self->_set( $field, $arg{$field} ) if defined $arg{$field} ;
    }

    $self->{-cc} = ' ' x $self->{-cpp} ;

    $self->load if $self->get( '-file' ) and not $self->{-pixels} ;

    foreach my $field ( qw( -width -height -cpp ) ) {
        croak "new() $field must be set" unless defined $self->get( $field ) ;
    }

    if( not $self->{-pixels} ) {
        $self->{-pixels} = ' ' x 
            ( $self->{-width} * $self->{-height} * $self->{-cpp} ) ;
        $self->_add_colour( 'white' ) ;
    }

    $self ;
}


sub get { # Object method 
    my $self  = shift ;
#    my $class = ref( $self ) || $self ;
  
    my @result ;

    push @result, $self->_get( shift() ) while @_ ;

    wantarray ? @result : shift @result ;
}


sub set { # Object method 
    my $self  = shift ;
#    my $class = ref( $self ) || $self ;
    
    while( @_ ) {
        my $field = shift ;
        my $val   = shift ;

        carp "set() -field has no value" unless defined $val ;
        carp "set() $field is read-only"
        if $field =~ 
            /^-(?:cpp|comments|cindex|ncolours|palette|pixels|
                  width|height|ext(?:name|lines))/ox ;
        carp "set() -hotx `$val' is out of range" 
        if $field eq '-hotx' and ( $val < -1 or $val >= $self->get( '-width' ) ) ;
        carp "set() -hoty `$val' is out of range" 
        if $field eq '-hoty' and ( $val < -1 or $val >= $self->get( '-height' ) ) ;

        $self->_set( $field, $val ) ;
    }
}


sub xy { # Object method
    my $self  = shift ;
#    my $class = ref( $self ) || $self ;

    my( $x, $y, $colour ) = @_ ; 

    # xy() is common so we can't afford the expense of method calls
    substr( $self->{-pixels}, 
        ( $y * $self->{-width} * $self->{-cpp} ) + ( $x * $self->{-cpp} ), 
        $self->{-cpp} ) = 
            $self->{-cindex}{lc $colour} || $self->_add_colour( $colour ) ;
}


sub vec { # Object method
    my $self  = shift ;
#    my $class = ref( $self ) || $self ;

    my( $offset, $colour ) = @_ ; 

    substr( $self->{-pixels}, $offset, $self->{-cpp} ) = 
        $self->{-cindex}{lc $colour} || $self->_add_colour( $colour ) ;
}


*rgb2color = \&rgb2colour ;

sub rgb2colour { # Class or object method
    my $self   = shift ;
#    my $class  = ref( $self ) || $self ;

    sprintf "#%02x%02x%02x", @_ ;
}


*add_colors = \&add_colours ;

sub add_colours { # Object method
    my $self   = shift ;
#    my $class  = ref( $self ) || $self ;

    $self->_add_colour( shift @_ ) while @_ ;
}


*del_color = \&del_colour ;

sub del_colour { # Object method
    my $self   = shift ;
#    my $class  = ref( $self ) || $self ;
    my $colour = lc shift ;

    my $cc = $self->{-cindex}{$colour} ;
    return undef unless defined $cc ; # Colour isn't there to delete

    my $cpp = $self->get( -cpp ) ;

    for( my $i = 0 ; $i < length( $self->{-pixels} ) / $cpp ; $i += $cpp ) {
        return 0 if substr( $self->{-pixels}, $i, $cpp ) eq $cc ;
    }

    delete $self->{-palette}{$cc} ;
    delete $self->{-colours}{$colour} ;
    $self->{-ncolours}-- ;

    1 ;
}


sub load { # Object method
    my $self  = shift ;
#    my $class = ref( $self ) || $self ;

    my $file  = shift() || $self->get( '-file' ) ;

    croak "load() no file specified" unless $file ;

    $self->set( '-file', $file ) ;

    my( $width, $height, $ncolours, $cpp, $hotx, $hoty, $extname ) ;
    my $next_state = $STATE_START ;
    my $state      = $STATE_START ;
    my $err        = "load() file `$file' " ;
    my %palette ;
    my $i ;
    local $_ ;
    my $fh = Symbol::gensym ;

    open $fh, $file or croak "load() failed to open `$file': $!" ;

    LINE:
    while( <$fh> ) {
        # Blank lines
        next LINE if /^\s*$/o ; 
        # Starting comment
        if( $state == $STATE_START ) {
            croak "$err does not begin with /* XPM */"
            unless m,/\*\s*XPM\s*\*/,o ;
            $state = $STATE_ARRAY ;
            next LINE ;
        }
        # Comment only lines 
        if( m,^(\s*/\*.*\*/\s*)$,o ) { 
            my $comment = $1 ;
            if( $comment =~ m,^\s*/\*\s*colou?rs?\s*\*/\s*$,o ) {
                $self->set( -commentcolour, $comment ) ;
            }
            elsif( $comment =~ m,^\s*/\*\s*pixels?\s*\*/\s*$,o ) {
                $self->set( -commentpixel, $comment ) ;
            }
            else {
                push @{$self->{-comments}}, $comment ;
            }
            next LINE ;
        }
        # Start of multi-line comment
        if( $state != $STATE_IN_COMMENT and m,^\s*/\*,o ) { 
            push @{$self->{-comments}}, $_ ;
            $next_state = $state ; # Remember the state we're due for
            $state      = $STATE_IN_COMMENT ;
            next LINE ;
        }
        # End of multi-line comment    
        if( $state == $STATE_IN_COMMENT ) {
            push @{$self->{-comments}}, $_ ;
            $state = $next_state if m,\*/,o ; 
            next LINE ;
        }
        # Name of C string
        if( $state == $STATE_ARRAY ) {
            croak "$err does not have a proper C array name"
            unless /static\s+char\s+\*\s*\w+\[\s*\]\s*=\s*\{/o ; #}
            $state = $STATE_VALUES ;
            next LINE ;
        }
        # Values line
        if( $state == $STATE_VALUES ) {
            ( $width, $height, $ncolours, $cpp, $hotx, $hoty, $extname ) =
            /"\s*(\d+)\s+(\d+)\s+(\d+)\s+(\d+)
                 (?:\s+(\d+)\s+(\d+))?(?:\s+(\w+))?\s*"/ox ;
            croak "$err missing width"            unless defined $width ;
            croak "$err missing height"           unless defined $height ;
            croak "$err missing ncolours"         unless defined $ncolours ;
            croak "$err missing cpp"              unless defined $cpp ;
            croak "$err zero width is invalid"    if $width    == 0 ;
            croak "$err zero height is invalid"   if $height   == 0 ;
            croak "$err zero ncolours is invalid" if $ncolours == 0 ;
            croak "$err zero cpp is invalid"      if $cpp      == 0 ;
            if( ( defined $hotx and not defined $hoty ) or
                ( defined $hotx and $hotx >= $width   ) or
                ( defined $hoty and $hoty >= $height  ) ) {
                carp "$err deleted invalid hotspot" ;
                $hotx = $hoty = -1 ;
            }
            $hotx = $hoty = -1 unless defined $hotx  ;
            carp "$err unusually large cpp `$cpp'" if $cpp > 4 ;
            $i     = 0 ;
            $state = $STATE_COLOURS ;
            next LINE ;
        }
        # Colour palette
        if( $state == $STATE_COLOURS ) {
            /"(.{$cpp})/o ; #"
            my $cc   = $1 ;
            my %pair = /\s+(m|s|g4|g|c)\s+(#[A-Fa-f\d]{3,}|\w+)/go ;
            $self->{-cindex}{lc $pair{'c'}} = $cc if exists $pair{'c'} ;
            $self->{-palette}{$cc} = { %pair } ;
            $i++ ;
            croak "$err palette larger than ncolors" if $i > $ncolours ;
            if( $i == $ncolours ) {
                $i = 0 ;
                $state = $STATE_PIXELS ;
            }
            next LINE ;
        }
        # Pixels
        if( $state == $STATE_PIXELS ) {
            /^\s*"(.*)"/o ;
            $self->{-pixels} .= $1 ;
            $i++ ;
            croak "$err more pixels than height indicates" if $i > $height ;
            $state = defined $extname ? $STATE_EXTENSIONS : $STATE_FINISH
            if $i == $height ;
            next LINE ;
        }
        # Extensions
        if( $state == $STATE_EXTENSIONS ) {
            if( /XPMENDEXT/o ) {
                $state = $STATE_FINISH ;
            }
            else {
                push @{$self->{-extlines}}, $_ ;
            }
            next LINE ;
        }
        # Finish
        if( $state == $STATE_FINISH ) {
            croak "$err invalid ending" unless /\}\s*;/ ;
            last LINE ;
        }
    }

    close $fh or croak "load() failed to close `$file': $!" ;

    $self->_set( -cpp      => $cpp ) ;
    $self->_set( -width    => $width ) ;
    $self->_set( -height   => $height ) ;
    $self->_set( -ncolours => $ncolours ) ;
    $self->_set( -extname  => $extname ) ;

    $self->set( -hotx => $hotx, -hoty => $hoty ) ;
}


sub save { # Object method
    my $self  = shift ;
#    my $class = ref( $self ) || $self ;

    my $file   = shift() || $self->get( '-file' ) ;

    croak "save() no file specified" unless $file ;

    $self->set( '-file', $file ) ;

    my( $width, $height, $cpp ) = $self->get( '-width', '-height', '-cpp' ) ;

    my $fh = Symbol::gensym ;
    open $fh, ">$file" or croak "save() failed to open `$file': $!" ;

    $file =~ s,^.*/,,o ;            
    $file =~ s/\.xpm$//o ;         
    $file =~ tr/[-_A-Za-z0-9]/_/c ;

    print $fh "/* XPM */\nstatic char *", $file, "[] = {\n" ; 
    print $fh @{$self->get( -comments )} ;
    print $fh qq{"$width $height }, $self->get( -ncolours ), " $cpp " ; #"
    print $fh $self->get( -hotx ), " ", $self->get( -hoty ), " "
    if $self->get( -hotx ) > -1 ;
    print $fh $self->get( -extname ) if defined $self->get( -extname ) ;
    print $fh qq{",\n}, $self->get( -commentcolour ) ; #"

    while( my( $cc, $pairs ) = each ( %{$self->{-palette}} ) ) {
        print $fh qq{"$cc } ; #"
        foreach my $key ( sort keys %{$pairs} ) {
            print $fh "$key $pairs->{$key} " ;
        }
        print $fh qq{",\n} ; #"
    }

    print $fh $self->get( -commentpixel ) ;

    for( my $y = 0 ; $y < $height ; $y++ ) {
        print $fh 
            '"', 
            substr( $self->{-pixels}, $y * $width * $cpp, $width * $cpp ),
            qq{",\n} ; #"
    }

    print $fh @{$self->get( -extlines )}, "} ;\n" ;

    close $fh or croak "save() failed to close `$file': $!" ;
}


1 ;


__END__

=head1 NAME

Image::Xpm - Load, create, manipulate and save xpm image files.

=head1 SYNOPSIS

    use Image::Xpm ;

    my $j = Image::Xpm->new( -file, 'Camel.xpm' ) ;

    my $i = Image::Xpm->new( -width => 10, -height => 16 ) ;

    my $h = $i->new ; # Copy of $i

    $i->xy( 5, 8, 'red' ) ;       # Set a colour (& add to palette if necessary)
    print $i->xy( 9, 3 ) ;        # Get a colour

    $i->xy( 120, 130, '#1256DD' ) ;
    $i->xy( 120, 130, $i->rgb2colour( 66, 0x4D, 31 ) ) ;

    $i->vec( 24, '#808080' ) ;    # Set a colour using a vector offset
    print $i->vec( 24 ) ;         # Get a colour using a vector offset

    print $i->get( -width ) ;     # Get and set object attributes
    $i->set( -height, 15 ) ;

    $i->load( 'test.xpm' ) ;
    $i->save ;

    # Changing just the palette
    $i->add_colours( qw( red green blue #123456 #C0C0C0 ) ) ;
    $i->del_colour( 'blue' ) ;

=head1 DESCRIPTION

=head2 new()

    my $i = Image::Xpm->new( -file => 'test.xpm' ) ;
    my $j = Image::Xpm->new( -width => 12, -height => 18 ) ;
    my $k = $i->new ;

We can create a new xpm image by reading in a file, or by creating an image
from scratch (all the pixels are white by default), or by copying an image
object that we created earlier.

If we set C<-file> then all the other arguments are ignored (since they're
taken from the file). If we don't specify a file, C<-width> and C<-height> are
mandatory and C<-cpp> will default to 1 unless specified otherwise.

Note that if you are creating an image from scratch you should not set
C<-file> when you call C<new>; you should either C<set> it later or simply
include the filename in any call to C<save> which will set it for you.

=over

=item C<-file>

The name of the file to read when creating the image. May contain a full path.
This is also the default name used for C<load>ing and C<save>ing, though it
can be overridden when you load or save.

=item C<-width>

The width of the image; taken from the file or set when the object is created;
read-only.

=item C<-height>

The height of the image; taken from the file or set when the object is created;
read-only.

=item C<-cpp>

Characters per pixel. Commonly 1 or 2, default is 1 for images created by the
module; read-only.

If we wanted to change an image's -cpp we could do this: 

    my $orig = Image::Xpm( -file => 'orig.xpm' ) ;
    # $orig is assumed to have -cpp != 2.
    my $new  = Image::Xpm(
                -width  => $orig->get( -width ),
                -height => $orig->get( -height ),
                -cpp    => 2,
                ) ;
    for( my $x = 0 ; $x < $orig->get( -width ) ; $x++ ) {
        for( my $y = 0 ; $y < $orig->get( -height ) ; $y++ ) {
            $new->xy( $x, $y, $orig->xy( $x, $y ) ) ;
        }
    }
    $new->save( 'orig2cpp.xpm' ) ;

Note that it is possible to change from a higher -cpp to a lower -cpp,
providing there are enough possible character combinations to represent the
palette (which may be the case as often the palette contains more colours than
are actually used).

=item C<-hotx>

The x-coord of the image's hotspot; taken from the file or set when the object
is created. Set to -1 if there is no hotspot.

=item C<-hoty>

The y-coord of the image's hotspot; taken from the file or set when the object
is created. Set to -1 if there is no hotspot.

=item C<-ncolours>

The number of unique colours in the palette. The image may not be using all
of them; read-only.

=item C<-cindex>

An hash whose keys are colour names, e.g. '#123456' or 'blue' and whose values
are the palette names, e.g. ' ', '#', etc; read-only. If you want to add more
colours to the image itself simply write pixels with the new colours using
C<xy>; if you want to add more colours to the palette without necessarily
using them in the image use C<add_colours>.

=item C<-palette>

A hash whose keys are the palette names, e.g. ' ', '#', etc. and whose values
are hashes of colour type x colour name pairs, e.g. C<c =E<gt> red>, etc;
read-only. If you want to add more colours to the image itself simply write
pixels with the new colours using C<xy>; if you want to add more colours to
the palette without necessarily using them in the image use C<add_colours>.

=item C<-pixels>

A string of palette names which constitutes the data for the image itself;
read-only.

=item C<-extname>

The name of the extension text if any; commonly XPMEXT; read-only.

=item C<-extlines>

The lines of text of any extensions; read-only.

=item C<-comments>

An array (possibly empty) of comment lines that were in a file that was read
in; they will be written out although we make no guarantee regarding their
placement; read-only.

=back

=head2 get()
    
    my $width = $i->get( -width ) ;
    my( $hotx, $hoty ) = $i->get( -hotx, -hoty ) ;

Get any of the object's attributes. Multiple attributes may be requested in a
single call.

See C<xy> and C<vec> to get/set colours of the image itself.

=head2 set()

    $i->set( -hotx => 120, -hoty => 32 ) ;

Set any of the object's attributes. Multiple attributes may be set in a single
call; some attributes are read-only.

See C<xy> and C<vec> to get/set colours of the image itself.

=head2 xy()

    $i->xy( 4, 11, '#123454' ) ;    # Set the colour at point 4,11
    my $v = $i->xy( 9, 17 ) ;       # Get the colour at point 9,17

Get/set colours using x, y coordinates; coordinates start at 0. If the colour
does not exist in the palette it will be added automatically.

=head2 vec()

    $i->vec( 43, 0 ) ;      # Unset the bit at offset 43
    my $v = $i->vec( 87 ) ; # Get the bit at offset 87

Get/set bits using vector offsets; offsets start at 0. The offset of a pixel
is ( ( y * width * cpp ) + ( x * cpp ) ).

=head2 rgb2colour() and rgb2color()
    
    $i->rgb2colour( 0xff, 0x40, 0x80 ) ;    # Returns #ff4080
    Image::Xpm->rgb2colour( 10, 20, 30 ) ;  # Returns #0a141e

Convenience class or object methods which accept three integers and return a
colour name string.

=head2 load()

    $i->load ;
    $i->load( 'test.xpm' ) ;

Load the image whose name is given, or if none is given load the image whose
name is in the C<-file> attribute.

=head2 save()

    $i->save ;
    $i->save( 'test.xpm' ) ;

Save the image using the name given, or if none is given save the image using
the name in the C<-file> attribute. The image is saved in xpm format.

=head2 add_colours() and add_colors()

    $i->add_colours( qw( #C0C0DD red blue #123456 ) ) ;

These are for adding colours to the palette; you don't need to use them to set
a pixel's colour - use C<xy> for that.

Add one or more colour names either as hex strings or as literal colour names.
These are always added as type 'c' colours; duplicates are ignored.

NB If you just want to set some pixels in colours that may not be in the
palette, simply do so using C<xy> since new colours are added automatically.

=head2 del_colour() and del_color()

    $i->del_colour( 'green' ) ;

Delete a colour from the palette; returns undef if the colour isn't in the
palette, false (0) if the colour is in the palette but also in the image, or
true (1) if the colour has been deleted (i.e. it was in the palette but not in
use in the image).

=head1 EXAMPLE

We do not provide any graphical transformations; you are expected to inherit
or aggregate the relevant classes and provide your own. Below is an example of
copying an image from xbm format to xpm:

    use Image::Xbm ;
    use Image::Xpm ;

    my $orig = Image::Xbm->new( -file => 'orig.xbm' ) ;
    my $new  = Image::Xpm->new( 
                -width  => $orig->get( -width ), 
                -height => $orig->get( -height ), 
                ) ;
    my( $setcolour, $unsetcolour ) = qw( black white ) ;

    for( my $x = 0 ; $x < $orig->get( -width ) ; $x++ ) {
        for( my $y = 0 ; $y < $orig->get( -height ) ; $y++ ) {
            $new->xy( $x, $y, $orig->xy( $x, $y ) ? $setcolour : $unsetcolour ) ;
        }
    }

    $new->save( 'new.xpm' ) ;


=head1 CHANGES

2000/05/03 

Created. 

=head1 AUTHOR

Mark Summerfield. I can be contacted as <summer@perlpress.com> -
please include the word 'xpm' in the subject line.

=head1 COPYRIGHT

Copyright (c) Mark Summerfield 2000. All Rights Reserved.

This module may be used/distributed/modified under the LGPL. 

=cut

