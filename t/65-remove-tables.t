#!/usr/bin/env perl
#
# This tests --remove-tales with pull action.
#
use strict;
use warnings;
use Test::More tests => 7;

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

t_drop_table( 'Service' );

$ret = system( @cmdroot, "pull" );
ok( $ret == 0, "pull without --remove-tables" );

$ret = system(qw(md5sum -c t/65-remove-tables.noremove.md5));
ok( $ret == 0, "check md5, should have Service table" );

$ret = system( @cmdroot, "--remove-tables", "pull" );
ok( $ret == 0, "pull with --remove-tables" );

$ret = system(qw(md5sum -c t/65-remove-tables.md5));
ok( $ret == 0, "check md5, should not have Service table" );

ok( ! -e "table/Service.sql", "check that table/Service.sql is removed" );

exit 0;
