Description
===========

This package contains 'The Washington Visual Double Star Catalog' (WDS, [VizieR B/wds](http://cdsarc.u-strasbg.fr/viz-bin/Cat?B/wds)) in SQL format (MySQL/MariaDB). Also package contains simple Perl to import data from text catalogue.

Catalogue info
--------------

**B/wds** The Washington Visual Double Star Catalog (Mason+ 2001-2014)

The Washington Visual Double Star Catalog (WDS), Version 2015-09-01

*Mason B.D., Wycoff G.L., Hartkopf W.I., Douglass G.G., Worley C.E.* Astron. J. 122, 3466 (2001)

About files
-----------
* wds_cat.sql.bz2 — WDS catalogue in SQL format. Bzipped. Tested in MariaDB (version 10.0.21-MariaDB). Contains two tables. Table *wds* is the main table. Table *wds_constell* contains constellation names of double stars. You can join these tables like:

    SELECT ... FROM `wds` w
    INNER JOIN `wds_constell` c ON (w.id = c.wds_id)
    WHERE ...

* wds2sql.pl — simple Perl script for importing text catalogue from B/wds into database. See below about usage.

* wds_my.sql — table structure for Perl script.

* utils/get_constell.pl — if you want to determine constellation by equatorial coordinates of double star. Using script from project [astronomy-get-constellation-by-coords](https://bitbucket.org/lukashjames/astronomy-get-constellation-by-coords). If you want use this util, you must change path to the script. Open file get_constell.pl and find line, contains this code:

    my $script_name = '../constByCoord/constByCoords.pl';

Change path to file constByCoords.pl and save script.

Requirements:
-------------

If you want your own import with Perl script, you need file wds.dat.gz from B/wds ([direct link](http://cdsarc.u-strasbg.fr/vizier/ftp/cats/B/wds/wds.dat.gz)).

Perl script requirements:

* PerlIO::gzip
* DBI
* Getopt::Long
* Term::ReadPassword
* FindBin
    
Usage
-----

If you want use SQL WDS from this package you need use this command:

    $ bzip2 -cd wds_cat.sql.bz2 | mysql -uusername -p wds

*Note* Do not forget create database 'wds' before execution this command.

Using Perl script (from console):

    $ ./wds2sql.pl [[--dbhost=db.myserver.org] --dbuser=username [--dbpasswd] --dbname=databasename [--quiet]]

*Note* Do not forget download [this file](http://cdsarc.u-strasbg.fr/vizier/ftp/cats/B/wds/wds.dat.gz).

Options:
--------

List of options:

* --dbhost Database host (default - localhost)
* --dbuser Username for database (required option)
* --dbpass Database password will be prompted (default - empty password)
* --dbname Database name (required option)
* --quiet  Do not print anything (quiet mode)

Examples:
---------

Before execution script do not forget create database 'wds' and import table structure from file wds_my.sql:

    $ mysql -h dbhost -u username -p wds < wds_my.sql

**Example 1.** Without any option:

    $ ./wds2sql.pl

Output:

> Usage: ./wds2sql.pl [[--dbhost=db.myserver.org] --dbuser=username [--dbpasswd] --dbname=databasename [--quiet]]

> --dbhost Database host (default - localhost)

> --dbuser Username for database (required option)

> --dbpass Database password will be prompted (default - empty password)

> --dbname Database name (required option)

> --quiet  Do not print anything (quiet mode)

**Example 2.** Connecting to localhost with empty password (**ATTENTION!!! Using empty password is not recommended by security reasons**).

    $ ./wds2sql.pl --dbuser=username --dbname=databasename

Output:

> 03072-0520 GWP 423      1995 1999...

> 03073+8025 HU 1049      1904 1991...

> 03073+3903 UC  952      1998 2002...

> ...

**Example 3.** Connecting to host db.myserver.org with password. Password will be prompted from STDIN without echoing (form like --dbpass=mypassword not supported, 'mypassword' will be ignored).

    $ ./wds2sql.pl --dbhost=db.myserver.org --dbuser=james --dbpasswd --dbname=wds

Output: like in Example 2.

**Example 4.** Using quiet mode (do not print anything)

    $ ./wds2sql.pl --dbhost=db.myserver.org --dbuser=jane --dbpasswd --dbname=wds --quiet

No output.
