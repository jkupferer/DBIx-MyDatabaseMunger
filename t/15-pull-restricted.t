#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 3;

use lib 'lib';
use_ok('DBIx::MyDatabaseMunger');

use FindBin ();
require "$FindBin::RealBin/util.pl";
my $conf_file = "$FindBin::RealBin/config/test.json";

clear_database();
clear_directories();

run_mysql("$FindBin::RealBin/sql/user-service.sql");

my @cmdroot = ("perl","$FindBin::RealBin/../bin/mydbmunger","-c",$conf_file);

my $ret = system( @cmdroot, qw(-t User pull) );
ok( $ret == 0, "run pull" );

$ret = system(qw(md5sum -c t/15-pull-restricted.md5));
ok( $ret == 0, "check pull md5" );

exit 0;
