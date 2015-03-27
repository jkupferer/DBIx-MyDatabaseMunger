#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 8;

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

$ret = system( @cmdroot, "-t", "Service", "make-archive" );
ok( $ret == 0, "Make archive table for Service" );

$ret = system( @cmdroot, "push" );
ok( $ret == 0, "push archive table stuff" );

open my $fh, ">", "table/Service.sql";
print $fh <<EOF;
CREATE TABLE `Service` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT COMMENT 'Numeric service identifier.',
  `name` varchar(64) NOT NULL COMMENT 'Unique text service identifier.',
  `description` text NOT NULL COMMENT 'Service description.',
  `owner_id` int(10) unsigned NOT NULL COMMENT 'Foreign key to user that owns service.',
  `user_management` enum('single','multi','none') NOT NULL COMMENT 'User management style for this service.',
  `revision` int(10) unsigned NOT NULL COMMENT 'Revision count for Service.',
  `mtime` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT 'Timestamp of Service last change.',
  `ctime` timestamp NOT NULL DEFAULT '0000-00-00 00:00:00' COMMENT 'Timestamp of Service creation.',
  PRIMARY KEY (`id`),
  UNIQUE KEY `name` (`name`),
  KEY `Service_owner` (`owner_id`),
  CONSTRAINT `Service_owner` FOREIGN KEY (`owner_id`) REFERENCES `User` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='A User''s Service'
EOF

$ret = system( @cmdroot, "-t", "Service", "make-archive" );
ok( $ret == 0, "Make updated archive table for Service" );

$ret = system( @cmdroot, "push" );
ok( $ret == 0, "push modifications" );

clear_directories();

$ret = system( @cmdroot, "pull" );
ok( $ret == 0, "pull again" );

$ret = system(qw(md5sum -c t/40-make-archive-then-modify-and-update.md5));
ok( $ret == 0, "check pull md5 again" );

#unlink glob "table/*";
#rmdir "table";

exit 0;
