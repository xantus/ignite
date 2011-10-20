use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

WriteMakefile(
    'NAME'            => 'Ignite',
    'VERSION_FROM'    => 'lib/Ignite.pm', # finds $VERSION
    'PREREQ_PM'        => {
        'Carp'        => undef,
        'Mojolicious' => undef,
    },
    'dist'         => {
        'SUFFIX'       => ".gz",
        'DIST_DEFAULT' => 'all tardist',
        'COMPRESS'     => "gzip -9vf",
    },
);
