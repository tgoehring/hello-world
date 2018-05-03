# MonArch - Groundwork Monitor Architect
# MonarchDoc.pm
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

package Doc;

sub properties_doc(@) {
	my $obj = $_[1];
	my $props = $_[2];
	my @props = @{$props};
	my %docs = ();
	$docs{'override'} = q(Inherit all values from template: Set all directives to inherit values from the selected template. Uncheck the left checkbox on the directives below to override the template values.);
	foreach my $prop (@props) {

# host template
		if ($obj eq 'host_templates' && $prop eq 'process_perf_data') {
			$docs{$obj eq 'host_templates' && $prop} = q(Process perf data: Optional. This directive is used to determine whether or not the processing of performance data is enabled for hosts using this template. Values:  unchecked = disable performance data processing, checked = enable performance data processing.);
		} elsif ($obj eq 'host_templates' && $prop eq 'retain_status_information') {
			$docs{$prop} = q(Retain status information: Optional. This directive is used to determine whether or not status-related information about the host is retained across program restarts. This is only useful if you have enabled state retention using the retain_state_information directive. Value:  unchecked = disable status information retention, checked = enable status information retention.);
		} elsif ($obj eq 'host_templates' && $prop eq 'flap_detection_enabled') {
			$docs{$obj eq 'host_templates' && $prop} = q(Flap detection enabled: Optional. This directive is used to determine whether or not flap detection is enabled for hosts using this template. Values:  unchecked = disable host flap detection, checked = enable host flap detection.);
		} elsif ($obj eq 'host_templates' && $prop eq 'low_flap_threshold') {
			$docs{$prop} = q(Low flap threshold: Optional. This directive is used to specify the low state change threshold used in flap detection for hosts using this template. If you set this directive to a value of 0, the program-wide value specified by the low_host_flap_threshold directive will be used.);
		} elsif ($obj eq 'host_templates' && $prop eq 'high_flap_threshold') {
			$docs{$prop} = q(High flap threshold: Optional. This directive is used to specify the high state change threshold used in flap detection for hosts using this template. If you set this directive to a value of 0, the program-wide value specified by the high_host_flap_threshold directive will be used.);
		} elsif ($obj eq 'host_templates' && $prop eq 'retain_nonstatus_information') {
			$docs{$prop} = q(Retain nonstatus information: Optional. This directive is used to determine whether or not non-status information about the host is retained across program restarts. This is only useful if you have enabled state retention using the retain_state_information directive. Value:  unchecked = disable non-status information retention, checked = enable non-status information retention.);
		} elsif ($prop eq 'checks_enabled') {
			$docs{$prop} = q(Checks enabled: Optional. This directive is used to determine whether or not checks of hosts using this template are enabled. Values:  unchecked = disable host checks, checked = enable host checks.);
		} elsif ($obj eq 'host_templates' && $prop eq 'active_checks_enabled') {
			$docs{$prop} = q(Active checkes enabled: This directive is used to determine whether or not active checks (either regularly scheduled or on-demand) of this host are enabled. Values: unchecked = disable active host checks, checked = enable active host checks.);
		} elsif ($obj eq 'host_templates' && $prop eq 'passive_checks_enabled') {
			$docs{$prop} = q(Passive checkes enabled: This directive is used to determine whether or not passive checks are enabled for this host. Values: uncehcked = disable passive host checks, checked = enable passive host checks.);
		} elsif ($obj eq 'host_templates' && $prop eq 'check_command') {
			$docs{$prop} = q(Host templates: Optional. This directive is used to specify the short name of the command that should be used to check if the host is up or down. Typically, this command would try to ping the host to see if it is 'alive'. The command must return a status of OK (0) or Nagios will assume the host is down. If you leave this argument blank, the host will not be checked - Nagios will always assume the host is up. This is useful if you are monitoring printers or other devices that are frequently turned off. The maximum amount of time that the notification command can run is controlled by the host_check_timeout option.);
		} elsif ($obj eq 'host_templates' && $prop eq 'max_check_attempts') {
			$docs{$prop} = q(Max check attempts: Required. This directive is used to define the number of times that Nagios will retry the host check command if it returns any state other than an OK state. Setting this value to 1 will cause Nagios to generate an alert without retrying the host check again. Note:  If you do not want to check the status of the host, you must still set this to a minimum value of 1. To bypass the host check, just leave the check_command option blank.);
		} elsif ($obj eq 'host_templates' && $prop eq 'check_interval') {
			$docs{$prop} = q(Check interval: Optional. NOTE: Do NOT enable regularly scheduled checks of a host unless you absolutely need to! Host checks are already performed on-demand when necessary, so there are few times when regularly scheduled checks would be needed. Regularly scheduled host checks can negatively impact performance. This directive is used to define the number of 'time units' between regularly scheduled checks of the host. Unless you've changed the interval_length directive from the default value of 60, this number will mean minutes.); 		
		} elsif ($obj eq 'host_templates' && $prop eq 'event_handler_enabled') {
			$docs{$prop} = q(Event handler enabled: Optional. This directive is used to determine whether or not the event handler for hosts using this template is enabled. Values:  unchecked = disable host event handler, checked = enable host event handler.);
		} elsif ($obj eq 'host_templates' && $prop eq 'event_handler') {
			$docs{$prop} = q(Event handler: Optional. This directive is used to specify the short name of the command that should be run whenever a change in the state of the host is detected (i.e. whenever it goes down or recovers). The maximum amount of time that the event handler command can run is controlled by the event_handler_timeout option.);
		} elsif ($obj eq 'host_templates' && $prop eq 'notifications_enabled') {
			$docs{$prop} = q(Notifications enabled: Optional. This directive is used to determine whether or not notifications for hosts using this template are enabled. Values:  unchecked = disable host notifications, checked = enable host notifications.);
		} elsif ($obj eq 'host_templates' && $prop eq 'notification_interval') {
			$docs{$prop} = q(Notification interval: Required. This directive is used to define the number of 'time units' to wait before re-notifying a contact that this server is still down or unreachable. Unless you've changed the interval_length directive from the default value of 60, this number will mean minutes. If you set this value to 0, Nagios will not re-notify contacts about problems for hosts using this template - only one problem notification will be sent out.);
		} elsif ($obj eq 'host_templates' && $prop eq 'notification_period') {
			$docs{$prop} = q(Notification period: Required. This directive is used to specify the short name of the time period during which notifications of events for hosts using this template can be sent out to contacts. If a host goes down, becomes unreachable, or recoveries during a time which is not covered by the time period, no notifications will be sent out.);
		} elsif ($obj eq 'host_templates' && $prop eq 'notification_options') {
			$docs{$prop} = q(Notification options: Required. This directive is used to determine when notifications for the host should be sent out. Valid options are a combination of one or more of the following:  Down checked = send notifications on a DOWN state, Unreachable checked = send notifications on an UNREACHABLE state, and Recovery checked = send notifications on recoveries (OK state). If you specify n (none) as an option, no host notifications will be sent out. Example:  If you specify Down and Recovery, notifications will only be sent out when the host goes DOWN and when it recovers from a DOWN state.);
		} elsif ($obj eq 'host_templates' && $prop eq 'stalking_options') {
			$docs{$prop} = q(Stalking options: Optional. This directive determines which host states 'stalking' is enabled for. Valid options are a combination of one or more of the following:  Up checked = stalk on UP states, Down checked = stalk on DOWN states, and Unreachable checked = stalk on UNREACHABLE states.);
		} elsif ($obj eq 'host_templates' && $prop eq 'obsess_over_host') {
			$docs{$prop} = q(Obsess over host: This directive determines whether or not checks for the host will be 'obsessed' over using the ochp_command (defined in Nagios main configuration). checked = enabled); 
		} elsif ($obj eq 'host_templates' && $prop eq 'check_freshness') {
			$docs{$prop} = q(Check freshness: This directive is used to determine whether or not freshness checks are enabled for hosts using this template. Checked = enable freshness checks.); 
		} elsif ($obj eq 'host_templates' && $prop eq 'freshness_threshold') {
			$docs{$prop} = q(Freshness threshold: This directive is used to specify the freshness threshold (in seconds) for hosts using this template. If you set this directive to a value of 0, Nagios will determine a freshness threshold to use automatically.); 
		} elsif ($obj eq 'host_templates' && $prop eq 'contactgroup') {
			$docs{$prop} = q(Contact groups: This is a list of the short names of the contact groups that should be notified whenever there are problems (or recoveries) with this host.);
# host dependencies
		} elsif ($obj eq 'host_dependencies' && $prop eq 'dependent_host') {
			$docs{$prop} = q(Dependent host: Required. This directive is used to identify the short name of the dependent host.);
		} elsif ($obj eq 'host_dependencies' && $prop eq 'parent_host') {
			$docs{$prop} = q(Parent host: Required. This directive is used to identify the short name of the host that is being depended upon.);
		} elsif ($obj eq 'host_dependencies' && $prop eq 'notification_failure_criteria') {
			$docs{$prop} = q(Notification failure criteria: Required. This directive is used to define the criteria that determine when notifications for the dependent host should not be sent out. If the host that is being depended upon is in one of the failure states we specify, notifications for the dependent host will not be sent to contacts. Valid options are a combination of one or more of the following:  o = fail on an UP state, d = fail on a DOWN state, and u = fail on an UNREACHABLE state. If you specify n (none) as an option, the notification dependency will never fail and notifications for the dependent host will always be sent out. Example:  If you specify d in this field, the notifications for the dependent host will not be sent out if the host that is being depended upon is in a DOWN state.);

# host / service ext info
		} elsif ($obj eq 'extended_host_info_templates' && $prop eq 'notes') {
			$docs{$prop} = q(This directive is used to define an optional string of notes pertaining to the host. If you specify a note here, you will see it in the extended information CGI (when you are viewing information about the specified host).);
		} elsif ($obj eq 'extended_host_info_templates' && $prop eq 'action_url') {
			$docs{$prop} = q(Action URL: Optional. This directive is used to define an optional URL that can be used to provide more actions to be performed on the host. If you specify an URL, you will see a link that says 'Extra Host Actions' in the extended information CGI (when you are viewing information about the specified host). Any valid URL can be used. If you plan on using relative paths, the base path will the the same as what is used to access the CGIs (i.e. /cgi-bin/nagios/).);
		} elsif ($obj eq 'extended_host_info_templates' && $prop eq 'notes_url') {
			$docs{$prop} = q(Notes URL: Optional. This option is used to define a URL that can be used to provide more information about the host. If you specify an URL, you will see a link that says 'Notes About This Host' in the extended information CGI (when you are viewing information about the specified host). Any valid URL can be used. If you plan on using relative paths, the base path will the the same as what is used to access the CGIs (i.e. /cgi-bin/nagios/). This can be very useful if you want to make detailed information on the host, emergency contact methods, etc. available to other support staff. Also, as this is a template, you may use macros $HOSTNAME$ and $HOSTADDRESS$ in the URL.);
		} elsif ($obj eq 'extended_service_info_templates' && $prop eq 'notes') {
			$docs{$prop} = q(This directive is used to define an optional string of notes pertaining to the service. If you specify a note here, you will see the it in the extended information CGI (when you are viewing information about the specified service).);
		} elsif ($obj eq 'extended_service_info_templates' && $prop eq 'notes_url') {
			$docs{$prop} = q(Notes URL: Optional. This option is used to define a URL that can be used to provide more information about the host. If you specify an URL, you will see a link that says 'Notes About This Host' in the extended information CGI (when you are viewing information about the specified host). Any valid URL can be used. If you plan on using relative paths, the base path will the the same as what is used to access the CGIs (i.e. /cgi-bin/nagios/). This can be very useful if you want to make detailed information on the host, emergency contact methods, etc. available to other support staff. Also, as this is a template, you may use macros $HOSTNAME$, $HOSTADDRESS$, $SERVICENAME$, $SERVICEDESC$ and $SERVICEDESCRIPTION$ in the URL.);
		} elsif ($obj eq 'extended_service_info_templates' && $prop eq 'action_url') {
			$docs{$prop} = q(Action URL: Optional. This directive is used to define an optional URL that can be used to provide more actions to be performed on the service. If you specify an URL, you will see a link that says 'Extra Service Actions' in the extended information CGI (when you are viewing information about the specified service). Any valid URL can be used. If you plan on using relative paths, the base path will the the same as what is used to access the CGIs (i.e. /cgi-bin/nagios/).);
		} elsif ($prop eq 'script') {
			$docs{$prop} = q(Script: Optional custom script. Enter full path, file name and command line arguments. Use Control -> Run Extended Info Scripts to execute custom scripts for objects assigned this template. Arguements can include $HOSTNAME$ and $SERVICENAME$ macros.);
		} elsif ($prop eq 'icon_image') {
			$docs{$prop} = q(Icon image: Optional. This variable is used to define the name of a GIF, PNG, or JPG image that should be associated with this host. This image will be displayed in the status and extended information CGIs. The image will look best if it is 40x40 pixels in size. Images for hosts are assumed to be in the logos/ subdirectory in your HTML images directory (i.e. /usr/local/nagios/share/images/logos).);
		} elsif ($prop eq 'icon_image_alt') {
			$docs{$prop} = q(Icon image alt: Optional. This variable is used to define an optional string that is used in the ALT tag of the image specified by the <icon_image> argument. The ALT tag is used in the status, extended information and statusmap CGIs.);
		} elsif ($prop eq 'vrml_image') {
			$docs{$prop} = q(VRML image: Optional. This variable is used to define the name of a GIF, PNG, or JPG image that should be associated with this host. This image will be used as the texture map for the specified host in the statuswrl CGI. Unlike the image you use for the <icon_image> variable, this one should probably not have any transparency. If it does, the host object will look a bit wierd. Images for hosts are assumed to be in the logos/ subdirectory in your HTML images directory (i.e. /usr/local/nagios/share/images/logos).);
		} elsif ($prop eq 'statusmap_image') {
			$docs{$prop} = q(Statusmap image: Optional. This variable is used to define the name of an image that should be associated with this host in the statusmap CGI. You can specify a JPEG, PNG, and GIF image if you want, although I would strongly suggest using a GD2 format image, as other image formats will result in a lot of wasted CPU time when the statusmap image is generated. GD2 images can be created from PNG images by using the pngtogd2 utility supplied with Thomas Boutell's gd library. The GD2 images should be created in uncompressed format in order to minimize CPU load when the statusmap CGI is generating the network map image. The image will look best if it is 40x40 pixels in size. You can leave these option blank if you are not using the statusmap CGI. Images for hosts are assumed to be in the logos/ subdirectory in your HTML images directory (i.e. /usr/local/nagios/share/images/logos).);
		} elsif ($prop eq '2d_coords') {
			$docs{$prop} = q(2d coords: Optional. This variable is used to define coordinates to use when drawing the host in the statusmap CGI. Coordinates should be given in positive integers, as the correspond to physical pixels in the generated image. The origin for drawing (0,0) is in the upper left hand corner of the image and extends in the positive x direction (to the right) along the top of the image and in the positive y direction (down) along the left hand side of the image. For reference, the size of the icons drawn is usually about 40x40 pixels (text takes a little extra space). The coordinates you specify here are for the upper left hand corner of the host icon that is drawn. Note:  Don't worry about what the maximum x and y coordinates that you can use are. The CGI will automatically calculate the maximum dimensions of the image it creates based on the largest x and y coordinates you specify.);
		} elsif ($prop eq '3d_coords') {
			$docs{$prop} = q(3d coords: Optional. This variable is used to set coordinates to use when drawing the host in the statuswrl CGI. Coordinates can be positive or negative real numbers. The origin for drawing is (0.0,0.0,0.0). For reference, the size of the host cubes drawn is 0.5 units on each side (text takes a little more space). The coordinates you specify here are used as the center of the host cube.);

# hostgroup
		} elsif ($obj eq 'hostgroups' && $prop eq 'alias') {
			$docs{$prop} = q(Alias: Required. This directive is used to define a longer name or description used to identify the host group. It is provided in order to allow you to more easily identify a particular host group.);
		} elsif ($obj eq 'hostgroups' && $prop eq 'members') {
			$docs{$prop} = q(Members: Required. This is a list of the short names of hosts that should be included in this group.);
		} elsif ($obj eq 'hostgroups' && $prop eq 'contactgroup') {
			$docs{$prop} = q(Contactgroup: Required Nagios 1.x. This is a list of the contact groups that should be notified whenever there are problems (or recoveries) with any of the hosts in this host group. When writing for 2.x and up, contact groups are correctly assigned to the hosts.);
		} elsif ($obj eq 'hostgroups' && $prop eq 'hostgroup_escalation_id') {
			$docs{$prop} = q(Hostgroup escalation id: Optional. Select the hostgrooup escalation tree applicable to this hostgroup (see Escalations -> Escalation Trees). (Note users of Nagios 2.x and up may use this directive or the Host escalation id directive to achieve the same result.));
		} elsif ($obj eq 'hostgroups' && $prop eq 'host_escalation_id') {
			$docs{$prop} = q(Host escalation id: Optional. Select the host escalation tree applicable to this hostgroup in (see Escalations -> Escalation Trees). All hosts in the hostgroup receive the same host escalation.);
		} elsif ($obj eq 'hostgroups' && $prop eq 'service_escalation_id') {
			$docs{$prop} = q(Service escalation id: Optional. Select the service escalation tree applicable to this hostgroup in (see Escalations -> Escalation Trees). All services on each host in the hostgroup receive the same host escalation.);

# service template
		} elsif ($obj eq 'service_templates' && $prop eq 'template') {
			$docs{$prop} = q(Service template: Required. Select the service template most suitable for this service. Note inheritance (left check box) on directives below. To override the template value, uncheck the left check box.);
		} elsif ($obj eq 'service_templates' && $prop eq 'is_volatile') {
			$docs{$prop} = q(Is volatile: This directive is used to denote whether the service is 'volatile'. Services are normally not volatile. More information on volatile service and how they differ from normal services can be found in the Nagios documentation. Unchecked = service is not volatile, checked = service is volatile.);
		} elsif ($obj eq 'service_templates' && $prop eq 'check_period') {
			$docs{$prop} = q(Check period: Required. This directive is used to specify the short name of the time period during which active checks of this service can be made.);
		} elsif ($obj eq 'service_templates' && $prop eq 'max_check_attempts') {
			$docs{$prop} = q(Max check attempts: Required. This directive is used to define the number of times that Nagios will retry the service check command if it returns any state other than an OK state. Setting this value to 1 will cause Nagios to generate an alert without retrying the service check again.);
		} elsif ($obj eq 'service_templates' && $prop eq 'normal_check_interval') {
			$docs{$prop} = q(Normal check interval: Required. This directive is used to define the number of 'time units' to wait before scheduling the next 'regular' check of the service. 'Regular' checks are those that occur when the service is in an OK state or when the service is in a non-OK state, but has already been rechecked max_attempts number of times. Unless you've changed the interval_length directive from the default value of 60, this number will mean minutes.);
		} elsif ($obj eq 'service_templates' && $prop eq 'retry_check_interval') {
			$docs{$prop} = q(Retry check interval: Required. This directive is used to define the number of 'time units' to wait before scheduling a re-check of the service. Services are rescheduled at the retry interval when they have changed to a non-OK state. Once the service has been retried max_attempts times without a change in its status, it will revert to being scheduled at its 'normal' rate as defined by the check_interval value. Unless you've changed the interval_length directive from the default value of 60, this number will mean minutes.);
		} elsif ($obj eq 'service_templates' && $prop eq 'active_checks_enabled') {
			$docs{$prop} = q(Active checks enabled: Optional. This directive is used to determine whether or not active checks of this service are enabled. Values:  unchecked = disable active service checks, checked = enable active service checks.);
		} elsif ($obj eq 'service_templates' && $prop eq 'passive_checks_enabled') {
			$docs{$prop} = q(Passive checks enabled: Optional. This directive is used to determine whether or not passive checks of this service are enabled. Values:  unchecked = disable passive service checks, checked = enable passive service checks.);
		} elsif ($obj eq 'service_templates' && $prop eq 'parallelize_check') {
			$docs{$prop} = q(Parallelize check: Optional. This directive is used to determine whether or not the service check can be parallelized. By default, all service checks are parallelized. Disabling parallel checks of services can result in serious performance problems. Values:  unchecked = service check cannot be parallelized (use with caution!), checked = service check can be parallelized.);
		} elsif ($obj eq 'service_templates' && $prop eq 'obsess_over_service') {
			$docs{$prop} = q(Obsess over service: This value determines whether or not Nagios will 'obsess' over service checks results and run the obsessive compulsive service processor command you define. This option is useful for performing distributed monitoring. If you're not doing distributed monitoring, don't enable this option.); 
		} elsif ($obj eq 'service_templates' && $prop eq 'check_freshness') {
			$docs{$prop} = q(Check freshness: Optional. This directive is used to determine whether or not freshness checks are enabled for this service. Values:  unchecked = disable freshness checks, checked = enable freshness checks.);
		} elsif ($obj eq 'service_templates' && $prop eq 'freshness_threshold') {
			$docs{$prop} = q(Freshness threshold: Optional. This directive is used to specify the freshness threshold (in seconds) for this service. If you set this directive to a value of 0, Nagios will determine a freshness threshold to use automatically.);
		} elsif ($obj eq 'service_templates' && $prop eq 'notifications_enabled') {
			$docs{$prop} = q(Notifications enabled: Optional. This directive is used to determine whether or not notifications for this service are enabled. Values:  unchecked = disable service notifications, checked = enable service notifications.);
		} elsif ($obj eq 'service_templates' && $prop eq 'notification_interval') {
			$docs{$prop} = q(Notification interval: Required. This directive is used to define the number of 'time units' to wait before re-notifying a contact that this service is still in a non-OK state. Unless you've changed the interval_length directive from the default value of 60, this number will mean minutes. If you set this value to 0, Nagios will not re-notify contacts about problems for this service - only one problem notification will be sent out, unless there has been a state change.);
		} elsif ($obj eq 'service_templates' && $prop eq 'notification_period') {
			$docs{$prop} = q(Notification period: Required. This directive is used to specify the short name of the time period during which notifications of events for this service can be sent out to contacts. No service notifications will be sent out during times which is not covered by the time period.);
		} elsif ($obj eq 'service_templates' && $prop eq 'notification_options') {
			$docs{$prop} = q(Notification options: Required. This directive is used to determine when notifications for the service should be sent out. Valid options are a combination of one or more of the following: Wawning checked = send notifications on a WARNING state, Unknown checked = send notifications on an UNKNOWN state, Critical checked = send notifications on a CRITICAL state, and Recovery checked = send notifications on recoveries (OK state). If you specify none as an option, no service notifications will be sent out.); 
		} elsif ($obj eq 'service_templates' && $prop eq 'event_handler_enabled') {
			$docs{$prop} = q(Event handler enabled: Optional. This directive is used to determine whether or not the event handler for this service is enabled. Values:  unchecked = disable service event handler, checked = enable service event handler.);
		} elsif ($obj eq 'service_templates' && $prop eq 'event_handler') {
			$docs{$prop} = q(Event handler: Optional. This directive is used to specify the short name of the command that should be run whenever a change in the state of the host is detected (i.e. whenever it goes down or recovers). The maximum amount of time that the event handler command can run is controlled by the event_handler_timeout option. );
		} elsif ($obj eq 'service_templates' && $prop eq 'flap_detection_enabled') {
			$docs{$prop} = q(Flap detection enabled: Optional. This directive is used to determine whether or not flap detection is enabled for this service. Values:  unchecked = disable service flap detection, checked = enable service flap detection.);
		} elsif ($obj eq 'service_templates' && $prop eq 'low_flap_threshold') {
			$docs{$prop} = q(Low flap threshold: Optional. This directive is used to specify the low state change threshold used in flap detection for this service. If you set this directive to a value of 0, the program-wide value specified by the low_service_flap_threshold directive will be used.);
		} elsif ($obj eq 'service_templates' && $prop eq 'high_flap_threshold') {
			$docs{$prop} = q(High flap threshold: Optional. This directive is used to specify the high state change threshold used in flap detection for this service. If you set this directive to a value of 0, the program-wide value specified by the high_service_flap_threshold directive will be used.);
		} elsif ($obj eq 'service_templates' && $prop eq 'retain_status_information') {
			$docs{$prop} = q(Retain status information: Optional. This directive is used to determine whether or not status-related information about the service is retained across program restarts. This is only useful if you have enabled state retention using the retain_state_information directive. Value:  unchecked = disable status information retention, checked = enable status information retention.);
		} elsif ($obj eq 'service_templates' && $prop eq 'retain_nonstatus_information') {
			$docs{$prop} = q(Retain nonstatus information: Optional. This directive is used to determine whether or not non-status information about the service is retained across program restarts. This is only useful if you have enabled state retention using the retain_state_information directive. Value:  unchecked = disable non-status information retention, checked = enable non-status information retention.);
		} elsif ($obj eq 'service_templates' && $prop eq 'check_command') {
			$docs{$prop} = q(Check command: Optional, sets the default value. Select the command that Nagios will run in order to check the status of the service. );
		} elsif ($obj eq 'service_templates' && $prop eq 'command_line') {
			$docs{$prop} = q(Command line: Optional, sets the default value. If check command requires arguments, enter the check command with command arguments separated by a ! character. Example: check-disk!/dev/sda1); 
		} elsif ($obj eq 'service_templates' && $prop eq 'process_perf_data') {
			$docs{$obj eq 'host_templates' && $prop} = q(Process perf data: Optional. This directive is used to determine whether or not the processing of performance data is enabled for this service. Values:  unchecked = disable performance data processing, checked = enable performance data processing.);

# service_dependency_templates
		} elsif ($obj eq 'service_dependency_templates' && $prop eq 'service_name') {
			$docs{$prop} = q(Service name: Required. Specify the parent service name.);
		} elsif ($obj eq 'service_dependency_templates' && $prop eq 'execution_failure_criteria') {
			$docs{$prop} = q(Execution failure criteria: Optional. This directive is used to specify the criteria that determine when the dependent service should not be executed. If the service that is being depended upon is in one of the failure states we specify, the dependent service will not be executed. Valid options are a combination of one or more of the following:  Okay checked = fail on an OK state, Warning checked = fail on a WARNING state, Unknown checked = fail on an UNKNOWN state, and Critical checked = fail on a CRITICAL state. If you specify n (none) as an option, the execution dependency will never fail and checks of the dependent service will always be executed. Example:  If you specify o,c,u in this field, the dependent service will not be executed if the service that's being depended upon is in either an OK, a CRITICAL, or an UNKNOWN state.);
		} elsif ($obj eq 'service_dependency_templates' && $prop eq 'notification_failure_criteria') {
			$docs{$prop} = q(Notification failure criteria: Optional. This directive is used to define the criteria that determine when notifications for the dependent service should not be sent out. If the service that is being depended upon is in one of the failure states we specify, notifications for the dependent service will not be sent to contacts. Valid options are a combination of one or more of the following:  Okay checked = fail on an OK state, Warning checked = fail on a WARNING state, Unknown checked = fail on an UNKNOWN state, and Critical checked = fail on a CRITICAL state. If you specify n (none) as an option, the notification dependency will never fail and notifications for the dependent service will always be sent out. Example:  If you specify w in this field, the notifications for the dependent service will not be sent out if the service that is being depended upon is in a WARNING state.);
# contact template
		} elsif ($obj eq 'contact_templates' && $prop eq 'host_notification_period') {
			$docs{$prop} = q(Host notification period: Required. This directive is used to specify the short name of the time period during which the contact can be notified about host problems or recoveries. You can think of this as an 'on call' time for host notifications for the contact. Read the documentation on time periods for more information on how this works and potential problems that may result from improper use.);
		} elsif ($obj eq 'contact_templates' && $prop eq 'service_notification_period') {
			$docs{$obj eq 'contact_templates' && $prop} = q(Service notification period: Required. This directive is used to specify the short name of the time period during which the contact can be notified about service problems or recoveries. You can think of this as an 'on call' time for service notifications for the contact. Read the documentation on time periods for more information on how this works and potential problems that may result from improper use.);
		} elsif ($obj eq 'contact_templates' && $prop eq 'host_notification_options') {
			$docs{$prop} = q(Host notification options: Required. This directive is used to define the host states for which notifications can be sent out to this contact. Valid options are a combination of one or more of the following:  Down checked = notify on DOWN host states, Unreachable checked = notify on UNREACHABLE host states, and Recovery checked = notify on host recoveries (UP states). If you specify None as an option, the contact will not receive any type of host notifications.);
		} elsif ($obj eq 'contact_templates' && $prop eq 'service_notification_options') {
			$docs{$prop} = q(Service notification options: Required. This directive is used to define the service states for which notifications can be sent out to this contact. Valid options are a combination of one or more of the following:  Warning checked = notify on WARNING service states, Unknown checked = notify on UNKNOWN service states, Critical checked = notify on CRITICAL service states, and Recovery checked = notify on service recoveries (OK states). Users of Nagios 2.x and up may also specify notifications on flapping starts and stops for hosts and services. If you specify None as an option, the contact will not receive any type of service notifications.);
		} elsif ($obj eq 'contact_templates' && $prop eq 'host_notification_commands') {
			$docs{$prop} = q(Host notification commands: Optional. This directive is used to define a list of the short names of the commands used to notify the contact of a host problem or recovery. All notification commands are executed when the contact needs to be notified. The maximum amount of time that a notification command can run is controlled by the notification_timeout option.);
		} elsif ($obj eq 'contact_templates' && $prop eq 'service_notification_commands') {
			$docs{$prop} = q(Service notification commands: Optional. This directive is used to define a list of the short names of the commands used to notify the contact of a service problem or recovery. All notification commands are executed when the contact needs to be notified. The maximum amount of time that a notification command can run is controlled by the notification_timeout option.);

# contacts 
		} elsif ($obj eq 'contacts' && $prop eq 'template') {
			$docs{$prop} = q(Contact template: Required. Select the contact template most suitable for this contact. Note inheritance (left check box) on directives below. To override the template value, uncheck the left check box.);
		} elsif ($obj eq 'contacts' && $prop eq 'alias') {
			$docs{$prop} = q(Alias: Required. This directive is used to define a longer name or description for the contact. Under the rights circumstances, the $CONTACTALIAS$ macro will contain this value.);
		} elsif ($obj eq 'contacts' && $prop eq 'email') {
			$docs{$prop} = q(Email: Optional. This directive is used to define an email address for the contact. Depending on how you configure your notification commands, it can be used to send out an alert email to the contact. Under the right circumstances, the $CONTACTEMAIL$ macro will contain this value.);
		} elsif ($obj eq 'contacts' && $prop eq 'pager') {
			$docs{$prop} = q(Pager: Optional. This directive is used to define a pager number for the contact. It can also be an email address to a pager gateway (e.g. pagejoe@pagenet.com). Depending on how you configure your notification commands, it can be used to send out an alert page to the contact. Under the right circumstances, the $CONTACTPAGER$ macro will contain this value.);
		} elsif ($obj eq 'contacts' && $prop eq 'notification') {
			$docs{$prop} = q(Pager: Required. Select the period for which this contact is available to receive notifications.);

# contactgroups
		} elsif ($obj eq 'contactgroups' && $prop eq 'alias') {
			$docs{$prop} = q(Alias: Required. This directive is used to define a longer name or description used to identify the contact group.);
		} elsif ($obj eq 'contactgroups' && $prop eq 'contact') {
			$docs{$prop} = q(Contacts: Required. Assign contacts to the group.);

# timeperiods
		} elsif ($obj eq 'time_periods' && $prop eq 'alias') {
			$docs{$prop} = q(Alias: Required. This directive is a longer name or description used to identify the time period.);
		} elsif ($obj eq 'time_periods' && $prop eq 'sunday') {
			$docs{$prop} = q(Sunday-Saturday: Optional. The Sunday through Saturday directives are comma-delimited lists of time ranges that are 'valid' times for a particular day of the week. Notice that there are seven different days for which you can define time ranges (Sunday through Saturday). Each time range is in the form of HH: MM-HH: MM, where hours are specified on a 24 hour clock. For example, 00:15-24: 00 means 12:15am in the morning for this day until 12:00am midnight (a 23 hour, 45 minute total time range). If you wish to exclude an entire day from the timeperiod, simply do not include it in the timeperiod definition.);

# commands
		} elsif ($obj eq 'commands' && $prop eq 'type') {
			$docs{$prop} = q(Type: Required. Specify command type: check = service/host check commands, handlers; notify = notification commands; other = other commands (i.e. performance data collectors).);
		} elsif ($obj eq 'commands' && $prop eq 'command_line') {
			$docs{$prop} = q(Command line: Required. This directive is used to define what is actually executed by Nagios when the command is used for service or host checks, notifications, or event handlers. Before the command line is executed, all valid macros are replaced with their respective values. See the documentation on macros for determining when you can use different macros. Note that the command line is not surrounded in quotes. Also, if you want to pass a dollar sign ($) on the command line, you have to escape it with another dollar sign.);
		} elsif ($obj eq 'commands' && $prop eq 'usage') {
			$docs{$prop} = q(Usage: This shows how the command is defined on the service.);

# escalation_templates
		} elsif ($obj =~ /escalation_templates/ && $prop eq 'first_notification') {
			$docs{$prop} = q(First notification: Required. This directive is a number that identifies the first notification for which this escalation is effective. For instance, if you set this value to 3, this escalation will only be used if the host is down or unreachable long enough for a third notification to go out or if the service is in a non-OK state long enough for a third notification to go out.);
		} elsif ($obj =~ /escalation_templates/ && $prop eq 'last_notification') {
			$docs{$prop} = q(Last notification: Required. This directive is a number that identifies the last notification for which this escalation is effective. For instance, if you set this value to 5, this escalation will not be used if more than five notifications are sent out for the host or service. Setting this value to 0 means to keep using this escalation entry forever (no matter how many notifications go out).);
		} elsif ($obj =~ /escalation_templates/ && $prop eq 'notification_interval') {
			$docs{$prop} = q(Notification interval: Required. This directive is used to determine the time interval (Unless you have changed the interval_length directive from the default value of 60, this number will mean minutes.) at which notifications should be made while this escalation is valid. If you specify a value of 0 for the interval, Nagios will send the first notification only, and will then prevent any more problem notifications from being sent out for the host. Specifying any other value will send continuous notifications at the time interval specified. Note:  If multiple escalation entries for a host overlap for one or more notification ranges, the smallest notification interval from all escalation entries is used.);
		} elsif ($obj =~ /escalation_templates/ && $prop eq 'service_description') {
			$docs{$prop} = q(Service description: Required. This directive is used to identify the description of the service the escalation should apply to.);
		} elsif ($obj =~ /escalation_templates/ && $prop eq 'escalation_period') {
			$docs{$prop} = q(Escalation period: Optional. This directive is used to specify the short name of the time period during which this escalation is valid. If this directive is not specified, the escalation is considered to be valid during all times.);
		} elsif ($obj =~ /service_escalation_templates/ && $prop eq 'escalation_options') {
			$docs{$prop} = q(Escalation options: Optional. This directive is used to define the criteria that determine when this service escalation is used. The escalation is used only if the service is in one of the states specified in this directive. If this directive is not specified in a service escalation, the escalation is considered to be valid during all service states. Valid options are a combination of one or more of the following: recovery = escalate on an OK (recovery) state, warning = escalate on a WARNING state, unknown = escalate on an UNKNOWN state, and critical = escalate on a CRITICAL state. Example: If you specify warning in this field, the escalation will only be used if the service is in a WARNING state.); 
		} elsif ($obj =~ /host_escalation_templates|hostgroup_escalation_templates/ && $prop eq 'escalation_options') {
			$docs{$prop} = q(Escalation options: Optional. This directive is used to define the criteria that determine when this host escalation is used. The escalation is used only if the host is in one of the states specified in this directive. If this directive is not specified in a host escalation, the escalation is considered to be valid during all host states. Valid options are a combination of one or more of the following: recovery = escalate on an UP (recovery) state, down = escalate on a DOWN state, and unreachable = escalate on an UNREACHABLE state. Example: If you specify d in this field, the escalation will only be used if the host is in a DOWN state.);
		} elsif ($obj =~ /escalation_templates/ && $prop eq 'escalation_period') {
			$docs{$prop} = q(Escalation period: This directive is used to specify the short name of the time period during which this escalation is valid. If this directive is not specified, the escalation is considered to be valid during all times.);
		} elsif ($obj =~ /escalation_templates/ && $prop eq 'escalation_options') {
			$docs{'escalation_options'} = q(Escalation options: This directive is used to define the criteria that determine when this service escalation is used. The escalation is used only if the service is in one of the states specified in this directive. If this directive is not specified in a service escalation, the escalation is considered to be valid during all service states. Valid options are a combination of one or more of the following: r = escalate on an OK (recovery) state, w = escalate on a WARNING state, u = escalate on an UNKNOWN state, and c = escalate on a CRITICAL state. Example: If you specify w in this field, the escalation will only be used if the service is in a WARNING state.);
		}
	}
	return %docs;
}

sub services() {
	my %docs = ();
	$docs{'description'} = q(Description: Optional. Store comments or instructions here.);
	$docs{'service_template'} = q(Service template: Required.  This option sets the default template for this service name definitions in 'Hosts -> New Host Wizard' and 'Hosts -> Modify -> Services -> Service Detail'.);
	$docs{'use_template_command'} = q(Inherit check from template: If checked, the check command and command line options are derived from the service template. Be careful to ensure the service template has a check command defined before checking this option.);
	$docs{'check_command'} = q(Check command: If 'Inherit check from template' is unchecked, select the command that Nagios will run in order to check the status of the service.);
	$docs{'command_line'} = q(Command line: If 'Inherit check from template' is unchecked and if check command requires arguments, enter the check command with command arguments separated by a ! character. Example: check-disk!/dev/sda1);
	$docs{'dependency'} = q(Service dependency template: Optional. Select the template that defines a parent service relationship on a given host. Monarch will create a service dependency relationship on a host assigned this service name. To define a dependency for a service running on a different host use 'Hosts -> Modify -> Services -> Service Dependency' and select the parent host. Be careful to ensure that the parent service is assigned to the parent host definition and is included in the relevant service profiles.);
	$docs{'parent_host'} = q(Parent host: Select the host on which the parent service runs. Choose 'same host' if the parent and child reside on the same host.);
	$docs{'ext_info'} = q(Extended info template: Optional. Defines extended service information for this service name. The template controls the icon and url link as seen in Nagios for hosts assigned this service definition.);
	$docs{'escalation'} = q(Service escalation tree: Optional. Select an escalation tree appropriate for this service name. To avoid amplified notifications (i.e. multiple notifications for the same event), a service escalation assigned to a service name should not also be assigned to the host or the host group.);
	$docs{'externals'} = q(Externals: Custom client specific option.);
	$docs{'dependencies'} = q(Add or remove service dependencies here. To add a dependency, select from the dependency list and after the screen refreshes, choose the appropriate host, or select same host if the dependency is for services on the same host.);
	$docs{'service_check'} = q(If you are satisfied with the check as inherited from the template, do nothing on this page. Otherwise uncheck the inherit checkbox and make the necessary changes. Use the test button to check the argument values, but bear in mind that the check command is run under the web servers account, so there may be issues with certain checks.);
	$docs{'service_profiles'} = q(Add or remove service profiles using this service. Adding or removing a service profile here has no effect on the service profile's member hosts until the apply tab is used on the service profile (or host profile), or the profile is applied on the individual hosts.);
	$docs{'apply'} = q(Select from the options what to apply to the listed hosts. Replace/Merge refers to the properties on the detail page.);
	return %docs;
}

sub service_profiles() {
	my %docs = ();
	$docs{'description'} = q(Description: Optional. Store comments or instructions here.);
	$docs{'services'} = q(Services: Required. Select services from the right hand list to be included in this profile. Where service dependencies have been assigned to service names, be careful to include the parent service names as defined in the dependency templates.);
	$docs{'file'} = q(File: Required. Select the default file for services in the profile. To add files go to 'Control -> Files -> Add a host/service file'.);
	$docs{'assign_hosts'} = q(Add or remove hosts to be managed by this profile. After saving, use the apply tab to instantiate changes to the host. Removing a host means the host is no longer managed by this profile. The host will retain its properties until the host is assigned and applied to another profile, or modified individually.);
	$docs{'assign_hostgroups'} = q(Add or remove host groups to be managed by this profile. After saving, use the apply tab to instantiate changes to the member hosts. Removing a host group means the host group is no longer managed by this profile. The member hosts will retain their properties until the host group is assigned and applied to another profile, or the member hosts are modified individually.);
	$docs{'host_profiles'} = q(Add or remove host profiles to which this profile is assigned. Adding or removing a host profile here has no effect the host profile's member hosts until the apply tab is used on the host profile, or the profile is applied on the individual hosts.);
	$docs{'apply'} = q(Select apply to hosts and/or apply to hostgroups to push changes to hosts, and select from the options what to apply. If you select replace existing services, all services are removed from the host and new ones are added from the profile. Merge with existing services means any existing service on the host remains unchanged.);
	return %docs;
}

sub host_profile_profile() {
	my %docs = ();
	$docs{'description'} = q(Description: Optional. Store comments or instructions here.);
	$docs{'extended_host_info_template'} = q(Extended host info template: Optional. Defines extended host information for this host profile. The template controls the icon and url link as seen in Nagios for hosts assigned this profile.);
	$docs{'file'} = q(File: Required. Select the default file for hosts assigned this profile. To add files go to 'Control -> Files -> Add a host/service file'.);
	return %docs;
}

sub host_profile() {
	my %docs = ();
	$docs{'hostgroups'} = q(Add or remove host groups for hosts using this profile. After saving, use the apply tab to push changes to the hosts. This option also sets the default host group or host groups in New Host Wizard.);
	$docs{'assign_hosts'} = q(Add or remove hosts to be managed by this profile. After saving, use the apply tab to instantiate changes to the host. Removing a host means the host is no longer managed by this profile. The host will retain its properties until the host is assigned and applied to another profile, or modified individually.);
	$docs{'assign_hostgroups'} = q(Add or remove host groups to be managed by this profile. After saving, use the apply tab to instantiate changes to the member hosts. Removing a host group means the host group is no longer managed by this profile. The member hosts will retain their properties until the host group is assigned and applied to another profile, or the member hosts are modified individually.);
	$docs{'parents'} = q(Add or remove parent hosts for hosts using this profile. After saving, use the apply tab to push changes to the hosts. This option also sets the default parents in New Host Wizard.);
	$docs{'description'} = q(Description: Optional. Store comments or instructions here.);
	$docs{'extended_host_info_template'} = q(Extended host info template: Optional. Defines extended host information for this host profile. The template controls the icon and url link as seen in Nagios for hosts assigned this profile.);
	$docs{'template'} = q(Template: Required. Select the host template most suitable for this host profile.);
	$docs{'file'} = q(File: Required. Select the file name associated with hosts using this host profile.);
	$docs{'service_profile'} = q(Service profile: Required. Select the default service profile for this host profile.);
	$docs{'escalations'} = q(Add or remove escalations for hosts using this profile. Assigning a service escalation sets the escalation for all services on hosts using this profile. After saving, use the apply tab to push changes to the hosts.);
	$docs{'host_escalation'} = q(Host escalation: Optional. Select an escalation tree appropriate for hosts assigned this profile. A host escalation assigned to a host using this profile should not also be assigned to a hostgroup in which the host is a member.);
	$docs{'service_escalation'} = q(Service escalation: Optional. Select an escalation tree appropriate for all services on hosts using this profile. When a service escalation is assigned to a host, all services on that host will use the same escalation. To use different escalations for different services on the same host, each service must have its own escalation. In that case, do not assign a service escalation here.);
	$docs{'service_profiles'} = q(Add or remove service profiles for hosts using this profile. After saving, use the apply tab to push changes to the hosts. This option also sets the default service profiles in the New Host Wizard.);
	$docs{'apply'} = q(Select apply to hosts and/or apply to hostgroups to push changes to hosts, and select from the options what to apply. Applying parents, hostgroups, detail, and/or escalations will replace those values found on the hosts. If you select replace existing services, all services are removed from the host and new ones are added from the profiles. Merge with existing services means any existing service on the host remains unchanged.);
	return %docs;
}

sub host_wizard_vitals() {
	my %docs = ();
	$docs{'alias'} = q(Alias: Required. This directive is used to define a longer name or description used to identify the host. It is provided in order to allow you to more easily identify a particular host.);
	$docs{'address'} = q(Address: Required. This directive is used to define the address of the host. Normally, this is an IP address, although it could really be anything you want (so long as it can be used to check the status of the host). You can use a FQDN to identify the host instead of an IP address, but if DNS services are not availble this could cause problems. When used properly, the $HOSTADDRESS$ macro will contain this address. Note: If you do not specify an address directive in a host definition, the name of the host will be used as its address. A word of caution about doing this, however - if DNS fails, most of your service checks will fail because the plugins will be unable to resolve the host name.);
	$docs{'host_profile'} = q(Host profile: Optional. Host Profiles can be used to aid the design and management of hosts.);

	return %docs;
}

sub host_wizard_attribs_1() {
	my %docs = ();
	$docs{'host_template'} = q(Host template: Required. Select the host template most suitable for this host.);
	$docs{'parents'} = q(Parents: Optional. Assign this host one or more parents. Parent child relationships may also be managed via 'Hosts -> Parent Child'. );
	$docs{'file'} = q(File: Required. Select the file for this host. To add files go to 'Control -> Files -> Add a host/service file'.);
	return %docs;
}

sub host_wizard_attribs_2() {
	my %docs = ();
	$docs{'hostgroups'} = q(Hostgroups: Optional. Assign this host one or more hostgroups. Hostgroups  may also be managed via 'Hosts -> Hostgroups'.);
	$docs{'extinfo'} = q(Extended host info template: Optional. Defines extended host information for this host profile. The template controls the icon and url link as seen in Nagios.);
	$docs{'coords2d'} = q(2d status map coords: Optional. Defines the host's position in the Nagios 2d status map. Coordinates should be given in positive integers, as they correspond to physical pixels in the generated image. The origin for drawing (0,0) is in the upper left hand corner of the image and extends in the positive x direction (to the right) along the top of the image and in the positive y direction (down) along the left hand side of the image. For reference, the size of the icons drawn is usually about 40x40 pixels (text takes a little extra space). The coordinates you specify here are for the upper left hand corner of the host icon that is drawn. Note: Don't worry about what the maximum x and y coordinates that you can use are. The CGI will automatically calculate the maximum dimensions of the image it creates based on the largest x and y coordinates you specify.);
	$docs{'coords3d'} = q(3d status map coords: Optional. Defines the host's position in the Nagios 3d status map.  Coordinates can be positive or negative real numbers. The origin for drawing is (0.0,0.0,0.0). For reference, the size of the host cubes drawn is 0.5 units on each side (text takes a little more space). The coordinates you specify here are used as the center of the host cube.);
	$docs{'host_escalation_tree'} = q(Host escalation tree: Optional. Select an escalation tree appropriate for this host. To avoid amplified notifications (i.e. multiple notifications for the same event), a host escalation assigned to this host should not also be assigned to a hostgroup in which the host is a member.);
	$docs{'service_escalation_tree'} = q(Service escalation tree: Optional. Select an escalation tree appropriate for services on this host. When a service escalation is assigned to a host, all services on that host use the same escalation tree. To avoid amplified notifications (i.e. multiple notifications for the same event), a service escalation assigned to a service name should not also be assigned to the host or the hostgroup.);
	$docs{'service_profile'} = q(Service profile: Optional. Select a service profile for this host. This sets up a default set of services);
	return %docs;
}

sub host_wizard_select_services() {
	my %docs = ();
	$docs{'services'} = q(Service list: By default the list of services is derived from the service profile selected in the last step. Each service has an option to Include/Modify/discard.<br><ul><li>Include: Accept this service as is with its default settings.</li><li>Modify: Accept this service but prompt for changes.</li><li>Discard: Do not include this service on this host.</li><li>Add to list: Add a service not included in the profile.</li></ul>);
	$docs{'file'} = q(File: Required. Select the default file for services assigned this host. To add files go to 'Control -> Files -> Add a host/service file'.);
	return %docs;
}

sub host_wizard_service_detail() {
	my %docs = ();
	$docs{'template'} = q(Service template: Required.  Select the appropriate service template for this service.);
	$docs{'use_template_command'} = q(Inherit check from template: If checked, the check command and command line options are derived from the service template. Be careful to ensure the service template has a check command defined before checking this option.);
	$docs{'check_command'} = q(Check command: If 'Inherit check from template' is unchecked, select the command that Nagios will run in order to check the status of the service.);
	$docs{'command_line'} = q(Command line: If 'Inherit check from template' is unchecked and if check command requires arguments, enter the check command with command arguments separated by a ! character. Example: check-disk!/dev/sda1);
	$docs{'dependency'} = q(Service dependency template: Optional. Select the template that defines a parent service relationship on this host. Monarch will create one service dependency relationship on this host setting this service name as the dependent service. To define a dependency for a service running on a different host use 'Hosts -> Modify -> Services -> Service Dependency' and select the parent host. Be careful to ensure that the parent service is included in the list of services for this host.);
	$docs{'extinfo'} = q(Extended info template: Optional. Defines extended service information for this service name. The template controls the icon and url link as seen in Nagios.);
	$docs{'escalation'} = q(Service escalation tree: Optional. Select an escalation tree appropriate for this service name. To avoid amplified notifications (i.e. multiple notifications for the same event), a service escalation assigned to a service name should not also be assigned to the host or one of the host's hostgroups.);
	return %docs;
}

sub escalations() {
	my %docs = ();
	$docs{'host_hostgroup'} = q(Assigning a host group sets the default host escalation for all hosts in the host group.);
	$docs{'service_hostgroup'} = q(Assigning a host group sets the default service escalation for all services on all hosts in the host group.);
	$docs{'host_host'}  = q(Assigning a host sets the host escalation for the host.);
	$docs{'service_host'} = q(Assigning a host sets the default service escalation for all services on the host.);
	$docs{'servicegroup'} = q(Assigning a service group sets the default service escalation for all services in the service group.);
	$docs{'service'} = q(Assigning a service sets the service escalation for the service, and selecting Apply to hosts propagates the escalation to all hosts assigned this service.);
	$docs{'contactgroup'} = q(Required. This directive is used to identify the short name of the contact group that should be notified when the host or service notification is escalated.);
	$docs{'detail'} = q(Select escalation type: 1. Hostgroup - Nagios v. 1.x defines a hostgroup escalation; Nagios v. 2.x and up define a host escalation. 2. Host: Defines a host escalation. 3. Service: Defines a service escalation.);
	$docs{'escalation_tree'} = q(Add escalation: Add an escalation to this escalation tree.<br>Remove escalation: Remove an escalation from this escalation tree.<br>Modify groups: Modify the list of contact groups associated with the escalation. At least one contact group is required.<br>);
	return %docs;
}

sub manage_hosts_vitals() {
	my %docs = ();
	$docs{'alias'} = q(Alias: Required. This directive is used to define a longer name or description used to identify the host. It is provided in order to allow you to more easily identify a particular host.);
	$docs{'address'} = q(Address: Required. This directive is used to define the address of the host. Normally, this is an IP address, although it could really be anything you want (so long as it can be used to check the status of the host). You can use a FQDN to identify the host instead of an IP address, but if DNS services are not availble this could cause problems. When used properly, the $HOSTADDRESS$ macro will contain this address. Note: If you do not specify an address directive in a host definition, the name of the host will be used as its address. A word of caution about doing this, however - if DNS fails, most of your service checks will fail because the plugins will be unable to resolve the host name.);
	$docs{'host_template'} = q(Host template: Required. Select the host template most suitable for this host. Note inheritance (left check box) on directives below. To override the template value, uncheck the left check box.);
	$docs{'checks_enabled'} = q(This directive is used to determine whether or not checks of this host are enabled. Values: unchecked = disable host checks, checked = enable host checks.);
	$docs{'extinfo'} = q(Extended host info template: Optional. Defines extended host information for this host profile. The template controls the icon and url link as seen in Nagios.);
	$docs{'coords2d'} = q(2d status map coords: Optional. Defines the host's position in the Nagios 2d status map. Coordinates should be given in positive integers, as they correspond to physical pixels in the generated image. The origin for drawing (0,0) is in the upper left hand corner of the image and extends in the positive x direction (to the right) along the top of the image and in the positive y direction (down) along the left hand side of the image. For reference, the size of the icons drawn is usually about 40x40 pixels (text takes a little extra space). The coordinates you specify here are for the upper left hand corner of the host icon that is drawn. Note: Don't worry about what the maximum x and y coordinates that you can use are. The CGI will automatically calculate the maximum dimensions of the image it creates based on the largest x and y coordinates you specify.);
	$docs{'coords3d'} = q(3d status map coords: Optional. Defines the host's position in the Nagios 3d status map.  Coordinates can be positive or negative real numbers. The origin for drawing is (0.0,0.0,0.0). For reference, the size of the host cubes drawn is 0.5 units on each side (text takes a little more space). The coordinates you specify here are used as the center of the host cube.);
	$docs{'file'} = q(File: Required. Select the file for this host. To add files go to 'Control -> Files -> Add a host/service file'.);
	return %docs;
}

sub manage_hosts_profile() {
	my %docs = ();
	$docs{'profile'} = q(Assign and apply host profiles and service profiles. After making changes, use the refresh button to update the service list. The replace option will remove all services from this host and replace them with those listed here. Merge will leave any existing services unchanged. Assigning a host profile here creates the association so that the host can be managed from the profile, but has no other effect on the host configuration.);
	$docs{'host_profile'} = q(Host profile: Optional. Host Profiles can be used to aid the design and management of hosts.);
	$docs{'service_profile'} = q(Service profile: Optional. Select a service profile for this host. This sets up a default set of services);

	return %docs;
}

sub manage_hosts_apply_profile() {
	my %docs = ();
	$docs{'host_profile'} = q(Host profile: Optional. Host Profiles can be used to aid the design and management of hosts.);
	$docs{'service_profile'} = q(Service profile: Optional. Select a service profile for this host. This sets up a default set of services);

	return %docs;
}

sub manage_hosts_parents() {
	my %docs = ();
	$docs{'parents'} = q(Parents: Optional. Assign this host one or more parents. Parent child relationships may also be managed via 'Hosts -> Parent Child'. );
	return %docs;
}

sub manage_hosts_hostgroups() {
	my %docs = ();
	$docs{'hostgroups'} = q(Hostgroups: Optional. Assign this host one or more hostgroups. Hostgroups  may also be managed via 'Hosts -> Hostgroups'.);
	return %docs;
}

sub manage_hosts_escalations() {
	my %docs = ();
	$docs{'escalations'} = q(Escalations: Optional. Select host and service escalation trees appropriate for this host. When a service escalation is assigned here, all services on this host will use the same escalation. To use different escalations for different services, each service must have its own escalation. In that case, do not assign a service escalation here.);
	$docs{'host_escalation_tree'} = q(Host escalation tree: Optional. Select an escalation tree appropriate for this host. To avoid amplified notifications (i.e. multiple notifications for the same event), a host escalation assigned to this host should not also be assigned to a hostgroup in which the host is a member.);
	$docs{'service_escalation_tree'} = q(Service escalation: Optional. Select an escalation tree appropriate for all services on this host. When a service escalation is assigned here, all services on this host will use the same escalation. To use different escalations for different services, each service must have its own escalation. In that case, do not assign a service escalation here.);
	return %docs;
}

sub manage_hosts_services() {
	my %docs = ();
	$docs{'services'} = q(Add, modify and remove services for this host. Managing services from this page will in all likelihood put the host out of sync with its service profiles. After making changes, use caution when applying profiles to this host.);
	return %docs;
}

sub servicegroups() {
	my %docs = ();

	return %docs;
}

sub manage_hosts_service_detail() {
	my %docs = ();
	$docs{'template'} = q(Service template: Required.  Select the appropriate service template for this service.);
	$docs{'use_template_command'} = q(Inherit check from template: If checked, the check command and command line options are derived from the service template. Be careful to ensure the service template has a check command defined before checking this option.);
	$docs{'check_command'} = q(Check command: If 'Inherit check from template' is unchecked, select the command that Nagios will run in order to check the status of the service.);
	$docs{'command_line'} = q(Command line: If 'Inherit check from template' is unchecked and if check command requires arguments, enter the check command with command arguments separated by a ! character. Example: check-disk!/dev/sda1);
	$docs{'extinfo'} = q(Extended info template: Optional. Defines extended service information for this service name. The template controls the icon and url link as seen in Nagios.);
	$docs{'escalation'} = q(Service escalation tree: Optional. Select an escalation tree appropriate for this service name. To avoid amplified notifications (i.e. multiple notifications for the same event), a service escalation assigned to a service name should not also be assigned to the host or one of the host's hostgroups.);
	return %docs;
}

sub manage_hosts_service_check() {
	my %docs = ();
	$docs{'service_check'} = q(If you are satisfied with the check as inherited from the template, do nothing on this page. Otherwise uncheck the inherit checkbox and make the necessary changes. Use the test button to check the argument values, but bear in mind that the check command is run under the web servers account, so there may be issues with certain checks.);
	$docs{'check_command'} = q(Check command: If 'Inherit check from template' is unchecked, select the command that Nagios will run in order to check the status of the service.);
	$docs{'command_line'} = q(Command line: If 'Inherit check from template' is unchecked and if check command requires arguments, enter the check command with command arguments separated by a ! character. Example: check-disk!/dev/sda1);
	$docs{'service_instance'} = q(If this check is the same as other checks on this host, where the check command is the same, all of the settings on the service detail page are the same, and only the arguments differ, you can define a set of checks here without creating new services. For example, a disk check can be defined for multiple partitions, or an snmp check on a network device can be defined for multiple interfaces. Enter a name to add a single instance or enter a range of numbers to add a list of numbered instances prefixed with an underscore. The instance names are appended to the service name so we recommend using an underscore for the first character in the name.);
	return %docs;
}


sub manage_hosts_service_dependencies() {
	my %docs = ();
	$docs{'dependencies'} = q(Add or remove service dependencies here. To add a dependency, select from the dependency list and after the screen refreshes, choose the appropriate host.);
	$docs{'dependency'} = q(Service dependency: Select the service dependency template that defines a parent service relationship on this host.);
	$docs{'parent_host'} = q(Select from the list a host where the parent service resides);

	return %docs;
}

sub setup() {
	my %docs = ();
	$docs{'login_authentication'} = q(Login authentication: Select none, active or passive. none = no authentication - all users have full control; active = users are prompted to login and access checks are enabled; passive = no login if user account is passed in URL but access checks are enabled (single sign-on method).);
	$docs{'session_timeout'} = q(Session timeout: With login authentication active, this is the number of seconds of inactivity before a user is prompted to login.);
	$docs{'nagios_etc'} = q(Nagios etc: Path to the folder containing nagios.cfg.);
	$docs{'nagios_bin'} = q(Nagios bin: Path to the folder containing the nagios binary.);
	$docs{'monarch_home'} = q(monarch home: The Monarch installation path. Your web server must have read write access.);
	$docs{'backup_home'} = q(Backup dir: This folder is used to backup your Nagios files and the Monarch database. Your web server must have read write access.);
	$docs{'max_tree_nodes'} = q(Max tree nodes: The number of hosts or services to appear in the left menu tree before the list is segmented. The larger the number the longer page loads will take. Default=500);
	$docs{'enable_externals'} = q(Enable externals: This is an advanced feature that requires some knowledge of perl. Externals are configuration data not directly related to Nagios, but can be useful when integrating other tools. Externals can be assigned to hosts and services. Your knowledge of perl will be required to modify MonarchExternals.pm. Check this box and Save Setup to display the Run Externals option in the left navigation. Select Run Externals to execute your code in  MonarchExternals.pm.);

	return %docs;
}

sub ez_defaults() {
	my %docs = ();
	$docs{'profile'} = q(Host profile: Required. Select the appropriate host profile for all hosts added with this tool. This should in most circumstances be a simple ping profile.);
	$docs{'contactgroup'} = q(Contact group: Required. Select the appropriate contact group for all contacts added with this tool.);
	$docs{'contact_template'} = q(Contact template: Required. Select the appropriate contact template for all contacts added with this tool.);
	return %docs;
}

sub ez_host() {
	my %docs = ();
	$docs{'hostgroups'} = q(Assign host groups or let the profile assign them. If the selected profile shows host groups, do nothing and they will be assigned to this host. Otherwise, add host groups to override those on the profile.);
	return %docs;
}


sub monarch_groups() {
	my %docs = ();
	$docs{'contactgroups'} = q(Selecting a contact group here will provide the default contact group for hosts and services where no contact group has been defined, and it WILL OVERRIDE the contact groups defined on host templates and service templates. Contact groups assigned to sub groups will in turn override these contact groups.);
	$docs{'status'} = q(Setting the group inactive will remove the member hosts and their services from the Status Viewer (GroundWork Monitor) and the Nagios GUI's while preserving their configurations. Hosts can be reinstated by simply removing them from the inactive group or removing the inactive setting for the group.);
	$docs{'build_instance_properties'} = q(These properties are required only if you wish to use this group as part of a distributed Nagios environment. It is not necessary to set these values to perform a pre-flight check for this group.);
	$docs{'location'} = q(Build folder: Enter the web service writeable folder for this distribution. An incorrect entry or a folder with the incorrect permissions will cause the build instance to fail.);
	$docs{'nagios_etc'} = q(Nagios etc folder: Enter the path of the Nagios configuration folder on the target host. The value here will only be used to generate the nagios.cfg file, but it should reflect the actual location on the target host where the Nagios object configuration files will reside.);
	$docs{'use_hosts'} = q(Force hosts: Select this option to dictate the list of hosts to be included in this instance. This option will override the sub group host lists while still applying the macros from those groups where common members reside.);
	$docs{'checks_enabled'} = q(Force checks: Select this option to override the checks enabled options for all hosts and their services included in this instance. Check the boxes below accordingly.);
	$docs{'assign_hosts'} = q(Assign hosts individually or by host group. The preferred method is to assign host groups as new hosts will be included here when they are assigned to the host group.);
	$docs{'sub_groups'} = q(Sub groups are mostly useful only in special circumstances, in particular to build multiple instances of Nagios. Select from the bottom list and click 'Add Group(s)' to assign groups. Select from the upper list and click 'Remove' to un-assign groups.);
	$docs{'macros'} = q(Select macros from the bottom list and click 'Add Macro(s)' to assign them to the group. Adjust the values as needed and select 'Save' to apply them to the group. To use the label option you must select 'Enable label' and enter a value, then click 'Save' to apply it to the group. The value is appended to the service description on services where the macro is found, so we suggest using an underscore as the first character.);
	return %docs;
}

sub monarch_macros() {
	my %docs = ();
	$docs{'macros'} = q(Group macros extend the Nagios $ARG#$ macros on service checks. Use names that are unique and not likely in the least to match some other part of the check command string. The values defined here become the default value when the macro is assigned to a group. Adjust the values as needed and click 'Save'. Note that changing a value here will not be applied to groups where the macro is already assigned.);
	return %docs;
}

sub access_list() {
	my %docs = ();
	$docs{'groups'} = q(To add, modify or delete groups and macros select Manage, and then choose the groups to which members of this user group have access. Access includes pre-flight checks and the capability to build and deploy instances. When a new group is defined by a member of this user group, all members will automatically have access.);
	$docs{'ez'} = q(Select Enable to allow access to the EZ interface for this user group, and then select a view option. Main-EZ: The main view is the default interface when users log in. EZ-Main: The EZ view is the default interface when users log in. EZ: The EZ view is the only interface available when users login. Deselect Enable to hide the EZ view.);
	return %docs;
}

sub nagios_cfg() {
	my %docs = ();
	$docs{'log_file'} = q(Log file: This is the main log file where service and host events are logged for historical purposes.  This should be the first option specified in the config file!);
	$docs{'object_cache_file'} = q(Object cache file: This directive is used to specify a file in which a cached copy of object definitions should be stored. The cache file is (re)created every time Nagios is (re)started and is used by the CGIs. It is intended to speed up config file caching in the CGIs and allow you to edit the source object config files while Nagios is running without affecting the output displayed in the CGIs.);
	$docs{'precached_object_file'} = q(Precached object file: This directive is used to specify a file in which a cached copy of pre-processed object definitions should be stored. The precached object file is (re)created every time Nagios is (re)started. It is intended to drastically shorten the time it takes to restart Nagios.);
	$docs{'resource_file'} = q(Resource file: This is an optional resource file that contains $USERx$ macro definitions. Multiple resource files can be specified by using multiple resource_file definitions.  The CGIs will not attempt to read the contents of resource files, so information that is considered to be sensitive (usernames, passwords, etc) can be defined as macros in this file and restrictive permissions (600) can be placed on this file.);
	$docs{'status_file'} = q(Status file: This is where the current status of all monitored services and hosts is stored.  Its contents are read and processed by the CGIs. The contents of the status file are deleted every time Nagios restarts.);
	
	$docs{'aggregate_status_updates'} = q(Aggregated status updates option: This option determines whether or not Nagios will aggregate updates of host, service, and program status data. If you do not enable this option, status data is updated every time a host or service check occurs. This can result in high CPU loads and file I/O if you are monitoring a lot of services. If you want Nagios to only update status data (in the status file) every few seconds (as determined by the status_update_interval option), enable this option. If you want immediate updates, disable it. I would highly recommend using aggregated updates (even at short intervals) unless you have good reason not to.);
	$docs{'status_update_interval'} = q(Aggregated status data update interval: This setting determines how often (in seconds) that Nagios will update status data in the status file. The minimum update interval is five seconds. If you have disabled aggregated status updates (with the aggregate_status_updates option), this option has no effect.);

	$docs{'nagios_user'} = q(Nagios user: This determines the effective user that Nagios should run as. You can either supply a username or a UID.);
	$docs{'nagios_group'} = q(Nagios group: This determines the effective group that Nagios should run as. You can either supply a group name or a GID.);

	$docs{'enable_notifications'} = q(Enable notifications: This option determines whether or not Nagios will send out notifications when it initially (re)starts. If this option is disabled, Nagios will not send out notifications for any host or service. Note: If you have state retention enabled, Nagios will ignore this setting when it (re)starts and use the last known setting for this option (as stored in the state retention file), unless you disable the use_retained_program_state option. If you want to change this option when state retention is active (and the use_retained_program_state is enabled), you'll have to use the appropriate external command or change it via the web interface.);
	$docs{'execute_service_checks'} = q(Execute service checks: This option determines whether or not Nagios will execute service checks when it initially (re)starts. If this option is disabled, Nagios will not actively execute any service checks and will remain in a sort of 'sleep' mode (it can still accept passive checks unless you've disabled them). This option is most often used when configuring backup monitoring servers, as described in the documentation on redundancy, or when setting up a distributed monitoring environment. Note: If you have state retention enabled, Nagios will ignore this setting when it (re)starts and use the last known setting for this option (as stored in the state retention file), unless you disable the use_retained_program_state option. If you want to change this option when state retention is active (and the use_retained_program_state is enabled), you'll have to use the appropriate external command or change it via the web interface.);
	$docs{'accept_passive_service_checks'} = q(Accept passive service checks: This option determines whether or not Nagios will accept passive service checks when it initially (re)starts. If this option is disabled, Nagios will not accept any passive service checks. Note: If you have state retention enabled, Nagios will ignore this setting when it (re)starts and use the last known setting for this option (as stored in the state retention file), unless you disable the use_retained_program_state option. If you want to change this option when state retention is active (and the use_retained_program_state is enabled), you'll have to use the appropriate external command or change it via the web interface.);

	$docs{'enable_event_handlers'} = q(Enable event handlers: This option determines whether or not Nagios will run event handlers when it initially (re)starts. If this option is disabled, Nagios will not run any host or service event handlers. Note: If you have state retention enabled, Nagios will ignore this setting when it (re)starts and use the last known setting for this option (as stored in the state retention file), unless you disable the use_retained_program_state option. If you want to change this option when state retention is active (and the use_retained_program_state is enabled), you'll have to use the appropriate external command or change it via the web interface. );
	
	$docs{'check_external_commands'} = q(Check external commands: This option allows you to specify whether or not Nagios should check for external commands (in the command file defined below).  By default Nagios will *not* check for external commands, just to be on the cautious side.  If you want to be able to use the CGI command interface you will have to enable this.  Setting this value to unchecked disables command checking (the default), other values enable it.);
	$docs{'command_check_interval'} = q(Command check interval: This is the interval at which Nagios should check for external commands. This is a value  of the interval_length that you specify later.  If you leave that at its default value of 60 (seconds), a value of 1 here will cause Nagios to check for external commands every minute.  If you specify a number followed by an 's' (i.e. 15s), this will be interpreted to mean actual seconds rather than a multiple of the interval_length variable. Note: In addition to reading the external command file at regularly scheduled intervals, Nagios will also check for external commands after event handlers are executed. NOTE: Setting this value to -1 causes Nagios to check the external command file as often as possible.);
	$docs{'command_file'} = q(External command file: This is the file that Nagios checks for external command requests. It is also where the command CGI will write commands that are submitted by users, so it must be writeable by the user that the web server is running as (under Linux, usually 'nobody').  Permissions should be set at the directory level instead of on the file, as the file is deleted every time its contents are processed.);
	$docs{'comment_file'} = q(Comment file: This is the file that Nagios will use for storing host and service comments.);
	$docs{'downtime_file'} = q(Downtime file: This is the file that Nagios will use for storing host and service downtime data.);
	$docs{'lock_file'} = q(Lock file: This is the lockfile that Nagios will use to store its PID number in when it is running in daemon mode.);
	$docs{'temp_file'} = q(Temp file: This is a temporary file that is used as scratch space when Nagios updates the status log, cleans the comment file, etc.  This file is created, used, and deleted throughout the time that Nagios is running.);
	$docs{'log_rotation_method'} = q(Log rotation method: This is the log rotation method that Nagios should use to rotate the main log file. Values are as follows. n = None - don't rotate the log. h = Hourly rotation (top of the hour). d = Daily rotation (midnight every day). w = Weekly rotation (midnight on Saturday evening). m = Monthly rotation (midnight last day of month));
	$docs{'log_archive_path'} = q(Log archive path: This is the directory where archived (rotated) log files should be placed (assuming you've chosen to do log rotation).);
	$docs{'use_syslog'} = q(Use syslog: If you want messages logged to the syslog facility as well as the NetAlarm log file, set this option to checked.  If not, set it to unchecked.);
	$docs{'log_notifications'} = q(Log notifications: If you don't want notifications to be logged, set this value to unchecked. If notifications should be logged, set the value to checked.);
	$docs{'log_service_retries'} = q(Log service retries: If you don't want service check retries to be logged, set this value to unchecked.  If retries should be logged, set the value to checked.);
	$docs{'log_host_retries'} = q(Log host retries: If you don't want host check retries to be logged, set this value to unchecked.  If retries should be logged, set the value to checked.);
	$docs{'log_event_handlers'} = q(Log event handlers: If you don't want host and service event handlers to be logged, set this value to unchecked.  If event handlers should be logged, set the value to checked.);
	$docs{'log_initial_states'} = q(Log initial states: If you want Nagios to log all initial host and service states to the main log file (the first time the service or host is checked) you can enable this option by setting this value to checked.  If you are not using an external application that does long term state statistics reporting, you do not need to enable this option.  In this case, set the value to unchecked.);
	$docs{'log_external_commands'} = q(Log external commands: If you don't want Nagios to log external commands, set this value to unchecked.  If external commands should be logged, set this value to checked. Note: This option does not include logging of passive service checks - see the option below for controlling whether or not passive checks are logged.);
	$docs{'log_passive_service_checks'} = q(Log passive service checks: If you don't want Nagios to log passive service checks, set this value to unchecked.  If passive service checks should be logged, set this value to checked.);
	$docs{'global_host_event_handler'} = q(Global host event handler: This option allows you to specify a host event handler command that is to be run for every host state change. The global event handler is executed immediately prior to the event handler that you have optionally specified in each host definition. The command argument is the short name of a command definition that you define in your host configuration file. Read the Nagios HTML docs for more information.);
	$docs{'global_service_event_handler'} = q(Global service event handler: This option allows you to specify a service event handler command that is to be run for every host state change. The global event handler is executed immediately prior to the event handler that you have optionally specified in each service definition. The command argument is the short name of a command definition that you define in your host configuration file. Read the Nagios HTML docs for more information.);
	$docs{'inter_check_delay_method'} = q(Inter check delay method: Inter check delay method: This is the method that Nagios should use when initially 'spreading out' service checks when it starts monitoring. The default is to use smart delay calculation, which will try to space all service checks out evenly to minimize CPU load. Using the dumb setting will cause all checks to be scheduled at the same time (with no delay between them)!  This is not a good thing for production, but is useful when testing the parallelization functionality. None: selected = None - don't use any delay between checks. Dumb: selected = Use a 'dumb' delay of 1 second between checks. Smart: selected = Use 'smart' inter-check delay calculation. Delay: selected = Enter an user-specified delay of x.xx seconds.);
	$docs{'service_interleave_factor'} = q(Service interleave factor: This variable determines how service checks are interleaved. Interleaving the service checks allows for a more even distribution of service checks and reduced load on remote hosts.  Setting this value to 1 is equivalent to how versions of Nagios previous to 0.0.5 did service checks.  Set this value to s (smart) for automatic calculation of the interleave factor unless you have a specific reason to change it. Smart: selected = Use 'smart' interleave factor calculation. Value: selected = Enter an interleave factor of x, where x is a number greater than or equal to 1.);
	$docs{'max_concurrent_checks'} = q(Max concurrent checks: This option allows you to specify the maximum number of service checks that can be run in parallel at any given time. Specifying a value of 1 for this variable essentially prevents any service checks from being parallelized.  A value of 0 will not restrict the number of concurrent checks that are being executed.);
	$docs{'check_result_path'} = q(Check result path: This directory contains the temporary files storing the results of host and service checks before processing. This directory should not contain any other files, as Nagios will periodically clean it out and any files stored in it will be lost.);
	$docs{'service_reaper_frequency'} = q(Service reaper frequency: This is the frequency (in seconds!) that Nagios will process the results of services that have been checked.);
	$docs{'sleep_time'} = q(Sleep time: This is the number of seconds to sleep between checking for system events and service checks that need to be run.  I would recommend *not* changing this from its default value of 1 second.);
	$docs{'timeout_values'} = q(Timeout values: These options control how much time Nagios will allow various types of commands to execute before killing them off.  Options are available for controlling maximum time allotted for service checks, host checks, event handlers, notifications, the ocsp command, and performance data commands.  All values are in seconds.);
	$docs{'retain_state_information'} = q(Retain state information: This setting determines whether or not Nagios will save state information for services and hosts before it shuts down. Upon startup Nagios will reload all saved service and host state information before starting to monitor.  This is useful for maintaining long-term data on state statistics, etc, but will slow Nagios down a bit when it (re)starts.  Since it's only a one-time penalty, I think it's well worth the additional startup delay. Checked = enabled.);
	$docs{'state_retention_file'} = q(State retention file: This is the file that Nagios should use to store host and service state information before it shuts down. The state information in this file is also read immediately prior to starting to monitor the network when Nagios is restarted. This file is used only if the preserve_state_information variable is checked.);
	$docs{'retention_update_interval'} = q(Retention update interval: This setting determines how often (in minutes) that Nagios will automatically save retention data during normal operation. If you set this value to 0, Nagios will not save retention data at regular intervals, but it will still save retention data before shutting down or restarting.  If you have disabled state retention, this option has no effect.);
	$docs{'use_retained_program_state'} = q(Use retained program state: This setting determines whether or not Nagios will set program status variables based on the values saved in the retention file.  If you want to use retained program status information, set this value to 1.  If not, set this value to 0.);
	$docs{'interval_length'} = q(Timing interval length: This is the seconds per unit interval as used in the host/contact/service configuration files.  Setting this to 60 means that each interval is one minute long (60 seconds).  Other settings have not been tested much, so your mileage is likely to vary...);
	$docs{'use_agressive_host_checking'} = q(Use agressive host checking: Nagios tries to be smart about how and when it checks the status of hosts. In general, disabling this option will allow Nagios to make some smarter decisions and check hosts a bit faster. Enabling this option will increase the amount of time required to check hosts, but may improve reliability a bit. Unless you have problems with Nagios not recognizing that a host recovered, it is strongly recommended that you not enable this option.); 		
	$docs{'execute_service_checks'} = q(Execute service checks: This determines whether or not Nagios will actively execute service checks when it initially starts.  If this option is disabled, checks are not actively made, but Nagios can still receive and process passive check results that come in.  Unless you're implementing redundant hosts or have a special need for disabling the execution of service checks, leave this enabled! Values: checked = enable checks, unchecked = disable checks.);
	$docs{'accept_passive_service_checks'} = q(Accept passive service checks: This determines whether or not Nagios will accept passive service check results when it initially (re)starts. Values: checked = accept passive checks, unchecked = reject passive checks.);
	$docs{'process_performance_data'} = q(Process performance data: This determines whether or not Nagios will process performance data returned from service and host checks.  If this option is enabled, host performance data will be processed using the host perfdata command (defined below) and service performance data will be processed using the service perfdata command (also defined below).  Read the HTML docs for more information on performance data. Values: checked = process performance data, unchecked = do not process performance data.);
	$docs{'use_agressive_host_checking'} = q(Use agressive host checking: Nagios tries to be smart about how and when it checks the status of hosts. In general, disabling this option will allow Nagios to make some smarter decisions and check hosts a bit faster. Enabling this option will increase the amount of time required to check hosts, but may improve reliability a bit. Unless you have problems with Nagios not recognizing that a host recovered, it is strongly reccomended that you DO NOT enable this option. Values: checked = enable agressive host checking, unchecked = do not aggressively check hosts.); 
	
	$docs{'use_agressive_service_checking'} = q(Use agressive service checking: This command is run after every service check is performed.  These commands are executed only if the enable_performance_data option (above) is checked.  The command argument is the short name of a command definition that you define in your host configuration file.  Read the Nagios HTML docs for more information on performance data.);
	$docs{'obsess_over_services'} = q(Obsess over services: This determines whether or not Nagios will obsess over service checks and run the ocsp_command defined below.  Unless you're planning on implementing distributed monitoring, do not enable this option.  Read the HTML docs for more information on implementing distributed monitoring. Values: checked = obsess over services, unchecked = do not obsess (default));
	$docs{'ocsp_command'} = q(Ocsp command: This is the command that is run for every service check that is processed by Nagios.  This command is executed only if the obsess_over_service option (above) is set to 1.  The command argument is the short name of a command definition that you define in your host configuration file. Read the HTML docs for more information on implementing distributed monitoring.);
	$docs{'check_for_orphaned_services'} = q(Check for orphaned services: This determines whether or not Nagios will periodically check for orphaned services.  Since service checks are not rescheduled until the results of their previous execution instance are processed, there exists a possibility that some checks may never get rescheduled.  This seems to be a rare problem and should not happen under normal circumstances. If you have problems with service checks never getting rescheduled, you might want to try enabling this option. Values: checked = enable checks, unchecked = disable checks.);
	$docs{'check_service_freshness'} = q(Check service freshness: This option determines whether or not Nagios will periodically check the 'freshness' of service results.  Enabling this option is useful for ensuring passive checks are received in a timely manner. Values: checked = enabled freshness checking, unchecked = disable freshness checking.);
	$docs{'freshness_check_interval'} = q(Freshness check interval: This setting determines how often (in seconds) Nagios will check the 'freshness' of service check results.  If you have disabled service freshness checking, this option has no effect.);
	$docs{'enable_flap_detection'} = q(Enable flap detection: This option determines whether or not Nagios will try to detect hosts and services that are 'flapping'. Flapping occurs when a host or service changes between states too frequently.  When Nagios detects that a host or service is flapping, it will temporarily suppress notifications for that host/service until it stops flapping.  Flap detection is very experimental, so read the HTML documentation before enabling this feature! Values: checked = enable flap detection unchecked = disable flap detection (default));
	$docs{'host_flap_detection_thresholds'} = q(Host flap detection thresholds: Read the Nagios HTML documentation on flap detection for an explanation of what this option does.  This option has no effect if flap detection is disabled.);
	$docs{'service_flap_detection_thresholds'} = q(Service flap detection thresholds: Read the Nagios HTML documentation on flap detection for an explanation of what this option does.  This option has no effect if flap detection is disabled.);
	$docs{'soft_state_dependencies'} = q(Soft service dependencies: This option determines whether or not Nagios will use soft service state information when checking service dependencies. Normally Nagios will only use the latest hard service state when checking dependencies. If you want it to use the latest state (regardless of whether it's a soft or hard state type), enable this option.);
	$docs{'date_format'} = q(Date format: This option determines how short dates are displayed. US: MM-DD-YYYY HH:MM:SS, Euro DD-MM-YYYY HH:MM:SS, ISO8601 YYYY-MM-DD HH:MM:SS,Strict-ISO8601 YYYY-MM-DDTHH:MM:SS);
	$docs{'illegal_object_name_chars'} = q(Illegal object name chars: This option allows you to specify illegal characters that cannot be used in host names, service descriptions, or names of other object types.);
	$docs{'illegal_macro_output_chars'} = q(Illegal macro output chars: This option allows you to specify illegal characters that are stripped from macros before being used in notifications, event handlers, etc.  This DOES NOT affect macros used in service or host check commands. The following macros are stripped of the characters you specify: $OUTPUT$, $PERFDATA$.);
	$docs{'admin_email'} = q(Admin email: The email address of the administrator of *this* machine (the one doing the monitoring).  Nagios never uses this value itself, but you can access this value by using the $ADMINEMAIL$ macro in your notification commands.);
	$docs{'admin_pager'} = q(Admin pager: The pager number/address for the administrator of *this* machine. Nagios never uses this value itself, but you can access this value by using the $ADMINPAGER$ macro in your notification commands.);
	# 2.0
	$docs{'object_cache_file_file'} = q(Object cache file: This directive is used to specify a file in which a cached copy of object definitions should be stored. The cache file is (re)created every time Nagios is (re)started and is used by the CGIs. It is intended to speed up config file caching in the CGIs and allow you to edit the source object config files while Nagios is running without affecting the output displayed in the CGIs.);
	$docs{'execute_host_checks'} = q(Host check execution option: This option determines whether or not Nagios will execute on-demand and regularly scheduled host checks when it initially (re)starts. If this option is disabled, Nagios will not actively execute any host checks, although it can still accept passive host checks unless you've disabled them. This option is most often used when configuring backup monitoring servers, as described in the documentation on redundancy, or when setting up a distributed monitoring environment. Note: If you have state retention enabled, Nagios will ignore this setting when it (re)starts and use the last known setting for this option (as stored in the state retention file), unless you disable the use_retained_program_state option. If you want to change this option when state retention is active (and the use_retained_program_state is enabled), you'll have to use the appropriate external command or change it via the web interface. Checked = Execute host checks.); 
	$docs{'accept_passive_host_checks'} = q(Passive host check acceptance option: This option determines whether or not Nagios will accept passive host checks when it initially (re)starts. If this option is disabled, Nagios will not accept any passive host checks. Note: If you have state retention enabled, Nagios will ignore this setting when it (re)starts and use the last known setting for this option (as stored in the state retention file), unless you disable the use_retained_program_state option. If you want to change this option when state retention is active (and the use_retained_program_state is enabled), you'll have to use the appropriate external command or change it via the web interface. Checked = Accept passive host checks );
	$docs{'use_retained_scheduling_info'} = q(Use retained scheduling info option: This setting determines whether or not Nagios will retain scheduling info (next check times) for hosts and services when it restarts. If you are adding a large number (or percentage) of hosts and services, it is recommended that this option be disabled when you first restart Nagios, as it can adversely skew the spread of initial checks. Otherwise you will probably want to leave it enabled.);
	$docs{'log_passive_checks'} = q(Passive check logging option: This variable determines whether or not Nagios will log passive host and service checks that it receives from the external command file. If you are setting up a distributed monitoring environment or plan on handling a large number of passive checks on a regular basis, you may wish to disable this option so your log file doesn't get too large. Checked = Log passive checks.);
	$docs{'service_inter_check_delay_method'} = q(Service inter-check delay method: This option allows you to control how service checks are initially 'spread out' in the event queue. Using a 'smart' delay calculation (the default) will cause Nagios to calculate an average check interval and spread initial checks of all services out over that interval, thereby helping to eliminate CPU load spikes. Using no delay is generally not recommended unless you are testing the service check parallelization functionality. Using no delay will cause all service checks to be scheduled for execution at the same time. This means that you will generally have large CPU spikes when the services are all executed in parallel. Values are as follows: None = Don't use any delay - schedule all service checks to run immediately (i.e. at the same time!). Dumb = Use a delay of 1 second between service checks. Smart = Use a delay calculation to spread service checks out evenly. Enter a user-specificed delay of x.xx seconds.);
	$docs{'max_service_check_spread'} = q(Maximum service check spread: This option determines the maximum number of minutes from when Nagios starts that all services (that are scheduled to be regularly checked) are checked. This option will automatically adjust the service inter-check delay (if necessary) to ensure that the initial checks of all services occur within the timeframe you specify. In general, this option will not have an effect on service check scheduling if scheduling information is being retained using the use_retained_scheduling_info option.); 
	$docs{'host_inter_check_delay_method'} = q(Host inter-check delay method: This option allows you to control how host checks that are scheduled to be checked on a regular basis are initially 'spread out' in the event queue. Using a 'smart' delay calculation (the default) will cause Nagios to calculate an average check interval and spread initial checks of all hosts out over that interval, thereby helping to eliminate CPU load spikes. Using no delay is generally not recommended. Using no delay will cause all host checks to be scheduled for execution at the same time. Values are as follows: None = Don't use any delay - schedule all host checks to run immediately (i.e. at the same time!). Dumb = Use a 'dumb' delay of 1 second between host checks. Smart = Use a 'smart' delay calculation to spread host checks out evenly (default). Use a user-specified delay of x.xx seconds.);
	$docs{'max_host_check_spread'} = q(Maximum host check spread: This option determines the maximum number of minutes from when Nagios starts that all hosts (that are scheduled to be regularly checked) are checked. This option will automatically adjust the host inter-check delay (if necessary) to ensure that the initial checks of all hosts occur within the timeframe you specify. In general, this option will not have an effect on host check scheduling if scheduling information is being retained using the use_retained_scheduling_info option.);
	$docs{'auto_reschedule_checks'} = q(Auto-rescheduling option: This option determines whether or not Nagios will attempt to automatically reschedule active host and service checks to 'smooth' them out over time. This can help to balance the load on the monitoring server, as it will attempt to keep the time between consecutive checks consistent, at the expense of executing checks on a more rigid schedule. Checked = enabled. WARNING: THIS IS AN EXPERIMENTAL FEATURE AND MAY BE REMOVED IN FUTURE VERSIONS. ENABLING THIS OPTION CAN DEGRADE PERFORMANCE - RATHER THAN INCREASE IT - IF USED IMPROPERLY!); 
	$docs{'auto_rescheduling_interval'} = q(Auto-rescheduling interval: This option determines how often (in seconds) Nagios will attempt to automatically reschedule checks. This option only has an effect if the auto_reschedule_checks option is enabled. WARNING: THIS IS AN EXPERIMENTAL FEATURE AND MAY BE REMOVED IN FUTURE VERSIONS. ENABLING THE AUTO-RESCHEDULING OPTION CAN DEGRADE PERFORMANCE - RATHER THAN INCREASE IT - IF USED IMPROPERLY!);
	$docs{'auto_rescheduling_window'} = q(Auto-rescheduling window: This option determines the 'window' of time (in seconds) that Nagios will look at when automatically rescheduling checks. Only host and service checks that occur in the next X seconds (determined by this variable) will be rescheduled. This option only has an effect if the auto_reschedule_checks option is enabled. WARNING: THIS IS AN EXPERIMENTAL FEATURE AND MAY BE REMOVED IN FUTURE VERSIONS. ENABLING THE AUTO-RESCHEDULING OPTION CAN DEGRADE PERFORMANCE - RATHER THAN INCREASE IT - IF USED IMPROPERLY!);
	$docs{'ochp_timeout'} = q(Obsessive compulsive host processor timeout:);
	$docs{'obsess_over_hosts'} = q(Obsess over hosts option: This value determines whether or not Nagios will 'obsess' over host check results and run the obsessive compulsive host processor command you define. I know - funny name, but it was all I could think of. This option is useful for performing distributed monitoring. If you're not doing distributed monitoring, don't enable this option. Checked = enabled.);
	$docs{'ochp_command'} = q(Obsessive compulsive host processor command: This option allows you to specify a command to be run after every host check, which can be useful in distributed monitoring. This command is executed after any event handler or notification command. The command argument is the short name of a command definition that you define in your object configuration file. The maximum amount of time that this command can run is controlled by the ochp_timeout option. This command is only executed if the obsess_over_hosts option is enabled globally and if the obsess_over_host directive in the host definition is enabled.);
	$docs{'host_perfdata_command'} = q(Host performance data processing command: This option allows you to specify a command to be run after every host check to process host performance data that may be returned from the check. The command argument is the short name of a command definition that you define in your object configuration file. This command is only executed if the process_performance_data option is enabled globally and if the process_perf_data directive in the host definition is enabled.);
	$docs{'service_perfdata_command'} = q(Service performance data processing command: This option allows you to specify a command to be run after every service check to process service performance data that may be returned from the check. The command argument is the short name of a command definition that you define in your object configuration file. This command is only executed if the process_performance_data option is enabled globally and if the process_perf_data directive in the service definition is enabled.);
	$docs{'host_perfdata_file'} = q(Host performance data file: This option allows you to specify a file to which host performance data will be written after every host check. Data will be written to the performance file as specified by the host_perfdata_file_template option. Performance data is only written to this file if the process_performance_data option is enabled globally and if the process_perf_data directive in the host definition is enabled.);
	$docs{'service_perfdata_file'} = q(Service performance data file: This option allows you to specify a file to which service performance data will be written after every service check. Data will be written to the performance file as specified by the service_perfdata_file_template option. Performance data is only written to this file if the process_performance_data option is enabled globally and if the process_perf_data directive in the service definition is enabled.);
	$docs{'host_perfdata_file_template'} = q(Host performance data file template: This option determines what (and how) data is written to the host performance data file. The template may contain macros, special characters (\t for tab, \r for carriage return, \n for newline) and plain text. A newline is automatically added after each write to the performance data file.);
	$docs{'service_perfdata_file_template'} = q(Service performance data file template: This option determines what (and how) data is written to the service performance data file. The template may contain macros, special characters (\t for tab, \r for carriage return, \n for newline) and plain text. A newline is automatically added after each write to the performance data file.);
	$docs{'host_perfdata_file_mode'} = q(Host performance data file mode: This option determines whether the host performance data file is opened in write or append mode. Unless the file is a named pipe, you will probably want to use the default mode of append. a = Open file in append mode. w = Open file in write mode.); 
	$docs{'service_perfdata_file_mode'} = q(Service performance data file mode: This option determines whether the service performance data file is opened in write or append mode. Unless the file is a named pipe, you will probably want to use the default mode of append. a = Open file in append mode. w = Open file in write mode.); 
	$docs{'host_perfdata_file_processing_interval'} = q(Host performance data file processing interval: This option allows you to specify the interval (in seconds) at which the host performance data file is processed using the host performance data file processing command. A value of 0 indicates that the performance data file should not be processed at regular intervals.);
	$docs{'service_perfdata_file_processing_interval'} = q(Service performance data file processing interval: This option allows you to specify the interval (in seconds) at which the service performance data file is processed using the service performance data file processing command. A value of 0 indicates that the performance data file should not be processed at regular intervals.);
	$docs{'host_perfdata_file_processing_command'} = q(Host performance data file processing command: This option allows you to specify the command that should be executed to process the host performance data file. The command argument is the short name of a command definition that you define in your object configuration file. The interval at which this command is executed is determined by the host_perfdata_file_processing_interval directive.);
	$docs{'service_perfdata_file_processing_command'} = q(Service performance data file processing command: This option allows you to specify the command that should be executed to process the service performance data file. The command argument is the short name of a command definition that you define in your object configuration file. The interval at which this command is executed is determined by the service_perfdata_file_processing_interval directive.);
	$docs{'check_host_freshness'} = q(Host freshness checking option: This option determines whether or not Nagios will periodically check the 'freshness' of host checks. Enabling this option is useful for helping to ensure that passive host checks are received in a timely manner. Checked = enabled.);
	$docs{'host_freshness_check_interval'} = q(Host freshness check interval: This setting determines how often (in seconds) Nagios will periodically check the 'freshness' of host check results. If you have disabled host freshness checking (with the check_host_freshness option), this option has no effect.);
	$docs{'use_regexp_matching'} = q(Regular expression matching option: This option determines whether or not various directives in your object definitions will be processed as regular expressions. Checked = Use regular expression matching);
	$docs{'use_true_regexp_matching'} = q(True regular expression matching option: If you've enabled regular expression matching of various object directives using the use_regexp_matching option, this option will determine when object directives are treated as regular expressions. If this option is disabled (the default), directives will only be treated as regular expressions if the contain a * or ? wildcard character. If this option is enabled, all appropriate directives will be treated as regular expression - be careful when enabling this! Checked = Use true regular expression matching.);
	$docs{'misc_directives'} = q(Add name = value pairs to be included in the nagios.cfg file.);
	return %docs;
}


sub cgi_cfg() {
	my %docs = ();
	$docs{'physical_html_path'} = q(Physical HTML path: This is the path where the HTML files for Nagios reside.  This value is used to locate the logo images needed by the statusmap and statuswrl CGIs.);
	$docs{'url_html_path'} = q(URL HTML path: This is the path portion of the URL that corresponds to the physical location of the Nagios HTML files (as defined above). This value is used by the CGIs to locate the online documentation and graphics.  If you access the Nagios pages with a URL like http://www.myhost.com/nagios, this value should be '/nagios' (without the quotes).);
	$docs{'show_context_help'} = q(Context sensitive help: This option determines whether or not a context-sensitive help icon will be displayed for most of the CGIs. Values: unchecked = disables context-sensitive help checked = enables context-sensitive help.);
	$docs{'nagios_check_command'} = q(Nagios check command: This is the full path and filename of the program used to check the status of the Nagios process.  It is used only by the CGIs and is completely optional.  However, if you don't use it, you'll see warning messages in the CGIs about the Nagios process not running and you won't be able to execute any commands from the web interface.  The program should follow the same rules as plugins; the return codes are the same as for the plugins, it should have timeout protection, it should output something to STDIO, etc. (Note: If you are using the check_nagios plugin here, the first argument should be the physical path to the status log, the second argument is the number of minutes that the status log contents should be 'fresher' than, and the third argument is the string that should be matched from the output of the 'ps' command in order to locate the running Nagios process.  That process string is going to vary depending on how you start Nagios.  Run the 'ps' command manually to see what the command line entry for the Nagios process looks like.));
	$docs{'use_authentication'} = q(Use authentication: This option controls whether or not the CGIs will use any authentication when displaying host and service information, as well as committing commands to Nagios for processing. Read the HTML documentation to learn how the authorization works! (NOTE: It is a really *bad* idea to disable authorization, unless you plan on removing the command CGI (cmd.cgi)!)  Failure to do so will leave you wide open to kiddies messing with Nagios and possibly hitting you with a denial of service attack by filling up your drive by continuously writing to your command file! Setting this value to unchecked will cause the CGIs to *not* use authentication (bad idea), while checked will make them use the authentication functions (the default).);
	$docs{'default_user_name'} = q(Default user: Setting this variable will define a default user name that can access pages without authentication.  This allows people within a secure domain (i.e., behind a firewall) to see the current status without authenticating.  You may want to use this to avoid basic authentication if you are not using a secure server since basic authentication transmits passwords in the clear. Important:  Do not define a default username unless you are running a secure web server and are sure that everyone who has access to the CGIs has been authenticated in some manner!  If you define this variable, anyone who has not authenticated to the web server will inherit all rights you assign to this user!);

	$docs{'authorized_for_system_information'} = q(System/process information access: This option is a comma separated list of all usernames that have access to viewing the Nagios process information as provided by the Extended Information CGI (extinfo.cgi).  By default, *no one* has access to this unless you choose to not use authorization.  You may use an asterisk (*) to authorize any user who has authenticated to the web server.);
	$docs{'authorized_for_configuration_information'} = q(Configuration information access: This option is a comma separated list of all usernames that can view ALL configuration information (hosts, commands, etc). By default, users can only view configuration information for the hosts and services they are contacts for. You may use an asterisk (*) to authorize any user who has authenticated to the web server.);
	$docs{'authorized_for_system_commands'} = q(System/process command access: This option is a comma separated list of all usernames that can issue shutdown and restart commands to Nagios via the command CGI (cmd.cgi).  Users in this list can also change the program mode to active or standby. By default, *no one* has access to this unless you choose to not use authorization. You may use an asterisk (*) to authorize any user who has authenticated to the web server.);
	
	$docs{'authorized_for_all_hosts'} = q(Global host information access: This is a comma separated list of names of authenticated users who can view status and configuration information for all hosts. Users in this list are also automatically authorized to view information for all services. Users in this list are not automatically authorized to issue commands for all hosts or services. If you want users able to issue commands for all hosts and services as well, you must add them to the authorized_for_all_host_commands variable.);
	$docs{'authorized_for_all_host_commands'} = q(Global host command access: This is a comma separated list of names of authenticated users who can issue commands for all hosts via the command CGI. Users in this list are also automatically authorized to issue commands for all services. Users in this list are not automatically authorized to view status or configuration information for all hosts or services. If you want users able to view status and configuration information for all hosts and services as well, you must add them to the authorized_for_all_hosts variable.);

	$docs{'authorized_for_all_services'} = q(Global service information access: This is a comma separated list of names of authenticated users who can view status and configuration information for all services. Users in this list are not automatically authorized to view information for all hosts. Users in this list are not automatically authorized to issue commands for all services. If you want users able to issue commands for all services as well, you must add them to the authorized_for_all_service_commands variable.);
	$docs{'authorized_for_all_service_commands'} = q(Global service command access: This is a comma separated list of names of authenticated users who can issue commands for all services via the command CGI. Users in this list are not automatically authorized to issue commands for all hosts. Users in this list are not automatically authorized to view status or configuration information for all hosts. If you want users able to view status and configuration information for all services as well, you must add them to the authorized_for_all_services variable.);
	$docs{'statusmap_background_image'} = q(Statusmap background image: This option allows you to specify an image to be used as a background in the statusmap CGI.  It is assumed that the image resides in the HTML images path (i.e. /usr/local/nagios/share/images). This path is automatically determined by appending '/images' to the path specified by the 'physical_html_path' directive. Note:  The image file must be in GD2 format!);
	$docs{'default_statusmap_layout'} = q(Default statusmap layout: This option allows you to specify the default layout method the statusmap CGI should use for drawing hosts.  If you do not use this option, the default is to use user-defined coordinates.  Valid options are as follows: User-defined coordinates, Depth layers, Collapsed tree, Balanced tree, Circular, Circular (Marked Up));
	$docs{'default_statuswrl_layout'} = q(Default statuswrl layout: This option allows you to specify the default layout method the statuswrl (VRML) CGI should use for drawing hosts.  If you do not use this option, the default is to use user-defined coordinates.  Valid options are as follows: User-defined coordinates, Collapsed tree, Balanced tree, Circular);
	$docs{'statuswrl_include'} = q(Statuswrl include: This option allows you to include your own objects in the generated VRML world.  It is assumed that the file resides in the HTML path (i.e. /usr/local/nagios/share).);
	$docs{'ping_syntax'} = q(Ping syntax: This option determines what syntax should be used when attempting to ping a host from the WAP interface (using the statuswml CGI).  You must include the full path to the ping binary, along with all required options.  The $HOSTADDRESS$ macro is substituted with the address of the host before the command is executed.);
	$docs{'refresh_rate'} = q(Refresh rate: This option allows you to specify the refresh rate in seconds of various CGIs (status, statusmap, extinfo, and outages).);
	$docs{'sound_options'} = q(Audio alerts: These options allow you to specify an optional audio file that should be played in your browser window when there are problems on the network.  The audio files are used only in the status CGI.  Only the sound for the most critical problem will be played.  Order of importance (higher to lower) is as follows: unreachable hosts, down hosts, critical services, warning services, and unknown services. If there are no visible problems, the sound file optionally specified by 'normal_sound' variable will be played. Note: All audio files must be placed in the /media subdirectory under the HTML path (i.e. /usr/local/nagios/share/media/).);
	$docs{'ddb'} = q(Database directives: These config directives are only used if you compiled Nagios with database support);
	return %docs;
}

sub import_wizard() {
	my %docs = ();
	$docs{'step_1_title'} = q(Step 1: Upload File);
	$docs{'step_1'} = q(Select your text file and the field delimiter.);
	$docs{'step_2_title'} = q(Step 2: Set Schema);
	$docs{'step_2'} = q(Map file data to import fields. Name and address are required for successful import.);
	$docs{'step_3_title'} = q(Step 3: Process Hosts);
	$docs{'step_3'} = q(WARNING: SERIOUS HARM TO THE DATABASE CAN RESULT IF THE DATA BELOW HAS ERRORS (COMMAS IN HOST NAMES, FOR EXAMPLE). USE THE BACK BUTTON TO CHANGE THE DELIMITER IF NECESSARY.<BR /><BR />The results of your import appear in the first of the larger boxes below. You may select the hosts by clicking the left checkbox. Some of the hosts may be highlighted, so note the color coded key. Any host marked 'exception' will be removed from the list and ignored should you attempt to add it. Any host marked exists will be updated should you attempt to add it. Click columns and keys to sort.);

	return %docs;
}

sub discover_wizard() {
	my %docs = ();
	$docs{'step_1_title'} = q(Step 1: Scan Parameters);
	$docs{'step_1'} = q(WARNING: THIS FEATURE DOES A LIMITED Nmap PORT SCAN TO GUESS THE OPERATING SYSTEM.<br /><br />The range of ports can be found in /usr/local/groundwork/monarch/bin/nmap_scan_one.pl. Nmap also does a reverse DNS lookup to resolve host names from their addresses. This requires that DNS is properly configured.<br /><br />To continue, enter a single ip address to discover one host or enter a range to scan part of a subnet. To sweep an entire subnet, set the fourth octet to *.);
	$docs{'step_2_title'} = q(Step 2: Scanning...);
	$docs{'step_2'} = q(Wait for scan to finish before moving to the next step.);
	$docs{'step_3_title'} = q(Step 3: Process Hosts);
	$docs{'step_3'} = q(The results of your scan appear in the first of the larger boxes below. You may select the hosts by clicking the left checkbox. Some of the hosts may be highlighted, so note the color coded key. Any host marked 'exception' will be removed from the list and ignored should you attempt to add it. Any host marked exists will be updated should you attempt to add it. Click columns and keys to sort.);

	return %docs;
}

sub profile_importer() {
	my %docs = ();
	$docs{'profile_importer'} = q(Select from the list of files found in the folder indicated below, or upload a file from your desktop. Files can be generated form the Export button found on the main Host Profile page or the main Service Profile page. Choose 'Overwrite existing objects' to replace all matching time periods, commands, templates, services and profiles. You may also select and remove files from the folder.);
	return %docs;

}

1;




