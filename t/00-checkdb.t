#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 1;

use FindBin ();

eval { require "$FindBin::RealBin/util.pl"; };
warn "\n!!! Unable to connect to database for testing.  !!!\n" .
       "!!! Please check settings it t/config/test.json !!!\n$@";
test( !$@, "Check database connectivity.");

exit 0;
