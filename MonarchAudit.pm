# MonArch - Groundwork Monitor Architect
# MonarchAudit.pm
#
############################################################################
# Release 2.5
# 7-Apr-2008
############################################################################
# Author: Scott Parris
#
# Copyright 2008 GroundWork Open Source, Inc. (GroundWork)  
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

package Audit;

# Command line option for debug
my $folder = '/var/nagios/monarch';
my $debug = 0;

sub auditlog(@) {
	my $appname = shift;
        my $audituser = shift;
	my $auditaction = shift;
	my $auditsection = shift;
	my $auditdata = shift;
	my $actiondate = datetime1();
	chomp($auditdata);
        open (AUDITFILE, ">> $folder/monarchaudit.log");
        print AUDITFILE "$actiondate;$audituser;$auditsection;$auditaction;$auditdata\n";
        close(AUDITFILE);
        return 1;
}

sub datetime1() {
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
        $year += 1900;
        $mon++;
        if ($mon =~ /^\d{1}$/) { $mon = "0".$mon }
        if ($mday =~ /^\d{1}$/) { $mday = "0".$mday }
        if ($hour =~ /^\d{1}$/) { $hour = "0".$hour }
        if ($min =~ /^\d{1}$/) { $min = "0".$min }
        if ($sec =~ /^\d{1}$/) { $sec = "0".$sec }
        return "$year-$mon-$mday $hour:$min:$sec";
}


sub foundation_sync(@) {
	my $folder = $_[1];
	my $force_reload = 0;
	my @errors = ();
	unless ($folder) { $folder = '/usr/local/groundwork/nagios/etc' }
	my %last = ();
	my %current = ();
	my %delta = ();
	if (-e "$folder/config-last.log") { 
		open(FILE, "< $folder/config-last.log") || push @errors, "Error: $folder/config-last.log $!";
		while (my $line = <FILE>) {
			chomp $line;
			my @values = split(/;;/, $line);
			if ($values[0] eq 'host') {
				$last{$values[0]}{$values[1]}{'address'} = $values[3];
			} elsif ($values[0] eq 'service') {
				$last{$values[0]}{$values[3]}{$values[1]} = 1;
			} elsif ($values[0] eq 'hostgroup') {
				my @members = split(/,/, $values[3]);
				foreach my $member (@members) {
					$last{$values[0]}{$values[1]}{$member} = 1;
				}
			} elsif ($values[0] eq 'inactive_host') {
				$last{'hostgroup'}{'__Inactive hosts'}{$values[1]} = 1;
			}	
		}
		close (FILE);
	} else {
		$force_reload = 1;
	}
	if (-e "$folder/config-current.log") { 
		open(FILE, "< $folder/config-current.log") || push @errors, "Error: $folder/config-current.log $!";
		while (my $line = <FILE>) {
			chomp $line;
			my @values = split(/;;/, $line);
			if ($values[0] eq 'host') {
				$delta{'exists'}{'host'}{$values[1]} = 1;
				$current{$values[0]}{$values[1]}{'address'} = $values[3];
			} elsif ($values[0] eq 'service') {
				$delta{'exists'}{'service'}{$values[3]}{$values[1]} = 1;
				$current{$values[0]}{$values[3]}{$values[1]} = 1;
			} elsif ($values[0] eq 'hostgroup') {
				$delta{'exists'}{'hostgroup'}{$values[1]} = 1;
				my @members = split(/,/, $values[3]);
				foreach my $member (@members) {
					$current{$values[0]}{$values[1]}{$member} = 1;
				}
			} elsif ($values[0] eq 'inactive_host') {
				$delta{'exists'}{'hostgroup'}{'__Inactive hosts'} = 1;
				$current{'hostgroup'}{'__Inactive hosts'}{$values[1]} = 1;
			}	
		}
		close (FILE);
	} else {
		push @errors, "Error: $folder/config-current.log is missing.";
	}
	foreach my $type (keys %current) {
		if ($type eq 'host') {
			foreach my $host (sort keys %{$current{'host'}}) {
				if ($last{'host'}{$host}) {
					unless ($last{'host'}{$host}{'address'} eq $current{'host'}{$host}{'address'}) {
						$delta{'alter'}{'host'}{$host}{'address'} = $current{'host'}{$host}{'address'};
					} 
					foreach my $service (keys %{$current{'service'}{$host}}) {
						if ($last{'service'}{$host}{$service}) {
							delete $last{'service'}{$host}{$service};
						} else {
							$delta{'add'}{'service'}{$host}{$service} = 1;
						}
					}
					foreach my $service (keys %{$last{'service'}{$host}}) {
						$delta{'delete'}{'service'}{$host}{$service} = 1;
					}
				} elsif ($force_reload) {
					unless ($current{'host'}{$host}{'address'}) { $current{'host'}{$host}{'address'} = $host } 
					$delta{'add'}{'host'}{$host}{'address'} = $host;
					foreach my $service (keys %{$current{'service'}{$host}}) {
						$delta{'add'}{'service'}{$host}{$service} = 1;
					}
				} else {
					unless ($current{'host'}{$host}{'address'}) { $current{'host'}{$host}{'address'} = $host } 
					$delta{'add'}{'host'}{$host}{'address'} = $host;
					foreach my $service (keys %{$current{'service'}{$host}}) {
						$delta{'add'}{'service'}{$host}{$service} = 1;
					}
				}
				delete $last{'host'}{$host};
			}
			foreach my $host (keys %{$last{'host'}}) {
				$delta{'delete'}{'host'}{$host} = 1;
			}
		}
		if ($type eq 'hostgroup') {
			foreach my $hostgroup (sort keys %{$current{'hostgroup'}}) {
				if ($last{'hostgroup'}{$hostgroup}) {
					foreach my $member (keys %{$current{'hostgroup'}{$hostgroup}}) {
						unless ($last{'hostgroup'}{$hostgroup}{$member}) {
							%{$delta{'alter'}{'hostgroup'}{$hostgroup}{'members'}} = %{$current{'hostgroup'}{$hostgroup}};
						} 
					}
					foreach my $member (keys %{$last{'hostgroup'}{$hostgroup}}) {
						unless ($current{'hostgroup'}{$hostgroup}{$member}) {
							%{$delta{'alter'}{'hostgroup'}{$hostgroup}{'members'}} = %{$current{'hostgroup'}{$hostgroup}};
						} 
					}
				} elsif ($force_reload) {
					%{$delta{'alter'}{'hostgroup'}{$hostgroup}{'members'}} = %{$current{'hostgroup'}{$hostgroup}};
				} else {
					%{$delta{'add'}{'hostgroup'}{$hostgroup}{'members'}} = %{$current{'hostgroup'}{$hostgroup}};
				}
				delete $last{'hostgroup'}{$hostgroup};
			}		
			foreach my $hostgroup (keys %{$last{'hostgroup'}}) {
				$delta{'delete'}{'hostgroup'}{$hostgroup} = 1;
			}
		}
	}
	if (-e "$folder/config-last.log") { 
		unlink "$folder/config-last.log";
	}
	rename "$folder/config-current.log", "$folder/config-last.log" || die $!;
	return %delta;
}

