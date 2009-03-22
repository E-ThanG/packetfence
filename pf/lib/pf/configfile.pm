package pf::configfile;

=head1 NAME

pf::configfile

=cut

use strict;
use warnings;

our (
    $configfile_add_sql,       $configfile_exist_sql,
    $configfile_exist_new_sql, $configfile_exist_old_sql,
    $configfile_update_sql,    $configfile_view_sql,
    $configfile_db_prepared
);

BEGIN {
    use Exporter ();
    our ( @ISA, @EXPORT );
    @ISA = qw(Exporter);
    @EXPORT
        = qw(configfile_db_prepare configfile_import configfile_export configfile_add configfile_update configfile_view configfile_exist);
}

use Log::Log4perl;
use File::Copy;
use pf::config;
use pf::util;
use pf::db;

$configfile_db_prepared = 0;

sub configfile_db_prepare {
    my ($dbh) = @_;
    db_connect($dbh);
    my $logger = Log::Log4perl::get_logger('pf::configfile');
    $logger->debug("Preparing pf::configfile database queries");
    $configfile_update_sql
        = $dbh->prepare(
        qq[ update configfile set filecontent=?, lastmodified=from_unixtime(?) where filename=? ]
        );
    $configfile_add_sql
        = $dbh->prepare(
        qq[ insert into configfile(filename,filecontent,lastmodified) values(?,?,from_unixtime(?)) ]
        );
    $configfile_exist_sql = $dbh->prepare(
        qq[ select filename from configfile where filename=? ]);
    $configfile_exist_new_sql
        = $dbh->prepare(
        qq[ select filename from configfile where filename=? and unix_timestamp(lastmodified) > ? ]
        );
    $configfile_exist_old_sql
        = $dbh->prepare(
        qq[ select filename from configfile where filename=? and unix_timestamp(lastmodified) < ? ]
        );
    $configfile_view_sql
        = $dbh->prepare(
        qq[ select filename,filecontent,lastmodified from configfile where filename=? ]
        );
    $configfile_db_prepared = 1;
}

sub configfile_import {
    my ($filename) = @_;
    my $logger = Log::Log4perl::get_logger('pf::configfile');
    if ( !configfile_exist($filename) ) {
        $logger->info(
            "config file $filename does not exist in database; addind new database entry"
        );
        configfile_add($filename);
    } else {
        if ( configfile_db_is_old($filename) ) {
            $logger->info(
                "config file $filename is outdated in database; updating database entry"
            );
            configfile_update($filename);
        }
    }
}

sub configfile_export {
    my ($filename) = @_;
    my $logger = Log::Log4perl::get_logger('pf::configfile');
    if ( !configfile_exist($filename) ) {
        $logger->info(
            "config file $filename does not exist in database; unable to export"
        );
    } else {
        if ( configfile_db_is_new($filename) ) {
            $logger->info(
                "config file $filename is outdated on filesystem; updating dfile"
            );
            copy( $filename, "$filename-" . time() );
            my $data = configfile_view($filename);
            open my $export_fh, '>', $filename;
            print {$export_fh} $data->{'filecontent'};
            close $export_fh;
        }
    }
}

sub configfile_exist {
    my ($filename) = @_;
    configfile_db_prepare($dbh) if ( !$configfile_db_prepared );
    $configfile_exist_sql->execute($filename) || return (0);
    my ($val) = $configfile_exist_sql->fetchrow_array();
    $configfile_exist_sql->finish();
    return ($val);
}

sub configfile_db_is_old {
    my ($filename) = @_;
    my $lastMod = ( stat($filename) )[9];
    configfile_db_prepare($dbh) if ( !$configfile_db_prepared );
    $configfile_exist_old_sql->execute( $filename, $lastMod ) || return (0);
    my ($val) = $configfile_exist_old_sql->fetchrow_array();
    $configfile_exist_old_sql->finish();
    return ($val);
}

sub configfile_db_is_new {
    my ($filename) = @_;
    my $lastMod = ( stat($filename) )[9];
    configfile_db_prepare($dbh) if ( !$configfile_db_prepared );
    $configfile_exist_new_sql->execute( $filename, $lastMod ) || return (0);
    my ($val) = $configfile_exist_new_sql->fetchrow_array();
    $configfile_exist_new_sql->finish();
    return ($val);
}

sub configfile_add {
    my ($filename) = @_;
    configfile_db_prepare($dbh) if ( !$configfile_db_prepared );
    my $lastMod = ( stat($filename) )[9];
    open my $configfile_fh, '<', $filename;
    my @content = <$configfile_fh>;
    close $configfile_fh;
    $configfile_add_sql->execute( $filename, join( '', @content ), $lastMod )
        || return (0);
    return (1);
}

sub configfile_update {
    my ($filename) = @_;
    configfile_db_prepare($dbh) if ( !$configfile_db_prepared );
    my $lastMod = ( stat($filename) )[9];
    open my $configfile_fh, '<', $filename;
    my @content = <$configfile_fh>;
    close $configfile_fh;
    $configfile_update_sql->execute( join( '', @content ),
        $lastMod, $filename )
        || return (0);
    return (1);
}

sub configfile_view {
    my ($filename) = @_;
    configfile_db_prepare($dbh) if ( !$configfile_db_prepared );
    $configfile_view_sql->execute($filename) || return (0);
    my $ref = $configfile_view_sql->fetchrow_hashref();

    # just get one row and finish
    $configfile_view_sql->finish();
    return ($ref);
}

=head1 AUTHOR

Dominik Gehl <dgehl@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2007-2009 Inverse groupe conseil

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
USA.

=cut

1;
