#!/usr/bin/env perl
use strict;
use warnings;
use Module::Build ();

my $build = new Module::Build (
    module_name => 'DBIx::MyDatabaseMunger',
    license => 'perl',
    requires => {
        'autodie' => undef,
        'DBI' => undef,
        'DBD::mysql' => undef,
        'JSON' => undef,
        'Storable' => undef,
    },
);
$build->create_build_script();
