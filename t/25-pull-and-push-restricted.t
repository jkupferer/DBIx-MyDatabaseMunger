#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 5;

use lib 'lib';
use_ok('DBIx::MyDatabaseMunger');

use FindBin ();
require "$FindBin::RealBin/util.pl";
my $conf_file = "$FindBin::RealBin/config/test.json";

clear_database();
clear_directories();

run_mysql("$FindBin::RealBin/sql/user-service.sql");

my @cmdroot = ("perl","$FindBin::RealBin/../bin/mydbmunger","-c",$conf_file);
my $ret;

$ret = system( @cmdroot, "pull" );
ok( $ret == 0, "run pull" );

clear_database();

$ret = system( @cmdroot, qw(-t User push) );
ok( $ret == 0, "clear then push" );

clear_directories();

$ret = system( @cmdroot, "pull" );
ok( $ret == 0, "pull again" );

$ret = system(qw(md5sum -c t/25-pull-and-push-restricted.md5));
ok( $ret == 0, "check pull md5 again" );

exit 0;
