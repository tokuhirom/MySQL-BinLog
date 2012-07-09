# for developers:
#   "cpanm < author/requires.cpanm" will install all the modules required
#   "make test_with_env" does all the extra tests (with pure Perl, Moose, etc.)
use strict;
use warnings;
BEGIN {
    unshift @INC, 'inc';
	# author requires, or bundled modules
    my @devmods = qw(
        inc::Module::Install             1.00
        Module::Install::XSUtil          0.42
        Module::Install::AuthorTests     0.002
    );
    my @not_available;
	while(my($mod, $ver) = splice @devmods, 0, 2) {
        eval qq{use $mod $ver (); 1} or push @not_available, $mod;
    }
    if(@not_available) {
        print qq{# The following modules are not available.\n};
        print qq{# `perl $0 | cpanm` will install them:\n};
        print $_, "\n" for @not_available;
		exit 1;
     }

    $INC{'Module/Install/ExtraTests.pm'} = 1;# considered harmful!
}
use inc::Module::Install;

all_from 'lib/MySQL/BinLog.pm';


cc_assert_lib (
	lib => 'replication',
);

cc_libs qw(replication stdc++ boost_system);

requires 'parent'               => '0.221';
requires 'Scalar::Util'         => '1.14';

test_requires 'Test::More' => 0.98; # done_testing()
test_requires 'Test::Requires';

tests_recursive;
author_tests 'xt';

my $want_xs = want_xs();
use_xshelper;
cc_warnings;
requires_cplusplus;

cc_src_paths qw(src);

clean_files qw(
    MySQL-BinLog-*
    nytprof *.out
    cover_db
);

WriteAll(check_nmake => 0);
