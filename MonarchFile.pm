# MonArch - Groundwork Monitor Architect
# MonarchFile.pm
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
#use warnings;
use MonarchStorProc;

package Files;

my %options = (); # Hash to hold the instructions for generating files
my @errors = ();
my %use = (); # Tracks which contacts, contact groups, host groups, etc, will be used for a particular instance 
my @out_files = (); # Holds the list of files for nagios.cfg and export presentation
my @extinfofiles = (); # For Nagios 1.x extended info files for nagios.cgi 
my @group_process_order = (); # Holds the parent-child order to process configuration groups
my %property_list = (); # Hash containing Nagios directives by object type
my ($audit, $log) = undef; # $log gathers content for foundation sync when $audit is set
my $log_file = "config-current.log"; # Audit file name
my $date_time = undef; # timestamp for file headers
my $group = undef; # 
my $destination = undef;


my %commands = (); # Holds the contents of the commands table (sub get_commands)
my %command_name = (); # Used to translate id to name 

my %timeperiods = (); # Holds the contents of the time_periods table (sub get_timeperiodss)
my %timeperiod_name = (); # Used to translate id to name 

my %host_extinfo_templates = (); # Holds the contents of the extended_host_info_templates table (sub get_exthostifo)
my %hostextinfo_name = (); # Used to translate template id to name 

my %host_templates = (); # Holds the contents of the host_templates table (sub get_host_templates)
my %hosttemplate_name = (); # Used to translate id to name 

my %hosts = (); # Stores all host records and their services
my %host_name = (); # Used to resolve host ids to names
my %host_name_id = (); # Used to resolve host names to ids
my %address = ();
my %host_groups = (); # Holds all info for host groups
my %hostgroup_name = (); # Used to translate id to name 
my %hosts_not_in_hostgroup = (); # Holder for unassigned hosts
my %host_dependencies = (); # Holds the contents of the host_dependencies table (sub host_dependencies)

my %service_templates = (); # Holds the contents of the service_templates table (sub get_services)
my %servicetemplate_name = (); # Used to translate id to name 
my %service_groups = (); # Holds service group data (sub get_services)
my %service_instances = (); # Holds the contents of the service_instances table (sub get_services)
my %servicename_name = (); # Used to translate servicename_id to name 

my %service_extinfo_templates = (); # Holds the contents of the extended_service_info_templates table (sub get_services)
my %serviceextinfo_name = (); # Used to translate id to name 
my %notes = (); # Assigned and translated from templates (sub process_serviceextinfo) to service extended info (sub process_services) 
my %notes_url = (); # same as %notes
my %action_url = (); # same as %notes

my %service_dependency_templates = (); # Holds the contents of the service_dependency_templates table (sub get_services)
my %service_dependencies = (); # Holds the contents of the service_dependencies table (sub get_services)

my %escalation_templates = (); # Holds the contents of the escalation_templates table (sub get_escalations)
my %escalation_name_id = (); # Used to translate escalation template id to name 
my %escalation_trees = (); # Holds the contents of the escalation_trees table (sub get_escalations)
my %escalation_tree_name = (); # Used to translate escalation tree id to name 

my %contact_groups = (); # Holds the contents of the contact_groups table (sub get_contact_groups)
my %contactgroup_name = (); # Used to translate id to name 
my %contactgroup_contact = (); # Holds contacts by contact groups (sub get_contact_groups) 

my %contacts = (); # Holds the contents of the contacts table (sub get_contacts)
my %contact_name = (); # Used to translate id to name 
my %contact_command_overrides = (); # Holds contents of the contact_command_overrides table by contact id (sub get_contacts)
my %contact_overrides = (); # Holds contents of the contact_command table by contact id (sub get_contacts)

my %contact_templates = (); # Holds the contents of the contact_templates table (sub get_contacts)
my %contact_template_name = (); # Used to translate id to name 

my %monarch_groups = (); # Holds all configuration groups
my %group_names = (); # Translates name to id
my %group_hosts = (); # Hash holds the list of configuration groups to process 
my %inactive_hosts = (); # Hosts to be excluded by processing
my %host_service_group = (); # 
my %host_group = (); # Associates a host with its configuration group
my %parent_checks = ();
my %parents_all = ();
my %parent_top = ();

my %nagios_cgi = ();
my %nagios_cfg = ();
my %resource_cfg = ();
my %nagios_cfg_misc = ();

my $debug = 0;