# debug 
if ($debug) {
	my %delta = foundation_sync('',$folder);

	my $count = keys %{$delta{'delete'}{'host'}};
	print "\n\n removing $count hosts...";
	foreach my $host (sort keys %{$delta{'delete'}{'host'}}) {
		print "\n\thost $host";
	}
	$count = keys %{$delta{'add'}{'host'}};
	print "\n\n adding $count hosts...";
	foreach my $host (sort keys %{$delta{'add'}{'host'}}) {
		print "\n\thost $host";
	}
	$count = keys %{$delta{'alter'}{'host'}};
	print "\n\n updating $count hosts...";
	foreach my $host (sort keys %{$delta{'alter'}{'host'}}) {
		print "\n\n\thost $host $delta{'alter'}{'host'}{$host}{'address'}";
	}

	$count = keys %{$delta{'delete'}{'service'}};
	print "\n\n removing $count services from hosts\n";
	foreach my $host (sort keys %{$delta{'delete'}{'service'}}) {
		foreach my $service (sort keys %{$delta{'delete'}{'service'}{$host}}) {
			print "\n\thost $host service $service";
		}
	}
	$count = keys %{$delta{'add'}{'service'}};
	print "\n\n adding services to $count hosts...";
	foreach my $host (sort keys %{$delta{'add'}{'service'}}) {
		foreach my $service (sort keys %{$delta{'add'}{'service'}{$host}}) {
			print "\n\thost $host service $service";
		}
	}

	$count = keys %{$delta{'add'}{'hostgroup'}};
	print "\n\n adding $count hostgroups...";
	foreach my $hostgroup (sort keys %{$delta{'add'}{'hostgroup'}}) {
		print "\n\thostgroup $hostgroup";
		foreach my $host (sort keys %{$delta{'add'}{'hostgroup'}{$hostgroup}{'members'}}) {
			print "\n\thost $host";
		}
	}
	$count = keys %{$delta{'delete'}{'hostgroup'}};
	print "\n\n removing $count hostgroups\n";
	foreach my $hostgroup (sort keys %{$delta{'delete'}{'hostgroup'}}) {
		print "\n\thostgroup $hostgroup";
	}
	my $cnt = 0;
	$count = keys %{$delta{'alter'}{'hostgroup'}};
	print "\n\n updating $count hostgroups\n";
	foreach my $hostgroup (sort keys %{$delta{'alter'}{'hostgroup'}}) {
		$cnt++;
		print "\n\n\n$cnt $hostgroup\n\n";
		foreach my $host (sort keys %{$delta{'alter'}{'hostgroup'}{$hostgroup}{'members'}}) {
			print "\n\thostgroup $hostgroup host $host";
		}
	}
}

1;

