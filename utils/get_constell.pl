#!/usr/bin/perl

use strict;
use warnings;
use DBI;
use Getopt::Long;
use Term::ReadPassword;
use FindBin qw/$Bin/;
use Data::Dumper;

my ($dbhost, $dbuser, $dbpass, $dbname, $quiet);
usage() if scalar @ARGV < 1;
GetOptions(
    'dbhost:s' => \$dbhost,
    'dbuser:s' => \$dbuser,
    'dbpass!' => \$dbpass,
    'dbname:s' => \$dbname,
    'quiet!' => \$quiet,
) or die("Error in command line arguments\n");

$dbhost ||= 'localhost';
unless ($dbuser) {
    print STDERR "You need MySQL username\n";
    exit -1;
}
unless ($dbname) {
    print STDERR "You need MySQL database name\n";
    exit -1;
}

if ($dbpass) {
    $dbpass = read_password('Enter MySQL password: ');
} else {
    $dbpass = '';
}

my $script_name = '../constByCoord/constByCoords.pl';
unless (-x $script_name) {
    print STDERR "Script not found\n";
    exit -1;
}

our $db = get_connect($dbhost, $dbuser, $dbpass, $dbname);
my $sth = $db->prepare(q/SELECT id, wds, rah, ram, ras, de_sign, ded, dem, des FROM wds ORDER BY id/);
if ($db->err) {
    print STDERR "SELECT prepare() error: ", $db->errstr, "\n";
    exit -1;
}
my $stmt = $db->prepare(q/INSERT INTO wds_constell (id, wds_id, wds_name, constell) VALUES (DEFAULT, ?, ?, ?)/);
if ($db->err) {
    print STDERR "INSERT prepare() error: ", $db->errstr, "\n";
    exit -1;
}

$sth->execute();
if ($db->err) {
    print STDERR "SELECT execute() error: ", $db->errstr, "\n";
    exit -1;
}
my ($row, $ra, $dec, $constell);
while ($row = $sth->fetchrow_hashref) {
    #print Dumper ($row);die;
    $ra = $row->{'rah'} + $row->{'ram'} / 60.0 + $row->{'ras'} / 3600.0;
    $dec = $row->{'ded'} + $row->{'dem'} / 60.0 + $row->{'des'} / 3600.0;
    $dec *= -1 if $row->{'de_sign'} eq '-';
    #print "RA: $ra, DEC: $dec\n";die;
    $constell = `$script_name --ra $ra --dec $dec --epoch 2000.0 --quiet`;
    chomp $constell;
    #print Dumper($constell);die;
    $stmt->execute($row->{'id'}, $row->{'wds'}, $constell);
    if ($db->err) {
        print STDERR "INSERT execute() error: ", $db->errstr, "\n";
        exit -1;
    }
    print $row->{'wds'}, ' ', $constell, "\n" unless $quiet;
}
print "Done\n" unless $quiet;

1;

sub get_connect
{
    my ($host, $user, $pass, $dbname) = @_;
    my $db = DBI->connect ('DBI:mysql:' . $dbname, $user, $pass, {'RaiseError' => 0});
    if (!$db and DBI->err) {
        print STDERR "Connection failed: ", DBI->errstr, "\n";
        exit -1;
    }
    return $db;
}

#sub get_data
#{
#    my $res = $db->
#}

sub usage
{
    print STDOUT qq/
Usage: $0 [[--dbhost=db.myserver.org] --dbuser=username [--dbpass] --dbname=databasename [--quiet]]
    --dbhost Database host (default - localhost)
    --dbuser Username for database (required option)
    --dbpass Database password will be prompted (default - empty password)
    --dbname Database name (required option)
    --quiet  Do not print anything (quiet mode)
/;
    exit 0;
}
