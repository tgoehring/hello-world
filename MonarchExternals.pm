# MonArch - Groundwork Monitor Architect
# MonarchExternals.pl
#
############################################################################
# Release 2.5
# 7-Apr-2008
############################################################################
# Author: Scott Parris
#
# Copyright 2007, 2008 GroundWork Open Source, Inc. (GroundWork)  
# All rights reserved. This program is free software; you can redistribute
# it and/or modify it under the terms of the GNU General Public License
# version 2 as published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#

use strict;
use MonarchStorProc;

my ($dbh, $err, $rows);

package Externals;

my $distribution_folder = '/usr/local/groundwork/distribution/test';
my $host_sequence_number = 0;

sub build_externals(@) {
	my $userid = $_[1];
	my @errors = ();
	my %hosts = StorProc->get_hosts();

	foreach my $host (sort keys %hosts) {
		my $dt = StorProc->datetime();
		my $head = qq(##########GROUNDWORK#############################################################################################
#GW
#GW\tgwmon_$host.cfg generated $dt by $userid from monarch.cgi
#GW
##########GROUNDWORK#############################################################################################
);
		my $body = undef;
		my $bodytmp= undef;
		my %w = ('host_id' => $hosts{$host});
		my @externals = StorProc->fetch_list_where('external_host','data',\%w);

		## The following Change made to create even load
		## Across GDMA installations. Each GDMA installation
		## Uses its sequence number to determine when to place itself
		## in the system-wide data collection cycle.
		## Changed Jan. 30, 2008, Daniel Emmanuel Feinsmith

		++$host_sequence_number;
		$body .= "\nNumHostsInInstallation=" . keys(%hosts);
		$body .= "\nHostSequenceNumber=$host_sequence_number";

		## End of Changes.

		foreach my $ext (@externals) { 
			$ext =~ s/\r//g;
			$body .= "\n$ext";
		}
		my @services = StorProc->fetch_list_where('services','service_id',\%w);
		my @allext = ();
		foreach my $service (@services) {
			%w = ('service_id' => $service);
			@externals = StorProc->fetch_list_where('external_service','data',\%w,'data');
			foreach my $ext (@externals) { 
				$ext =~ s/^[\n\r\s]+//;
				$ext =~ s/[\n\r\s]+$//;
				$ext =~ s/\r//g;
				push @allext,$ext;
			}
		}
		foreach my $ext (sort @allext) {	# Sort by external text
			$body .= "\n$ext\n";
		}
		if ($body) {
			open(FILE, "> $distribution_folder/gwmon_$host.cfg") || push @errors, "Error: Unable to write $distribution_folder/gwmon_$host.cfg $!";
			print FILE $head.$body;
			close (FILE);
		}
	}
	return @errors;
}


1;

