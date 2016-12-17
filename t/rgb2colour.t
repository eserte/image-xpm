#===============================================================================
#
#         FILE: rgb2colour.t
#
#  DESCRIPTION: Tests of the rgb2colour method
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

plan tests => 12;

use Image::Xpm;

# As a class method
cmp_ok (Image::Xpm->rgb2colour(0, 0, 0), 'eq', '#000000', "Class method: black");
cmp_ok (Image::Xpm->rgb2colour(255, 255, 255), 'eq', '#ffffff', "Class method: white");
cmp_ok (Image::Xpm->rgb2colour(51, 102, 153), 'eq', '#336699', "Class method: web-safe");

# Alternative spelling
cmp_ok (Image::Xpm->rgb2color(0, 0, 0), 'eq', '#000000', "Class method: black");
cmp_ok (Image::Xpm->rgb2color(255, 255, 255), 'eq', '#ffffff', "Class method: white");
cmp_ok (Image::Xpm->rgb2color(51, 102, 153), 'eq', '#336699', "Class method: web-safe");

# As an object method
my $xpm = Image::Xpm->new(-width => 1, -height => 1);
cmp_ok ($xpm->rgb2colour(0, 0, 0), 'eq', '#000000', "Class method: black");
cmp_ok ($xpm->rgb2colour(255, 255, 255), 'eq', '#ffffff', "Class method: white");
cmp_ok ($xpm->rgb2colour(51, 102, 153), 'eq', '#336699', "Class method: web-safe");

# Alternative spelling
$xpm = Image::Xpm->new(-width => 1, -height => 1);
cmp_ok ($xpm->rgb2color(0, 0, 0), 'eq', '#000000', "Class method: black");
cmp_ok ($xpm->rgb2color(255, 255, 255), 'eq', '#ffffff', "Class method: white");
cmp_ok ($xpm->rgb2color(51, 102, 153), 'eq', '#336699', "Class method: web-safe");
