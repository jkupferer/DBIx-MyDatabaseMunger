#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 17;

use lib 'lib';
use_ok('DBIx::MyDatabaseMunger');

use FindBin ();
require "$FindBin::RealBin/util.pl";
my $conf_file = "$FindBin::RealBin/config/test.json";

sub t_add_trigger_fragment()
{
    my $fh;
    open $fh, ">", "trigger/10-allone.before.insert.Service.sql";
    print $fh <<EOF;
SET NEW.owner_id = 1;
EOF
    close $fh;
}

clear_database();
clear_directories();

run_mysql("$FindBin::RealBin/sql/user-service.sql");

my @cmdroot = ("perl","$FindBin::RealBin/../bin/mydbmunger","-c",$conf_file);
my $ret;

$ret = system( @cmdroot, "pull" );
ok( $ret == 0, "run pull" );

# Add triggers
mkdir "trigger" unless -d "trigger";

my $fh;

open $fh, ">", "trigger/10-test.before.insert.Service.sql";
print $fh <<EOF;
SET NEW.description = 'Overridden before insert.';
EOF
close $fh;

open $fh, ">", "trigger/10-test.before.update.Service.sql";
print $fh <<EOF;
SET NEW.description = 'Overridden before update.';
EOF
close $fh;

$ret = system( @cmdroot, "push" );
ok( $ret == 0, "push with new triggers" );

clear_directories();

$ret = system( @cmdroot, "pull" );
ok( $ret == 0, "pull to get new triggers" );

$ret = system(qw(md5sum -c t/70-remove-triggers.init.md5));
ok( $ret == 0, "new triggers md5" );

# Create another trigger fragment that is local only
t_add_trigger_fragment();

# Run pull again without --remove-triggers
$ret = system( @cmdroot, "pull" );
ok( $ret == 0, "pull without --remove-triggers" );

$ret = system(qw(md5sum -c t/70-remove-triggers.noremove.md5));
ok( $ret == 0, "with extra local trigger md5" );

# Run pull again with --remove-triggers
$ret = system( @cmdroot, "--remove-triggers", "pull" );
ok( $ret == 0, "pull with --remove-triggers" );

$ret = system(qw(md5sum -c t/70-remove-triggers.init.md5));
ok( $ret == 0, "check triggers that should be present" );

ok( ! -e "trigger/10-allone.before.insert.Service.sql", "check trigger fragment was removed." );

# Now remove one of the local trigger fragments.
unlink "trigger/10-test.before.insert.Service.sql";

# Push without --remove-triggers should leave the trigger in the database.
$ret = system( @cmdroot, "push" );
ok( $ret == 0, "push without --remove-triggers" );

clear_directories();

$ret = system( @cmdroot, "pull" );
ok( $ret == 0, "pull to check results of push without --remove-triggers" );

# We should be back to the initial state
$ret = system(qw(md5sum -c t/70-remove-triggers.init.md5));
ok( $ret == 0, "check md5 on pull after push without --remove-triggers" );

# Again remove one of the local trigger fragments.
unlink "trigger/10-test.before.insert.Service.sql";

# Push with --remove-triggers.
$ret = system( @cmdroot, qw(--remove-triggers push) );
ok( $ret == 0, "push with --remove-triggers" );

clear_directories();

$ret = system( @cmdroot, "pull" );
ok( $ret == 0, "pull to check results of push with --remove-triggers" );

$ret = system(qw(md5sum -c t/70-remove-triggers.remove.md5));
ok( $ret == 0, "check md5 on pull after push with --remove-triggers" );

ok( ! -e "trigger/10-test.before.insert.Service.sql", "check trigger fragment was removed from database." );

exit 0;
