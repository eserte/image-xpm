use ExtUtils::MakeMaker ;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'         => 'Image::Xpm',
    'VERSION_FROM' => 'Xpm.pm', # finds $VERSION
    'DISTNAME'     => 'Image-Xpm',
    ($] >= 5.005 ?
        (
            ABSTRACT => 'Load, create, manipulate and save xpm image files.',
            AUTHOR   => 'Mark Summerfield <summer@perlpress.com>',
        ) : () ),
    'LIBS'         => [''],   # e.g., '-lm'
    'DEFINE'       => '',     # e.g., '-DHAVE_SOMETHING'
    'INC'          => '',     # e.g., '-I/usr/include/other'
    'PREREQ_PM'    => { 'Image::Base' => '1.06', },
    'dist'         => { COMPRESS => "gzip -9", SUFFIX => "gz" },
) ;
