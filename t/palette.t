#===============================================================================
#
#         FILE: palette.t
#
#  DESCRIPTION: Tests of the methods which add and remove colours in the
#               palette
#
#===============================================================================

use strict;
# No warnings - would not hurt to add but would bring MIN_PERL_VERSION
# up to 5.6.0

BEGIN {
    if (!eval q{
	use Test::More;
	1;
    }) {
	print "1..0 # skip no Test::More module\n";
	exit;
    }
}

plan tests => 22;

use Image::Xpm;

my $xpm = Image::Xpm->new(-width => 1, -height => 1);

is ($xpm->get('-ncolours'), 1, '1 colour to start');
is ((keys %{$xpm->get('-cindex')})[0], 'white', 'Just white to start');

$xpm->add_colours ('white');
is ($xpm->get('-ncolours'), 1, 'Still 1 colour after adding white');
is ((keys %{$xpm->get('-cindex')})[0], 'white', 'Just white after adding white');

$xpm->add_colours ('white', 'white', 'white');
is ($xpm->get('-ncolours'), 1, 'Still 1 colour after adding 3 x white');
is ((keys %{$xpm->get('-cindex')})[0], 'white', 'Just white after adding 3 x white');

$xpm->add_colours ('black');
is ($xpm->get('-ncolours'), 2, '2 colours after adding black');
is_deeply ([sort keys %{$xpm->get('-cindex')}], ['black', 'white'],
	'Now white and black');

$xpm->add_colours ('#ff33ff');
is ($xpm->get('-ncolours'), 3, '3 colours after adding #ff33ff');
is_deeply ([sort keys %{$xpm->get('-cindex')}], ['#ff33ff', 'black', 'white'],
	'All 3 listed');

is ($xpm->del_colour ('black'), 1, 'Black deleted');
is ($xpm->get('-ncolours'), 2, '2 colours after deleting black');
is_deeply ([sort keys %{$xpm->get('-cindex')}], ['#ff33ff', 'white'],
	'Now white and #ff33ff only');

is ($xpm->del_colour ('black'), undef, 'Black not deleted');
is ($xpm->get('-ncolours'), 2, '2 colours after not deleting black');
is_deeply ([sort keys %{$xpm->get('-cindex')}], ['#ff33ff', 'white'],
	'Still white and #ff33ff only');

$xpm->vec(0, '#ff33ff');
is ($xpm->del_colour ('#ff33ff'), 0, 'Colour used in image not deleted');
is ($xpm->get('-ncolours'), 2, 'Still 2 colours');
is_deeply ([sort keys %{$xpm->get('-cindex')}], ['#ff33ff', 'white'],
	'Still white and #ff33ff');

$xpm->vec(0, 'white');
is ($xpm->del_colour ('#ff33ff'), 1, '#ff33ff deleted');
is ($xpm->get('-ncolours'), 1, '1 colour');
is_deeply ([keys %{$xpm->get('-cindex')}], ['white'],
	'Just white');

