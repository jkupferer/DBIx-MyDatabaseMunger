#!/usr/bin/env perl
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

unlink "table/Service.pm";

$ret = system( @cmdroot, "push" );
ok( $ret == 0, "push without --remove-tables" );

clear_directories();

$ret = system( @cmdroot, "pull" );
ok( $ret == 0, "pull again" );

$ret = system(qw(md5sum -c t/60-remove-tables.noremove.md5));

unlink "table/Service.sql";

$ret = system( @cmdroot, "--remove-tables", "push" );
ok( $ret == 0, "push with --remove-tables" );

clear_directories();

$ret = system( @cmdroot, "pull" );
ok( $ret == 0, "pull again" );

$ret = system(qw(md5sum -c t/60-remove-tables.md5));
ok( $ret == 0, "check md5" );

exit 0;
