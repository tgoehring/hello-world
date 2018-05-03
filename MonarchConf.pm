# MonArch - Groundwork Monitor Architect
# MonarchConf.pm
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

package Conf;

use strict;

sub get_dbauth() {
	my $dbhost = 'localhost';
	my $database = 'monarch';
	my $dbuser = 'root';
	my $dbpass = 'DPmm10Zls!';
	return $dbhost, $database, $dbuser, $dbpass;
}

1;
