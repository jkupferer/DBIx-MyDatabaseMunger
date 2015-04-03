#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 7;

sub write_modification
{
    open my $fh, ">", "table/Service.sql";
    print $fh <<EOF;
CREATE TABLE `Service` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Numeric service identifier.',
  `name` varchar(64) NOT NULL COMMENT 'Unique text service identifier.',
  `owner_id` int(10) unsigned NOT NULL COMMENT 'Foreign key to user that owns service.',
  `revision` int(10) unsigned NOT NULL COMMENT 'Revision count for Service.',
  `mtime` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Timestamp of Service last change.',
  `ctime` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' COMMENT 'Timestamp of Service creation.',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  KEY `Service_owner` (`owner_id`),
  CONSTRAINT `Service_owner` FOREIGN KEY (`owner_id`) REFERENCES `User` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='A User''s Service'
EOF
}

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

write_modification();

$ret = system( @cmdroot, "push" );
ok( $ret == 0, "push without drop columns" );

clear_directories();

$ret = system( @cmdroot, "pull" );
ok( $ret == 0, "pull again" );

$ret = system(qw(md5sum -c t/50-drop-columns.nodrop.md5));

write_modification();

$ret = system( @cmdroot, "--drop-columns", "push" );
ok( $ret == 0, "push with drop columns" );

clear_directories();

$ret = system( @cmdroot, "pull" );
ok( $ret == 0, "pull again" );

$ret = system(qw(md5sum -c t/50-drop-columns.md5));
ok( $ret == 0, "check md5" );

exit 0;
