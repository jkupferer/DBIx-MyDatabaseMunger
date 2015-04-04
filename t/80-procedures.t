#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 13;

use lib 'lib';
use_ok('DBIx::MyDatabaseMunger');

use FindBin ();
require "$FindBin::RealBin/util.pl";
my $conf_file = "$FindBin::RealBin/config/test.json";

sub t_add_procedure_sql()
{
    my $fh;
    open $fh, ">", "procedure/create_user.sql";
    print $fh <<EOF;
CREATE DEFINER=`example`@`localhost` PROCEDURE `create_user`(IN name VARCHAR(64), IN email VARCHAR(64), OUT id INT UNSIGNED)
BEGIN
    INSERT INTO User (name,email) VALUES (name,email);
    SELECT LAST_INSERT_ID() INTO id;
END
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

# Add procedure
t_add_procedure_sql();

$ret = system( @cmdroot, "pull" );
ok( $ret == 0, "Run pull without --remove-procedures" );

$ret = system(qw(md5sum -c t/80-procedures.md5));
ok( $ret == 0, "Check procedures md5" );

$ret = system( @cmdroot, "--remove-procedures", "pull" );
ok( $ret == 0, "pull with --remove-procedures" );

$ret = system(qw(md5sum -c t/80-procedures.remove.md5));
ok( $ret == 0, "Check procedures md5" );
ok( !-e "procedure/create_user.sql", "check procedure sql was removed." );

t_add_procedure_sql();

$ret = system( @cmdroot, "push" );
ok( $ret == 0, "push" );

clear_directories();

$ret = system( @cmdroot, "pull" );
$ret = system(qw(md5sum -c t/80-procedures.md5));
ok( $ret == 0, "Check procedures md5" );

# Remove local sql then test push without remove
unlink "procedure/create_user.sql";

$ret = system( @cmdroot, "push" );
ok( $ret == 0, "push" );

clear_directories();

$ret = system( @cmdroot, "pull" );
$ret = system(qw(md5sum -c t/80-procedures.md5));
ok( $ret == 0, "Check procedures md5" );

# Remove local sql then test push with remove
unlink "procedure/create_user.sql";

$ret = system( @cmdroot, "--remove-procedures", "push" );
ok( $ret == 0, "push --remove-procedures" );

clear_directories();

$ret = system( @cmdroot, "pull" );
$ret = system(qw(md5sum -c t/80-procedures.remove.md5));
ok( $ret == 0, "Check procedures md5" );

exit 0;
