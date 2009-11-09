use strict;

BEGIN {
    if (!eval q{
	use Test::More;
	1;
    }) {
	print "1..0 # skip no Test::More module\n";
	exit;
    }
}

plan tests => 2;

use Image::Xpm;

my $TestImage = <<'EOT';
/* XPM */
static const char* noname[] = {
/* width height ncolors chars_per_pixel */
"4 10 4 1",
/* colors */
"` c #000000",
"a c #FA1340",
"b c #3BFA34",
"c c #FFFF00",
/* pixels */
"````",
"`aa`",
"`aa`",
"````",
"`cc`",
"`cc`",
"````",
"`bb`",
"`bb`",
"````"
};
EOT

my $xpm = Image::Xpm->new(-width => 0, -height => 0);
$xpm->load(\$TestImage);
is($xpm->get('-width'), 4, 'Image with static const char loaded');
is($xpm->get('-height'), 10);