# This sub formats all objects for printing to file
sub format_obj(@) {
	my $props = shift;
	my $type = shift;
	my $object = shift;
	my @props = @{ $props };
	my %object = %{ $object };
	my $register = 0;
	my $obj_log = "\n$type";
	if ($type =~ /_template/) {
		$type =~ s/_template//;
		$register = 1;
	}

	if (! defined($object{'comment'}) || $object{'comment'} !~ /\n$/) { $object{'comment'} .= "\n" }
	my $objout = qq(\n$object{'comment'}define $type \{);

	my ($tabs, $got_props, $prop);
	foreach $prop (@props) {
		my $pname = $prop;
		if ($prop eq 'template')                                        { $pname = 'use' }
		if ($type eq 'contactgroup' && $prop eq 'name')                 { $pname = 'contactgroup_name' }
		if ($type eq 'contact' && $prop eq 'name')                      { $pname = 'contact_name' }
		if ($type eq 'contact' && $prop eq 'name')                      { $pname = 'contact_name' }
		if ($type eq 'service' && $prop eq 'name')                      { $pname = 'service_description' }
		if ($type eq 'servicegroup' && $prop eq 'name')                 { $pname = 'servicegroup_name' }
		if ($type eq 'service_dependency' && $prop eq 'service_name')   { $pname = 'dependent_service_description' }
		if ($type eq 'service_dependency' && $prop eq 'host_name')      { $pname = 'dependent_host_name' }
		if ($type eq 'service_dependency' && $prop eq 'depend_on_host') { $pname = 'host_name' }
		if ($type eq 'hostgroup_escalation' && $prop eq 'name')         { $pname = 'hostgroup_name' }
		if ($type eq 'host_escalation' && $prop eq 'name')              { $pname = 'host_name' }
		if ($type eq 'timeperiod' && $prop eq 'name')                   { $pname = 'timeperiod_name' }
		if ($type eq 'command' && $prop eq 'name')                      { $pname = 'command_name' }
		if ($type eq 'hostgroup' && $prop eq 'name')                    { $pname = 'hostgroup_name' }
		if ($type eq 'hostgroup' && $prop =~ /hostgroup_escalation_id|host_escalation_id|service_escalation_id/) { next }
		if ($type eq 'host' && $prop eq 'name')                         { $pname = 'host_name' }
		if ($prop eq 'contactgroup')                                    { $pname = 'contact_groups' }
		if ($register && $prop eq 'name')                               { $pname = 'name' }
		if ($object{$prop}) {
			$object{$prop} =~ s/-zero-/0/g;
			my $length = length($pname);
			if ($length < 8) {
				$tabs = "\t\t\t\t";
			} elsif ($length < 16) {
				$tabs = "\t\t\t";
			} elsif ($length < 24) {
				$tabs = "\t\t";
			} else {
				$tabs = "\t";
			}
			my $obj_prop = $object{$prop};
			$objout .= qq(
	$pname$tabs$obj_prop);
			$obj_prop =~ s/;;/-/g;
			$obj_log .= ";;$obj_prop";
		}
		$tabs = undef;
	}
	if ($register) {	
		$objout .= qq(
	register			0);
	}
	$objout .= "\n}\n";
	if ($audit && $type =~ /^host$|^hostgroup$|^service$/) {
		unless ($register) { $log .= "$obj_log" }
	}
	return $objout;
}

sub write_to_text_file {
	my $file = shift || return "Error: write_to_text_file() requires filename argument";
	my $text = shift || return "Error: write_to_text_file() requires output text argument";

    open(FILE, "> $file") or return "Error: Unable to open $file $!";
    print FILE $text;
    close (FILE);
    return;
}


############################################################################
# Time periods
############################################################################

sub get_timeperiods() {
	my %where = ();
	my %timeperiod_hash_array = StorProc->fetch_list_hash_array('time_periods',\%where); 
	foreach my $id (keys %timeperiod_hash_array) {
		$timeperiod_name{$id} = $timeperiod_hash_array{$id}[1];
		$timeperiods{$id}{'name'} = $timeperiod_hash_array{$id}[1];
		$timeperiods{$id}{'alias'} = $timeperiod_hash_array{$id}[2];
		$timeperiods{$id}{'comment'} = $timeperiod_hash_array{$id}[4];
		my %data = StorProc->parse_xml($timeperiod_hash_array{$id}[3]);
		foreach my $name (keys %data) {
			$timeperiods{$id}{$name} = $data{$name}; 
		}
	}
}

sub process_timeperiods() {
	my $outfile = qq(##########GROUNDWORK#############################################################################################
#GW
#GW\ttimeperiods.cfg generated $date_time by $options{'user_acct'} from monarch.cgi nagios v $options{'nagios_version'}
#GW
##########GROUNDWORK#############################################################################################
);	
	my @props = split(/,/, $property_list{'time_periods'});
	foreach my $id (sort {$timeperiod_name{$a} cmp $timeperiod_name{$b}} keys %timeperiods) {
		$outfile .= format_obj(\@props,'timeperiod',\%{$timeperiods{$id}});
	}
	push @out_files, 'time_periods.cfg';
	my $error = write_to_text_file("$destination/time_periods.cfg", $outfile);
	push(@errors, $error) if (defined($error));
}


############################################################################
# Commands
############################################################################

sub get_commands() {
	my %where = ();
	my %commands_hash_array = StorProc->fetch_list_hash_array('commands',\%where); 
	foreach my $id (keys %commands_hash_array) {
		$command_name{$id} = $commands_hash_array{$id}[1];
		$commands{$id}{'name'} = $commands_hash_array{$id}[1];
		$commands{$id}{'type'} = $commands_hash_array{$id}[2];
		$commands{$id}{'comment'} = $commands_hash_array{$id}[4];
		my %data = StorProc->parse_xml($commands_hash_array{$id}[3]);
		foreach my $name (keys %data) {
			$commands{$id}{$name} = $data{$name}; 
		}
	}
}

sub process_commands() {
	my $out_check = qq(##########GROUNDWORK#############################################################################################
#GW
#GW\tcheck_commands.cfg generated $date_time by $options{'user_acct'} from monarch.cgi nagios v $options{'nagios_version'}
#GW
##########GROUNDWORK#############################################################################################
);	
	my $out_misc = qq(##########GROUNDWORK#############################################################################################
#GW
#GW\tmisccommands.cfg generated $date_time by $options{'user_acct'} from monarch.cgi nagios v $options{'nagios_version'}
#GW
##########GROUNDWORK#############################################################################################
);

	my @props = ('name','command_line');
	foreach my $id (sort {$command_name{$a} cmp $command_name{$b}} keys %command_name) {
		my %command = %{$commands{$id}};
		if ($command{'type'} eq 'check') {
			$out_check .= format_obj(\@props,'command',\%command);
		} else {
			$out_misc .= format_obj(\@props,'command',\%command);
		}
	}
	push @out_files, 'check_commands.cfg';
	my $error = write_to_text_file("$destination/check_commands.cfg", $out_check);
	push(@errors, $error) if (defined($error));
	push @out_files, 'misccommands.cfg';
	$error = write_to_text_file("$destination/misccommands.cfg", $out_misc);
	push(@errors, $error) if (defined($error));
}


############################################################################
# Host extended info
############################################################################

sub get_hostextinfo() {
	%host_extinfo_templates = StorProc->get_hostextinfo_templates();
}

sub process_hostextinfo() {
	my $outfile = qq(##########GROUNDWORK#############################################################################################
#GW
#GW\textended_host_info_templates.cfg generated $date_time by $options{'user_acct'} from monarch.cgi nagios v $options{'nagios_version'}
#GW
##########GROUNDWORK#############################################################################################
);	

	my @props = split(/,/, $property_list{'extended_host_info_templates'});	
	foreach my $name (sort keys %host_extinfo_templates) {
		$hostextinfo_name{$host_extinfo_templates{$name}{'id'}} = $name;
		$notes{$host_extinfo_templates{$name}{'id'}} = $host_extinfo_templates{$name}{'notes'} unless $options{'nagios_version'} eq '1.x';
		$notes_url{$host_extinfo_templates{$name}{'id'}} = $host_extinfo_templates{$name}{'notes_url'};
		$action_url{$host_extinfo_templates{$name}{'id'}} = $host_extinfo_templates{$name}{'action_url'} unless $options{'nagios_version'} eq '1.x';
		delete $host_extinfo_templates{$name}{'notes_url'};
		delete $host_extinfo_templates{$name}{'action_url'};
		delete $host_extinfo_templates{$name}{'notes'};
		$outfile .= format_obj(\@props,'hostextinfo_template',\%{$host_extinfo_templates{$name}});
	}

	if ($options{'nagios_version'}  =~ /^[23]\.x$/) {
		push @out_files, 'extended_host_info_templates.cfg';
	} else {
		push @extinfofiles, 'extended_host_info_templates.cfg';
	}
	my $error = write_to_text_file("$destination/extended_host_info_templates.cfg", $outfile);
	push(@errors, $error) if (defined($error));
}


############################################################################
# Contact groups
############################################################################

sub get_contact_groups() {
	my %where = ();
	my %contactgroup_hash_array = StorProc->fetch_list_hash_array('contactgroups',\%where);
	foreach my $id (keys %contactgroup_hash_array) {
		my $cname = $contactgroup_hash_array{$id}[1];
		$contactgroup_name{$id} = $cname;
		$contact_groups{$cname}{'name'} = $cname;
		$contact_groups{$cname}{'id'} = $id;
		$contact_groups{$cname}{'alias'} = $contactgroup_hash_array{$id}[2];
		$contact_groups{$cname}{'comment'} = $contactgroup_hash_array{$id}[3];
	}
	my %contactgroup_contact_hash_array = StorProc->fetch_hash_array_generic_key('contactgroup_contact',\%where);
	foreach my $key (keys %contactgroup_contact_hash_array) {
		my $cname = $contactgroup_name{$contactgroup_contact_hash_array{$key}[0]};
		push @{$contactgroup_contact{$cname}}, $contact_name{$contactgroup_contact_hash_array{$key}[1]};
	}
}

sub process_contactgroups() {
	my $outfile = qq(##########GROUNDWORK#############################################################################################
#GW
#GW\tcontact_groups.cfg generated $date_time by $options{'user_acct'} from monarch.cgi nagios v $options{'nagios_version'}
#GW
##########GROUNDWORK#############################################################################################
);	
	my @props = split(/,/, $property_list{'contactgroups'});
	push @props, 'members';	
	foreach my $cname (sort keys %{$use{'contactgroups'}}) {	
		my %contactgroup = %{$contact_groups{$cname}};	
		foreach my $contact (@{$contactgroup_contact{$cname}}) {
			$contactgroup{'members'} .= "$contact,";
			$use{'contacts'}{$contact} = 1;
		}
		chop $contactgroup{'members'};
		$contactgroup{'name'} =~ s/\s/-/g;
		$outfile .= format_obj(\@props,'contactgroup',\%contactgroup);
	}

	push @out_files, 'contact_groups.cfg';
	my $error = write_to_text_file("$destination/contact_groups.cfg", $outfile);
	push(@errors, $error) if (defined($error));
}


############################################################################
# Host templates
############################################################################

sub get_host_templates() {
	my %where = ();
	my %host_template_contactgroup = StorProc->fetch_hash_array_generic_key('contactgroup_host_template',\%where);
	my %host_template_hash_array = StorProc->fetch_list_hash_array('host_templates',\%where);
	foreach my $id (keys %host_template_hash_array) {
		my $tname = $host_template_hash_array{$id}[1];
		$hosttemplate_name{$id} = $tname;
		$host_templates{$tname}{'id'} = $id;
		$host_templates{$tname}{'check_period'} = $host_template_hash_array{$id}[2];
		$host_templates{$tname}{'notification_period'} = $host_template_hash_array{$id}[3];
		$host_templates{$tname}{'check_command'} = $host_template_hash_array{$id}[4];
		$host_templates{$tname}{'event_handler'} = $host_template_hash_array{$id}[5];
		my %data = StorProc->parse_xml($host_template_hash_array{$id}[6]);
		# host template comment not used? would be $host_template_hash_array{$id}[7];
		foreach my $name (keys %data) {
			$host_templates{$tname}{$name} = $data{$name}; 
		}
	}
	foreach my $key (keys %host_template_contactgroup) {
		# get the hosttemplate_id ([1]) from %host_template_contactgroup, and use it as a key
		# to dereference hosttemplate_name, returning the name for the hosttemplate.
		my $tname = $hosttemplate_name{$host_template_contactgroup{$key}[1]};
		# now get the contactgroup id ([0]) and push it onto the contactgroups array for the $tname host template
		push @{$host_templates{$tname}{'contactgroups'}}, $host_template_contactgroup{$key}[0];
	}
	
}

sub process_host_templates() {
	my $outfile = qq(##########GROUNDWORK#############################################################################################
#GW
#GW\thost_templates.cfg generated $date_time by $options{'user_acct'} from monarch.cgi nagios v $options{'nagios_version'}
#GW
##########GROUNDWORK#############################################################################################
);		
	
	my @props = split(/,/, $property_list{'host_templates'});	
	if ($options{'nagios_version'} eq '2.x') { push @props, 'contact_groups' }
	foreach my $name (sort keys %host_templates) {
		my %template = ();
		my $command_line = undef;
		foreach my $prop (keys %{$host_templates{$name}}) {
			if ($prop eq 'contactgroups') {
				foreach my $cgid (@{$host_templates{$name}{'contactgroups'}}) {
					my $cg = $contactgroup_name{$cgid};
					$cg =~ s/\s/-/g;
					$template{'contact_groups'} .= "$cg,";
					$use{'contactgroups'}{$contactgroup_name{$cgid}} = 1;
				}
				chop $template{'contact_groups'};
			} elsif ($prop eq 'event_handler' || $prop eq 'check_command') {
				$template{$prop} = $command_name{$host_templates{$name}{$prop}};
			} elsif ($prop =~ /^check_period$|^notification_period$/) {
				$template{$prop} = $timeperiod_name{$host_templates{$name}{$prop}};
			} elsif ($prop eq 'command_line') {
				$command_line = $host_templates{$name}{$prop};
			} else {
				$template{$prop} = $host_templates{$name}{$prop};
			}
		}
		if ($command_line) { $template{'check_command'} = $command_line	}
		$template{'name'} = $name;
		$outfile .= format_obj(\@props,'host_template',\%template);
	}
	push @out_files, 'host_templates.cfg';
	my $error = write_to_text_file("$destination/host_templates.cfg", $outfile);
	push(@errors, $error) if (defined($error));
}


############################################################################
# Host groups
############################################################################

sub get_hostgroups() {
	my %where = ();
	my %hostgroup_host = StorProc->fetch_hash_array_generic_key('hostgroup_host',\%where);
	my %hostgroup_hash_array = StorProc->fetch_list_hash_array('hostgroups',\%where);
	foreach my $id (keys %hostgroup_hash_array) {
		my $hname = $hostgroup_hash_array{$id}[1];
		$hostgroup_name{$id} = $hname;
		$host_groups{$hname}{'name'} = $hname;
		$host_groups{$hname}{'id'} = $id;
		$host_groups{$hname}{'alias'} = $hostgroup_hash_array{$id}[2];
		# hostprofile id not used - not a nagios concept. so no [3]
		$host_groups{$hname}{'host_escalation_id'} = $hostgroup_hash_array{$id}[4];
		$host_groups{$hname}{'service_escalation_id'} = $hostgroup_hash_array{$id}[5];
		# status [6]
		$host_groups{$hname}{'comment'} = $hostgroup_hash_array{$id}[7];
		@{$host_groups{$hname}{'members'}} = ();
	}
	foreach my $key (keys %hostgroup_host) {
		my $hgname = $hostgroup_name{$hostgroup_host{$key}[0]};
		# %host_name gets populated in get_hosts(), so that should be called before this.
		push @{$host_groups{$hgname}{'members'}}, $host_name{$hostgroup_host{$key}[1]};
		push @{$hosts{$host_name{$hostgroup_host{$key}[1]}}{'hostgroups'}}, $hgname;
	}
}

sub process_hostgroups() {	
	my $outfile = qq(##########GROUNDWORK#############################################################################################
#GW
#GW\thostgroups.cfg generated $date_time by $options{'user_acct'} from monarch.cgi nagios v $options{'nagios_version'}
#GW
##########GROUNDWORK#############################################################################################
);		
	
	my @props = split(/,/, $property_list{'hostgroups'});	
	if ($options{'nagios_version'} eq '1.x') { push @props, 'contact_groups' }
	foreach my $name (sort keys %host_groups) {
		my %hostgroup = ();
		$hostgroup{'name'} = $name;
		$hostgroup{'alias'} = $host_groups{$name}{'alias'};
		$hostgroup{'comment'} = $host_groups{$name}{'comment'};
		foreach my $host (sort @{$host_groups{$name}{'members'}}) {
			if ($use{'hosts'}{$host}) { 
				$hostgroup{'members'} .= "$host,";
				delete $hosts_not_in_hostgroup{$host}; 	
			}
		}
		chop $hostgroup{'members'};
		if ($options{'nagios_version'} eq '1.x') {
			foreach my $cg (sort @{$host_groups{$name}{'contactgroups'}}) {
				$use{'contactgroups'}{$cg} = 1;
				$cg =~ s/\s/-/g;
				$hostgroup{'contact_groups'} .= "$cg,";
			}
			chop $hostgroup{'contact_groups'};
		}
		if ($hostgroup{'members'}) {
			$outfile .= format_obj(\@props,'hostgroup',\%hostgroup);
			$use{'hostgroups'}{$name} = 1;
		}
	}
	my $members = undef;
	foreach my $host (sort keys %hosts_not_in_hostgroup) { $members .= "$host," }
	chop $members;
	if ($audit && $members) {	$log .= "\nhostgroup;;__Hosts not in any host group;;alias;;$members" }

	push @out_files, 'hostgroups.cfg';
	my $error = write_to_text_file("$destination/hostgroups.cfg", $outfile);
	push(@errors, $error) if (defined($error));
}

############################################################################
# Hosts
############################################################################


sub get_hosts() {
	my %where = ();
	my %host_hash_array = StorProc->fetch_list_hash_array('hosts',\%where);
	foreach my $id (keys %host_hash_array) {
		my $hname = $host_hash_array{$id}[1];
		$host_name{$id} = $hname;
		$host_name_id{$hname} = $id;
		$hosts{$hname}{'name'} = $hname;
		$hosts{$hname}{'id'} = $id;
		$hosts{$hname}{'alias'} = $host_hash_array{$id}[2];
		$hosts{$hname}{'address'} = $host_hash_array{$id}[3];
		# [4] os
		$hosts{$hname}{'hosttemplate_id'} = $host_hash_array{$id}[5];
		$hosts{$hname}{'hostextinfo_id'} = $host_hash_array{$id}[6];
		# [7] hostprofile_id
		$hosts{$hname}{'host_escalation_id'} = $host_hash_array{$id}[8];
		$hosts{$hname}{'service_escalation_id'} = $host_hash_array{$id}[9];
		# [10] status
		$hosts{$hname}{'comment'} = $host_hash_array{$id}[11];
		@{$hosts{$hname}{'contactgroups'}} = ();
		@{$hosts{$hname}{'hostgroups'}} = ();
		%{$hosts{$hname}{'overrides'}} = ();
		%{$hosts{$hname}{'extended_info_coords'}} = ();
		%{$hosts{$hname}{'services'}} = (); 
	}
	
# Organize host overrides
	my %host_override_hash_array = StorProc->fetch_list_hash_array('host_overrides',\%where);
	foreach my $id (keys %host_override_hash_array) {
		my %overrides = ();
		$overrides{'check_period'} = $host_override_hash_array{$id}[1];
		$overrides{'notification_period'} = $host_override_hash_array{$id}[2];
		$overrides{'check_command'} = $host_override_hash_array{$id}[3];
		$overrides{'event_handler'} = $host_override_hash_array{$id}[4];
		my %data = StorProc->parse_xml($host_override_hash_array{$id}[5]);
		foreach my $name (keys %data) {
			$overrides{$name} = $data{$name}; 
		}
		%{$hosts{$host_name{$id}}{'overrides'}} = %overrides;
	}

# Assign contact groups to host records
	my %host_contactgroup = StorProc->fetch_hash_array_generic_key('contactgroup_host',\%where);
	foreach my $key (keys %host_contactgroup) {
		push @{ $hosts{$host_name{$host_contactgroup{$key}[1]}}{'contactgroups'}}, $contactgroup_name{$host_contactgroup{$key}[0]};
	}

# Assign parents to host records
	my %host_parent = StorProc->fetch_hash_array_generic_key('host_parent',\%where);
	foreach my $key (keys %host_parent) {
		if ($host_name{$host_parent{$key}[1]} && $host_name{$host_parent{$key}[0]}) {
			$hosts{$host_name{$host_parent{$key}[0]}}{'parents'} .= "$host_name{$host_parent{$key}[1]},";
		}
	}

# Assign extended info coords
	my %extended_info_coords = StorProc->fetch_hash_array_generic_key('extended_info_coords',\%where);
	foreach my $key (keys %extended_info_coords) {
		%{$hosts{$host_name{$extended_info_coords{$key}[0]}}{'extended_info_coords'}} = StorProc->parse_xml($extended_info_coords{$key}[1]);
	}
}


sub process_hosts() {
	my %address = ();
	my %files = ();
	my %force_hosts = ();
	foreach my $grp (@group_process_order) {
		@{$host_service_group{$grp}{'hosts'}} = ();
		%{$host_service_group{$grp}{'macros'}} = ();
		if ($group_hosts{$grp}{'macros'}) { %{$host_service_group{$grp}{'macros'}} = %{$group_hosts{$grp}{'macros'}}; }
		if ($group_hosts{$grp}{'label_enabled'} && $group_hosts{$grp}{'label'}) {
			$host_service_group{$grp}{'label'} = "$group_hosts{$grp}{'label'}";
		}				
		foreach my $host (sort keys %{$group_hosts{$grp}{'hosts'}}) {
			if ($audit && $inactive_hosts{$host_name{$host}}) { $log .= "\ninactive_host;;$host" }
			# check to see if parent group has force hosts chceked
			if ($group_hosts{$group}{'use_hosts'}) {
				# use parent hosts
				if ($group_hosts{$group}{'hosts'}{$host}) { 
					$use{'hosts'}{$host} = 1;
					$host_group{$host} = $grp;
					push @{$host_service_group{$grp}{'hosts'}}, $host;
				}
			} else {
				$use{'hosts'}{$host} = 1;
				$host_group{$host} = $grp;
				push @{$host_service_group{$grp}{'hosts'}}, $host;
			}
		}
		foreach my $hostgroup (sort keys %{$group_hosts{$grp}{'hostgroups'}}) {			
			foreach my $host (@{$host_groups{$hostgroup}{'members'}}) { 
				if ($audit && $inactive_hosts{$host_name{$host}}) { $log .= "inactive_host;;$host\n" }
				$host_group{$host} = $grp;
				# check to see if parent group has force hosts checked
				if ($group_hosts{$group}{'hosts'}{$host}) {
					# use parent hosts
					if ($group_hosts{$group}{'hosts'}{$host}) { 
						$use{'hosts'}{$host} = 1;
						$host_group{$host} = $grp;
						push @{$host_service_group{$grp}{'hosts'}}, $host;
					}
				} else {
					$use{'hosts'}{$host} = 1;
					$host_group{$host} = $grp;
					push @{$host_service_group{$grp}{'hosts'}}, $host;
				}
			}
		}
	}

	my $extinfofile = undef;
	my @props = ('name','alias','address','template','parents','checks_enabled','active_checks_enabled','passive_checks_enabled',
		'check_interval','check_period','obsess_over_host','check_command','command_line','max_check_attempts','event_handler_enabled',
		'event_handler','process_perf_data','retain_status_information','retain_nonstatus_information','notifications_enabled',
		'notification_interval','notification_period','notification_options','stalking_options','flap_detection_enabled',
		'high_flap_threshold','low_flap_threshold','check_freshness','freshness_threshold');

	if ($options{'nagios_version'} =~ /^[23]\.x$/) { push @props, 'contact_groups' }
	my @extinfoprops = split(/,/, $property_list{'extended_host_info'});
	foreach my $host (sort keys %host_group) {
		my %host = %{$hosts{$host}};
		$host{'template'} = $hosttemplate_name{$host{'hosttemplate_id'}};
		chop $host{'parents'}; # removes trailing comma from above	
		if ($options{'nagios_version'} =~ /^[23]\.x$/) {
			my @contactgroups = @{$host{'contactgroups'}};
			foreach my $cg (@contactgroups) { 
				$use{'contactgroups'}{$cg} = 1;
				$cg =~ s/\s/-/g; # Nagios didn't like spaces in contact group names
				$host{'contact_groups'} .= "$cg,";
			}
			chop $host{'contact_groups'};
			unless ($host{'contact_groups'}) {
				foreach my $hostgroup (@{$host{'hostgroups'}}) {
					my %cg_use = ();
					foreach my $cg (@{$host_groups{$hostgroup}{'contactgroups'}}) { 
						unless ($cg_use{$cg}) {
							$use{'contactgroups'}{$cg} = 1;
							$cg_use{$cg} = 1;
							$cg =~ s/\s/-/g;
							$host{'contact_groups'} .= "$cg,";
						}
					}
				}
				chop $host{'contact_groups'};
				unless ($host{'contact_groups'}) {
					if ($group_hosts{$host_group{$host}}{'contactgroups'}) {
						foreach my $cg (sort keys %{$group_hosts{$host_group{$host}}{'contactgroups'}}) {
							$use{'contactgroups'}{$cg} = 1;
							$cg =~ s/\s/-/g;
							$host{'contact_groups'} .= "$cg,";
						}
						chop $host{'contact_groups'};
					}
				}
			}
		}
		$address{$host} = $host{'address'};
		my %overrides = %{$hosts{$host}{'overrides'}};
		foreach my $name (keys %overrides) {
			if ($options{'nagios_version'} eq '2.x' && $name eq 'check_period') {
				$host{'check_period'} = $timeperiod_name{$overrides{$name}};
			} elsif ($name eq 'notification_period') {
				$host{'notification_period'} = $timeperiod_name{$overrides{$name}};			
			} elsif ($name eq 'check_command') {
				$host{'check_command'} = $command_name{$overrides{$name}};	
			} elsif ($name eq 'event_handler') {
				$host{'event_handler'} = $command_name{$overrides{$name}};		
			} elsif ($name eq 'check_freshness') {
				unless ($options{'nagios_version'} eq '1.x') { $host{$name} = $overrides{$name} }
			} elsif ($name eq 'freshness_threshold') {
				unless ($options{'nagios_version'} eq '1.x') { $host{$name} = $overrides{$name} }
			} elsif ($name eq 'obsess_over_host') {
				unless ($options{'nagios_version'} eq '1.x') { $host{$name} = $overrides{$name} }
			} elsif ($name eq 'active_checks_enabled') {
				unless ($options{'nagios_version'} eq '1.x') { $host{$name} = $overrides{$name} }
			} elsif ($name eq 'passive_checks_enabled') {
				unless ($options{'nagios_version'} eq '1.x') { $host{$name} = $overrides{$name} }
			} elsif ($name eq 'checks_enabled') {
				if ($options{'nagios_version'} eq '1.x') { $host{$name} = $overrides{$name} }
			} else {
				$host{$name} = $overrides{$name};
			}
		}
		# if force checks on the parent group (building an instance) is checked override checks enabled
		if	($parent_checks{'use_checks'}) {
			if ($options{'nagios_version'} =~ /^[23]\.x$/) {
				$host{'active_checks_enabled'} = $parent_checks{'active_checks_enabled'};
				$host{'passive_checks_enabled'} = $parent_checks{'passive_checks_enabled'};
			} else {
				$host{'checks_enabled'} = 1;
			}
		}
		if ($host{'hostextinfo_id'}) {
			my %host_extinfo = ();
			my %coords = %{$hosts{$host}{'extended_info_coords'}};
			$host_extinfo{$host}{'2d_coords'} = $coords{'2d_coords'};
			$host_extinfo{$host}{'3d_coords'} = $coords{'3d_coords'};
			$host_extinfo{$host}{'host_name'} = $host;
			$host_extinfo{$host}{'template'} = $hostextinfo_name{$host{'hostextinfo_id'}};
			$host_extinfo{$host}{'notes'} = $notes{$host{'hostextinfo_id'}};
			$host_extinfo{$host}{'notes'} =~ s/\$HOSTNAME\$/$host/g;
			$host_extinfo{$host}{'notes'} =~ s/\$HOSTADDRESS\$/$host{'address'}/g;
			$host_extinfo{$host}{'notes_url'} = $notes_url{$host{'hostextinfo_id'}};
			$host_extinfo{$host}{'notes_url'} =~ s/\$HOSTNAME\$/$host/g;
			$host_extinfo{$host}{'notes_url'} =~ s/\$HOSTADDRESS\$/$host{'address'}/g;
			$host_extinfo{$host}{'action_url'} = $action_url{$host{'hostextinfo_id'}} unless $options{'nagios_version'} eq '1.x';
			$host_extinfo{$host}{'action_url'} =~ s/\$HOSTNAME\$/$host/g unless $options{'nagios_version'} eq '1.x';
			$host_extinfo{$host}{'action_url'} =~ s/\$HOSTADDRESS\$/$host{'address'}/g unless $options{'nagios_version'} eq '1.x';
			$extinfofile .= format_obj(\@extinfoprops,'hostextinfo',\%{$host_extinfo{$host}});
		}
		$hosts_not_in_hostgroup{$host} = 1;
		$files{$host_group{$host}} .= format_obj(\@props,'host',\%host);
	}

	foreach my $grp (sort keys %files) {
		my $file = 'hosts.cfg';
		if ($grp eq ':all:') {
			$file = "hosts.cfg";
		} else {
			$file = "$grp\_hosts.cfg";
		}
		my $outfile = qq(##########GROUNDWORK#############################################################################################
#GW
#GW\t$file generated $date_time by $options{'user_acct'} from monarch.cgi nagios v $options{'nagios_version'}
#GW
##########GROUNDWORK#############################################################################################

$files{$grp}
);	
		push @out_files, $file;
		my $error = write_to_text_file("$destination/$file", $outfile);
		push(@errors, $error) if (defined($error));
	}

	@extinfofiles = ();

	my $outfile = qq(##########GROUNDWORK#############################################################################################
#GW
#GW\textended_host_info.cfg generated $date_time by $options{'user_acct'} from monarch.cgi nagios v $options{'nagios_version'}
#GW
##########GROUNDWORK#############################################################################################

$extinfofile
);	

	if ($options{'nagios_version'}  eq '2.x') {
		push @out_files, 'extended_host_info.cfg';
	} else {
		push @extinfofiles, 'extended_host_info.cfg';
	}
	my $error = write_to_text_file("$destination/extended_host_info.cfg", $outfile);
	push(@errors, $error) if (defined($error));
}


############################################################################
# Host dependencies
############################################################################

sub get_host_dependencies() {
	%host_dependencies = StorProc->get_host_dependencies();
}

sub process_host_dependencies() {
	my $outfile = qq(##########GROUNDWORK#############################################################################################
#GW
#GW\thost_dependencies.cfg generated $date_time by $options{'user_acct'} from monarch.cgi nagios v $options{'nagios_version'}
#GW
##########GROUNDWORK#############################################################################################
);		
	my @props = ('dependent_host_name','host_name','inherits_parent','execution_failure_criteria','notification_failure_criteria');
	foreach my $host_id (keys %host_dependencies) {
		if ($use{'hosts'}{$host_name{$host_id}}) {
			foreach my $parent_id (keys %{$host_dependencies{$host_id}}) {
				if ($use{'hosts'}{$host_name{$parent_id}}) {
					my %dependency = ('dependent_host_name' => $host_name{$host_id},'host_name' => $host_name{$parent_id},'notification_failure_criteria' => $host_dependencies{$host_id}{$parent_id}{'notification_failure_criteria'});
					if ($options{'nagios_version'} =~ /^[23]\.x$/) {
						$dependency{'inherits_parent'} = $host_dependencies{$host_id}{$parent_id}{'inherits_parent'};
						$dependency{'execution_failure_criteria'} = $host_dependencies{$host_id}{$parent_id}{'execution_failure_criteria'};
					}
					$outfile .= format_obj(\@props,'hostdependency',\%dependency);
				}	
			}
		}
	}
	push @out_files, 'host_dependencies.cfg';
	my $error = write_to_text_file("$destination/host_dependencies.cfg", $outfile);
	push(@errors, $error) if (defined($error));
}


############################################################################
# Service extended info
############################################################################

sub get_serviceextinfo() {
	%service_extinfo_templates = StorProc->get_serviceextinfo_templates();
}

sub process_serviceextinfo() {
	my $outfile = qq(##########GROUNDWORK#############################################################################################
#GW
#GW\textended_service_info_templates.cfg generated $date_time by $options{'user_acct'} from monarch.cgi nagios v $options{'nagios_version'}
#GW
##########GROUNDWORK#############################################################################################
);	

	%serviceextinfo_name = ();
	%notes = ();
	%notes_url = ();
	%action_url = ();
	my @props = split(/,/, $property_list{'extended_service_info_templates'});	
	foreach my $name (sort keys %service_extinfo_templates) {
		$serviceextinfo_name{$service_extinfo_templates{$name}{'id'}} = $name;
		$notes{$service_extinfo_templates{$name}{'id'}} = $service_extinfo_templates{$name}{'notes'};
		$notes_url{$service_extinfo_templates{$name}{'id'}} = $service_extinfo_templates{$name}{'notes_url'};
		$action_url{$service_extinfo_templates{$name}{'id'}} = $service_extinfo_templates{$name}{'action_url'} unless $options{'nagios_version'} eq '1.x';
		delete $service_extinfo_templates{$name}{'notes'};
		delete $service_extinfo_templates{$name}{'notes_url'};
		delete $service_extinfo_templates{$name}{'action_url'};
		$outfile .= format_obj(\@props,'serviceextinfo_template',\%{$service_extinfo_templates{$name}});
	}

	if ($options{'nagios_version'}  eq '2.x') {
		push @out_files, 'extended_service_info_templates.cfg';
	} else {
		push @extinfofiles, 'extended_service_info_templates.cfg';
	}
	my $error = write_to_text_file("$destination/extended_service_info_templates.cfg", $outfile);
	push(@errors, $error) if (defined($error));
}


############################################################################
# Services
############################################################################

sub get_services() {
	# Get service groups
	%service_groups = StorProc->get_service_groups();


# Get service templates
	%service_templates = StorProc->get_service_templates();
	foreach my $tname (keys %service_templates) {
		$servicetemplate_name{$service_templates{$tname}{'id'}} = $tname; 
	}

# Services
	%servicename_name = StorProc->get_table_objects('service_names','1');
	%service_instances = ();
	my %where = ();
	my %service_hash_array = StorProc->fetch_list_hash_array('services',\%where);
	my %service_override_hash_array = StorProc->fetch_list_hash_array('service_overrides',\%where);
	my %contactgroup_service_hash = StorProc->fetch_hash_array_generic_key('contactgroup_service',\%where);
	foreach my $id (keys %service_hash_array) {
		%{$service_instances{$id}} = ();
		my $hname = $host_name{$service_hash_array{$id}[1]};
		$hosts{$hname}{'services'}{$id}{'servicename_id'} = $service_hash_array{$id}[2];
		$hosts{$hname}{'services'}{$id}{'servicetemplate_id'} = $service_hash_array{$id}[3];
		$hosts{$hname}{'services'}{$id}{'serviceextinfo_id'} = $service_hash_array{$id}[4];
		$hosts{$hname}{'services'}{$id}{'escalation_id'} = $service_hash_array{$id}[5];
		# [6] status
		$hosts{$hname}{'services'}{$id}{'check_command'} = $service_hash_array{$id}[7];
		$hosts{$hname}{'services'}{$id}{'command_line'} = $service_hash_array{$id}[8];
		$hosts{$hname}{'services'}{$id}{'comment'} = $service_hash_array{$id}[9];
		if ($service_override_hash_array{$id}) {
			$hosts{$hname}{'services'}{$id}{'check_period'} = $service_override_hash_array{$id}[1];
			$hosts{$hname}{'services'}{$id}{'notification_period'} = $service_override_hash_array{$id}[2];
			$hosts{$hname}{'services'}{$id}{'event_handler'} = $service_override_hash_array{$id}[3];
			my %data = StorProc->parse_xml($service_override_hash_array{$id}[4]);
			foreach my $prop (keys %data) { $hosts{$hname}{'services'}{$id}{$prop} = $data{$prop} }			
		}
		foreach my $key (keys %contactgroup_service_hash) {
			if ($id eq $contactgroup_service_hash{$key}[1]) {
				push @{$hosts{$hname}{'services'}{$id}{'contactgroups'}}, $contactgroup_name{$contactgroup_service_hash{$key}[0]};
			}
		}
	}
	# xxx
	my %service_instance_hash_array = StorProc->fetch_list_hash_array('service_instance',\%where);
	foreach my $id (keys %service_instance_hash_array) {
		my $sid = $service_instance_hash_array{$id}[1];
		my $iname = $service_instance_hash_array{$id}[2];
		$service_instances{$sid}{$iname}{'status'} = $service_instance_hash_array{$id}[3];
		$service_instances{$sid}{$iname}{'args'} = $service_instance_hash_array{$id}[4];
		$service_instances{$sid}{$iname}{'id'} = $id;
	}
	%service_dependency_templates = StorProc->get_service_dependency_templates();
	%service_dependencies = StorProc->fetch_list_hash_array('service_dependency',\%where);
	
}


sub process_services() {
	my %files = ();
	# build all instances of service checks
	my %host_instances = ();
	my %instance_group = ();
	my %service_extinfo = ();
	my %host_ext_service = ();
	my $extinfofile = undef;
	my @props = split(/,/, $property_list{'services'});	
	foreach my $grp (sort keys %host_service_group) {
		foreach my $host (sort @{$host_service_group{$grp}{'hosts'}}) {			
			my %services = %{$hosts{$host}{'services'}};
			# determine all service instances for the host and apply macros to check command
			foreach my $sid (keys %services) {
				# my %instances = StorProc->get_service_instances($sid);
				my %instances = %{$service_instances{$sid}};
				if (%instances) {
					foreach my $instance (keys %instances) { 
						if ($instances{$instance}{'status'}) {
							my $instance_name = "$servicename_name{$services{$sid}{'servicename_id'}}$instance";
							if ($host_service_group{$grp}{'label'}) { $instance_name = "$servicename_name{$services{$sid}{'servicename_id'}}$instance$host_service_group{$grp}{'label'}" }
							# Add all props from the service to the instance
							foreach my $prop (keys %{$services{$sid}}) {
								unless ($prop eq 'check_command') { $host_instances{$host}{$instance_name}{$prop} = $services{$sid}{$prop} }
							}
							# apply instance arguments and macros to check command
							# but has it been processed in a previous group? 
							my $got_match = 0;
							if ($host_instances{$host}{$instance_name}{'check_command'}) {
								# yes - only apply macros
								foreach my $macro (keys %{$host_service_group{$grp}{'macros'}}) {
									if ($host_instances{$host}{$instance_name}{'check_command'} =~ /$macro/) { $got_match = 1 }
									$host_instances{$host}{$instance_name}{'check_command'} =~ s/$macro/$host_service_group{$grp}{'macros'}{$macro}/g;
								}
							} else {
								# no - get args and apply macros
								if ($instances{$instance}{'args'}) {
									$instances{$instance}{'args'} =~ s/^!//;
									$host_instances{$host}{$instance_name}{'check_command'} = "$command_name{$services{$sid}{'check_command'}}!$instances{$instance}{'args'}";
									foreach my $macro (keys %{$host_service_group{$grp}{'macros'}}) {
										if ($host_instances{$host}{$instance_name}{'check_command'} =~ /$macro/) { $got_match = 1 }
										$host_instances{$host}{$instance_name}{'check_command'} =~ s/$macro/$host_service_group{$grp}{'macros'}{$macro}/g;
									}
								}
							}
							# when processing a group label and there is not a macro match don't use the instance
							if ($host_service_group{$grp}{'label'} && !$got_match) {
								delete $host_instances{$host}{$instance_name};
								next;
							}
							# for use in applying dependencies and escalations
							$use{'services'}{$sid}{$instance_name} = 1;
							# assigns to file of last group read
							$instance_group{$host}{$instance_name} = $grp;
							# this seems to have no purpose: $service_name{$instance_name}{'name'} = 1;
							$host_instances{$host}{$instance_name}{'name'} = $instance_name;
							$host_instances{$host}{$instance_name}{'host_name'} = $host;
							$host_instances{$host}{$instance_name}{'template'} = $servicetemplate_name{$services{$sid}{'servicetemplate_id'}};
							$use{'service_templates'}{$services{$sid}{'template'}} = 1;
							$host_instances{$host}{$instance_name}{'check_period'} = $timeperiod_name{$services{$sid}{'check_period'}};
							$host_instances{$host}{$instance_name}{'notification_period'} = $timeperiod_name{$services{$sid}{'notification_period'}};
							$host_instances{$host}{$instance_name}{'event_handler'} = $command_name{$services{$sid}{'event_handler'}};
							# we don't want to assign redundant contact groups 
							unless ($host_instances{$host}{$instance_name}{'contactgroup'}) {
								foreach my $cg (@{$services{$sid}{'contactgroups'}}) { 
									$use{'contactgroups'}{$cg} = 1;
									$cg =~ s/\s/-/g;
									$host_instances{$host}{$instance_name}{'contactgroup'} .= "$cg,";
								}
								chop $host_instances{$host}{$instance_name}{'contactgroup'} if defined($host_instances{$host}{$instance_name}{'contactgroup'});
							}
							# if we don't have acontact group yet get it from the group
							unless ($host_instances{$host}{$instance_name}{'contactgroup'}) {
								foreach my $cg (sort keys %{$group_hosts{$host_group{$host}}{'contactgroups'}}) {
									$use{'contactgroups'}{$cg} = 1;
									$cg =~ s/\s/-/g;
									$host_instances{$host}{$instance_name}{'contactgroup'} .= "$cg,";
								}
								chop $host_instances{$host}{$instance_name}{'contactgroup'} if defined($host_instances{$host}{$instance_name}{'contactgroup'});
							}
							# if force checks on the parent group (building an instance) is checked override checks enabled
							if ($parent_checks{'use_checks'}) {
								$host_instances{$host}{$instance_name}{'active_checks_enabled'}  = $parent_checks{'active_checks_enabled'};
								$host_instances{$host}{$instance_name}{'passive_checks_enabled'} = $parent_checks{'passive_checks_enabled'};
							}
							# if extended service info is defined we create an entry for each instance, but only once
							if ($services{$sid}{'serviceextinfo_id'} && !$service_extinfo{$instance_name}) {
								my @extinfoprops = ('template','service_description','host_name','notes','notes_url','action_url');
								$service_extinfo{$instance_name}{'host_name'} = $host;
								$service_extinfo{$instance_name}{'service_description'} = $instance_name;
								$service_extinfo{$instance_name}{'template'} = $serviceextinfo_name{$services{$sid}{'serviceextinfo_id'}};
								$service_extinfo{$instance_name}{'notes'} = $notes{$services{$sid}{'serviceextinfo_id'}} unless $options{'nagios_version'} eq '1.x';
								$service_extinfo{$instance_name}{'notes'} =~ s/\$HOSTNAME\$/$host/g unless $options{'nagios_version'} eq '1.x';
								$service_extinfo{$instance_name}{'notes'} =~ s/\$HOSTADDRESS\$/$address{$host}/g unless $options{'nagios_version'} eq '1.x';
								$service_extinfo{$instance_name}{'notes'} =~ s/\$SERVICENAME\$|\$SERVICEDESC\$|\$SERVICEDESCRIPTION\$/$instance_name/g unless $options{'nagios_version'} eq '1.x';
								$service_extinfo{$instance_name}{'notes_url'} = $notes_url{$services{$sid}{'serviceextinfo_id'}};
								$service_extinfo{$instance_name}{'notes_url'} =~ s/\$HOSTNAME\$/$host/g;
								$service_extinfo{$instance_name}{'notes_url'} =~ s/\$HOSTADDRESS\$/$address{$host}/g;
								$service_extinfo{$instance_name}{'notes_url'} =~ s/\$SERVICENAME\$|\$SERVICEDESC\$|\$SERVICEDESCRIPTION\$/$instance_name/g;
								$service_extinfo{$instance_name}{'action_url'} = $action_url{$services{$sid}{'serviceextinfo_id'}} unless $options{'nagios_version'} eq '1.x';
								$service_extinfo{$instance_name}{'action_url'} =~ s/\$HOSTNAME\$/$host/g unless $options{'nagios_version'} eq '1.x';
								$service_extinfo{$instance_name}{'action_url'} =~ s/\$HOSTADDRESS\$/$address{$host}/g unless $options{'nagios_version'} eq '1.x';
								$service_extinfo{$instance_name}{'action_url'} =~ s/\$SERVICENAME\$|\$SERVICEDESC\$|\$SERVICEDESCRIPTION\$/$instance_name/g unless $options{'nagios_version'} eq '1.x';
								unless ($host_ext_service{$host}{$instance_name}) {
									$extinfofile .= format_obj(\@extinfoprops,'serviceextinfo',\%{$service_extinfo{$instance_name}});
									$host_ext_service{$host}{$instance_name} = 1;
								}
							}
							# for every entry of the service in a service group create an entry for each instance
							foreach my $sg (keys %service_groups) {
								if ($service_groups{$sg}{'hosts'}{$host_name_id{$host}}{$sid}) {
									$use{'servicegroups'}{$sg} = 1;
									$service_groups{$sg}{'members'} .= "$host,$instance_name,";
								}
							}
						}
					}
				} else {
					my $svcdesc = $servicename_name{$services{$sid}{'servicename_id'}};
					if ($host_service_group{$grp}{'label'}) { $svcdesc = "$svcdesc$host_service_group{$grp}{'label'}" }
					# Add all props from the service to the instance
					foreach my $prop (keys %{$services{$sid}}) {
						$host_instances{$host}{$svcdesc}{$prop} = $services{$sid}{$prop};
					}
					$host_instances{$host}{$svcdesc}{'check_command'} = $services{$sid}{'command_line'};
					unless ($host_instances{$host}{$svcdesc}{'check_command'}) { $host_instances{$host}{$svcdesc}{'check_command'} = $command_name{$services{$sid}{'check_command'}} }
					my $got_match = 0;
					$host_instances{$host}{$svcdesc}{'name'} = $svcdesc;
					foreach my $macro (keys %{$host_service_group{$grp}{'macros'}}) {
						if ($host_instances{$host}{$svcdesc}{'check_command'} =~ /$macro/) { $got_match = 1 }
						$host_instances{$host}{$svcdesc}{'check_command'} =~ s/$macro/$host_service_group{$grp}{'macros'}{$macro}/g;
					}
					# when processing a group label and there is not a macro match don't use the instance
					if ($host_service_group{$grp}{'label'} && !$got_match) {
						delete $host_instances{$host}{$svcdesc};
						next;
					}
					# for use in applying dependencies and escalations
					$use{'services'}{$sid}{$svcdesc} = 1;
					# assigns to file of last group read
					$instance_group{$host}{$svcdesc} = $grp;
					# apply values to the rest of the props
					#  this seems to have no purpose: $service_name{$svcdesc}{'name'} = 1;
					$host_instances{$host}{$svcdesc}{'host_name'} = $host;
					$host_instances{$host}{$svcdesc}{'template'} = $servicetemplate_name{$services{$sid}{'servicetemplate_id'}};
					$use{'service_templates'}{$services{$sid}{'template'}} = 1;
					$host_instances{$host}{$svcdesc}{'check_period'} = $timeperiod_name{$services{$sid}{'check_period'}};
					$host_instances{$host}{$svcdesc}{'notification_period'} = $timeperiod_name{$services{$sid}{'notification_period'}};
					$host_instances{$host}{$svcdesc}{'event_handler'} = $command_name{$services{$sid}{'event_handler'}};
					# we don't want to assign redundant contact groups 
					unless ($host_instances{$host}{$svcdesc}{'contactgroup'}) {
						foreach my $cg (@{$services{$sid}{'contactgroups'}}) { 
							$use{'contactgroups'}{$cg} = 1;
							$cg =~ s/\s/-/g;
							$host_instances{$host}{$svcdesc}{'contactgroup'} .= "$cg,";
						}
						chop $host_instances{$host}{$svcdesc}{'contactgroup'} if (defined($host_instances{$host}{$svcdesc}{'contactgroup'}));
					}
					# if we don't have a contact group yet get it from the group
					unless ($host_instances{$host}{$svcdesc}{'contactgroup'}) {
						foreach my $cg (sort keys %{$group_hosts{$host_group{$host}}{'contactgroups'}}) {
							$use{'contactgroups'}{$cg} = 1;
							$cg =~ s/\s/-/g;
							$host_instances{$host}{$svcdesc}{'contactgroup'} .= "$cg,";
						}
						chop $host_instances{$host}{$svcdesc}{'contactgroup'} if (defined($host_instances{$host}{$svcdesc}{'contactgroup'}));
					}
					# if force checks on the parent group (building an instance) is checked override checks enabled
					if ($parent_checks{'use_checks'}) {
						$host_instances{$host}{$svcdesc}{'active_checks_enabled'} = $parent_checks{'active_checks_enabled'};
						$host_instances{$host}{$svcdesc}{'passive_checks_enabled'} = $parent_checks{'passive_checks_enabled'};
					} 
					# if extended service info is defined we create an entry
					if ($services{$sid}{'serviceextinfo_id'}) {
						my @extinfoprops = ('template','service_description','host_name','notes','notes_url','action_url');
						$service_extinfo{$svcdesc}{'host_name'} = $host;
						$service_extinfo{$svcdesc}{'service_description'} = $svcdesc;
						$service_extinfo{$svcdesc}{'template'} = $serviceextinfo_name{$services{$sid}{'serviceextinfo_id'}};
						$service_extinfo{$svcdesc}{'notes'} = $notes{$services{$sid}{'serviceextinfo_id'}} unless $options{'nagios_version'} eq '1.x';
						$service_extinfo{$svcdesc}{'notes'} =~ s/\$HOSTNAME\$/$host/g unless $options{'nagios_version'} eq '1.x';
						$service_extinfo{$svcdesc}{'notes'} =~ s/\$HOSTADDRESS\$/$address{$host}/g unless $options{'nagios_version'} eq '1.x';
						$service_extinfo{$svcdesc}{'notes'} =~ s/\$SERVICENAME\$|\$SERVICEDESC\$|\$SERVICEDESCRIPTION\$/$svcdesc/g unless $options{'nagios_version'} eq '1.x';
						$service_extinfo{$svcdesc}{'notes_url'} = $notes_url{$services{$sid}{'serviceextinfo_id'}};
						$service_extinfo{$svcdesc}{'notes_url'} =~ s/\$HOSTNAME\$/$host/g;
						$service_extinfo{$svcdesc}{'notes_url'} =~ s/\$HOSTADDRESS\$/$address{$host}/g;
						$service_extinfo{$svcdesc}{'notes_url'} =~ s/\$SERVICENAME\$|\$SERVICEDESC\$|\$SERVICEDESCRIPTION\$/$svcdesc/g;
						$service_extinfo{$svcdesc}{'action_url'} = $action_url{$services{$sid}{'serviceextinfo_id'}} unless $options{'nagios_version'} eq '1.x';
						$service_extinfo{$svcdesc}{'action_url'} =~ s/\$HOSTNAME\$/$host/g unless $options{'nagios_version'} eq '1.x';
						$service_extinfo{$svcdesc}{'action_url'} =~ s/\$HOSTADDRESS\$/$address{$host}/g unless $options{'nagios_version'} eq '1.x';
						$service_extinfo{$svcdesc}{'action_url'} =~ s/\$SERVICENAME\$|\$SERVICEDESC\$|\$SERVICEDESCRIPTION\$/$svcdesc/g unless $options{'nagios_version'} eq '1.x';
						unless ($host_ext_service{$host}{$svcdesc}) {
							$extinfofile .= format_obj(\@extinfoprops,'serviceextinfo',\%{$service_extinfo{$svcdesc}});
							$host_ext_service{$host}{$svcdesc} = 1;
						}
					}
					# for every entry of the service in a service group create an entry for each instance (i.e. label on group)
					foreach my $sg (keys %service_groups) {
						if ($service_groups{$sg}{'hosts'}{$host_name_id{$host}}{$sid}) {
							$use{'servicegroups'}{$sg} = 1;
							$service_groups{$sg}{'members'} .= "$host,$svcdesc,";
						}
					}
				}
			}
		}
	}

	
	# Build the service files
	foreach my $host (keys %host_instances) {
		foreach my $svcdesc (keys %{$instance_group{$host}}) {
			if ($host_instances{$host}{$svcdesc}) {
				$files{$instance_group{$host}{$svcdesc}} .= format_obj(\@props,'service',\%{$host_instances{$host}{$svcdesc}});
			}
		}
	}

	foreach my $grp (sort keys %files) {
		my $file = 'services.cfg';
		unless ($grp eq ':all:') {
			$file = "$grp\_services.cfg";
		}
		my $outfile = qq(##########GROUNDWORK#############################################################################################
#GW
#GW\t$file generated $date_time by $options{'user_acct'} from monarch.cgi nagios v $options{'nagios_version'}
#GW
##########GROUNDWORK#############################################################################################

$files{$grp}
);	
		push @out_files, $file;
		my $error = write_to_text_file("$destination/$file", $outfile);
		push(@errors, $error) if (defined($error));
	}




# service extinfo

	my $outfile = qq(##########GROUNDWORK#############################################################################################
#GW
#GW\textended_service_info.cfg generated $date_time by $options{'user_acct'} from monarch.cgi nagios v $options{'nagios_version'}
#GW
##########GROUNDWORK#############################################################################################

$extinfofile
);	

	if ($options{'nagios_version'}  =~ /^[23]\.x$/) {
		push @out_files, 'extended_service_info.cfg';
	} else {
		push @extinfofiles, 'extended_service_info.cfg';
	}
	my $error = write_to_text_file("$destination/extended_service_info.cfg", $outfile);
	push(@errors, $error) if (defined($error));

# service groups

	if ($options{'nagios_version'} =~ /^[23]\.x$/) {
		$outfile = qq(##########GROUNDWORK#############################################################################################
#GW
#GW\tservice_groups.cfg generated $date_time by $options{'user_acct'} from monarch.cgi nagios v $options{'nagios_version'}
#GW
##########GROUNDWORK#############################################################################################
);

		my @props = ('name','alias','members');
		foreach my $sg (sort keys %service_groups) {
			chop $service_groups{$sg}{'members'};
			if ($service_groups{$sg}{'members'}) { $outfile .= format_obj(\@props,'servicegroup',\%{$service_groups{$sg}}) }
		}
		push @out_files, 'service_groups.cfg';
		$error = write_to_text_file("$destination/service_groups.cfg", $outfile);
		push(@errors, $error) if (defined($error));
	}
}


sub process_service_dependencies() {

	my $outfile = qq(##########GROUNDWORK#############################################################################################
#GW
#GW\tservice_dependency_templates.cfg generated $date_time by $options{'user_acct'} from monarch.cgi nagios v $options{'nagios_version'}
#GW
##########GROUNDWORK#############################################################################################
);	
	my %sdtemp_name = ();
	my @props = ('name','service_description','execution_failure_criteria','notification_failure_criteria');
	foreach my $name (sort keys %service_dependency_templates) {
		$sdtemp_name{$service_dependency_templates{$name}{'id'}} = $name;
		$service_dependency_templates{$name}{'name'} = $name;
		$service_dependency_templates{$name}{'service_description'} = $servicename_name{$service_dependency_templates{$name}{'servicename_id'}};
		$outfile .= format_obj(\@props,'servicedependency_template',\%{$service_dependency_templates{$name}});
	}

	push @out_files, 'service_dependency_templates.cfg';
	my $error = write_to_text_file("$destination/service_dependency_templates.cfg", $outfile);
	push(@errors, $error) if (defined($error));

# service dependencies

	$outfile = qq(##########GROUNDWORK#############################################################################################
#GW
#GW\tservice_dependencies.cfg generated $date_time by $options{'user_acct'} from monarch.cgi nagios v $options{'nagios_version'}
#GW
##########GROUNDWORK#############################################################################################
);	
	my @props = ('use','dependent_service_description','dependent_host_name','host_name');
	foreach my $id (keys %service_dependencies) {
		if ($use{'services'}{$service_dependencies{$id}[1]}) {
			# for each instance of the service id create a dependency
			foreach my $name (sort keys %{$use{'services'}{$service_dependencies{$id}[1]}}) {
				my %dependency = ();
				$dependency{'use'} = $sdtemp_name{$service_dependencies{$id}[4]};
				$dependency{'dependent_service_description'} = $name;
				$dependency{'dependent_host_name'} = $host_name{$service_dependencies{$id}[2]};
				$dependency{'host_name'} = $host_name{$service_dependencies{$id}[3]};
				$dependency{'comment'} = $service_dependencies{$id}[5];
				$outfile .= format_obj(\@props,'servicedependency',\%dependency);
			}
		}
	}

	push @out_files, 'service_dependencies.cfg';
	$error = write_to_text_file("$destination/service_dependencies.cfg", $outfile);
	push(@errors, $error) if (defined($error));
}

sub process_service_templates() {
	my $outfile = qq(##########GROUNDWORK#############################################################################################
#GW
#GW\tservice_templates.cfg generated $date_time by $options{'user_acct'} from monarch.cgi nagios v $options{'nagios_version'}
#GW
##########GROUNDWORK#############################################################################################
); 
	my @props = split(/,/, $property_list{'service_templates'});	
	foreach my $name (sort keys %service_templates) {
		my %template = ();
		foreach my $prop (@props) {
			if ($prop eq 'contactgroup') {
				foreach my $cgid (@{$service_templates{$name}{'contactgroups'}}) {
					my $cg = $contactgroup_name{$cgid};
					$cg =~ s/\s/-/g;
					$template{'contactgroup'} .= "$cg,";
					$use{'contactgroups'}{$contactgroup_name{$cgid}} = 1;
				}
				chop $template{'contactgroup'};
			} elsif ($prop eq 'template') {
				$template{$prop} = $servicetemplate_name{$service_templates{$name}{'parent_id'}};
			} elsif ($prop =~ /^check_command$|^event_handler$/) {
				$template{$prop} = $command_name{$service_templates{$name}{$prop}};
			} elsif ($prop =~ /^check_period$|^notification_period$/) {
				$template{$prop} = $timeperiod_name{$service_templates{$name}{$prop}};
			} else {
				$template{$prop} = $service_templates{$name}{$prop};
			}
		}
		if ($template{'command_line'}) { $template{'check_command'} = $template{'command_line'}	}
		delete $template{'command_line'};
		$template{'name'} = $name;
		$outfile .= format_obj(\@props,'service_template',\%template);
	}
	
	push @out_files, 'service_templates.cfg';
	my $error = write_to_text_file("$destination/service_templates.cfg", $outfile);
	push(@errors, $error) if (defined($error));
}


############################################################################
# Escalations
############################################################################


sub get_escalations() {
	my %where = ();
	my %escalation_name = ();
	my %escalationtree_name = ();
	my %escalation_template_hash_array = StorProc->fetch_list_hash_array('escalation_templates',\%where);
	foreach my $id (keys %escalation_template_hash_array) {
		my $ename = $escalation_template_hash_array{$id}[1];
		$escalation_name{$id} = $ename;
		$escalation_templates{$ename}{'id'} = $id;
		$escalation_templates{$ename}{'type'} = $escalation_template_hash_array{$id}[2];
		$escalation_templates{$ename}{'escalation_period'} = $escalation_template_hash_array{$id}[5];
		my %data = StorProc->parse_xml($escalation_template_hash_array{$id}[3]);
		foreach my $prop (keys %data) { $escalation_templates{$ename}{$prop} = $data{$prop} }
	}
	my %escalation_tree_hash = StorProc->fetch_list_hash_array('escalation_trees',\%where);
	foreach my $id (keys %escalation_tree_hash) {
		my $name = $escalation_tree_hash{$id}[1];
		$escalationtree_name{$id} = $name;
		$escalation_trees{$name}{'type'} = $escalation_tree_hash{$id}[3];
		$escalation_trees{$name}{'id'} = $id;
	}
	my %tree_template_contactgroup_hash = StorProc->fetch_hash_array_generic_key('tree_template_contactgroup',\%where);
	foreach my $key (keys %tree_template_contactgroup_hash) {
		my $name = $escalationtree_name{$tree_template_contactgroup_hash{$key}[0]};
		my $esc = $escalation_name{$tree_template_contactgroup_hash{$key}[1]}; # GWMON-5079 why are we using an escalation template id as an escalation id?
		push @{$escalation_trees{$name}{'escalations'}{$esc}{'contactgroups'}}, $contactgroup_name{$tree_template_contactgroup_hash{$key}[2]};
	}
}


sub process_escalation_templates() {
	my $outfile = qq(##########GROUNDWORK#############################################################################################
#GW
#GW\tescalation_templates.cfg generated $date_time by $options{'user_acct'} from monarch.cgi nagios v $options{'nagios_version'}
#GW
##########GROUNDWORK#############################################################################################
);	
	my @props = split(/,/, $property_list{'host_escalation_templates'});
	foreach my $name (sort keys %escalation_templates) {
		my $type = undef;
		if ($escalation_templates{$name}{'type'} eq 'hostgroup') { $type = 'hostgroupescalation' }
		if ($escalation_templates{$name}{'type'} eq 'host') { $type = 'hostescalation' }
		if ($escalation_templates{$name}{'type'} eq 'service') { $type = 'serviceescalation' }
		if ($escalation_templates{$name}{'escalation_options'} =~ /all/) { delete $escalation_templates{$name}{'escalation_options'} }
		$escalation_templates{$name}{'escalation_period'} = $timeperiod_name{$escalation_templates{$name}{'escalation_period'}};
		if ($options{'nagios_version'} eq '1.x') {
			delete $escalation_templates{$name}{'escalation_period'};
			delete $escalation_templates{$name}{'escalation_options'};
		}
		delete $escalation_templates{$name}{'type'};
		$escalation_templates{$name}{'name'} = $name;
		$outfile .= format_obj(\@props,$type."_template",\%{$escalation_templates{$name}});
	}
	push @out_files, 'escalation_templates.cfg';
	my $error = write_to_text_file("$destination/escalation_templates.cfg", $outfile);
	push(@errors, $error) if (defined($error));
}


sub process_escalations() {
	my $outhostfile = qq(##########GROUNDWORK#############################################################################################
#GW
#GW\thost_escalations.cfg generated $date_time by $options{'user_acct'} from monarch.cgi nagios v $options{'nagios_version'}
#GW
##########GROUNDWORK#############################################################################################
);


	my $outservicefile = qq(##########GROUNDWORK#############################################################################################
#GW
#GW\tservice_escalations.cfg generated $date_time by $options{'user_acct'} from monarch.cgi nagios v $options{'nagios_version'}
#GW
##########GROUNDWORK#############################################################################################
);

	my %host_host_esc = ();
	my %host_service_esc = ();
	my %host_service_service_esc = ();
	foreach my $hname (keys %hosts) {
		if ($hosts{$hname}{'host_escalation_id'}) { push @{$host_host_esc{$hosts{$hname}{'host_escalation_id'}}}, $hname }
		if ($hosts{$hname}{'service_escalation_id'}) { push @{$host_service_esc{$hosts{$hname}{'service_escalation_id'}}}, $hname }		
		foreach my $id (keys %{$hosts{$hname}{'services'}}) {
			if ($hosts{$hname}{'services'}{$id}{'escalation_id'}) { $host_service_service_esc{$hosts{$hname}{'services'}{$id}{'escalation_id'}}{$hname}{$id} = 1 }
		}
	}

	my %hostgroup_host_esc = ();
	my %hostgroup_service_esc = ();
	foreach my $hname (keys %host_groups) {
		if ($host_groups{$hname}{'host_escalation_id'}) { push @{$hostgroup_host_esc{$host_groups{$hname}{'host_escalation_id'}}}, $hname }
		if ($host_groups{$hname}{'service_escalation_id'}) { push @{$hostgroup_service_esc{$host_groups{$hname}{'service_escalation_id'}}}, $hname }
	}

	my %servicegroup_esc = ();
	foreach my $service_group (keys %service_groups) {
		if ($service_groups{$service_group}{'escalation_id'}) { push @{$servicegroup_esc{$service_groups{$service_group}{'escalation_id'}}}, $service_group }
	}

	foreach my $tree (sort keys %escalation_trees) {
		my $tree_id = $escalation_trees{$tree}{'id'};
		if ($escalation_trees{$tree}{'type'} eq 'host') {
			$outhostfile .= "\n\n#\n# $escalation_trees{$tree}{'comment'}\n#\n\n";
			delete $escalation_trees{$tree}{'comment'};
			delete $escalation_trees{$tree}{'id'};
			delete $escalation_trees{$tree}{'type'};
			foreach my $esc (sort keys %{$escalation_trees{$tree}{'escalations'}}) {
				my $escalation_id = $escalation_templates{$esc}{'id'};
				my %escalation = ('use' => $esc);
				foreach my $cg (@{$escalation_trees{$tree}{'escalations'}{$esc}{'contactgroups'}}) {
					$use{'contactgroups'}{$cg} = 1;
					$cg =~ s/\s/-/g;
					$escalation{'contact_groups'} .= "$cg,";
				}
				chop $escalation{'contact_groups'};
				my @props = ('use','hostgroup_name','contact_groups');
				#foreach my $hostgroup (@{$hostgroup_host_esc{$escalation_id}}) {
				foreach my $hostgroup (@{$hostgroup_host_esc{$tree_id}}) {
					if ($use{'hostgroups'}{$hostgroup}) { $escalation{'hostgroup_name'} .= "$hostgroup," }
				}
				chop $escalation{'hostgroup_name'};
				if ($escalation{'hostgroup_name'}) { $outhostfile .= format_obj(\@props,'hostescalation',\%escalation) }
				@props = ('use','host_name','contact_groups');
				#foreach my $host (@{$host_host_esc{$escalation_id}}) {
				foreach my $host (@{$host_host_esc{$tree_id}}) {
					if ($use{'hosts'}{$host}) { $escalation{'host_name'} .= "$host," }
				}
				chop $escalation{'host_name'};
				if ($escalation{'host_name'}) { $outhostfile .= format_obj(\@props,'hostescalation',\%escalation) }

			}
		}

		if ($escalation_trees{$tree}{'type'} eq 'service') {
			delete $escalation_trees{$tree}{'comment'};
			delete $escalation_trees{$tree}{'id'};
			delete $escalation_trees{$tree}{'type'};
			foreach my $esc (sort keys %{$escalation_trees{$tree}{'escalations'}}) {
				my $escalation_id = $escalation_templates{$esc}{'id'};		
				my %escalation = ('use' => $esc,'service_description' => '*');
				foreach my $cg (@{$escalation_trees{$tree}{'escalations'}{$esc}{'contactgroups'}}) {
					$use{'contactgroups'}{$cg} = 1;
					$cg =~ s/\s/-/g;
					$escalation{'contact_groups'} .= "$cg,";
				}
				chop $escalation{'contact_groups'};
				my @props = ('use','hostgroup_name','service_description','contact_groups');
				foreach my $hostgroup (@{$hostgroup_service_esc{$tree_id}}) {
					if ($use{'hostgroups'}{$hostgroup}) { $escalation{'hostgroup_name'} .= "$hostgroup," }
				}
				chop $escalation{'hostgroup_name'};
				if ($escalation{'hostgroup_name'}) { $outservicefile .= format_obj(\@props,'serviceescalation',\%escalation) }
				@props = ('use','host_name','service_description','contact_groups');
				foreach my $host (@{$host_service_esc{$tree_id}}) {
					if ($use{'hosts'}{$host}) { $escalation{'host_name'} .= "$host," }
				}
				chop $escalation{'host_name'};
				if ($escalation{'host_name'}) { $outservicefile .= format_obj(\@props,'serviceescalation',\%escalation) }
				@props = ('use','servicegroup_name','contact_groups');
				delete $escalation{'service_description'};
				foreach my $sg (@{$servicegroup_esc{$tree_id}}) {
					if ($use{'servicegroups'}{$sg}) { $escalation{'servicegroup_name'} .= "$sg," }
				}
				chop $escalation{'servicegroup_name'};
				if ($escalation{'servicegroup_name'}) { $outservicefile .= format_obj(\@props,'serviceescalation',\%escalation) }
				@props = ('use','host_name','service_description','contact_groups');
				foreach my $host (sort keys %{$host_service_service_esc{$tree_id}}) {
					$escalation{'host_name'} = $host;
					foreach my $service_id (sort keys %{$host_service_service_esc{$tree_id}{$host}}) {
						foreach my $sname (sort keys %{$use{'services'}{$service_id}}) {
							$escalation{'service_description'} = $sname;
							$outservicefile .= format_obj(\@props,'serviceescalation',\%escalation);
						}
					}
				}
			}
		}
	}
	push @out_files, 'host_escalations.cfg';
	my $error = write_to_text_file("$destination/host_escalations.cfg", $outhostfile);
	push(@errors, $error) if (defined($error));

	push @out_files, 'service_escalations.cfg';
	$error = undef;
	$error = write_to_text_file("$destination/service_escalations.cfg", $outservicefile);
	push(@errors, $error) if (defined($error));
}


############################################################################
# Contacts
############################################################################

sub get_contacts() {
	my %where = ();
	my %contact_name_id = ();
	my %contact_hash_array = StorProc->fetch_list_hash_array('contacts',\%where);
	foreach my $id (keys %contact_hash_array) {
		my $cname = $contact_hash_array{$id}[1];
		$contact_name{$id} = $cname;
		$contact_name_id{$cname} = $id;
		$contacts{$cname}{'name'} = $cname;
		$contacts{$cname}{'alias'} = $contact_hash_array{$id}[2];
		$contacts{$cname}{'email'} = $contact_hash_array{$id}[3];
		$contacts{$cname}{'pager'} = $contact_hash_array{$id}[4];
		$contacts{$cname}{'contacttemplate_id'} = $contact_hash_array{$id}[5];
		$contacts{$cname}{'comments'} = $contact_hash_array{$id}[7];
		@{$contact_command_overrides{$cname}{'host'}} = ();
		@{$contact_command_overrides{$cname}{'service'}} = ();
		%{$contact_overrides{$cname}} = ();
	}
	my %contact_command_overrides_hash_array = StorProc->fetch_hash_array_generic_key('contact_command_overrides',\%where);
	foreach my $key (keys %contact_command_overrides_hash_array) {
		my $cname = $contact_name{$contact_command_overrides_hash_array{$key}[0]};
		my $contact_id = $contact_command_overrides_hash_array{$key}[0];
		my $type = $contact_command_overrides_hash_array{$key}[1];
		my $command_id = $contact_command_overrides_hash_array{$key}[2];
		push @{$contact_command_overrides{$cname}{$type}}, $command_name{$command_id};
	}
	my %contact_overrides_hash_array = StorProc->fetch_hash_array_generic_key('contact_overrides',\%where);
	foreach my $key (keys %contact_overrides_hash_array) {
		my $cname = $contact_name{$contact_overrides_hash_array{$key}[0]};
		$contact_overrides{$cname}{'host_notification_period'} = $contact_overrides_hash_array{$key}[1];
		$contact_overrides{$cname}{'service_notification_period'} = $contact_overrides_hash_array{$key}[2];
		my %data = StorProc->parse_xml($contact_overrides_hash_array{$key}[3]);
		foreach my $name (keys %data) {
			$contact_overrides{$cname}{$name} = $data{$name}; 
		}
	}
	my %contact_template_hash_array = StorProc->fetch_list_hash_array('contact_templates',\%where);
	foreach my $id (keys %contact_template_hash_array) {
		my $name = $contact_template_hash_array{$id}[1];
		$contact_template_name{$id} = $name;
		$contact_templates{$name}{'name'} = $name;
		$contact_templates{$name}{'host_notification_period'} = $timeperiod_name{$contact_template_hash_array{$id}[2]};
		$contact_templates{$name}{'service_notification_period'} = $timeperiod_name{$contact_template_hash_array{$id}[3]};
		my %data = StorProc->parse_xml($contact_template_hash_array{$id}[4]);
		$contact_templates{$name}{'host_notification_options'} = $data{'host_notification_options'};
		$contact_templates{$name}{'service_notification_options'} = $data{'service_notification_options'};
	}
	# Temp fix for duplicate commands in notification string
	# Remove %temp_fix_commands when source of problem is discovered
	my %temp_fix_commands = ();
	my %contact_template_command_hash_array = StorProc->fetch_hash_array_generic_key('contact_command',\%where);
	foreach my $key (keys %contact_template_command_hash_array) {
		my $ctname = $contact_template_name{$contact_template_command_hash_array{$key}[0]};
		unless ($temp_fix_commands{$ctname}{$contact_template_command_hash_array{$key}[1]}{$contact_template_command_hash_array{$key}[2]}) {
			$temp_fix_commands{$ctname}{$contact_template_command_hash_array{$key}[1]}{$contact_template_command_hash_array{$key}[2]} = 1;
			if ($contact_template_command_hash_array{$key}[1] eq 'host') {
				$contact_templates{$ctname}{'host_notification_commands'} .= "$command_name{$contact_template_command_hash_array{$key}[2]},";
			} else {
				$contact_templates{$ctname}{'service_notification_commands'} .= "$command_name{$contact_template_command_hash_array{$key}[2]},";				
			}
		}
	}	
}

sub process_contact_templates() {
	my $outfile = qq(##########GROUNDWORK#############################################################################################
#GW
#GW\tcontact_templates.cfg generated $date_time by $options{'user_acct'} from monarch.cgi nagios v $options{'nagios_version'}
#GW
##########GROUNDWORK#############################################################################################
);	
	
	my @props = split(/,/, $property_list{'contact_templates'});
	foreach my $name (sort keys %contact_templates) {
		chop $contact_templates{$name}{'host_notification_commands'};
		chop $contact_templates{$name}{'service_notification_commands'};
		$outfile .= format_obj(\@props,'contact_template',\%{$contact_templates{$name}});
	}	
	push @out_files, 'contact_templates.cfg';
	my $error = write_to_text_file("$destination/contact_templates.cfg", $outfile);

	# Mod by PL
	%contact_templates = ();

	push(@errors, $error) if (defined($error));
}

sub process_contacts() {
	my $outfile = qq(##########GROUNDWORK#############################################################################################
#GW
#GW\tcontacts.cfg generated $date_time by $options{'user_acct'} from monarch.cgi nagios v $options{'nagios_version'}
#GW
##########GROUNDWORK#############################################################################################
);	

	foreach my $name (sort keys %{$use{'contacts'}}) {
		my @props = ('name','use','alias','email','pager');
		my %contact = %{$contacts{$name}};
		$contact{'use'} =  $contact_template_name{$contact{'contacttemplate_id'}};
		my %overrides = %{$contact_overrides{$name}};
		delete $overrides{'contact_id'};
		foreach my $prop (keys %overrides) {
			if ($prop eq 'host_notification_period') {
				$contact{'host_notification_period'} = $timeperiod_name{$overrides{$prop}};			
			} elsif ($prop eq 'service_notification_period') {
				$contact{'service_notification_period'} = $timeperiod_name{$overrides{$prop}};			
			} else {
				$contact{$prop} = $overrides{$prop};
			}
			push @props, $prop;
		}
		
		my @commands = @{$contact_command_overrides{$name}{'host'}};
		foreach my $command (@commands) {
			$contact{'host_notification_commands'} .= "$command,";
		}
		chop $contact{'host_notification_commands'};
		push @props, 'host_notification_commands';
		
		my @commands = @{$contact_command_overrides{$name}{'service'}};
		foreach my $command (@commands) {
			$contact{'service_notification_commands'} .= "$command,";
		}
		chop $contact{'service_notification_commands'};
		push @props, 'service_notification_commands';
		$outfile .= format_obj(\@props,'contact',\%contact);
	}
	push @out_files, 'contacts.cfg';
	my $error = write_to_text_file("$destination/contacts.cfg", $outfile);
	push(@errors, $error) if (defined($error));
}


############################################################################
# nagios.cgi
############################################################################

sub process_nagios_cgi() {
	my @cgiprops = ('physical_html_path','url_html_path','show_context_help','nagios_check_command','use_authentication','default_user_name',
'authorized_for_system_information','authorized_for_system_commands','authorized_for_configuration_information','authorized_for_all_services','authorized_for_all_hosts','authorized_for_all_host_commands',
'authorized_for_all_service_commands','statusmap_background_image','default_statusmap_layout','default_statuswrl_layout',
'statuswrl_include','refresh_rate','ping_syntax','host_unreachable_sound','host_down_sound','service_critical_sound','service_warning_sound',
'service_unknown_sound','ddb');
	my $outfile = qq(##########GROUNDWORK#############################################################################################
#GW
#GW\tcgi.cfg generated $date_time by $options{'user_acct'} from monarch.cgi nagios v $options{'nagios_version'}
#GW
##########GROUNDWORK#############################################################################################
);
	$outfile .= "\n# MAIN NAGIOS CONFIGURATION FILE\nmain_config_file=$options{'nagios_home'}/nagios.cfg\n";
	foreach my $prop (@cgiprops) {
		my $title = "\U$prop";
		$title =~ s/_/ /g;
		$nagios_cgi{$prop} =~ s/-zero-/0/g;
		my $comment = undef;
		if ($prop eq 'use_authentication') {
			unless ($nagios_cgi{$prop}) { $nagios_cgi{$prop} = '0'}
		}
		if ($nagios_cgi{$prop} eq '') { $comment = '# ' }
		$outfile .= "\n# $title\n$comment$prop=$nagios_cgi{$prop}\n";
		if (@extinfofiles && $prop eq 'nagios_check_command') {
			$outfile .= "\n# XEDTEMPLATE CONFIG FILES\n";
			foreach my $file (sort @extinfofiles) {
				if (-e "$destination/$file") {
					$outfile .= "xedtemplate_config_file=$options{'nagios_home'}/$file\n";
				}
			}
		}
	}
	my $error = write_to_text_file("$destination/cgi.cfg", $outfile);
	push(@errors, $error) if (defined($error));
	
}

############################################################################
# nagios.cfg
############################################################################

sub process_nagios_cfg() {
	my %nagkeys = StorProc->nagios_defaults($options{'nagios_version'},'');
	my @nagprops = ('log_file','object_cache_file','precached_object_file','resource_file','temp_file','status_file',
'status_update_interval','nagios_user','nagios_group','enable_notifications','execute_service_checks',
'accept_passive_service_checks','execute_host_checks','accept_passive_host_checks','enable_event_handlers','log_rotation_method','log_archive_path',
'check_external_commands','command_file','lock_file','retain_state_information','state_retention_file',
'retention_update_interval','use_retained_program_state','use_retained_scheduling_info','use_syslog','log_notifications','log_service_retries','log_host_retries',
'log_event_handlers','log_initial_states','log_external_commands','log_passive_service_checks','log_passive_checks','global_host_event_handler',
'global_service_event_handler','sleep_time','inter_check_delay_method','service_inter_check_delay_method','max_service_check_spread','service_interleave_factor',
'max_concurrent_checks','check_result_path','service_reaper_frequency','host_inter_check_delay_method','max_host_check_spread','interval_length','auto_reschedule_checks',
'auto_rescheduling_interval','auto_rescheduling_window','use_agressive_host_checking','enable_flap_detection','low_service_flap_threshold','high_service_flap_threshold',
'low_host_flap_threshold','high_host_flap_threshold','soft_state_dependencies','service_check_timeout','host_check_timeout','event_handler_timeout',
'notification_timeout','ocsp_timeout','ochp_timeout','perfdata_timeout','obsess_over_services','ocsp_command','obsess_over_hosts','ochp_command',
'process_performance_data','host_perfdata_command','service_perfdata_command','host_perfdata_file','service_perfdata_file','host_perfdata_file_template',
'service_perfdata_file_template','host_perfdata_file_mode','service_perfdata_file_mode','host_perfdata_file_processing_interval',
'service_perfdata_file_processing_interval','host_perfdata_file_processing_command','service_perfdata_file_processing_command',
'check_for_orphaned_services','check_service_freshness','freshness_check_interval','check_host_freshness','host_freshness_check_interval','event_broker_options',		
'broker_module','date_format','illegal_object_name_chars','illegal_macro_output_chars','admin_email','admin_pager');

	my $outfile = qq(##########GROUNDWORK#############################################################################################
#GW
#GW\tnagios.cfg generated $date_time by $options{'user_acct'} from monarch.cgi nagios $options{'nagios_version'}
#GW
##########GROUNDWORK#############################################################################################
);
	foreach my $prop (@nagprops) {
		my $title = "\U$prop";
		$title =~ s/_/ /g;
		my $comment = undef;
		if ($prop =~ /aggregate_status_updates|enable_notifications|execute_service_checks|accept_passive_service_checks|execute_host_checks|accept_passive_host_checks|enable_event_handlers|use_retained_program_state|use_retained_scheduling_info|use_syslog|log_notifications|log_service_retries|log_host_retries|log_event_handlers|log_initial_states|log_external_commands|log_passive_checks|check_service_freshness|check_host_freshness|max_concurrent_checks/) {
			unless ($nagios_cfg{$prop}) { $nagios_cfg{$prop} = '0'}
		}
		$nagios_cfg{$prop} =~ s/-zero-/0/;
		if ($nagios_cfg{$prop} eq '') { $comment = '# ' }
		if ($prop eq 'resource_file') {
			my ($folder,$file) = $nagios_cfg{$prop} =~ /(.*)\/(.*\.cfg)/;
			if ($options{'commit_step'} eq 'preflight') {
				$outfile .= "\n# $title\n$comment$prop=$destination/$file\n";
			} else {
				$outfile .= "\n# $title\n$comment$prop=$nagios_cfg{$prop}\n";
			}
		} elsif (defined $nagkeys{$prop}) {
			$outfile .= "\n# $title\n$comment$prop=$nagios_cfg{$prop}\n";
		}
		if ($prop eq 'log_file') {
			$outfile .= "\n# OBJECT CONFIGURATION FILE(S)\n";
			# Temp fix for duplicate files listings
			# Remove %temp_fix_file after source problem is fixed 
			my %temp_fix_file = ();
			foreach my $file (sort @out_files) {
				unless ($temp_fix_file{$file}) {
					if ($options{'commit_step'} eq 'preflight') {
						$outfile .= "cfg_file=$destination/$file\n";
					} else {
						$outfile .= "cfg_file=$options{'nagios_home'}/$file\n";
					}
					$temp_fix_file{$file} = 1;
				}
			}
		}	
	}	
	if (%nagios_cfg_misc) {
		$outfile .= "\n# MISC DIRECTIVES\n";
		foreach my $misc_prop (sort {$a <=> $b} keys %nagios_cfg_misc) {
                        my $misc_proptmp=$misc_prop;
                        $misc_proptmp=~ s/key\d+.\d+//;
                        $outfile .= "$misc_proptmp=$nagios_cfg_misc{$misc_prop}\n";


		}
	}
	my $error = write_to_text_file("$destination/nagios.cfg", $outfile);
	push(@errors, $error) if (defined($error));
	push @out_files, 'nagios.cfg';
	# Note @extinfofiles is empty unless nagios ver is 1.x
	push (@out_files, @extinfofiles);
	push @out_files, 'cgi.cfg';
	
}

############################################################################
# resource.cfg
############################################################################

sub process_resource_cfg() {
	my $outfile = qq(##########GROUNDWORK#############################################################################################
#GW
#GW\tresource.cfg generated $date_time by $options{'user_acct'} from monarch.cgi nagios v $options{'nagios_version'}
#GW
##########GROUNDWORK#############################################################################################
);

	for (my $i = 1; $i <= 32; $i++) {
		my $key = "user$i";
		if ($resource_cfg{$key}) {
			$outfile .= qq(
\$USER$i\$=$resource_cfg{$key}
);
		}					
	}
	if ($nagios_cfg{'resource_file'}) {
		my ($res_folder, $res_file) = $nagios_cfg{'resource_file'} =~ /(.*)\/(.*\.cfg)/;
		if ($options{'commit_step'} eq 'commit') {
			$res_folder = $destination;
		} elsif ($options{'commit_step'} || $options{'export'}) { 
			$res_folder = $destination; 
		} else {
			unless (-e "$res_folder") { mkdir("$res_folder", 0770) || push @errors, "Cannot create $res_folder $!" }
		}
		my $error = write_to_text_file("$res_folder/$res_file", $outfile);
		push(@errors, $error) if (defined($error));
		push @out_files, $res_file;
	} else {
		push @errors, "Error: You have not yet defined a resource file! Check the Nagios cfg for this instance.";
	}
}

sub get_default_parent() {
	my %default_parent = ();
	%{$default_parent{'nagios'}} = ();
	%{$default_parent{'nagios_cgi'}} = ();
	%{$default_parent{'resource'}} = ();
	%{$default_parent{'nagios_cfg_misc'}} = ();
	my %where = ();
	my %setup_hash_array = StorProc->fetch_list_hash_array('setup',\%where);
	foreach my $prop (keys %setup_hash_array) {
		$default_parent{$setup_hash_array{$prop}[1]}{$prop} = $setup_hash_array{$prop}[2];
	}
	return %default_parent;
}

sub get_groups() {
	my %monarchgroup_name = ();
	my %where = ();
	my %monarch_group_hash_array = StorProc->fetch_list_hash_array('monarch_groups',\%where);
	foreach my $id (keys %monarch_group_hash_array) {
		my $name = $monarch_group_hash_array{$id}[1];
		$monarchgroup_name{$id} = $name;
		$group_names{$name} = $id;
		$monarch_groups{$name}{'location'} = $monarch_group_hash_array{$id}[3];
		$monarch_groups{$name}{'status'} = $monarch_group_hash_array{$id}[4];
		%{$monarch_groups{$name}{'nagios_cgi'}} = ();
		%{$monarch_groups{$name}{'nagios_cfg'}} = ();
		%{$monarch_groups{$name}{'nagios_cfg_misc'}} = ();
		%{$monarch_groups{$name}{'resource'}} = ();
		my %data = StorProc->parse_xml($monarch_group_hash_array{$id}[5]);
		foreach my $prop (keys %data) { $monarch_groups{$name}{$prop} = $data{$prop} }
	}
	
	# Hosts assigned
	my %monarch_group_host_hash_array = StorProc->fetch_hash_array_generic_key('monarch_group_host',\%where);
	foreach my $key (keys %monarch_group_host_hash_array) {
		my $gname = $monarchgroup_name{$monarch_group_host_hash_array{$key}[0]};
		my $hname = $host_name{$monarch_group_host_hash_array{$key}[1]};
		$monarch_groups{$gname}{'hosts'}{$hname} = $monarch_group_host_hash_array{$key}[1];
	}
	
	# Host groups assigned
	my %monarch_group_hostgroup_hash_array = StorProc->fetch_hash_array_generic_key('monarch_group_hostgroup',\%where);
	foreach my $key (keys %monarch_group_hostgroup_hash_array) {
		my $gname = $monarchgroup_name{$monarch_group_hostgroup_hash_array{$key}[0]};
		my $hname = $hostgroup_name{$monarch_group_hostgroup_hash_array{$key}[1]};
		$monarch_groups{$gname}{'hostgroups'}{$hname} = $monarch_group_hostgroup_hash_array{$key}[1];
	}
	
	# Group macros to apply
	my %monarch_macro_hash_array = StorProc->fetch_list_hash_array('monarch_macros',\%where);
	my %monarch_group_macro_hash_array = StorProc->fetch_hash_array_generic_key('monarch_group_macro',\%where);
	foreach my $key (keys %monarch_group_macro_hash_array) {
		my $gname = $monarchgroup_name{$monarch_group_macro_hash_array{$key}[0]};
		my $mname = $monarch_macro_hash_array{$monarch_group_macro_hash_array{$key}[1]}[1];
		$monarch_groups{$gname}{'macros'}{$mname} = $monarch_group_macro_hash_array{$key}[2];
	}
	
	# Contact group overrides
	my %contactgroup_group_hash_array = StorProc->fetch_hash_array_generic_key('contactgroup_group',\%where);
	foreach my $key (keys %contactgroup_group_hash_array) {
		my $gname = $monarchgroup_name{$contactgroup_group_hash_array{$key}[1]};
		my $cname = $contactgroup_name{$contactgroup_group_hash_array{$key}[0]};
		$monarch_groups{$gname}{'contactgroups'}{$cname} = $contactgroup_group_hash_array{$key}[0];
	}
	
	# Group properties - resource nagios_cgi nagios_cfg
	my %monarch_group_props_hash_array = StorProc->fetch_hash_array_generic_key('monarch_group_props',\%where);
	foreach my $key (sort { $monarch_group_props_hash_array{$a} <=> $monarch_group_props_hash_array{$b} } %monarch_group_props_hash_array) {
		my $gname = $monarchgroup_name{$monarch_group_props_hash_array{$key}[1]};
		my $prop = $monarch_group_props_hash_array{$key}[2];
		my $type = $monarch_group_props_hash_array{$key}[3];
		$monarch_groups{$gname}{$type}{$prop} = $monarch_group_props_hash_array{$key}[4];
	}
	
	# Determine inactive hosts
	foreach my $gname (keys %monarch_groups) {
		if ($monarch_groups{$gname}{'status'} eq 1) {
			foreach my $hname (keys %{$monarch_groups{$gname}{'hosts'}}) {
				$inactive_hosts{$host_name_id{$hname}} = 1;
			}
			foreach my $hgname (keys %{$monarch_groups{$gname}{'hostgroups'}}) {
				foreach my $hname (@{$host_groups{$hgname}{'members'}}) {
					$inactive_hosts{$host_name_id{$hname}} = 1;
				}
			}	
		}
	}
	
	%parents_all = StorProc->get_group_parents_all();
	%parent_top = StorProc->get_group_parents_top();
}

sub process_group() {
	@errors = ();
	@out_files = ();
	%use = ();
	@extinfofiles = ();
	@group_process_order = ();
	$log = undef;
	%parent_checks = ();
	%host_group = ();
	%host_service_group = ();
	%group_hosts = ();	
	my %group_child = ();	
	# processing a single instance
	%{$group_hosts{$group}} = %{$monarch_groups{$group}};
	#$parent_checks{'use_checks'} = $group_hosts{$options{'group'}}{'use_checks'};
	$parent_checks{'use_checks'} = $group_hosts{$options{'group'}}{'checks_enabled'};
	$parent_checks{'passive_checks_enabled'} = $group_hosts{$group}{'passive_checks_enabled'};
	$parent_checks{'active_checks_enabled'} = $group_hosts{$group}{'active_checks_enabled'};
	$options{'nagios_home'} = $group_hosts{$options{'group'}}{'nagios_etc'};
	unless ($options{'commit_step'} eq 'preflight' || $options{'export'}) { $destination = $group_hosts{$group}{'location'} }
	push @group_process_order, $group;
	my ($group_hosts, $order) = StorProc->get_group_hosts($options{'group'},\%parents_all,\%group_names,\%group_hosts,\@group_process_order,\%group_child);
	%group_hosts = %{ $group_hosts };
	@group_process_order = @{ $order };
	%nagios_cfg = %{$monarch_groups{$group}{'nagios_cfg'}};
	%nagios_cgi = %{$monarch_groups{$group}{'nagios_cgi'}};
	%resource_cfg = %{$monarch_groups{$group}{'resource'}};
	%nagios_cfg_misc = %{$monarch_groups{$group}{'nagios_cfg_misc'}};
}

sub process_standalone() {
	@errors = ();
	@out_files = ();
	%use = ();
	@extinfofiles = ();
	@group_process_order = ();
	$log = undef;
	%parent_checks = ();
	%host_group = ();
	%host_service_group = ();
	%group_hosts = ();	
	my %group_child = ();	
	%{$group_hosts{':all:'}{'macros'}} = ();
	%{$group_hosts{':all:'}{'hosts'}} = ();
	%{$group_hosts{':all:'}{'hostgroups'}} = ();
	my %parent_cfg = get_default_parent();
	%nagios_cfg = %{$parent_cfg{'nagios'}};
	%nagios_cgi = %{$parent_cfg{'nagios_cgi'}};
	%resource_cfg = %{$parent_cfg{'resource'}};
	%nagios_cfg_misc = %{$parent_cfg{'nagios_cfg_misc'}};
	
	if (%parent_top) {	
		# Process parent groups
		foreach my $group (sort keys %parent_top) {
			push @group_process_order, $group;
			%{$group_hosts{$group}} = %{$monarch_groups{$group}};
			my ($group_hosts_ref, $order) = StorProc->get_group_hosts($group,\%parents_all,\%group_names,\%group_hosts,\@group_process_order,\%group_child);
			%group_hosts = %{ $group_hosts_ref };
			@group_process_order = @{ $order };
		}
	} else {
		# No parent-child groups, just groups (if any) to organize hosts/services by file
		foreach my $group (sort keys %monarch_groups) {
			push @group_process_order, $group;
			%{$group_hosts{$group}} = %{$monarch_groups{$group}};
			my ($group_hosts_ref, $order) = StorProc->get_group_hosts($group,\%parents_all,\%group_names,\%group_hosts,\@group_process_order,\%group_child);
			%group_hosts = %{ $group_hosts_ref };
			@group_process_order = @{ $order };
		}
	}
	%{$group_hosts{':all:'}{'hosts'}} = StorProc->get_group_orphans();
	push @group_process_order, ':all:';
}


sub read_db() {
	# order matters
	get_timeperiods();
	get_commands();
	get_contacts();
	get_contact_groups();
	get_host_templates();
	get_hostextinfo();
	get_hosts();
	get_hostgroups();
	get_host_dependencies();
	get_serviceextinfo();
	get_services();
	get_escalations();
	get_groups();
}


sub gen_files() {
	# Set audit (always generate the audit log) and reset log
	$audit = 1;
	$log = undef;
	
	# Time stamps for file header 
	$date_time = StorProc->datetime();
	
	# Hash contains all Nagios directives by objects
	%property_list = StorProc->property_list();
	
	# Time periods and commands
	process_timeperiods();
	process_commands();
	
	# Create host objects
	process_hostextinfo();
	process_host_templates();
	process_hosts();
	process_host_dependencies(); 
	process_hostgroups();
	
	# Create service objects
	process_serviceextinfo();
	process_service_templates();
	process_services(); 
	process_service_dependencies();
	
	# Escalations
	process_escalation_templates();
	process_escalations();
	
	# Contact objects
	process_contactgroups();
	process_contact_templates();
	process_contacts(); 
	
	# Nagios configuration files
	process_nagios_cfg();
	process_nagios_cgi();
	process_resource_cfg();
	
	if ($options{'tarball'}) {
		my @outfiles = ();
		foreach my $file (@out_files) {
			push @outfiles, "$destination/$file";
		}
		use Archive::Tar;
		use IO::File;
		my $tar = Archive::Tar->new;
	    $tar->add_files(@outfiles);
		$date_time =~ s/\d+:\d+:\d+//g;
		$date_time =~ s/\s+/-/g;
		chop $date_time;
		unless ($group) { $group = 'complete' }
		my $filename = "$destination/$group-nagios-$date_time.tar";
		my $fh = new IO::File;
		$tar->write($filename);
		$fh->close;
		push @out_files, "$group-nagios-$date_time.tar";
	}
	if ($audit) {
		my $error = write_to_text_file("$destination/$log_file", $log);
		push(@errors, $error) if (defined($error));
		push @out_files, "$log_file";
	}
}


sub copy_files(@) {
	my $source_folder = $_[1] or return "Error: copy_files() requires source_folder argument";
	my $destination_folder = $_[2] or return "Error: copy_files() requires destination_folder argument";
	use File::Copy;
	opendir(DIR, $source_folder) or return "Error: Unable to open $source_folder $!";
	while (my $file = readdir(DIR)) {
		if ($file =~ /^\./) { next }
		copy("$source_folder/$file","$destination_folder/$file") or return "Error: Unable to copy $source_folder/$file to $destination_folder/$file $!";
	}
	close(DIR);	
}

sub rewrite_nagios_cfg(@) {
	my $preflight_folder = $_[1] || return "Error: rewrite_nagios_cfg() requires preflight path argument";
	my $nagios_etc = $_[2] || return "Error: rewrite_nagios_cfg() requires nagios etc path argument";
	my $nagios_out = undef;
	open (NAGIOS_CFG, "< $preflight_folder/nagios.cfg") or return "Error: Unable to open $preflight_folder/nagios.cfg $!";
	while (my $line = <NAGIOS_CFG>) {
		$line =~ s/$preflight_folder/$nagios_etc/;
		$nagios_out .= $line;
	}
    close (NAGIOS_CFG);
 	open (NAGIOS_CFG, "> $nagios_etc/nagios.cfg") or return "Error: Unable to open $nagios_etc/nagios.cfg $!";
	print NAGIOS_CFG $nagios_out;
    close (NAGIOS_CFG);    
    return;
}


sub build_instance(@) {
	%options = %{$_[1]};
	$group = $options{'group'};
	unless ($group) { $group = 'parent' }
	if ($options{'commit_step'} eq 'preflight') { $options{'nagios_home'} = $options{'destination'} }
	unless (($options{'commit_step'} eq 'preflight') || $options{'export'}) { $audit = 1 }

	read_db();
	if ($group eq 'parent') {
		process_standalone();
	} else {
		process_group();
	}
	gen_files();
	return \@out_files, \@errors;
}

sub build_all_instances(@) {
	%options = %{$_[1]};
	read_db();
	$audit = 1;
	foreach my $grp (keys %monarch_groups) {
		$group = $grp;
		if ($monarch_groups{$group}{'location'}) {
			if ($options{'commit_step'} eq 'preflight') { $options{'nagios_home'} = $monarch_groups{$group}{'location'} }
			$destination = $monarch_groups{$group}{'location'};		
			process_group();
			gen_files();
		}
		if (@errors) {
			return @errors;
		}
	}	
	$destination = $options{'destination'};
	process_standalone();
	gen_files();
}

############################################################################
# Build files -this sub is for backward compatibility and gen_files now drives file creation.
############################################################################

sub build_files(@) {
	my $user_acct = $_[1];
	$group = $_[2];
	my $commit_step = $_[3];
	my $export = $_[4];
	my $version = $_[5];
	my $nagios_home = $_[6];
	$destination = $_[7];
	my $tarball = $_[8];
	@out_files = ();
	%options = (
		'user_acct' => $user_acct,
		'group' => $group,
		'commit_step' => $commit_step,
		'export' => $export,
		'nagios_version' => $version,
		'nagios_home' => $nagios_home,
		'destination' => $destination,
		'tarball' => $tarball
		);
	if ($options{'commit_step'} eq 'preflight') { $nagios_home = $options{'destination'} }
	unless (($options{'commit_step'} eq 'preflight') || $export) { $audit = 1 }
	read_db();
	if ($options{'group'}) {	
		# processing a single instance		
		process_group();
	} else {
		# No group specified, so process standalone 
		process_standalone();
	}
	gen_files();
	return \@out_files, \@errors;
}

if ($debug) {
	%options = (
		'user_acct' => 'test user', 
		'group' => '',
		'commit_step' => 'preflight',
		'export' => '',
		'nagios_version' => '2.x',
		'nagios_home' => '/etc/nagios',
		'destination' => '',
		'tarball' => ''
		);
	StorProc->dbconnect;	
	build_all_instances('',\%options);
	StorProc->dbdisconnect;
}

1;
