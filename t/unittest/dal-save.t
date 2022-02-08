#!/usr/bin/perl

=head1 NAME

dal-save

=head1 DESCRIPTION

unit test for dal-save

=cut

use strict;
use warnings;

BEGIN {
    #include test libs
    use lib qw(/usr/local/pf/t);
    #Module for overriding configuration paths
    use setup_test_config;
}

use pf::dal::security_event;
use pf::security_event;
use Data::Dumper;
use Test::More tests => 3;

#This test will running last
use Test::NoWarnings;

pf::dal::security_event->remove_items();

my %data = (
    status => 'open',
    release_date => 0,
    mac => '00:11:22:33:44:55',
);


my ($status, $existing) = pf::dal::security_event->find_or_create({
    %data,
});

my $newId = $existing->{id};
$existing->save();
is($newId, $existing->{id}, "Id is the same");

=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2022 Inverse inc.

=head1 LICENSE

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

