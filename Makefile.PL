use ExtUtils::MakeMaker;

eval {
    if ((getpwuid($<))[0] eq 'eserte' && $ExtUtils::MakeMaker::VERSION < 6.54) {
	warn <<EOF;
**********************************************************************
* WARNING:
* ExtUtils::MakeMaker too old. META.yml will be imcomplete
**********************************************************************
EOF
    }
};

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
    'PREREQ_PM'    => { 'Image::Base' => '1.06',
			($] < 5.008001 ? ('IO::String' => 0) : ()),
		      },
    'dist'         => { COMPRESS => "gzip -9", SUFFIX => "gz" },
    ($ExtUtils::MakeMaker::VERSION >= 6.54 ?
      (META_ADD => { resources => { repository => 'git://github.com/eserte/image-xpm.git' },
		     author => ['Mark Summerfield <summer@perlpress.com>',
				'Slaven Rezic <srezic@cpan.org',
			       ],
		   }) : ()),
) ;
