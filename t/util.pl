use strict;
use warnings;

$ENV{'PERL5LIB'} = 'lib';

use JSON ();
my $json = JSON->new->relaxed;

my $conf_file = "$FindBin::RealBin/config/test.json";
my $conf;
open my $fh, "<", $conf_file;
{ local $/;
    $conf = $json->decode( <$fh> );
}
    
# Build Perl DBI dsn
my $dsn = "DBI:mysql:database=$conf->{schema}";
$dsn .= ";host=$conf->{host}" if $conf->{host};
$dsn .= ";port=$conf->{port}" if $conf->{port};

use DBI ();
my $dbh = DBI->connect($dsn,$conf->{user},$conf->{password},{RaiseError=>1});

sub clear_database ()
{
    my $sth;
    
    # Drop all constraints...
    $sth = $dbh->prepare("SELECT TABLE_NAME, CONSTRAINT_NAME FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE WHERE TABLE_SCHEMA=? AND REFERENCED_TABLE_NAME IS NOT NULL");
    $sth->execute( $conf->{schema} );
    while( my($table,$constraint) = $sth->fetchrow_array() ) {
        $dbh->do("ALTER TABLE `$table` DROP FOREIGN KEY `$constraint`");
    }
    
    # Drop all tables...
    $sth = $dbh->prepare("SHOW TABLES");
    $sth->execute();
    while( my( $table ) = $sth->fetchrow_array() ) {
        $dbh->do("DROP TABLE `$table`");
    }
}

sub run_mysql ($)
{
    my($file) = shift;
    my @cmd = ("mysql","-c","-u",$conf->{user},"-p$conf->{password}");
    push @cmd, "-h", $conf->{host}
        if $conf->{host};
    push @cmd, $conf->{schema};
    open my $io, "|-", @cmd;
    open my $fh, "<", $file;
    while( my $line = <$fh> ) {
        print $io $line;
    }
    close $io;
    die "Run of $file failed." if $?;
}
