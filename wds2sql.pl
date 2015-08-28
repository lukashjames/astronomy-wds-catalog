#!/usr/bin/perl

use strict;
use warnings;
use PerlIO::gzip;
use DBI;
use Data::Dumper;

my $bytes_str =<< 'EOS';
   1- 10  A10   ---     WDS     WDS name (based on J2000 position)
  11- 17  A7    ---     Disc    Discoverer Code (1 to 4 letters) and Number (5)
  18- 22  A5    ---     Comp    Components when more than 2 (1)
  24- 27  I4    yr      Obs1    ? Date of first satisfactory observation
  29- 32  I4    yr      Obs2    ? Date of last satisfactory observation
  34- 37  I4    ---     Nobs    Number of Observations (up to 9999)
  39- 41  I3    deg     pa1     ? Position Angle at date Obs1 (2)
  43- 45  I3    deg     pa2     ? Position Angle at date Obs2 (2)
  47- 51  F5.1  arcsec  sep1    ? Separation at date Obs1
  53- 58  F6.2  arcsec  sep2    ? Separation at date Obs12
  59- 63  F5.2  mag     mag1    ? Magnitude of First Component
  65- 69  F5.2  mag     mag2    ? Magnitude of Second Component
  71- 80  A10   ---     SpType  Spectral Type (Primary/Secondary)
  81- 84  I4    mas/yr  pmRA1   ? Primary Proper Motion (RA)
  85- 88  I4    mas/yr  pmDE1   ? Primary Proper Motion (Dec)
  90- 93  I4    mas/yr  pmRA2   ? Secondary Proper Motion (RA)
  94- 97  I4    mas/yr  pmDE2   ? Secondary Proper Motion (Dec)
  99-107  A9    ---     DM      Durchmusterung Number (3)
 108-111  A4    ---     Notes   [B-Z ] Notes about the binary (4)
     112  A1    ---     n_RAh   [!] indicates a position derived from WDS name
 113-114  I2    h       RAh     Right Ascension J2000 (Ep=J2000, hours)
 115-116  I2    min     RAm     Right Ascension J2000 (Ep=J2000, minutes)
 117-121  F5.2  s       RAs     [0/60] Right Ascension J2000 (Ep=J2000, seconds)
     122  A1    ---     DE-     Declination J2000 (Ep=J2000, sign)
 123-124  I2    deg     DEd     Declination J2000 (Ep=J2000, degrees)
 125-126  I2    arcmin  DEm     Declination J2000 (Ep=J2000, minutes)
 127-130  F4.1  arcsec  DEs     [0/60]? Declination J2000 (Ep=J2000, seconds)
EOS

my @bytes;

while ($bytes_str =~ /^(.{8})  (.{4})/gms)
{
    my ($tmp_bytes, $tmp_format) = ($1, $2);
    my %tmp_elem;
    if ($tmp_bytes =~ /^\s*(\d+)\-\s*(\d+)$/)
    {
        @tmp_elem{'first_byte', 'last_byte'} = ($1, $2);
    }
    elsif ($tmp_bytes =~ /^\s*(\d+)$/)
    {
        @tmp_elem{'first_byte', 'last_byte'} = ($1, $1);
    }
    $tmp_elem{'length'} = $tmp_elem{'last_byte'} - $tmp_elem{'first_byte'} + 1;
    #print Dumper (\%tmp_elem);die;
    push @bytes, \%tmp_elem;
}
#print Dumper (@bytes);die;

our $db = get_connect ();
if ( ! $db)
{
    print STDERR "Connection failed\n";
    exit -1;
}

my $db_fields = get_wds_fields ();
my @pattern = map { '?' } @$db_fields;
#print Dumper (@pattern);die;
my $sql = 'INSERT INTO wds (' . join (', ', @$db_fields) . ') VALUES (' . join (', ', @pattern) . ');';
#print "$sql\n";die;
my $sth = $db->prepare ($sql);

open my $F, '<:gzip', 'wds.dat.gz' or die "open() error: $!\n";


while (my $line = <$F>)
{
    my @item = ('DEFAULT');
    print $line;
    chomp $line;
    #print;die;
    #my @item = unpack ('A10 A7 A5 x1 A4 x1 A4 x1 A4 x1 A3 x1 A3 x1 A5 x1 A6 A5 x1 A5 x1 A10 A4', $line);
    for (@bytes)
    {
        #print Dumper ($_);die;
        push @item, substr ($line, $_->{'first_byte'} - 1, $_->{'length'});
    }
    #print Dumper (@item);
    $sth->execute (@item);
    #die;
}
close $F;
1;

sub get_connect
{
    my $db = DBI->connect ('DBI:mysql:wds', 'user', 'm4r14db_u53r', {'RaiseError' => 0});
    return (defined $db ? $db : 0);
}

# извлечем из таблицы список полей
sub get_wds_fields
{
    my $res = $db->selectcol_arrayref (q/SELECT column_name FROM information_schema.columns WHERE table_name = 'wds' ORDER BY ordinal_position/);
    if ($db->err)
    {
        print STDERR 'Error: get_wds_fields(): ' . $db->errstr, "\n";
        exit -1;
    }
    return $res;
}