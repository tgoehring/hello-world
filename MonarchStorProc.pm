# MonArch - Groundwork Monitor Architect
# MonarchStorProc.pm
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
use XML::LibXML;
use DBI;
use Time::Local;
use MonarchConf;
#use FITSAudit;
use MonarchAudit;
use CGI::Session qw/-ip-match/;

package StorProc;

my $debug = 2;
my ($dbh, $err, $rows);
my ($dbhost, $database,$user,$passwd) = undef;
my $is_portal = 0;
if (-e "/usr/local/groundwork/config/db.properties") { $is_portal = 1 }

#
# get_normalized_hostname
#
# Given a hostname with any capitalization, return the same hostname, but with
# the same capitalization that is already stored in the hosts table of the
# monarch database. If there is no such hostname in the monarch database,
# the original hostname is returned.
sub get_normalized_hostname(@) {
    my $name = $_[1];
    my $sqlstmt = "select name from hosts where name = '$name'";
    my $sth = $dbh->prepare($sqlstmt);
    $sth->execute;
    my @values = $sth->fetchrow_array();
    $sth->finish;
    if (@values) {
		return $values[0];
    }
	return $name; # host was not found in monarch database; return original.
}


sub table_enforce_uniqueness {
	my $table = shift;

	my $restricted_tables = {
		'discover_group_filter'       => [ qw(group_id filter_id) ],
		'discover_group_method'       => [ qw(group_id method_id) ],
		'discover_method_filter'      => [ qw(method_id filter_id) ],
		'import_match_contactgroup'   => [ qw(match_id contactgroup_id) ],
		'import_match_group'          => [ qw(match_id group_id) ],
		'import_match_hostgroup'      => [ qw(match_id hostgroup_id) ],
		'import_match_parent'         => [ qw(match_id parent_id) ],
		'import_match_servicename'    => [ qw(match_id servicename_id) ],
		'import_match_serviceprofile' => [ qw(match_id serviceprofile_id) ],
		'contactgroup_group'          => [ qw(contactgroup_id group_id) ],   # GWMON-4351
		'contactgroup_contact'        => [ qw(contactgroup_id contact_id) ], # GWMON-4351
	};
	return unless defined($restricted_tables->{$table});
	return $restricted_tables->{$table};
}

sub dbconnect() {
	if ($is_portal) {
		open(FILE, "< /usr/local/groundwork/config/db.properties");
		while (my $line = <FILE>) {
			if ($line =~ /\s*monarch\.dbhost\s*=\s*(\S+)/) { $dbhost = $1 }
			if ($line =~ /\s*monarch\.database\s*=\s*(\S+)/) { $database = $1 }
			if ($line =~ /\s*monarch\.username\s*=\s*(\S+)/) { $user = $1 }
			if ($line =~ /\s*monarch\.password\s*=\s*(\S+)/) { $passwd = $1 }
		}
		close(FILE);
	} else {
		($dbhost,$database,$user,$passwd) = Conf->get_dbauth();
	}
	my $dsn = "DBI:mysql:$database:$dbhost";
	$dbh = DBI->connect($dsn, $user, $passwd, {'RaiseError' => 1});
	my $sqlstmt = "select value from setup where name = 'login_authentication'";
	my ($login_type) = $dbh->selectrow_array($sqlstmt);
	if ($login_type eq 'none') {
		return 1;
	} elsif ($login_type eq 'passive')  {
		return 3;
	} else {
		return 2;
	}
}

sub set_session(@) {
	my $userid = $_[1];
	my $user_acct = $_[2];
	my $sqlstmt = "select value from setup where name = 'session_timeout'";
	my ($timeout) = $dbh->selectrow_array($sqlstmt);
	my $session = new CGI::Session("driver:MySQL", undef, {Handle=>$dbh});
	my $session_id = $session->id();
 	$session->expire($timeout);     
	$session->param('userid', $userid);
	$session->param('user_acct', $user_acct);
	my $stale = time + 172800;
	$session->param('session_stale', $stale);
	$dbh->do("update users set session = '$session_id' where user_id = '$userid'");
	cleanup_sessions();
	return $session_id;
}

sub set_gwm_session(@) {
	my $user_acct = $_[1];
	my $sqlstmt = "select value from setup where name = 'session_timeout'";
	my ($timeout) = $dbh->selectrow_array($sqlstmt);
	my $session = new CGI::Session("driver:MySQL", undef, {Handle=>$dbh});
	my $session_id = $session->id();
	$sqlstmt = "select user_id from users where user_acct = '$user_acct'";
	my ($userid) = $dbh->selectrow_array($sqlstmt);
	unless ($userid) {
		$sqlstmt = "select usergroup_id from user_groups where name = 'super_users'";
		my ($gid) = $dbh->selectrow_array($sqlstmt);
		$dbh->do("insert into users values(NULL,'$user_acct','$user_acct','','$session_id')");
		$userid = $dbh->selectrow_array("select max(user_id) as lastrow from users");
		$dbh->do("replace into user_group values('$gid','$userid')");
	}
	my $stale = time + 172800;
	$session->param('session_stale', $stale);
	$session->param('userid', $userid);
	$session->param('user_acct', $user_acct);
	$dbh->do("update users set session = '$session_id' where user_id = '$userid'");
	cleanup_sessions();
	return $userid, $session_id;
}

sub cleanup_sessions() {
	my $session_stale = time - 172800;
	my $sqlstmt = "select * from sessions";
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		if ($values[1] =~ /session_stale\s*=>\s*(\d+)/) {
			if ($1 < $session_stale) {
				$dbh->do("delete from sessions where id = '$values[0]'");
			}
		}
	}
	$sth->finish;
}

sub get_session(@) {
	my $sid = $_[1];
	my $auth_passive = $_[2];
	my $now = time;
	my $dt = StorProc->datetime();
	my $session = new CGI::Session("driver:MySQL", $sid, {Handle=>$dbh});
	if ($session) {
		my $stale = time + 172800;
		$session->param('session_stale', $stale);
		if ($is_portal) {
			my $stale = time + 172800;
			$session->param('session_stale', $stale);
		} else {
			my $sqlstmt = "select value from setup where name = 'session_timeout'";
			my ($timeout) = $dbh->selectrow_array($sqlstmt);
			$session->expire($timeout);     
		}
		my $user_acct = $session->param('user_acct');
		my $userid = $session->param('userid');
		return $userid, $user_acct, $sid;
	} else {
		$dbh->do("delete from sessions where id = '$sid'");
		if ($is_portal) {
			my $sqlstmt = "select user_id, user_acct from users where session = '$sid'";
			my ($userid,$user_acct) = $dbh->selectrow_array($sqlstmt);
			$sqlstmt = "select value from setup where name = 'session_timeout'";
			my ($timeout) = $dbh->selectrow_array($sqlstmt);
			my $session = new CGI::Session("driver:MySQL", undef, {Handle=>$dbh});
			$sid = $session->id();
			my $stale = time + 172800;
			$session->param('session_stale', $stale);
			$session->param('userid', $userid);
			$session->param('user_acct', $user_acct);
			$dbh->do("update users set session = '$sid' where userid = '$userid'");
			return $userid, $user_acct, $sid;
		} else {
			return 0;
		}
	}
}

sub check_user(@) {
	my $user_acct = $_[1];
	my $password = $_[2];
	my $error = undef;
	my $now = time;
	my $sqlstmt = "select user_id, session from users where user_acct = '$user_acct'";
	my ($userid,$session) = $dbh->selectrow_array($sqlstmt);
	if ($userid) {
		$sqlstmt = "select value from setup where name = 'login_authentication'";
		my ($login_type) = $dbh->selectrow_array($sqlstmt);
		if ($login_type eq 'active') {
			if ($password) {
				$sqlstmt = "select password from users where user_id = '$userid'";
				my ($ck_password) = $dbh->selectrow_array($sqlstmt);
				if (crypt($password,$ck_password) eq $ck_password) {
					my $sth = $dbh->prepare ("update users set session = $now where user_id = '$userid'");
					$sth->execute;
					$sth->finish;
				} else {
					$error = "Invalid username or password";
				}
			} else {
				$sqlstmt = "select value from setup where name = 'session_timeout'";
				my ($timeout) = $dbh->selectrow_array($sqlstmt);
				if (($now - $session) > $timeout) {
					$error = "Session timed out. Please login.";
				} else {
					my $sth = $dbh->prepare ("update users set session = $now where user_id = '$userid'");
					$sth->execute;
					$sth->finish;
				}
			}
		} else {
			my $sth = $dbh->prepare ("update users set session = $now where user_id = '$userid'");
			$sth->execute;
			$sth->finish;
		}
	} else {
		$error = "Invalid username or password";
	}
	if ($error) {
		return $error;
	} else {
		return $userid;
	}
}

sub auth_matrix(@) {
	my $userid = $_[1];
	my %auth_add = ();
	my %auth_modify = ();
	my %auth_delete = ();
	my $sqlstmt = "select usergroup_id, name from user_groups where usergroup_id in (select usergroup_id from user_group where user_id ='$userid')";
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	my $groupid = undef;
	my $gname = undef;
	eval {$sth->bind_columns(undef, \$groupid, \$gname)};
	while($sth->fetch()) {
		my ($object,$type,$access_values) = undef;
		$sqlstmt = "select object, type, access_values from access_list where usergroup_id = '$groupid'";
		my $sth2 = $dbh->prepare($sqlstmt);
		$sth2->execute;
		eval {$sth2->bind_columns(undef,\$object,\$type,\$access_values)};
		while($sth2->fetch()) {
			if ($type eq 'design_manage') {
				if ($access_values =~ /add/) { $auth_add{$object} = 1; $auth_add{'design'} = 1 }
				if ($access_values =~ /modify/) { $auth_modify{$object} = 1; $auth_add{'modify'} = 1 }
				if ($access_values =~ /delete/) { $auth_delete{$object} = 1 }
			} else {
				if ($type eq 'control' || $gname eq 'super_users') {
					$auth_add{'control'} = 1;
				}
				#if ($type eq 'groups' || $gname eq 'super_users') {
				if ($type eq 'group_macro' || $gname eq 'super_users') {
					$auth_add{'groups'} = 1;
					if ($access_values =~ /manage/) { $auth_add{'groups_manage'} = 1; }
				}
				if ($type eq 'auto_discover' || $gname eq 'super_users') {
					$auth_add{'auto_discover'} = 1;
				}
				$auth_add{$object} = 1;
			} 
		}
		$sth2->finish;
	}
	$sth->finish;
	return (\%auth_add, \%auth_modify, \%auth_delete);
}

sub logout(@) {
	my $user_acct = $_[1];
	my $sth = $dbh->prepare ("update users set session = '0' where user_acct = '$user_acct'");
	$sth->execute;
	$sth->finish;
}

sub dbdisconnect() {
	if ($dbh) {
		$dbh and $dbh->disconnect();
	}
}

sub get_hosts() {
	my %hosts = ();
	my $sqlstmt = "select name, host_id from hosts";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		$hosts{$values[0]} = $values[1];
	}
	$sth->finish;
	return %hosts;
}


sub parse_xml(@) {
	my $data = $_[1];
	my %properties = ();
	if ($data) {
		my $parser = XML::LibXML->new();
		my $doc = $parser->parse_string($data);
		my @nodes = $doc->findnodes( "//prop" );
		foreach my $node (@nodes) {
			if ($node->hasAttributes()) {
				my $property = $node->getAttribute('name');
				my $value = $node->textContent;
				$value =~ s/\s+$|\n//g;
				if ($property =~ /command$/) {
					my $command_line = '';
					if ($value) {
						my @command = split(/!/, $value);
						$properties{$property} = $command[0];
						if ($command[1]) {
							foreach my $c (@command) {
								$command_line .= "$c!";
							}
						}
					}
					$command_line =~ s/!$//;
					$properties{'command_line'} = $command_line;
				} elsif ($property =~ /last_notification$/) {
					my $value = $node->textContent;
					$value =~ s/\s+$|\n//g;
					if ($value == 0) {
						$properties{$property} = '-zero-';
					} else {					
						$properties{$property} = $value;
					}
				} else {
					$properties{$property} = $value;
				}
			}
		}
		return %properties;
	} else {
		$properties{'error'} = "Empty String (parse_xml)";
	}
}

sub fetch_last(@) {
	my $table = $_[1];
	my $sqlstmt = "select max(id) as lastrow from $table";
	my $id = $dbh->selectrow_array($sqlstmt);
	return $id;
}

sub fetch_one(@) {
	my $table = $_[1];
	my $name = $_[2];
	my $value = $_[3];
	my $values = undef;
	my %properties = ();
	$value = $dbh->quote($value);
	my $sqlstmt = "select * from $table where $name = $value";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	$values = $sth->fetchrow_hashref();
	foreach my $key (keys %{$values}) {
		if ($key eq 'data' && $table !~ /external/) {
			my %data = parse_xml('',$values->{$key});
			foreach my $k (keys %data) {
				$properties{$k} = $data{$k};
			}
		} else {
			$properties{$key} = $values->{$key};
		}
	}
	$sth->finish;
	return %properties;
}

sub fetch_one_where(@) {
	my $table = $_[1];
	my $where = $_[2];
	my %where = %{$where};
	my $where_clause = undef;
	foreach my $name (keys %where) {
		unless ($name =~ /^HASH(?:\(0x[0-9A-Fa-f]+\))?$/) {
			if ($name eq 'data') {
				my $like = '%[CDATA['.$where{$name}.']%';
				$like = $dbh->quote($like);
				$where_clause .= " $name like '$like' and"; 
			} else {
				$where{$name} = $dbh->quote($where{$name});
				$where_clause .= " $name = $where{$name} and"; 
			}
		}
	}
	$where_clause =~ s/ and$//;
	my $sqlstmt = "select * from $table where $where_clause";
	#print STDERR "in fetch_one_where() sql is [$sqlstmt]\n" if ($debug);
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	my $values = $sth->fetchrow_hashref();
	my %properties = ();
	foreach my $key (keys %{$values}) {
		#print STDERR "in fetch_one_where() key is [$key] and value is [$values->{$key}]\n" if ($debug);
		if ($key eq 'data' && $table !~ /external/) {
			my %data = parse_xml('',$values->{$key});
			foreach my $k (keys %data) {
				$properties{$k} = $data{$k};
			}
		} else {
			$properties{$key} = $values->{$key};
		}
	}
	$sth->finish;
	return %properties;
}


sub fetch_list(@) {
	my $table = $_[1];
	my $list = $_[2];
	my $orderby = $_[3];
	my @values = ();
	my @elements = ();
	if ($orderby) { $orderby = " order by $orderby" }
	my $sqlstmt = "select $list from $table$orderby";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	while(@values = $sth->fetchrow_array()) {
		unless ($values[0] eq '*') { push @elements, $values[0] }
	}
	$sth->finish;
	return @elements;
}

sub fetch_list_where(@) {
	my $table = $_[1];
	my $list = $_[2];
	my $where = $_[3];
	my $orderby = $_[4];
	if ($orderby) { $orderby = " order by $orderby" }
	my %where = %{$where};
	my $where_clause = undef;
	foreach my $name (keys %where) {
		unless ($name =~ /^HASH(?:\(0x[0-9A-Fa-f]+\))?$/) {
			if ($name eq 'data') {
				my $like = '%[CDATA['.$where{$name}.']%';
				$like = $dbh->quote($like);
				$where_clause .= " $name like $like and"; 
			} else {
				$where{$name} = $dbh->quote($where{$name});
				$where_clause .= " $name = $where{$name} and"; 
			}
		}
	}
	$where_clause =~ s/ and$//;
	my $sqlstmt = "select $list from $table where $where_clause$orderby";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	my @elements = ();
	my @values = ();
	while(@values = $sth->fetchrow_array()) {
		unless ($values[0] eq '*') { push @elements, $values[0] }
	}
	$sth->finish;
	return @elements;
}

sub fetch_list_like(@) {
	my $table = $_[1];
	my $list = $_[2];
	my $where = $_[3];
	my %where = %{$where};
	my $where_clause = undef;
	foreach my $name (keys %where) {
		unless ($name =~ /^HASH(?:\(0x[0-9A-Fa-f]+\))?$/) {
			my $like = '%'.$where{$name}.'%';
			$like = $dbh->quote($like);
			$where_clause .= " $name like $like and"; 
		}
	}
	$where_clause =~ s/ and$//;
	my $sqlstmt = "select $list from $table where $where_clause";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	my @elements = ();
	my @values = ();
	while(@values = $sth->fetchrow_array()) {
		push @elements, $values[0];
	}
	$sth->finish;
	return @elements;
}

sub fetch_list_start(@) {
	my $table = $_[1];
	my $list = $_[2];
	my $name = $_[3];
	my $value = $_[4];
	$value .= "%";
	$value = $dbh->quote($value);
	my $sqlstmt = "select $list from $table where $name like $value";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	my @elements = ();
	while(my @values = $sth->fetchrow_array()) {
		push @elements, $values[0];
	}
	$sth->finish;
	return @elements;
}

sub fetch_distinct_list(@) {
	my $table = $_[1];
	my $list = $_[2];
	my @values = ();
	my @elements = ();
	my $sqlstmt = "select distinct $list from $table";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	while(@values = $sth->fetchrow_array()) {
		push @elements, $values[0];
	}
	$sth->finish;
	return @elements;
}

sub fetch_unique(@) {
	my $table = $_[1];
	my $list = $_[2];
	my $object = $_[3];
	my $value = $_[4];
	my @values = ();
	my @elements = ();
	$value = $dbh->quote($value);
	my $sqlstmt = "select $list from $table where $object = $value";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	while(@values = $sth->fetchrow_array()) {
		push @elements, $values[0];
	}
	$sth->finish;
	return @elements;
}

sub fetch_list_hash_array(@) {
	my $table = $_[1];
	my $where = $_[2];
	my %where = %{$where};
	my %elements = ();
	my $where_clause = undef;
	foreach my $name (keys %where) {
		unless ($name =~ /^(?:HASH(?:\(0x[0-9A-Fa-f]+\))?)|NONE$/) {
			$where{$name} = $dbh->quote($where{$name});
			$where_clause .= " $name = $where{$name} and"; 
		}
	}
	$where_clause =~ s/ and$//;
	if ($where_clause) { $where_clause = " where $where_clause" }
	my $sqlstmt = "select * from $table$where_clause";
	my $sth = $dbh->prepare($sqlstmt);
	if ($sth->execute) {
		while(my @values = $sth->fetchrow_array()) {
			$elements{$values[0]} = [ @values ];
		}
		$sth->finish;
		return %elements;
	} else {
		$elements{'error'} = "Error: $@";
		$sth->finish;
		return %elements;
	}
}

# same as fetch_list_hash_array but uses a generated key, useful to dump associative tables
sub fetch_hash_array_generic_key(@) {
	my $table = $_[1];
	my $where = $_[2];
	my %where = %{$where};
	my %elements = ();
	my $where_clause = undef;
	foreach my $name (keys %where) {
		unless ($name =~ /^(?:HASH(?:\(0x[0-9A-Fa-f]+\))?)|NONE$/) {
			$where{$name} = $dbh->quote($where{$name});
			$where_clause .= " $name = $where{$name} and"; 
		}
	}
	$where_clause =~ s/ and$//;
	if ($where_clause) { $where_clause = " where $where_clause" }
	my $sqlstmt = "select * from $table$where_clause";
	my $sth = $dbh->prepare($sqlstmt);
	if ($sth->execute) {
		my $key = 1;
		while(my @values = $sth->fetchrow_array()) {
			$elements{$key} = [ @values ];
			$key++;
		}
		$sth->finish;
		return %elements;
	} else {
		$elements{'error'} = "Error: $@";
		$sth->finish;
		return %elements;
	}
}



sub fetch_all($) {
	my $table = $_[1];
	my %elements = ();
	my @values = undef;
	my $sqlstmt = "select * from $table";
	my $sth = $dbh->prepare ($sqlstmt);
	if ($sth->execute) {
		while(@values = $sth->fetchrow_array()) {
			$elements{$values[0]} = [ @values ];
		}
		$sth->finish;
		return %elements;
	} else {
		$sth->finish;
		return "Error: $sqlstmt $@";
	}
}

sub insert_obj(@) {
	my $table = $_[1];
	my $values =  $_[2];
	my @values = @{$values};
	my $valstr = undef;
	foreach my $val (@values) {
		unless ($val) { $val = 'NULL' }
		unless ($val eq 'NULL') { $val = $dbh->quote($val) }
		$valstr .= "$val,";
	}
	chop $valstr;
	if ($table eq 'service_instance' && $values[2] eq 'NULL') {
		print STDERR "warning: attempted to insert record with column 'name' value of NULL into service_instance\n" if ($debug);
		return 1;
	}

	if (my $fields = table_enforce_uniqueness($table)) {
		my $offset = 0;
		my %where = ();
		foreach my $field (@$fields) {
			$where{$field} = $values[$offset++];
			$where{$field} =~ s/^\s*'(.*)'\s*$/$1/; # prevent double quoting; fetch_one_where() will add quotes.
		}
		print STDERR "warning: more values than expected in table [$table]\n" if ($debug && $values[$offset]);
		my %result = fetch_one_where('', $table, \%where);
		if (keys %result) {
			print STDERR "pre-existing record for [$valstr] found in table [$table]; extra insert prevented.\n" if ($debug);
			return 1; # record with these values already exists; return immediately
		}
	}

	my $sqlstmt = "insert into $table values($valstr)";
	Audit->auditlog("userid", "INSERT", "$table", "$valstr");
	print STDERR "in insert_obj() sql is [$sqlstmt]\n" if ($debug);
	my $sth = undef;
	eval{$sth = $dbh->prepare ($sqlstmt);
	$sth->execute()};
	if ($@) {
		$sth->finish;
		return "Error: $sqlstmt $@";
	} else {
		$sth->finish;
		return 1;
	}
}

sub insert_obj_id(@) {
	my $table = $_[1];
	my $values =  $_[2];
	my $id =  $_[3];
	my @values = @{$values};
	my $valstr = undef;
	foreach my $val (@values) {
		unless ($val) { $val = 'NULL' }
		unless ($val eq 'NULL') { $val = $dbh->quote($val) }
		$valstr .= "$val,";
	}
	chop $valstr;

#   Uncomment this if duplicate key errors are encountered and are traced to this subroutine.
#   So far we only have records of such errors happening in insert_obj(), not insert_obj_id().
#   If it turns out this code is needed, check the TODO item below before using.
#
#	if (my $fields = table_enforce_uniqueness($table)) {
#		if ($debug) {
#			my $debug_string = "insert_obj_id(): enforcing uniqueness for table [$table] with fields " . join(":", @$fields) . " and values " . join(":", @values);
#			print STDERR "$debug_string\n" if ($debug);
#		}
#		my $offset = 0;
#		my $where = 'where';
#		foreach my $field (@$fields) {
# TODO: check whether single quotes in next line are redundant
#			$where .= " $field = '$values[$offset++]' and";
#		}
#		$where =~ s/ and$//;
#		print STDERR "warning: more values than expected in table [$table]\n" if ($debug && $values[$offset]);
#		my $sqlstmt = "select max($id) as lastrow from $table $where";
#		my $id = $dbh->selectrow_array($sqlstmt);
#		if ($id ne 'NULL') {
#			print STDERR "pre-existing record for [$valstr] found in table [$table]; extra insert prevented.\n" if ($debug);
#			return $id;
#		}
#	}

	my $sqlstmt = "insert into $table values($valstr)";
	my $sth = undef;
	eval{$sth = $dbh->prepare ($sqlstmt);
	$sth->execute()};
	if ($@) {
		$sth->finish;
		return "Error: $sqlstmt $@";
	} else {
		$sqlstmt = "select max($id) as lastrow from $table";
		my $id = $dbh->selectrow_array($sqlstmt);
		$sth->finish;
		return $id;
	}
}

sub update_obj(@) {
	my $table = $_[1];
	my $name = $_[2];
	my $obj = $_[3];
	my $values =  $_[4];
	my %values = %{$values};
	my $valstr = undef;
	$obj = $dbh->quote($obj);
	foreach my $key (keys %values) {
		unless ($key =~ /^HASH(?:\(0x[0-9A-Fa-f]+\))?$/) {
			unless ($values{$key}) { $values{$key} = 'NULL' }
			unless ($values{$key} eq 'NULL') { $values{$key} = $dbh->quote($values{$key}) }
			$valstr .= "$key = $values{$key},";
		}
	}
	chop $valstr;
	my $sqlstmt = "update $table set $valstr where $name = $obj";
	my $sth = undef;
	eval{$sth = $dbh->prepare ($sqlstmt);
	$sth->execute()};
	if ($@) {
		$sth->finish;
		return "Error: $sqlstmt $@";
	} else {
		$sth->finish;
		return 1;
	}
}

sub update_obj_where(@) {
	my $table = $_[1];
	my $values =  $_[2];
	my $where = $_[3];
	my %values = %{$values};
	my %where = %{$where};
	my $valstr = undef;
	foreach my $key (keys %values) {
		unless ($key =~ /^HASH(?:\(0x[0-9A-Fa-f]+\))?$/) {
			unless ($values{$key}) { $values{$key} = 'NULL' }
			unless ($values{$key} eq 'NULL') { $values{$key} = $dbh->quote($values{$key}) }
			$valstr .= "$key = $values{$key},";
		}
	}
	chop $valstr;
	my $where_clause = undef;
	foreach my $name (keys %where) {
		unless ($name =~ /^HASH(?:\(0x[0-9A-Fa-f]+\))?$/) {
			my $val = $dbh->quote($where{$name});
			$where_clause .= " $name = $val and"; 
		}
	}
	$where_clause =~ s/ and$//;
	my $sqlstmt = "update $table set $valstr where $where_clause";
	my $sth = $dbh->prepare ($sqlstmt);
	if ($sth->execute) {
		$sth->finish;
		return 1;
	} else {
		$sth->finish;
		return "Error: $sqlstmt $@";
	}
}

sub delete_all(@) {
	my $table = $_[1];
	my $name = $_[2];
	my $obj = $_[3];
	$obj = $dbh->quote($obj);
	my $sqlstmt = "delete from $table where $name = $obj";
	my $sth = $dbh->prepare ($sqlstmt);
	if ($sth->execute) {
		$sth->finish;
		return 1;
	} else {
		$sth->finish;
		return "Error: $sqlstmt $@";
	}
}

sub delete_one_where(@) {
	my $table = $_[1];
	my $where = $_[2];
	my %where = %{$where};
	my $where_clause = undef;
	foreach my $name (keys %where) {
		unless ($name =~ /^HASH(?:\(0x[0-9A-Fa-f]+\))?$/) {
			if ($name eq 'data') {
				my $like = '%[CDATA['.$where{$name}.']%';
				$like = $dbh->quote($like);
				$where_clause .= " $name like $like and"; 
			} else {
				my $val = $dbh->quote($where{$name});
				$where_clause .= " $name = $val and"; 
			}
		}
	}
	$where_clause =~ s/ and$//;
	my $sqlstmt = "delete from $table where $where_clause";
	my $sth = $dbh->prepare ($sqlstmt);
	if ($sth->execute) {
		$sth->finish;
		return 1;
	} else {
		$sth->finish;
		return "Error: $sqlstmt $@";
	}
}


sub fetch_service(@) {
	my $sid = $_[1];
	my @errors = ();
	my $values = undef;
	my %properties = ();
	my $sqlstmt = "select * from services where service_id = '$sid'";
	my $sth = $dbh->prepare ($sqlstmt);
	if ($sth->execute) {
		$values = $sth->fetchrow_hashref();
		foreach my $key (keys %{$values}) {
			$properties{$key} = $values->{$key};
		}
	} else {
		push @errors, "$sqlstmt $@";
	}
	$sth->finish;

	$sqlstmt = "select name from service_names where servicename_id = '$properties{'servicename_id'}'";
	$properties{'service_name'} = $dbh->selectrow_array($sqlstmt);

	$sqlstmt = "select name from service_templates where servicetemplate_id = '$properties{'servicetemplate_id'}'";
	$properties{'template'} = $dbh->selectrow_array($sqlstmt);

	$sqlstmt = "select name from extended_service_info_templates where serviceextinfo_id = '$properties{'serviceextinfo_id'}'";
	$properties{'ext_info'} = $dbh->selectrow_array($sqlstmt);

	$sqlstmt = "select name from escalation_trees where tree_id = '$properties{'escalation_id'}'";
	$properties{'escalation'} = $dbh->selectrow_array($sqlstmt);

	$sqlstmt = "select name from commands where command_id = '$properties{'check_command'}'";
	$properties{'check_command'} = $dbh->selectrow_array($sqlstmt);

	$sqlstmt = "select name from service_dependency_templates where id in ".
		"(select template from service_dependency where service_id = '$sid')";
	$properties{'dependency'} = $dbh->selectrow_array($sqlstmt);

	if (@errors) {
		$properties{'errors'} = @errors;
	}
	return %properties;
}



sub fetch_host(@) {
	my $name = $_[1];
	my $by = $_[2];
	my @errors = ();
	my $values = undef;
	my %properties = ();
	my $where = 'name';
	if ($by eq 'address') { $where = 'address'	}
	my $sqlstmt = "select * from hosts where $where = '$name'";
	my $sth = $dbh->prepare ($sqlstmt);
	if ($sth->execute) {
		$values = $sth->fetchrow_hashref();
		foreach my $key (keys %{$values}) {
			$properties{$key} = $values->{$key};
		}
	} else {
		push @errors, "$sqlstmt $@";
	}
	$sth->finish;

	$sqlstmt = "select name from host_templates where hosttemplate_id = '$properties{'hosttemplate_id'}'";
	$properties{'template'} = $dbh->selectrow_array($sqlstmt);

	# Host parent
	$sqlstmt = "select hosts.name from hosts left join host_parent on hosts.host_id = host_parent.parent_id ".
		"where host_parent.host_id = '$properties{'host_id'}'";
	$sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	my @names = ();
	while(my @values = $sth->fetchrow_array()) { push @names, $values[0] }
	$sth->finish;	
	$properties{'parents'} = [ @names ];

	# Hostgroups
	$sqlstmt = "select hostgroups.name from hostgroups left join ".
		"hostgroup_host on hostgroups.hostgroup_id = hostgroup_host.hostgroup_id where host_id = '$properties{'host_id'}'";
	$sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	@names = ();
	while(my @values = $sth->fetchrow_array()) { push @names, $values[0] }
	$sth->finish;	
	$properties{'hostgroups'} = [ @names ];

	$sqlstmt = "select name from extended_host_info_templates where hostextinfo_id = '$properties{'hostextinfo_id'}'";
	$properties{'ext_info'} = $dbh->selectrow_array($sqlstmt);

	$sqlstmt = "select name from extended_host_info_templates where hostextinfo_id = '$properties{'hostextinfo_id'}'";
	$properties{'coords2d'} = $dbh->selectrow_array($sqlstmt);

	$sqlstmt = "select data from extended_info_coords where host_id = '$properties{'host_id'}'";
	my $data = $dbh->selectrow_array($sqlstmt);
	my %data = parse_xml('',$data);
	$properties{'coords2d'} = $data{'2d_coords'};
	$properties{'coords3d'} = $data{'3d_coords'};

	$sqlstmt = "select name from escalation_trees where tree_id = '$properties{'host_escalation_id'}'";
	$properties{'host_escalation'} = $dbh->selectrow_array($sqlstmt);

	$sqlstmt = "select name from escalation_trees where tree_id = '$properties{'service_escalation_id'}'";
	$properties{'service_escalation'} = $dbh->selectrow_array($sqlstmt);
	
	my %overrides = fetch_one('','host_overrides','host_id',$properties{'host_id'});
	if ($overrides{'status'}) {
		foreach my $name (keys %overrides) {
			$properties{$name} = $overrides{$name};
		}
	}

	
	if (@errors) {
		$properties{'errors'} = @errors;
	}
	return %properties;

}

sub datetime() {
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


sub pre_flight_check(@) {
	my $nagios_bin = $_[1];
	my $monarch_home = $_[2];
	my @results = ();
	my $results = qx($nagios_bin/nagios -v $monarch_home/workspace/nagios.cfg 2>&1) || push @results, "Error(s) executing $nagios_bin/nagios -v $monarch_home/workspace/nagios.cfg $!";
	if ($results =~ /Things look okay/i) {
		push @results, "Success:";
	}
	my @res = split(/\n/, $results);
	foreach my $msg (@res) {
		if ($is_portal) {
			if ($msg =~ /Warning: Size of service_message struct/) {
				next;
			} elsif ($msg =~ /Total Warnings: (\d+)/) {
				my $warnings = $1 - 1;
				push @results, "Total Warnings: $warnings";
			} else {
				push @results, $msg;
			}
		} else {
			push @results, $msg;
		}
	}
	return @results;
}

sub get_dir(@) {
	my $dir = $_[1];
	my $includes = $_[2];
	my @includes = @{$includes} if $includes;
	my @files = ();
	opendir(DIR, $dir) || (push @files, "error: cannot open $dir to read $!");
	while (my $file = readdir(DIR)) {
		if ( -f "$dir/$file") { push @files, $file }
	}
	close(DIR);
	if (@includes) {
		my @inc_files = ();
		foreach my $file (@files) {
			foreach my $ext (@includes) {
				if ($file =~ /$ext$/i) { push @inc_files, $file }
			}
		}
		@files = @inc_files;
	}
	return @files;
}

sub commit(@) {
	my $monarch_home = $_[1];
	my @results = ();
	my $res = qx($monarch_home/bin/nagios_reload 2>&1) || push @results, "Error(s) executing $monarch_home/bin/nagios_reload $!";
	if ($res =~ /NAGIOS ok|Starting nagios ..done|Nagios start complete/i) {
		push @results, $res;
		push @results, "Good. Changes accepted.";
		if ($is_portal) {
			use MonarchFoundationSync;
			my $string = FoundationSync->sync();
			push @results, $string;
		}
		use MonarchCallOut;
		my $string = CallOut->submit($monarch_home);
		push @results, $string;
	} else {
		push @results, $res;
	}
	return @results;
}

sub upload(@) {
	my $upload = $_[1];
	my $filename = $_[2];
	my $write_to = $_[3];
	my $buff = 0;
	my $bytes_read = undef;
	my $size = (-s $filename);
	my $file = "$upload/$filename";
	if ($write_to) { $file = $write_to } 
	unless (open (WFD, "> $file")) {
	    return qq(Error: Could not open file for writing. $file $!);
	} else {
		binmode WFD;	
		while ($bytes_read = read($filename, $buff, 2096)) {
			$size += $bytes_read;
			binmode WFD;
			print WFD $buff;
		}
		close WFD;
		if ((stat $file)[7] <= 0) {
			unlink($file);
			return qq(Error: Could not upload file: $filename to $file $!);
		} else {
			# dos 2 unix
			my $out = undef;
			open (FILE, "< $file");
			while (my $line = <FILE>) {
				$line =~ s/\r\n/\n/;
				$out .= $line;
			}
			close FILE;
			open (FILE, "> $file");
			print FILE $out;
			close FILE;
			return $file;
		}
	}
}

sub parse_file(@) {
	my $file = $_[1];
	my $delimiter = $_[2];
	my $name_pos = $_[3];
	my %file_data = ();
	unless ($name_pos) { $name_pos = 0 }
	my $i = 1;
	unless (open (FILE, "< $file")) {
		$file_data{'error'} = "$file $!";
	} else {
		my $line_1 = undef;
		while (my $line = <FILE>) {
			unless ($line =~ /\S+/) { next }
			if ($delimiter eq 'tab' && $line !~ /\t/) {
				next;
			} elsif ($line !~ /$delimiter/) {
				next;
			}
			unless ($file_data{'line_1'}) { $file_data{'line_1'} = $line  }
			if ($delimiter) {
				my @fields = split(/$delimiter/, $line);
				if ($delimiter eq 'tab') { @fields = split(/\t/, $line) }
				$file_data{$fields[$name_pos]} = $line;
			} else {
				$file_data{$i} = $line;
				$i++;
			}
		}
	}
	close(FILE);
	return %file_data;
}



sub process_schema() {
	my $userid = $_[1];
	my $filename = $_[2];
	my $schema = $_[3];
	my @errors = ();
	my %schema = fetch_one('','import_schemas','name',$schema);
	$schema{'host'}--;
	$schema{'alias'}--;
	$schema{'address'}--;
	$schema{'os'}--;
	$schema{'service'}--;
	$schema{'info'}--;
	my ($service, $host, $services, $hosts) = undef;
	my ($os, $address, $hostname, $got_host) = undef;
	my @services = ();
	open (FILE, "< $filename") || push @errors, "error: cannot open $filename $!";
	my @lines = ();
	while (my $line = <FILE>){
		$line =~ s/\"//g;
		push @lines, $line;
	}
	close (FILE);
	push @lines, 'EOF';
	foreach my $line (@lines) {
		my @values = split(/$schema{'field_separator'}/,$line);
		if ($values[$schema{'host'}] eq $hostname ) { 
			my $svc = $values[$schema{'service'}];
			$svc =~ s/^\s+|\s+$//g;
			my $info = $values[$schema{'info'}];
			$info =~ s/^\s+|\s+$//g;
			my %service = (
				service => $svc,
				info => $info
				);
			push @services, { %service };
			$got_host = 1;
		} else {
			if ($got_host || $line eq 'EOF') {
				if (!$os) { $os = "nomatch" }
				my @host_vals = split(/\./, $hostname);
				my $name = shift @host_vals;
				my $alias = $hostname;
				if (!$name) { $name = $address }
				my @host_values = ($name,$userid,'import','incomplete',$alias,$address,$os,'','','');
				my $result = insert_obj('','stage_hosts',\@host_values);
				if ($result =~ /Error/) {
					push @errors, $result;

				} else {				
					for my $i ( 0 .. $#services ) {
						my @service_values = ($services[$i]{'service'},$userid,'import','incomplete',$name,'');
						$result = insert_obj('','stage_host_services',\@service_values);
						if ($result =~ /Error/) { push @errors, $result }
					}
				}
				@services = ();
				$os = undef;
				$address = undef;
				$host = undef;
			}
			$hostname = $values[$schema{'host'}]; 
			$hostname =~ s/^\s+|\s+$//g;
			$address = $values[$schema{'address'}];
			$address =~ s/^\s+|\s+$//g;
			$os = $values[$schema{'os'}];
			$os =~ s/^\s+|\s+$//g;
			if ($values[$schema{'service'}]) {
				my $svc = $values[$schema{'service'}];
				$svc =~ s/^\s+|\s+$//g;
				my $info = $values[$schema{'info'}];
				$info =~ s/^\s+|\s+$//g;
				my %service = (
					service => $svc,
					info => $info
					);
				push @services, { %service };
			}
		}
	}
	return @errors;
}

sub process_nmap(@) {
	my $data = $_[1];
	my ($tree, $os, $address, $hostname) = undef;
	my ($line, $service, $host, $services, $hosts, $status) = undef;
	my @errors = ();
	my $parser = XML::LibXML->new();
	$tree = $parser->parse_string($data);
	my $root = $tree->getDocumentElement;
	my @nodes = $root->findnodes( "//host" );
	my %host_values = ();
	foreach my $node (@nodes) {
		my @siblings = $node->getChildnodes();
		foreach my $sibling (@siblings) {
			if ($sibling->nodeName() =~ /hostnames$/) {
				if ($sibling->hasChildNodes()) {
					my $child = $sibling->getFirstChild();
					$hostname = $child->getAttribute('name');
				}
			} elsif ($sibling->nodeName() =~ /address$/) {
				my $addrtype = $sibling->getAttribute('addrtype');
				if ($addrtype =~ /ip/i) {
					$address = $sibling->getAttribute('addr');
				}
			} elsif ($sibling->nodeName() =~ /status$/) {
				$status = $sibling->getAttribute('state');
			} elsif ($sibling->nodeName() =~ /os$/) {
				my @children = $sibling->getChildnodes();
				foreach my $child (@children) {
					if ($child->nodeName() =~ /osmatch$/) {$os = $child->getAttribute('name');}
				}
			}
		}
		if (!$os) { $os = "nomatch" }
		my @host_vals = split(/\./, $hostname);
		my $name = shift @host_vals;
		my $alias = $hostname;
		unless ($name) { $name = $address }
		%host_values = ('name' => $name,'alias' => $alias,'os' => $os,'status' => $status);
	}
	if (@errors) { $host_values{'errors'} = [ @errors ] }
	return %host_values;
}

sub get_service_name(@) {
	my $sid = $_[1];
	my $sqlstmt = "select service_names.name from service_names left join services on ".
		"service_names.servicename_id = services.servicename_id where services.service_id = '$sid'";
	my $name = $dbh->selectrow_array($sqlstmt);
	return $name;
}

sub get_names_in(@) {
	my $id1 = $_[1];
	my $table1 = $_[2];
	my $table2 = $_[3];
	my $id2 = $_[4];
	my $value = $_[5];
	my $where = undef;
	if ($value) { $where = " where $id2 = '$value'" }
	my $sqlstmt = "select * from $table1 where $id1 in ".
		"(select $id1 from $table2$where)";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	my @names = ();
	while(my @values = $sth->fetchrow_array()) { push @names, $values[1]}
	$sth->finish;	
	return @names;
}

sub get_tree_templates(@) {
	my $id = $_[1];
	my %properties = ();
	my $sqlstmt = "select * from escalation_templates where template_id in ".
		"(select template_id from escalation_tree_template where tree_id = '$id')";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	my @order = ();
	my %first_notify = ();
	my %notification_names = ();
	my %name_id = ();
	while(my @values = $sth->fetchrow_array()) {
		my %data = parse_xml('',$values[3]);
		$first_notify{$values[0]} = $data{'first_notification'};
		$properties{$values[0]} = [ @values ];
		$name_id{$values[1]} = $values[0];
		$notification_names{$data{'first_notification'}} .= "$values[1],";
	}
	$sth->finish;
	chop $notification_names{'-zero-'};
	my @sort = split(/,/, $notification_names{'-zero-'});
	@sort = sort @sort;
	foreach my $name (@sort) {
		push @order, $name_id{$name};
	}
	delete $notification_names{'-zero-'};

	foreach my $notification (sort keys %notification_names) {
		my @sort = split(/,/, $notification_names{$notification});
		@sort = sort @sort;
		foreach my $name (@sort) {
			push @order, $name_id{$name};
		}
	}

	return \@order, \%first_notify, \%properties;
}

sub get_tree_template_contactgroup(@) {
	my $tree_id = $_[1];
	my $temp_id = $_[2];
	my %properties = ();
	my $sqlstmt = "select contactgroups.name from contactgroups where contactgroup_id in ".
		"(select contactgroup_id from tree_template_contactgroup where tree_id = '$tree_id' and template_id = '$temp_id')";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	my @names = ();
	while(my @values = $sth->fetchrow_array()) { push @names, $values[0]}
	$sth->finish;	
	return @names;
}


sub get_contactgroups(@) {
	my $type = $_[1];
	my $id = $_[2];
	my $table = table_by_object('',$type);
	my %obj_id = get_obj_id();
	my $sqlstmt = "select * from contactgroups where contactgroup_id in ".
#		"(select contactgroup_id from contactgroup_assign where type = '$type' and object = '$obj')";
		"(select contactgroup_id from $table where $obj_id{$table} = '$id')";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	my @names = ();
	while(my @values = $sth->fetchrow_array()) { push @names, $values[1]}
	$sth->finish;	
	return @names;
}

sub get_profile_hostgroup(@) {
	my $pid = $_[1];
	my $sqlstmt = "select name from hostgroups where hostgroup_id in ".
		"(select hostgroup_id from profile_hostgroup where hostprofile_id = '$pid')";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	my @names = ();
	while(my @values = $sth->fetchrow_array()) { push @names, $values[0]}
	$sth->finish;	
	return @names;
}

sub get_externals() {
	my %externals = ();
	my $sqlstmt = "select * from externals";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) { 
		$externals{$values[0]}{'name'} = $values[1];
		$externals{$values[0]}{'type'} = $values[3];
		$externals{$values[0]}{'data'} = $values[4];
	}
	$sth->finish;	
	return %externals;
}

sub get_profile_external(@) {
	my $pid = $_[1];
	my $sqlstmt = "select name from externals where external_id in ".
		"(select external_id from external_host_profile where hostprofile_id = '$pid')";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	my @names = ();
	while(my @values = $sth->fetchrow_array()) { push @names, $values[0]}
	$sth->finish;	
	return @names;
}

sub get_servicename_external(@) {
	my $sid = $_[1];
	my $sqlstmt = "select name from externals where external_id in ".
		"(select external_id from external_service_names where servicename_id = '$sid')";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	my @names = ();
	while(my @values = $sth->fetchrow_array()) { push @names, $values[0]}
	$sth->finish;	
	return @names;
}

sub get_profile_parent(@) {
	my $pid = $_[1];
	my $sqlstmt = "select name from hosts where host_id in ".
		"(select host_id from profile_parent where hostprofile_id = '$pid')";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	my @names = ();
	while(my @values = $sth->fetchrow_array()) { push @names, $values[0]}
	$sth->finish;	
	return @names;
}

sub get_profiles() {
	my %profiles = ();
	my $sqlstmt = "select * from profiles_host";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	my @names = ();
	while(my @values = $sth->fetchrow_array()) { 
		$profiles{$values[1]}{'description'} = $values[2];
		$sqlstmt = "select name, description from profiles_service where serviceprofile_id in (select serviceprofile_id from profile_host_profile_service where hostprofile_id = $values[0])";
		my $sth2 = $dbh->prepare ($sqlstmt);
		$sth2->execute;
		while(my @vals = $sth2->fetchrow_array()) { $profiles{$values[1]}{$vals[0]} = $vals[1] } 
		my %data = parse_xml('',$values[8]);
		@{$profiles{$values[1]}{'hostgroups'}} = ();
		if ($data{'apply_hostgroups'}) {
			$sqlstmt = "select name from hostgroups where hostgroup_id in (select hostgroup_id from profile_hostgroup where hostprofile_id = '$values[0]')";
			my $sth3 = $dbh->prepare ($sqlstmt);
			$sth3->execute;
			while(my @hgs = $sth3->fetchrow_array()) { push @{$profiles{$values[1]}{'hostgroups'}}, $hgs[0] } 
			$sth3->finish;	
		}
		$sth2->finish;	
	}
	$sth->finish;	
	return %profiles;
}

sub get_host_parent(@) {
	my $hid = $_[1];
	my $sqlstmt = "select name from hosts where host_id in ".
		"(select parent_id from host_parent where host_id = '$hid')";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	my @names = ();
	while(my @values = $sth->fetchrow_array()) { push @names, $values[0]}
	$sth->finish;	
	return @names;
}

sub get_parents(@) {
	my $sqlstmt = "select name from hosts where host_id in (select distinct parent_id from host_parent)";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	my @names = ();
	while(my @values = $sth->fetchrow_array()) { push @names, $values[0]}
	$sth->finish;	
	return @names;
}

sub get_host_dep_parents() {
	my $sqlstmt = "select host_id, parent_id from host_dependencies";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	my @dep_hosts = ();
	while(my @values = $sth->fetchrow_array()) { 
		my %d = fetch_one('','hosts','host_id', $values[0]);
		my %p = fetch_one('','hosts','host_id', $values[1]);
		push @dep_hosts, "$d{'name'}::--::$p{'name'}";
	}
	$sth->finish;	
	return @dep_hosts;
}

sub get_host_dependencies() {
	my $sqlstmt = "select * from host_dependencies";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	my %host_dependencies = ();
	while(my @values = $sth->fetchrow_array()) { 
		my %data = parse_xml('',$values[2]);
		foreach my $prop (keys %data) { $host_dependencies{$values[0]}{$values[1]}{$prop} = $data{$prop} }
	}
	$sth->finish;	
	return %host_dependencies;
}

sub get_children() {
	my $pid = $_[1];
	my $sqlstmt = "select hosts.host_id, hosts.name from hosts left join host_parent on hosts.host_id = host_parent.host_id where parent_id = '$pid'"; 
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	my @names = ();
	while(my @values = $sth->fetchrow_array()) { push @names, $values[1]}
	$sth->finish;	
	return @names;
}

sub get_hosts_unassigned() {
	my $sqlstmt = "select name from hosts where host_id not in (select host_id from hostgroup_host)";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	my @names = ();
	while(my @values = $sth->fetchrow_array()) { push @names, $values[0]}
	$sth->finish;	
	return @names;
}

sub get_host_hostgroup(@) {
	my $name = $_[1];
	my $sqlstmt = "select name from hosts where host_id  in (select hostgroup_host.host_id from hostgroup_host ".
		"left join hostgroups on hostgroup_host.hostgroup_id = hostgroups.hostgroup_id where hostgroups.name = '$name')";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	my @names = ();
	while(my @values = $sth->fetchrow_array()) { push @names, $values[0]}
	$sth->finish;	
	return @names;
}

sub get_hostgroup_host(@) {
	my $name = $_[1];
	my $sqlstmt = "select name from hostgroups where hostgroup_id  in (select hostgroup_host.hostgroup_id from hostgroup_host ".
		"left join hosts on hostgroup_host.host_id = hosts.host_id where hosts.name = '$name')";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	my @names = ();
	while(my @values = $sth->fetchrow_array()) { push @names, $values[0]}
	$sth->finish;	
	return @names;
}

sub get_hostgroups_hosts() {
	my $gid = $_[1];
	my %hostgroups = ();
	my $sqlstmt = "select hostgroup_id, name from hostgroups where hostgroup_id in (select hostgroup_id from monarch_group_hostgroup where group_id = '$gid')";
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		$hostgroups{$values[1]} = $values[0];
	}
	$sth->finish;
	my %members = ();
	my %nonmembers = ();
	$sqlstmt = "select * from hostgroups";
	$sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		my @hostgroups_hosts = ();
		$sqlstmt = "select name from hosts where host_id in (select host_id from hostgroup_host where hostgroup_id = '$values[0]') order by name";
		my $sth2 = $dbh->prepare($sqlstmt);
		$sth2->execute;
		while(my @vals = $sth2->fetchrow_array()) { push @hostgroups_hosts, $vals[0] }
		$sth2->finish;	
		if ($hostgroups{$values[1]}) { 
			@{$members{$values[1]}} = ();
			@{$members{$values[1]}} = @hostgroups_hosts;
		} else {
			@{$nonmembers{$values[1]}} = ();
			@{$nonmembers{$values[1]}} = @hostgroups_hosts;
		}
	}
	$sth->finish;
	return \%nonmembers, \%members;
}

sub get_names(@) {
	my $id = $_[1];
	my $table = $_[2];
	my $members = $_[3];
	my @names = ();
	foreach my $mem (@{$members}) {
		my %m = fetch_one('',$table,$id,$mem);
		push @names, $m{'name'};
	}
	return @names;
}

sub get_ids(@) {
	my $id = $_[1];
	my $table = $_[2];
	my $members = $_[3];
	my @ids;
	foreach my $mem (@{$members}) {
		my %m = fetch_one('',$table,'name',$mem);
		push @ids, $m{$id};
	}
	return @ids;
}

sub get_tree_detail(@) {
	my $name = $_[1];
	my %ranks = ();
	my %templates = ();
	my %t = fetch_one('','escalation_trees','name',$name);
	my $sqlstmt = "select * from escalation_templates where template_id in ".
		"(select escalation_tree_template.template_id from escalation_tree_template left join escalation_trees on ".
		"escalation_tree_template.tree_id = escalation_trees.tree_id where escalation_trees.name = '$name')";

	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while (my @values = $sth->fetchrow_array()) {
		$templates{$values[1]}{'name'} = $values[1];
		$templates{$values[1]}{'id'} = $values[0];
		my %data = parse_xml('',$values[3]);
		foreach my $k (keys %data) { 
			if ($k eq 'first_notification') { 
				$ranks{$data{$k}} = $values[1];
			}
			#$data{$k} =~ s/\*/star/g;
			$templates{$values[1]}{$k} = $data{$k};
		}
	}
	$sth->finish;
	foreach my $template (keys %templates) {
		$sqlstmt = "select name from contactgroups where contactgroup_id in ".
			"(select contactgroup_id from tree_template_contactgroup where tree_id = '$t{'tree_id'}' and template_id = '$templates{$template}{'id'}')";
		$sth = $dbh->prepare($sqlstmt);
		$sth->execute;
		while (my @values = $sth->fetchrow_array()) {
			$templates{$template}{'contactgroups'} .= "$values[0],";
		}
		$sth->finish;
		chop $templates{$template}{'contactgroups'};
	}
	return \%ranks, \%templates;
}

sub get_dependencies(@) {
	my $sid = $_[1];
	my $sqlstmt = "select * from service_dependency where service_id = '$sid'";
	my %dependencies = ();
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while (my @values = $sth->fetchrow_array()) {
		my %t = fetch_one('','service_dependency_templates','id',$values[4]);
		my %h = fetch_one('','hosts','host_id',$values[3]);
		my @vals = ($t{'name'},$h{'name'});
		$dependencies{$values[0]} = [ @vals ]; 
	}	
	$sth->finish;
	return %dependencies;
}

sub get_servicename_dependencies(@) {
	my $sid = $_[1];
	my $sqlstmt = "select * from servicename_dependency where servicename_id = '$sid'";
	my %dependencies = ();
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while (my @values = $sth->fetchrow_array()) {
		my %t = fetch_one('','service_dependency_templates','id',$values[3]);
		my %h = fetch_one('','hosts','host_id',$values[2]);
		unless ($values[2]) { $h{'name'} = 'same host' }
		my @vals = ($t{'name'},$h{'name'});
		$dependencies{$values[0]} = [ @vals ]; 
	}
	$sth->finish;
	return %dependencies;
}

sub check_dependency() {
	my $sid = $_[1];
	my $parent = $_[2];
	my $dependency = $_[3];
	my $result = 0;
	my $sqlstmt = undef;
	if ($parent eq 'same host') {
		$sqlstmt = "select id from servicename_dependency where servicename_id = '$sid' and template = '$dependency' and depend_on_host_id is null";
	} else {
		$sqlstmt = "select id from servicename_dependency where servicename_id = '$sid' and template = '$dependency' and depend_on_host_id = '$parent'";
	}
	$result = $dbh->selectrow_array($sqlstmt);
	return $result;
}

sub insert_dependency() {
	my $sid = $_[1];
	my $parent = $_[2];
	my $dependency = $_[3];
	my $sqlstmt = undef;
	if ($parent eq 'same host') {
		$sqlstmt = "insert into servicename_dependency values(NULL,'$sid',null,'$dependency')";
	} else {
		$sqlstmt = "insert into servicename_dependency values(NULL,'$sid','$parent','$dependency')";
	}
	my $sth = undef;
	eval{$sth = $dbh->prepare ($sqlstmt);
	$sth->execute()};
	if ($@) {
		$sth->finish;
		return "Error: $sqlstmt $@";
	} else {
		$sth->finish;
		return 1;
	}
}

sub update_dependencies() {
	my $snid = $_[1];
	my @errors = ();
	my %service_host = ();
	my $sqlstmt = "select service_id, host_id from services where servicename_id = '$snid'"; 
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while (my @values = $sth->fetchrow_array()) {
		$service_host{$values[0]} = $values[1];
	}
	$sth->finish;
	my %dependencies = ();
	$sqlstmt = "select id, template, depend_on_host_id from servicename_dependency where servicename_id = '$snid'"; 
	$sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while (my @values = $sth->fetchrow_array()) {
		unless ($values[2]) { $values[2] = 'same_host' }
		$dependencies{$values[1]}{$values[2]} = 1;
	}
	$sth->finish;
	foreach my $sid (keys %service_host) {
		my $result = delete_all('','service_dependency','service_id',$sid);
		if ($result =~ /^Error/) { push @errors, $result }
		foreach my $temp (keys %dependencies) {
			foreach my $depend_on_host (keys %{$dependencies{$temp}}) {
				if ($depend_on_host eq 'same_host') { 
					# check to see that depend on service exists on host
					my %t = fetch_one('','service_dependency_templates','id',$temp);
					my %where = ('host_id' => $service_host{$sid},'servicename_id' => $t{'servicename_id'});
					my %s = fetch_one_where('','services',\%where);
					if ($s{'service_id'}) {
						my @values = ('',$sid,$service_host{$sid},$service_host{$sid},$temp,'');
						my $result = insert_obj('','service_dependency',\@values);
						if ($result =~ /^Error/) { push @errors, $result }
					}
				} else {
					my @values = ('',$sid,$service_host{$sid},$depend_on_host,$temp,'');
					my $result = insert_obj('','service_dependency',\@values);
					if ($result =~ /^Error/) { push @errors, $result }
				}
			}
		}
	}
	return @errors;
}

sub add_dependencies() {
	my $host_id = $_[1];
	my @errors = ();
	my %services = ();
	my %snids = ();
	my $sqlstmt = "select service_id, servicename_id from services where host_id = '$host_id'";
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while (my @values = $sth->fetchrow_array()) {
		$services{$values[0]} = $values[1];
		$snids{$values[1]} = 1;
	}
	$sth->finish;
	foreach my $service (keys %services) {
		my %dependencies = ();
		$sqlstmt = "select id, template, depend_on_host_id from servicename_dependency where servicename_id = '$services{$service}'"; 
		my $sth1 = $dbh->prepare($sqlstmt);
		$sth1->execute;
		while (my @values = $sth1->fetchrow_array()) {
			unless ($values[2]) { $values[2] = 'same_host' }
			$dependencies{$values[1]}{$values[2]} = 1;
		}
		$sth1->finish;
		foreach my $temp (keys %dependencies) {
			foreach my $depend_on_host (keys %{$dependencies{$temp}}) {
				if ($depend_on_host eq 'same_host') { 
					# make sure the depend on service has been added to the host
					if ($snids{$services{$service}}) {
						my @values = ('',$service,$host_id,$host_id,$temp,'');
						my $result = insert_obj('','service_dependency',\@values);
						if ($result =~ /^Error/) { push @errors, $result }
					}
				} else {
					my @values = ('',$service,$host_id,$depend_on_host,$temp,'');
					my $result = insert_obj('','service_dependency',\@values);
					if ($result =~ /^Error/) { push @errors, $result }
				}
			}
		}
	}
	return @errors;
}

sub get_dep_on_hosts(@) {
	my $snid = $_[1];
	my $host_id = $_[2];
	my $sqlstmt = "select name from hosts where host_id in (select host_id from services where servicename_id = '$snid')";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	my @hosts = ();
	my $host = 0;
	while(my @values = $sth->fetchrow_array()) {
		if ($host_id eq $values[0]) {
			$host = 1;	
		} else {
			push @hosts, $values[0];
		}
	}
	$sth->finish;
	@hosts = sort { $a <=> $b } @hosts;
	return $host,\@hosts;
}

sub get_host_services(@) {
	my $host_id = $_[1];
	my $sqlstmt = "select service_names.name from service_names where servicename_id in (select servicename_id from services where host_id = '$host_id')";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	my @services = ();
	while(my @values = $sth->fetchrow_array()) {
		push @services, $values[0];
	}
	$sth->finish;
	@services = sort { $a <=> $b } @services;
	return @services;
}

sub get_service_hosts(@) {
	my $id = $_[1];
	my $sqlstmt = "select hosts.name from hosts where host_id in (select host_id from services where servicename_id = '$id')";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	my @hosts = ();
	while(my @values = $sth->fetchrow_array()) {
		push @hosts, $values[0];
	}
	$sth->finish;
	@hosts = sort { $a <=> $b } @hosts;
	return @hosts;
}

sub get_upload(@) {
	my $upload_dir = $_[1];
	my $type = $_[2];
	my @nmaps = ();
	my @imports = ();
	my @errors = ();
	opendir(DIR, $upload_dir) || push @errors, "error: cannot open $upload_dir to read $!";
	my @files = readdir DIR;
	@files = grep{-T "$upload_dir/$_"} @files;
	foreach my $file (@files) {
		open(FILE, "< $upload_dir/$file") || push @errors, "error: cannot open $upload_dir/$file to read $!";
		$/ = undef;
		my $slurp = <FILE>;
		if ($slurp =~ /nmaprun scanner/) {
			push @nmaps, $file;
		} else {
			push @imports, $file;
		}
		close(FILE);		
	}
	close(DIR);
	if ($type eq 'nmap') {
		return \@errors,\@nmaps;
	} else {
		return \@errors,\@imports;
	}	
}

sub get_num_records(@) {
	my $table = $_[1];
	my $sqlstmt = "select count(*) from service_names";
	my $rows = $dbh->selectrow_array($sqlstmt);
	return $rows;
}

sub get_host_service(@) {
	my $servicename_id = $_[1];
	my %host_service = ();
	my $sqlstmt = "select host_id, service_id from services where servicename_id = '$servicename_id'";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		$host_service{$values[0]} = $values[1];
	}
	$sth->finish;
	return %host_service;
}

sub get_hostname_servicename(@) {
	my $table = $_[1];
	my $column = $_[2];
	my $value = $_[3];
	my @names = ();
	my $sqlstmt = undef;
	if ($table eq 'services') {
		$sqlstmt = "select host_id, servicename_id from services where $column = '$value'";
	} elsif ($table eq 'service_dependency') {
		$sqlstmt = "select services.host_id, services.servicename_id from services left join service_dependency on ".
			"services.service_id = service_dependency.service_id where $column = '$value'";
	}
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		my %h = fetch_one('','hosts','host_id',$values[0]);
		my %s = fetch_one('','service_names','servicename_id',$values[1]);
		if ($h{'name'} && $s{'name'}) {
			my %rec = ($h{'name'} => $s{'name'});
			push @names, \%rec;
		}
	}
	$sth->finish;		
	return @names;
}

sub get_contactgroup_object(@) {
	my $value = $_[1];
	my $obj_id = $_[2];
	my %obj_id = %{$obj_id};
	my $sqlstmt = "select type, object from contactgroup_assign where contactgroup_id = '$value'";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	my @names = ();
	while(my @values = $sth->fetchrow_array()) {
		my %obj = fetch_one('',$values[0],$obj_id{$values[0]},$values[1]);
		my %rec = ($values[0] => $obj{'name'});
		push @names, \%rec;		
	}
	$sth->finish;		
	return @names;
}

sub get_contact_contactgroup(@) {
	my $value = $_[1];
	my $sqlstmt = "select contacts.name from contacts left join contactgroup_contact on ".
		"contactgroup_contact.contact_id = contacts.contact_id where contactgroup_id = '$value'";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	my @names = ();
	while(my @values = $sth->fetchrow_array()) {
		push @names, $values[0];		
	}
	$sth->finish;		
	return @names;
}

sub get_contactgroup_contact(@) {
	my $value = $_[1];
	my $sqlstmt = "select contactgroups.name from contactgroups left join contactgroup_contact on ".
		"contactgroup_contact.contactgroup_id = contactgroups.contactgroup_id where contact_id = '$value'";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	my @names = ();
	while(my @values = $sth->fetchrow_array()) {
		push @names, $values[0];		
	}
	$sth->finish;		
	return @names;
}

sub get_command_contact_template(@) {
	my $id = $_[1];
	my $type = $_[2];
	my $sqlstmt = "select commands.name from commands left join contact_command on commands.command_id = contact_command.command_id ".
		"where contact_command.contacttemplate_id = '$id' and contact_command.type = '$type'";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	my @names = ();
	while(my @values = $sth->fetchrow_array()) {
		push @names, $values[0];		
	}
	$sth->finish;		
	return @names;
}

sub get_command_contact(@) {
	my $id = $_[1];
	my $type = $_[2];
	my $sqlstmt = "select commands.name from commands left join contact_command_overrides on commands.command_id = contact_command_overrides.command_id ".
		"where contact_command_overrides.contact_id = '$id' and contact_command_overrides.type = '$type'";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	my @names = ();
	while(my @values = $sth->fetchrow_array()) {
		push @names, $values[0];		
	}
	$sth->finish;		
	return @names;
}

sub get_tree_contactgroup(@) {
	my $value = $_[1];
	my $sqlstmt = "select name from escalation_trees left join tree_template_contactgroup on ".
		"tree_template_contactgroup.tree_id = escalation_trees.tree_id where contactgroup_id = '$value'";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	my @names = ();
	while(my @values = $sth->fetchrow_array()) {
		push @names, $values[0];		
	}
	$sth->finish;		
	return @names;
}

sub fetch_scripts(@) {
	my $type = $_[1];
	my %scripts = ();
	my $sqlstmt = "select name, script from extended_$type\_info_templates where script != ''"; 
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		$scripts{$values[0]} = $values[1];		
	}
	$sth->finish;		
	return %scripts;
}

sub delete_file(@) {
	my $dir = $_[1];
	my $file = $_[2];
	my $result = 1;
	unlink("$dir/$file") or $result = "Error: Unable to remove $dir/$file $!";
	return $result;	
}

sub fetch_service_extinfo(@) {
	my $extinfo_id = $_[1];
	my $sqlstmt = "select service_id, servicename_id, host_id from services where serviceextinfo_id = '$extinfo_id'";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	my %service_host = ();
	while(my @values = $sth->fetchrow_array()) {
		my %sn = fetch_one('','service_names','servicename_id',$values[1]);
		my %h = fetch_one('','hosts','host_id',$values[2]);
		my @vals = ($h{'name'},$sn{'name'});
		$service_host{$values[0]} = [ @vals ];
	}
	$sth->finish;		
	return %service_host;
}

sub get_template_properties(@) {
	my $id = $_[1];
	my %properties = fetch_one('','service_templates','servicetemplate_id',$id);
	my $sqlstmt = "select contactgroups.name from contactgroups left join contactgroup_group on "
		. "contactgroups.contactgroup_id = contactgroup_service_template.contactgroup_id where servicetemplate_id = '$id'";
	my @contactgroups = ();
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		push @contactgroups, "$values[0],";
	}
	$sth->finish;		
	if ($properties{'parent_id'}) {
		my $pid = $properties{'parent_id'};
		until (!$pid) {
			my %parent = fetch_one('','service_templates','servicetemplate_id',$pid);
			if ($parent{'parent_id'}) { 
				$pid = $parent{'parent_id'};
			} else {
				$pid = 0;
			}
			foreach my $prop (keys %parent) {
				if (!$properties{$prop}) {
					$properties{$prop} = $parent{$prop};
				}
			}
			$sqlstmt = "select contactgroups.name from contactgroups left join contactgroup_group on ".
				"contactgroups.contactgroup_id = contactgroup_service_template.contactgroup_id where servicetemplate_id = '$id'";
			my $sth1 = $dbh->prepare ($sqlstmt);
			$sth1->execute;
			while(my @values = $sth1->fetchrow_array()) {
				push @contactgroups, "$values[0],";
			}
			$sth1->finish;

		}
	}
	@contactgroups = sort @contactgroups;
	$properties{'contactgroup'} = [ @contactgroups ]; 
	return %properties;
}

sub get_servicegroup(@) {
	my $id = $_[1];
	my %host_service = ();
	my $sqlstmt = "select distinct host_id from servicegroup_service where servicegroup_id = '$id'"; 
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		my %host = fetch_one('','hosts','host_id',$values[0]);
		my @services = ();
		$sqlstmt = "select service_names.name from service_names left join services on service_names.servicename_id = services.servicename_id ".
"where service_id in (select service_id from servicegroup_service where host_id = '$host{'host_id'}' and servicegroup_id = '$id')";
		my $sth2 = $dbh->prepare($sqlstmt);
		$sth2->execute;
		while(my @vals = $sth2->fetchrow_array()) {
			push @services, $vals[0];
		}
		$sth2->finish;		
		@services = sort @services;
		$host_service{$host{'name'}} = [ @services ];
	}
	$sth->finish;		
	return %host_service;
}

sub get_resources() {
	my $sqlstmt = "select name, value from setup where type = 'resource' and name like 'User%'";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	my %resources = ();
	while(my @values = $sth->fetchrow_array()) {
		$resources{$values[0]} = $values[1];
	}
	$sth->finish;
	return %resources;
}

sub get_resources_doc() {
	my $sqlstmt = "select name, value from setup where type = 'resource' and name like 'resource_label%'";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	my %resource_doc = ();
	while(my @values = $sth->fetchrow_array()) {
		$resource_doc{$values[0]} = $values[1];
	}
	$sth->finish;
	return %resource_doc;
}

sub test_command(@) {
	my $name = $_[1];
	my $command = $_[2];
	my $host = $_[3];
	my $arg_string = $_[4];
	my $monarch_home = $_[5];
	my $service_desc = $_[6];
	$arg_string =~ s/$name!//;
	unless ($service_desc) { $service_desc = 'service_desc' }
	my %resources = get_resources();
	my %host = StorProc->fetch_one('hosts','name',$host);
	unless ($host{'alias'}) { $host{'alias'} = $host }
	unless ($host{'address'}) { $host{'address'} = $host }
	foreach my $res (keys %resources) {
		if ($command =~ /$res/i) { $command =~ s/\$$res\$/$resources{$res}/ig } 
	}
	$command =~ s/\$HOSTNAME\$/$host/g;
	$command =~ s/\$HOSTALIAS\$/$host{'alias'}/g;
	$command =~ s/\$HOSTADDRESS\$/$host{'address'}/g;
	$command =~ s/\$HOSTSTATE\$/UP/g;
	$command =~ s/\$HOSTSTATEID\$/0/g;
	$command =~ s/\$SERVICEDESC\$/$service_desc/g;
	$command =~ s/\$SERVICESTATE\$/UP/g;
	$command =~ s/\$SERVICESTATEID\$/0/g;	
	$command =~ s/\$SERVICECHECKCOMMAND\$/$name/g;	
	my $dt = datetime();
	$command =~ s/\$LONGDATETIME\$/$dt/g;
	$command =~ s/\$SHORTDATETIME\$/$dt/g;
	$command =~ s/\$DATE\$/$dt/g;
	$dt =~ s/\d+-\d+-\d+\s+//;
	$command =~ s/\$TIME\$/$dt/g;
	my $now = time;
	$command =~ s/\$TIMET\$/$now/g;
	
	my @args = split(/!/, $arg_string);
	my $cnt = 1;
	foreach my $a (@args) {
		$command =~ s/\$ARG$cnt\$/$a/g;
		$cnt++;
	}
	$command =~ s/\$\S+\$/-/g;
	my $results = "$command<br/>";
	if (-x "$monarch_home/bin/monarch_as_nagios") {
		$results .= monarch_as_nagios('',$command,$monarch_home);
	} else {
		$results .= qx($command 2>&1) || ($results = "Error(s) executing $command $!");
	}
	return $results;
}

sub monarch_as_nagios(@) {
	my $command = $_[1];
	my $monarch_home = $_[2];
	unless ($monarch_home) { $monarch_home = '/usr/local/groundwork/monarch' }
	my $error = undef;
	my $results = undef;
	my $temp = "$monarch_home/bin/temp".rand();
	open (FILE, ">$temp") || ($error = "Cannot open $temp to write $!");
	print FILE "$command";
	close FILE;
	if ($error) { $results = $error	}	
	unless ($error) {
		my $run_as = "$monarch_home/bin/monarch_as_nagios $temp $monarch_home/bin/monarch_as_nagios.pl";
		$results = qx($monarch_home/bin/monarch_as_nagios $temp $monarch_home/bin/monarch_as_nagios.pl 2>&1) || ($results = "Error(s) executing $run_as $!");
	}
	unlink ($temp);
	return $results;
}

sub host_profile_apply(@) {
	my $profile = $_[1];
	my $hosts = $_[2];
	my @hosts = @{$hosts};
	my @errors = ();
	my %update = ();
	my $sqlstmt = "select * from profiles_host where hostprofile_id = '$profile'";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	my @profile_values = $sth->fetchrow_array();
	$update{'hostextinfo_id'} = $profile_values[4];
	$sth->finish;
	$sqlstmt = "select * from hostprofile_overrides where hostprofile_id = '$profile'";
	$sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	my @override_values = $sth->fetchrow_array();
	$sth->finish;
	foreach my $hid (@hosts) {
		my $result = delete_all('','host_overrides','host_id',$hid);
		my @values = ($hid,$override_values[1],$override_values[2],$override_values[3],$override_values[4],$override_values[5]);
		$result = insert_obj('','host_overrides',\@values);
		if ($result =~ /Error/) { push @errors, $result }
		$result = update_obj('','hosts','host_id',$hid,\%update);
		if ($result =~ /Error/) { push @errors, $result }
	}
	return @errors;
}

sub service_profile_apply(@) {
	my $profiles = $_[1];
	my $service = $_[2];
	my $hosts = $_[3];
	my @profiles = @{$profiles};
	my @hosts = @{$hosts};
	my @errors = ();
	my $cnt = 0;
	if (@hosts) {
		my %profile_services = ();
		my %servicename_overrides = ();
		my %dependencies = ();
		my %contactgroups = ();
		my $sqlstmt = '';
########### Add here - P. Loh
		my %externals = ();
		my %externals_display = ();
####################
		foreach my $profile (@profiles) {
			$sqlstmt = "select * from service_names where servicename_id in (select servicename_id from serviceprofile where serviceprofile_id = '$profile')";
			my $sth = $dbh->prepare ($sqlstmt);
			$sth->execute;
			while(my @values = $sth->fetchrow_array()) { 
				$profile_services{$values[0]} = [ @values ];
			}
			$sth->finish;
			$sqlstmt = "select * from servicename_overrides";
			$sth = $dbh->prepare ($sqlstmt);
			$sth->execute;
			while(my @values = $sth->fetchrow_array()) { $servicename_overrides{$values[0]} = [ @values ] }
			$sth->finish;
			foreach my $snid (keys %profile_services) {
				$sqlstmt = "select * from servicename_dependency where servicename_id = '$snid'";
				$sth = $dbh->prepare ($sqlstmt);
				$sth->execute;
				while(my @values = $sth->fetchrow_array()) { 
					$dependencies{$snid}{$values[0]} = [ @values ];	
				}
				$sth->finish;
#				$sqlstmt = "select contactgroup_id from contactgroup_assign where type = 'service_names' and object = '$snid'";
				$sqlstmt = "select contactgroup_id from contactgroup_service_name where servicename_id = '$snid'";
				$sth = $dbh->prepare ($sqlstmt);
				$sth->execute;
				while(my @values = $sth->fetchrow_array()) { 
					if ($values[0]) { $contactgroups{$snid} = [ @values ] }	
				}
				$sth->finish;
##############################################
#		Add Externals Code Here - P. Loh - 5-15-2006
				$sqlstmt = "select e.external_id,e.display from external_service_names as esn, externals as e where esn.servicename_id = '$snid' and e.external_id=esn.external_id";
				$sth = $dbh->prepare ($sqlstmt);
				$sth->execute;
				while(my @values = $sth->fetchrow_array()) { 
					if ($values[0]) { 
						$externals{$snid} = $values[0];					# Set externals id
						$externals_display{$values[0]} = $values[1];		# Set externals data
					}	
				}
				$sth->finish;
###############################################
			}
		}
		my %host = ();
		foreach my $hid (@hosts) {
			unless ($host{$hid}) {
				$host{$hid} = 1;
				my %host_service = ();
				if ($service eq 'replace') {
					eval { $dbh->do("delete from services where host_id = $hid") };
					push @errors, "Error: $@" if $@;
				} else {
					$sqlstmt = "select servicename_id, service_id from services where host_id = '$hid'";
					my $sth = $dbh->prepare ($sqlstmt);
					$sth->execute;
					while(my @values = $sth->fetchrow_array()) { $host_service{$values[0]} = $values[1] }
					$sth->finish;
				}

				foreach my $snid (keys %profile_services) {
					unless ($host_service{$snid}) {
						$cnt++;
						my @values = ('',$hid,$profile_services{$snid}[0],$profile_services{$snid}[3],$profile_services{$snid}[7],$profile_services{$snid}[6],'1',
							$profile_services{$snid}[4],$profile_services{$snid}[5],'');
						my $sid = insert_obj_id('','services',\@values,'service_id');
						if ($sid =~ /Error/) { 
							push @errors, $sid;
						} else {
							$host_service{$snid} = $sid;
							if ($servicename_overrides{$snid}) {
								my @values = ($sid,$servicename_overrides{$snid}[1],$servicename_overrides{$snid}[2],$servicename_overrides{$snid}[3],$servicename_overrides{$snid}[4]);
								my $result = insert_obj('','service_overrides',\@values);
								if ($result =~ /Error/) { push @errors, $result }
							}
							if ($contactgroups{$snid}) {
								foreach my $cgid (@{$contactgroups{$snid}}) {
#									my @values = ($cgid,'services',$sid);
#									my $result = insert_obj('','contactgroup_assign',\@values);
									my @values = ($cgid,$sid);
									my $result = insert_obj('','contactgroup_service',\@values);
									if ($result =~ /Error/) { push @errors, $result }
								}
							}
###################################### - Add here - P. Loh
							if ($externals{$snid}) {
								# insert external_id, new host id, new service id, data from external_service table
								my @values = ($externals{$snid},$hid,$sid,$externals_display{$externals{$snid}});
								my $result = insert_obj('','external_service',\@values);
								if ($result =~ /Error/) { push @errors, $result }
							}
######################################
						}
					}
				}
				my %dep_hash = ();
				$sqlstmt = "select * from service_dependency";
				my $sth = $dbh->prepare($sqlstmt);
				$sth->execute;
				while(my @values = $sth->fetchrow_array()) { $dep_hash{$values[1]}{$values[2]}{$values[3]}{$values[4]} = 1 }
				$sth->finish;
				foreach my $snid (keys %profile_services) {
					if ($dependencies{$snid}) {
						foreach my $did (keys %{$dependencies{$snid}}) {
							my $depend_on_host = $dependencies{$snid}{$did}[2];
							unless ($depend_on_host) { $depend_on_host = $hid }
							unless ($dep_hash{$host_service{$snid}}{$hid}{$depend_on_host}{$dependencies{$snid}{$did}[3]}) { 
								my @values = ('',$host_service{$snid},$hid,$depend_on_host,$dependencies{$snid}{$did}[3],'');
								my $result = insert_obj('','service_dependency',\@values);
								if ($result =~ /Error/) { push @errors, $result }
							} 
						}
					}
				}
			}
		}	
	}
	return $cnt, \@errors;
}

sub apply_service_overrides() {
	my $sid = $_[1];
	my $snid = $_[2];
	my @errors = ();
#	my $sqlstmt = "select contactgroup_id from contactgroup_assign where type = 'service_names' and object = '$snid'";
	my $sqlstmt = "select contactgroup_id from contactgroup_service_name where servicename_id = '$snid'";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {  
#		my @vals = ($values[0],'services',$sid);
#		my $result = insert_obj('','contactgroup_assign',\@vals);
		my @vals = ($values[0],$sid);
		my $result = insert_obj('','contactgroup_service',\@vals);
		if ($result =~ /Error/) { push @errors, $result }
	}
	$sth->finish;
	my @values = ($sid);
	$sqlstmt = "select check_period, notification_period, event_handler, data from servicename_overrides where servicename_id = '$snid'";
	my @vals = $dbh->selectrow_array($sqlstmt);
	if (@vals) {
		push (@values,@vals);
		my $result = insert_obj('','service_overrides',\@values);
		if ($result =~ /Error/) { push @errors, $result }
	}
	return @errors;
}


sub service_merge() {
	my $service = $_[1];
	my %service = %{$service};
	my %overrides = fetch_one('','servicename_overrides','servicename_id',$service{'servicename_id'});
	my %where = ('servicename_id' => $service{'servicename_id'});
	my @services = fetch_list_where('','services','service_id',\%where);
	my @errors = ();
	my $cnt = 0;
	my %so = ();
	my $sqlstmt = "select service_id from service_overrides";
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while(my @vals = $sth->fetchrow_array()) { $so{$vals[0]} = 1 }
	$sth->finish;	
	foreach my $sid (@services) {
		$cnt++;
		my %over = fetch_one('','service_overrides','service_id',$sid);
		my %values = ();
		my $data = "<?xml version=\"1.0\" ?>\n<data>";
		foreach my $name (keys %over) {
			$overrides{$name} = $over{$name};
		}
		foreach my $name (keys %overrides) {
			if ($name =~ /^check_period$|^notification_period$|^event_handler$/) {
				$values{$name} = $overrides{$name};
			} else {
				$data .= " <prop name=\"$name\"><![CDATA[$overrides{$name}]]>\n";				
				$data .= " </prop>\n";
			}
		}
		$data .= "\n</data>\n";
		$values{'data'} = $data;
		if ($so{$sid}) {
			my $result = update_obj('','service_overrides','service_id',$sid,\%values);
			if ($result =~ /Error/) { push @errors, $result }
		} else {
			my @values = ($sid,$values{'check_period'},$values{'notification_period'},$values{'event_handler'},$values{'data'});
			my $result = insert_obj('','service_overrides',\@values);
			if ($result =~ /Error/) { push @errors, $result }
		}
	}
	unless (@errors) { $errors[0] = "Changes applied to $cnt services." }
	return @errors;
}

sub service_replace() {
	my %service = %{$_[1]};
	my %overrides = fetch_one('','servicename_overrides','servicename_id',$service{'servicename_id'});
	my @errors = ();
	my $cnt = 0;
	my %so = ();
	my $sqlstmt = "select service_id from service_overrides";
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while(my @vals = $sth->fetchrow_array()) { $so{$vals[0]} = 1 }
	$sth->finish;	
	my %where = ('servicename_id' => $service{'servicename_id'});
	my @services = fetch_list_where('','services','service_id',\%where);
	foreach my $sid (@services) {
		$cnt++;
		my %values = ();
		my $data = "<?xml version=\"1.0\" ?>\n<data>";
		foreach my $name (keys %overrides) {
			if ($name =~ /^check_period$|^notification_period$|^event_handler$/) {
				$values{$name} = $overrides{$name};
			} else {
				$data .= " <prop name=\"$name\"><![CDATA[$overrides{$name}]]>\n";				
				$data .= " </prop>\n";
			}
		}
		$data .= "\n</data>\n";
		$values{'data'} = $data;
		if ($so{$sid}) {
			my $result = update_obj('','service_overrides','service_id',$sid,\%values);
			if ($result =~ /Error/) { push @errors, $result }
		} else {
			my @values = ($sid,$values{'check_period'},$values{'notification_period'},$values{'event_handler'},$values{'data'});
			my $result = insert_obj('','service_overrides',\@values);
			if ($result =~ /Error/) { push @errors, $result }
		}
	}
	unless (@errors) { $errors[0] = "Changes applied to $cnt services." }
	return @errors;
}

sub clone_service(@) {
	my $name = $_[1];
	my $clone_service = $_[2];
	my $assign_profiles = $_[3];
	my @errors = ();
	my @values = ('',$name);
	my $sqlstmt = "select description, template, check_command, command_line, escalation, extinfo, data, servicename_id from service_names where name = '$clone_service'";
	my @vals = $dbh->selectrow_array($sqlstmt);
	my $clone_service_id = pop @vals;
	push (@values,@vals);
	my $id = insert_obj_id('','service_names',\@values,'servicename_id');
	if ($id =~ /Error/) { push @errors, $id }
	unless (@errors) {
		@values = ($id);
		$sqlstmt = "select check_period, notification_period, event_handler, data from servicename_overrides where servicename_id = '$clone_service_id'";
# push @errors, $sqlstmt;
		@vals = $dbh->selectrow_array($sqlstmt);
		if (@vals) {
			push (@values,@vals);
			my $result = insert_obj('','servicename_overrides',\@values);
			if ($result =~ /Error/) { push @errors, $result }
		}
		unless (@errors) {
			$sqlstmt = "select depend_on_host_id, template from servicename_dependency where servicename_id = '$clone_service_id'";
			my $sth = $dbh->prepare($sqlstmt);
			$sth->execute;
			while(my @vals = $sth->fetchrow_array()) { 
				@values = ('',$id);
				push (@values,@vals);
				my $result = insert_obj('','servicename_dependency',\@values);
				if ($result =~ /Error/) { push @errors, $result }
			}
			$sth->finish;
			unless (@errors) {
#				my %where = ('type' => 'service_names', 'object' => $clone_service_id);
#				my @cgids = fetch_list_where('','contactgroup_assign','contactgroup_id',\%where); 
				my %where = ('servicename_id' => $clone_service_id);
				my @cgids = fetch_list_where('','contactgroup_service_name','contactgroup_id',\%where); 
				foreach my $cgid (@cgids) {
#					@values = ($cgid,'service_names',$id);
#					my $result = insert_obj('','contactgroup_assign',\@values);
					@values = ($cgid,$id);
					my $result = insert_obj('','contactgroup_service_name',\@values);
					if ($result =~ /Error/) { push @errors, $result }

				}
				if ($assign_profiles) {
					%where = ('servicename_id' => $clone_service_id);
					my @pids = fetch_list_where('','serviceprofile','serviceprofile_id',\%where); 
					foreach my $pid (@pids) {
						@values = ($id,$pid);
						my $result = insert_obj('','serviceprofile',\@values);
						if ($result =~ /Error/) { push @errors, $result }
					}
				}
			}
		}
	}
	return @errors;
}

sub clone_host(@) {
	my $host = $_[1];
	my $clone_name = $_[2];
	my $clone_alias = $_[3];
	my $clone_address = $_[4];
        my $user_acct = $_[5];
	my @errors = ();
	my %host = fetch_one('','hosts','name',$host);
	my %where = ('host_id' => $host{'host_id'});
	my @hostgroups = fetch_list_where('','hostgroup_host','hostgroup_id',\%where);
	my @parents = fetch_list_where('','host_parent','parent_id',\%where);
	my @service_profiles = fetch_list_where('','serviceprofile_host','serviceprofile_id',\%where);
	my @values = ('',$clone_name,$clone_alias,$clone_address,$host{'os'},$host{'hosttemplate_id'},$host{'hostextinfo_id'},$host{'hostprofile_id'},$host{'host_escalation_id'},$host{'service_escalation_id'},'1','');
	my $id = insert_obj_id('','hosts',\@values,'host_id');
	if ($id =~ /Error/) { push @errors, $id }
	my @host_over = ($id);
	my $sqlstmt = "select * from host_overrides where host_id = '$host{'host_id'}'";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	my $values = $sth->fetchrow_hashref();
	$sth->finish;
	Audit->auditlog("$user_acct","HOST","ADD","$clone_name");
	if ($values->{'check_period'} || $values->{'notification_period'} || $values->{'check_command'} || $values->{'event_handler'} || $values->{'data'}) {
		@values = ($id,$values->{'check_period'},$values->{'notification_period'},$values->{'check_command'},$values->{'event_handler'},$values->{'data'});
		my $result = insert_obj('','host_overrides',\@values);
		if ($result =~ /Error/) { push @errors, $result }
	}
	foreach my $hg (@hostgroups) {
		@values = ($hg,$id);
		my $result = insert_obj('','hostgroup_host',\@values);
		if ($result =~ /Error/) { push @errors, $result }
	}

	foreach my $p (@parents) {
		@values = ($id,$p);
		my $result = insert_obj('','host_parent',\@values);
		if ($result =~ /Error/) { push @errors, $result }	
	}
	foreach my $sp (@service_profiles) {
		@values = ($sp,$id);
		my $result = insert_obj('','serviceprofile_host',\@values);
		if ($result =~ /Error/) { push @errors, $result }	
	}
	$sqlstmt = "select * from services where host_id = '$host{'host_id'}'";
	$sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	while (my @values = $sth->fetchrow_array()) {
		my @vals = ('',$id,$values[2],$values[3],$values[4],$values[5],$values[6],$values[7],$values[8],$values[9]);
		my $sid = insert_obj_id('','services',\@vals,'service_id');
		if ($sid =~ /Error/) { push @errors, $sid }

		$sqlstmt = "select name, status, arguments from service_instance where service_id = '$values[0]'";

		my $sth2 = $dbh->prepare ($sqlstmt);
		$sth2->execute;
		while(my @vals = $sth2->fetchrow_array()) {
			@vals = ('',$sid,$vals[0],$vals[1],$vals[2]);
			my $result = insert_obj('','service_instance',\@vals);
			if ($result =~ /Error/) { push @errors, $result }
		}
		$sth2->finish;	
		$sqlstmt = "select * from service_overrides where service_id = '$values[0]'";
		$sth2 = $dbh->prepare ($sqlstmt);
		$sth2->execute;
		my $ovals = $sth2->fetchrow_hashref();
		if ($ovals->{'check_period'} || $ovals->{'notification_period'} || $ovals->{'event_handler'} || $ovals->{'data'}) {
			@vals = ($sid,$ovals->{'check_period'},$ovals->{'notification_period'},$ovals->{'event_handler'},$ovals->{'data'});
			my $result = insert_obj('','service_overrides',\@vals);
			if ($result =~ /Error/) { push @errors, $result }
		}
		$sth2->finish;	
		$sqlstmt = "select host_id, depend_on_host_id, template from service_dependency where service_id = '$values[0]'";
		$sth2 = $dbh->prepare ($sqlstmt);
		$sth2->execute;
		while(my @vals = $sth2->fetchrow_array()) {
			if ($vals[0] eq $vals[1]) { $vals[1] = $id }
			@vals = ('',$sid,$id,$vals[1],$vals[2],'');
			my $result = insert_obj('','service_dependency',\@vals);
			if ($result =~ /Error/) { push @errors, $result }
		}
		$sth2->finish;	
############################################################################
# CODE TO HANDLE SERVICE EXTERNALS. ADDED BY P. LOH ON 5-12-2006.  HOPE THIS WORKS

#		Trying to populate external_service table - external_id, host_id, service_id, data
#		Get external data for this service
		$sqlstmt = "select external_id,data from external_service where host_id = '$host{'host_id'}' and service_id = '$values[0]'";
		$sth2 = $dbh->prepare ($sqlstmt);
		$sth2->execute;
		while(my @vals = $sth2->fetchrow_array()) {
			# insert external_id, new host id, new service id, data from external_service table
			@vals = ($vals[0],$id,$sid,$vals[1]);
			my $result = insert_obj('','external_service',\@vals);
			if ($result =~ /Error/) { push @errors, $result }
		}
		$sth2->finish;	

############################################################################
        }
	$sth->finish;	
	if (@errors) {
		my %w = ('host_id' => $id);
		delete_one_where('','hosts',\%w);
	}
	return @errors;
}

sub copy_servicename(@) {
	my $copy_snid = $_[1];
	my $name = $_[2];
	my $sqlstmt = "select description, template, check_command, command_line, escalation, extinfo, data from service_names where servicename_id = '$copy_snid'";
	my @vals = $dbh->selectrow_array($sqlstmt);
	my @values = ('',$name);
	push (@values,@vals);
	my $servicename_id = insert_obj_id('','service_names',\@values,'servicename_id');
	@values = ($servicename_id);
	$sqlstmt = "select check_period, notification_period, event_handler, data from servicename_overrides where servicename_id = '$copy_snid'";
	@vals = $dbh->selectrow_array($sqlstmt);
	if (@vals) {
		push (@values,@vals);
		my $result = insert_obj('','servicename_overrides',\@values);
	}
	return $servicename_id;
}

sub get_possible_parents() {
	my $template_id = $_[1];
	my @possible_parents = ();
	my %templates = ();
	my $sqlstmt = "select servicetemplate_id, name from service_templates";
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) { $templates{$values[0]} = $values[1] }
	$sth->finish;
	delete $templates{$template_id};
	my $got_children = 0;
	my %children = ();
	$sqlstmt = "select servicetemplate_id from service_templates where parent_id = '$template_id'";
	$sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) { $children{$values[0]} = 1 }
	$sth->finish;	
	until ($got_children) {
		my %gchildren = ();
		$got_children = 1;
		foreach my $cid (keys %children) {
			delete $templates{$cid};
			$sqlstmt = "select servicetemplate_id from service_templates where parent_id = '$cid'";
			$sth = $dbh->prepare($sqlstmt);
			$sth->execute;
			while(my @values = $sth->fetchrow_array()) { $gchildren{$values[0]} = 1; $got_children = 0 }
			$sth->finish;
		}
		%children = %gchildren;
	}
	foreach my $t (keys %templates) { push @possible_parents, $templates{$t} }
	@possible_parents = sort @possible_parents;
	return @possible_parents;
}

sub get_service_profiles(@) {
	my $spid = $_[1];
	my %service_names = ();
	my $sqlstmt = "select servicename_id, name from service_names where servicename_id in (select servicename_id from serviceprofile where serviceprofile_id = '$spid')";
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) { $service_names{$values[1]} = $values[0] }
	$sth->finish;	
	return %service_names;
}

sub get_host_profile_service_profiles(@) {
	my $hpid = $_[1];
	my %service_profiles = ();
	my $sqlstmt = "select serviceprofile_id, name from profiles_service where serviceprofile_id in (select serviceprofile_id from profile_host_profile_service where hostprofile_id = '$hpid')";
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) { $service_profiles{$values[1]} = $values[0] }
	$sth->finish;	
	return %service_profiles;
}

sub get_service_profile_services(@) {
	my $profile_id = $_[1];
	my %services = ();
	my $sqlstmt = "select service_names.name, service_names.template, service_templates.name, commands.name, service_names.command_line, ".
		"extended_service_info_templates.name ".
		"from service_names left join commands on service_names.check_command = commands.command_id ".
		"left join service_templates on service_templates.servicetemplate_id = service_names.template ".
		"left join extended_service_info_templates on extended_service_info_templates.serviceextinfo_id = service_names.extinfo ".
		"where service_names.servicename_id in (select servicename_id from serviceprofile where serviceprofile_id = '$profile_id')";
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) { 
		if ($values[4]) {
			$values[3] = $values[4];
		}
		unless ($values[3]) {
			my $got_parent = 0;
			my $temp_id = $values[1];
			until ($values[3] || $got_parent) {
				my $sql = "select commands.name, service_templates.command_line, service_templates.parent_id ".
					"from service_templates left join commands on service_templates.check_command = commands.command_id ".
					"where service_templates.servicetemplate_id = '$temp_id'";
				my $sth2 = $dbh->prepare($sql);
				$sth2->execute;
				my @vals = $sth2->fetchrow_array();
				$sth2->finish;
				unless ($values[3]) {
					if ($vals[1]) {
						$values[3] = $vals[1];
					} else {
						$values[3] = $vals[0];
					}
					if ($vals[2]) {
						unless ($values[3]) {
							$temp_id = $vals[2];						
						}
					} else {
						$got_parent = 1;
					}
				}
			}
		} 
		$services{$values[0]}{'template'} = $values[2];
		$services{$values[0]}{'command'} = $values[3];
		$services{$values[0]}{'dependency'} = $values[5];
		$services{$values[0]}{'extinfo'} = $values[6];
	}
	$sth->finish;	
	return %services;
}

sub get_service_detail(@) {
	my $name = $_[1];
	my %service = ();
	my $sqlstmt = "select service_names.name, service_names.template, service_templates.name, commands.name, service_names.command_line, ".
		"extended_service_info_templates.name ".
		"from service_names left join commands on service_names.check_command = commands.command_id ".
		"left join service_templates on service_templates.servicetemplate_id = service_names.template ".
		"left join extended_service_info_templates on extended_service_info_templates.serviceextinfo_id = service_names.extinfo ".
		"where service_names.name = '$name'";
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	my @values = $sth->fetchrow_array();
	$sth->finish;	
	if ($values[4]) {
		$values[3] = $values[4];
	}
	unless ($values[3]) {
		my $got_parent = 0;
		my $temp_id = $values[1];
		until ($values[3] || $got_parent) {
			my $sql = "select commands.name, service_templates.command_line, service_templates.parent_id ".
				"from service_templates left join commands on service_templates.check_command = commands.command_id ".
				"where service_templates.servicetemplate_id = '$temp_id'";
			my $sth2 = $dbh->prepare($sql);
			$sth2->execute;
			my @vals = $sth2->fetchrow_array();
			$sth2->finish;
			unless ($values[3]) {
				if ($vals[1]) {
					$values[3] = $vals[1];
				} else {
					$values[3] = $vals[0];
				}
				if ($vals[2]) {
					unless ($values[3]) {
						$temp_id = $vals[2];						
					}
				} else {
					$got_parent = 1;
				}
			}
		}
	}
	$service{$values[0]}{'template'} = $values[2];
	$service{$values[0]}{'command'} = $values[3];
	$service{$values[0]}{'extinfo'} = $values[6];
	return %service;
}

sub get_service_dependencies(@) {
	my $snid = $_[1];
	my %service_dependencies = ();
	my $sqlstmt = "select id, name from service_dependency_templates where id in (select template from servicename_dependency where servicename_id = '$snid' and depend_on_host_id is null)";
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) { $service_dependencies{$values[1]} = $values[0] }
	$sth->finish;	
	return %service_dependencies;
}

sub get_hosts_services() {
	my %hosts_services = ();
	my %hosts = ();
	my $sqlstmt = "select name, host_id from hosts";
	my $sth = $dbh->prepare ($sqlstmt);
	my $host_count = 0;
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		$hosts{$values[0]} = $values[1];
		$host_count++;
	}
	$sth->finish;
	foreach my $host (sort keys %hosts) {
		@{$hosts_services{$host}} = ();
		$sqlstmt = "select service_names.name from service_names where servicename_id in (select servicename_id from services where host_id = '$hosts{$host}')";
		$sth = $dbh->prepare ($sqlstmt);
		$sth->execute;
		while(my @values = $sth->fetchrow_array()) {
			push @{$hosts_services{$host}}, $values[0];
		}
		$sth->finish;
	}
	$hosts_services{'host_count'} = $host_count;
	return %hosts_services;
}

sub get_host_services_detail(@) {
	my $host_id = $_[1];
	my %services = ();
	my $sqlstmt = "select * from services where host_id = '$host_id'";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		$services{$values[0]}{'id'} = $values[0];
		$services{$values[0]}{'servicename_id'} = $values[2];
		$services{$values[0]}{'servicetemplate_id'} = $values[3];
		$services{$values[0]}{'serviceextinfo_id'} = $values[4];
		$services{$values[0]}{'check_command'} = $values[7];
		$services{$values[0]}{'command_line'} = $values[8];
		$services{$values[0]}{'comment'} = $values[9];
		$sqlstmt = "select * from service_overrides where service_id = '$values[0]'"; 
		my $sth2 = $dbh->prepare ($sqlstmt);
		$sth2->execute;
		while(my @vals = $sth2->fetchrow_array()) {
			$services{$values[0]}{'check_period'} = $vals[1];
			$services{$values[0]}{'notification_period'} = $vals[2];
			$services{$values[0]}{'event_handler'} = $vals[3];
			my %data = parse_xml('',$vals[4]);
			foreach my $prop (keys %data) { $services{$values[0]}{$prop} = $data{$prop} }
		}
		$sth2->finish;
#		$sqlstmt = "select contactgroups.name from contactgroups where contactgroup_id in ".
#			"(select contactgroup_id from contactgroup_assign where type = 'services' and object = '$values[0]')";
		$sqlstmt = "select contactgroups.name from contactgroups where contactgroup_id in ".
			"(select contactgroup_id from contactgroup_service where service_id = '$values[0]')";
		$sth2 = $dbh->prepare ($sqlstmt);
		$sth2->execute;
		@{$services{$values[0]}{'contactgroups'}} = ();
		while(my @vals = $sth2->fetchrow_array()) {
			push @{$services{$values[0]}{'contactgroups'}}, $vals[0];
		}
		$sth2->finish;
	}
	$sth->finish;
	return %services;
}

sub get_service_instances(@) {
	my $sid = $_[1];
	my %instances = ();
	my $sqlstmt = "select * from service_instance where service_id = '$sid'"; 
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		$instances{$values[2]}{'status'} = $values[3];
		$instances{$values[2]}{'args'} = $values[4];
 		$instances{$values[2]}{'id'} = $values[0];
	}
	$sth->finish;
	return %instances;
}


sub get_service_instances_names(@) {
	my $sid = $_[1];
	my %instances = ();
	my $sqlstmt = "select * from service_instance where service_id = '$sid'"; 
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		$instances{$values[0]}{'name'} = $values[2];
	}
	$sth->finish;
	return %instances;
}

sub ez_defaults() {
	my %objects = ();
	my $sqlstmt = "select name, value from setup where type = 'monarch_ez'";
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	my %tables = ('host_profile' => 'profiles_host','contact_template' => 'contact_templates','contactgroup' => 'contactgroups');
	while(my @values = $sth->fetchrow_array()) {
		my %obj = fetch_one('',$tables{$values[0]},'name',$values[1]);
		if ($obj{'name'}) {
			$objects{$values[0]} = $values[1];
		} else {
			$objects{$values[0]} = 'not_defined';
		}
	}
	$sth->finish;
	return %objects;
}


sub get_objects() {
	my %objects = ();
	my $sqlstmt = "select value, name from setup where type = 'resource'";
	my $sth = $dbh->prepare($sqlstmt);
	if ($sth->execute) {
		while(my @values = $sth->fetchrow_array()) {
			$objects{'resources'}{$values[1]} = $values[0];
		}
	} else {
		$objects{'errors'}{'commands'} = "Error: $@";
	}
	$sth->finish;

	$sqlstmt = "select command_id, name from commands";
	$sth = $dbh->prepare($sqlstmt);
	if ($sth->execute) {
		while(my @values = $sth->fetchrow_array()) {
			$objects{'commands'}{$values[1]} = $values[0];
		}
	} else {
		$objects{'errors'}{'commands'} = "Error: $@";
	}
	$sth->finish;

	$sqlstmt = "select timeperiod_id, name from time_periods";
	$sth = $dbh->prepare($sqlstmt);
	if ($sth->execute) {
		while(my @values = $sth->fetchrow_array()) {
			$objects{'time_periods'}{$values[1]} = $values[0];
		}
	} else {
		$objects{'errors'}{'time_periods'} = "Error: $@";
	}
	$sth->finish;

	$sqlstmt = "select hosttemplate_id, name from host_templates";
	$sth = $dbh->prepare($sqlstmt);
	if ($sth->execute) {
		while(my @values = $sth->fetchrow_array()) {
			$objects{'host_templates'}{$values[1]} = $values[0];
		}
	} else {
		$objects{'errors'}{'host_templates'} = "Error: $@";
	}
	$sth->finish;
	
	$sqlstmt = "select hostextinfo_id, name from extended_host_info_templates";
	$sth = $dbh->prepare($sqlstmt);
	if ($sth->execute) {
		while(my @values = $sth->fetchrow_array()) {
			$objects{'extended_host_info_templates'}{$values[1]} = $values[0];
		}
	} else {
		$objects{'errors'}{'extended_host_info_templates'} = "Error: $@";
	}
	$sth->finish;

	$sqlstmt = "select serviceextinfo_id, name from extended_service_info_templates";
	$sth = $dbh->prepare($sqlstmt);
	if ($sth->execute) {
		while(my @values = $sth->fetchrow_array()) {
			$objects{'extended_service_info_templates'}{$values[1]} = $values[0];
		}
	} else {
		$objects{'errors'}{'extended_service_info_templates'} = "Error: $@";
	}
	$sth->finish;

	$sqlstmt = "select servicetemplate_id, name from service_templates";
	$sth = $dbh->prepare($sqlstmt);
	if ($sth->execute) {
		while(my @values = $sth->fetchrow_array()) {
			$objects{'service_templates'}{$values[1]} = $values[0];
		}
	} else {
		$objects{'errors'}{'service_templates'} = "Error: $@";
	}
	$sth->finish;

	$sqlstmt = "select servicename_id, name from service_names";
	$sth = $dbh->prepare($sqlstmt);
	if ($sth->execute) {
		while(my @values = $sth->fetchrow_array()) {
			$objects{'service_names'}{$values[1]} = $values[0];
		}
	} else {
		$objects{'errors'}{'service_names'} = "Error: $@";
	}
	$sth->finish;

	$sqlstmt = "select serviceprofile_id, name from profiles_service";
	$sth = $dbh->prepare($sqlstmt);
	if ($sth->execute) {
		while(my @values = $sth->fetchrow_array()) {
			$objects{'profiles_service'}{$values[1]} = $values[0];
		}
	} else {
		$objects{'errors'}{'profiles_service'} = "Error: $@";
	}
	$sth->finish;
	
	$sqlstmt = "select hostprofile_id, name from profiles_host";
	$sth = $dbh->prepare($sqlstmt);
	if ($sth->execute) {
		while(my @values = $sth->fetchrow_array()) {
			$objects{'profiles_host'}{$values[1]} = $values[0];
		}
	} else {
		$objects{'errors'}{'profiles_host'} = "Error: $@";
	}
	$sth->finish;

	$sqlstmt = "select external_id, name from externals";
	$sth = $dbh->prepare($sqlstmt);
	if ($sth->execute) {
		while(my @values = $sth->fetchrow_array()) {
			$objects{'externals'}{$values[1]} = $values[0];
		}
	} else {
		$objects{'errors'}{'profiles_host'} = "Error: $@";
	}
	$sth->finish;

	return %objects;
}


sub get_table_objects(@) {
	my $table = $_[1];
	my $id_name = $_[2];
	my %objects = ();
	my %table_id = (
		'time_periods' => 'timeperiod_id',
		'commands' => 'command_id',
		'contactgroups' => 'contactgroup_id',
		'contacts' => 'contact_id',
		'contact_templates' => 'contacttemplate_id',
		'discover_method' => 'method_id',
		'discover_group' => 'group_id',
		'import_schema' => 'schema_id',
		'extended_host_info_templates' => 'hostextinfo_id',
		'extended_service_info_templates' => 'serviceextinfo_id',
		'hosts' => 'host_id',
		'host_templates' =>	'hosttemplate_id',
		'monarch_macros' => 'macro_id',
		'monarch_groups' => 'group_id',
		'hostgroups' => 'hostgroup_id',
		'servicegroups' => 'servicegroup_id',
		'service_names' =>	'servicename_id',
		'service_templates' =>	'servicetemplate_id',
		'escalation_templates' => 'template_id',
		'escalation_trees' => 'tree_id',
		'externals' => 'external_id',
		'profiles_service' => 'serviceprofile_id',
		'profiles_host' => 'hostprofile_id');
	my $sqlstmt = "select name, $table_id{$table} from $table";
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		if ($id_name) {
			$objects{$values[1]} = $values[0];
		} else {
			$objects{$values[0]} = $values[1];
		}
	}
	$sth->finish;
	return %objects;
}


sub purge(@) {
	my $purge_option = $_[1];
	my $escalation_option = $_[2];
	StorProc->delete_all('setup','type','file');
	my %tables = ();
	my $sqlstmt = "show tables";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		$tables{$values[0]} = 1;
	}
	$sth->finish;
	delete $tables{'sessions'};	
	delete $tables{'monarch_groups'};
	delete $tables{'monarch_group_child'};
	delete $tables{'monarch_group_macro'};
	delete $tables{'monarch_group_props'};
	delete $tables{'monarch_macros'};
	delete $tables{'users'};	
	delete $tables{'user_groups'};	
	delete $tables{'user_group'};	
	delete $tables{'access_list'};	
	delete $tables{'setup'};	
	delete $tables{'users'};	
	delete $tables{'datatype'};	
	delete $tables{'host_service'};	
	delete $tables{'import_services'};	
	delete $tables{'import_hosts'};	
	delete $tables{'import_schema'};
	delete $tables{'import_column'};
	delete $tables{'import_match'};
	delete $tables{'import_match_contactgroup'};
	delete $tables{'import_match_group'};
	delete $tables{'import_match_hostgroup'};
	delete $tables{'import_match_parent'};
	delete $tables{'import_match_serviceprofile'};
	if ($purge_option eq 'purge_nice') {
		delete $tables{'monarch_group_host'};
		delete $tables{'monarch_group_hostgroup'};
		delete $tables{'commands'};
		delete $tables{'timeperiods'};
		delete $tables{'profile_hostgroup'};
		delete $tables{'profile_parent'};
		delete $tables{'profiles_host'};
		delete $tables{'host_templates'};
		delete $tables{'hostgroup_host'};
		delete $tables{'hostgroups'};
		delete $tables{'hostprofile_overrides'};
		delete $tables{'hosts'};
		delete $tables{'commands'};
		delete $tables{'contact_command'};
		delete $tables{'contact_command_overrides'};
		delete $tables{'contact_overrides'};
		delete $tables{'contact_templates'};
		#delete $tables{'contactgroup_assign'};
		delete $tables{'contactgroup_contact'};
		delete $tables{'contactgroups'};
		delete $tables{'contacts'};
		delete $tables{'host_dependencies'};
		delete $tables{'host_overrides'};
		delete $tables{'host_parent'};
		delete $tables{'external_host'};
		delete $tables{'external_host_profile'};
		delete $tables{'extended_host_info_templates'};
		delete $tables{'extended_info_coords'};
		delete $tables{'externals'};
		delete $tables{'profiles_service'};
		delete $tables{'serviceprofile'};
		delete $tables{'serviceprofile_host'};
		delete $tables{'serviceprofile_hostgroup'};
		#$dbh->do("delete from contactgroup_assign where type = 'services'");
		#$dbh->do("delete from contactgroup_assign where type = 'service_templates'");
	}
	if ($purge_option eq 'update') {
		my @tables = ('stage_other');
		if ($escalation_option) { push (@tables,('escalation_trees','escalation_templates','tree_template_contactgroup')) }
		foreach my $table (@tables) {
			$dbh->do("truncate table $table");
		}
	} else {
		foreach my $table (keys %tables) {
			$dbh->do("truncate table $table");
		}
	}
}

sub truncate_table(@) {
	my $table = $_[1];
	$dbh->do("truncate table $table");
}

sub get_contact_templates() {
	my %contact_templates = ();
	my $sqlstmt = "select * from contact_templates";
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		$contact_templates{$values[1]}{'id'} = $values[0];
		$contact_templates{$values[1]}{'host_notification_period'} = $values[2];
		$contact_templates{$values[1]}{'service_notification_period'} = $values[3];
		my %data = parse_xml('',$values[4]);
		$contact_templates{$values[1]}{'host_notification_options'} = $data{'host_notification_options'};
		$contact_templates{$values[1]}{'service_notification_options'} = $data{'service_notification_options'};
		my %where = ('type' => 'host','contacttemplate_id' => $values[0]);
		@{$contact_templates{$values[1]}{'host_notification_commands'}} = ();
		@{$contact_templates{$values[1]}{'host_notification_commands'}} = fetch_list_where('','contact_command','command_id',\%where);
		%where = ('type' => 'service','contacttemplate_id' => $values[0]);
		@{$contact_templates{$values[1]}{'service_notification_commands'}} = ();
		@{$contact_templates{$values[1]}{'service_notification_commands'}} = fetch_list_where('','contact_command','command_id',\%where);
	}
	$sth->finish;
	return %contact_templates;
}

sub get_host_templates() {
	my %host_templates = ();
	my $sqlstmt = "select * from host_templates";
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		$host_templates{$values[1]}{'id'} = $values[0];
		$host_templates{$values[1]}{'check_period'} = $values[2];
		$host_templates{$values[1]}{'notification_period'} = $values[3];
		$host_templates{$values[1]}{'check_command'} = $values[4];
		$host_templates{$values[1]}{'event_handler'} = $values[5];
		my %data = parse_xml('',$values[6]);
		foreach my $prop (keys %data) { $host_templates{$values[1]}{$prop} = $data{$prop} }
#		my %where = ('type' => 'host_templates','object' => $values[0]);
		my %where = ('hosttemplate_id' => $values[0]);
		@{$host_templates{$values[1]}{'contactgroups'}} = ();
#		@{$host_templates{$values[1]}{'contactgroups'}} = fetch_list_where('','contactgroup_assign','contactgroup_id',\%where);
		@{$host_templates{$values[1]}{'contactgroups'}} = fetch_list_where('','contactgroup_host_template','contactgroup_id',\%where);
	}
	$sth->finish;
	return %host_templates;
}

sub get_service_templates() {
	my %service_templates = ();
	my $sqlstmt = "select * from service_templates";
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		$service_templates{$values[1]}{'id'} = $values[0];
		$service_templates{$values[1]}{'parent_id'} = $values[2];
		$service_templates{$values[1]}{'check_period'} = $values[3];
		$service_templates{$values[1]}{'notification_period'} = $values[4];
		$service_templates{$values[1]}{'check_command'} = $values[5];
		$service_templates{$values[1]}{'command_line'} = $values[6];
		$service_templates{$values[1]}{'event_handler'} = $values[7];
		my %data = parse_xml('',$values[8]);
		foreach my $prop (keys %data) { $service_templates{$values[1]}{$prop} = $data{$prop} }
#		my %where = ('type' => 'service_templates','object' => $values[0]);
		my %where = ('servicetemplate_id' => $values[0]);
		@{$service_templates{$values[1]}{'contactgroups'}} = ();
#		@{$service_templates{$values[1]}{'contactgroups'}} = fetch_list_where('','contactgroup_assign','contactgroup_id',\%where);
		@{$service_templates{$values[1]}{'contactgroups'}} = fetch_list_where('','contactgroup_service_template','contactgroup_id',\%where);


	}
	$sth->finish;
	return %service_templates;
}

sub get_hostgroups(@) {
	my $version = $_[1];
	my %hostgroups = ();
	my $sqlstmt = "select * from hostgroups";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	my @members = ();
	while(my @values = $sth->fetchrow_array()) { 
		$hostgroups{$values[1]}{'id'} = $values[0];
		$hostgroups{$values[1]}{'alias'} = $values[2];
		$hostgroups{$values[1]}{'host_escalation'} = $values[4];
		$hostgroups{$values[1]}{'service_escalation'} = $values[5];
		$hostgroups{$values[1]}{'comment'} = $values[7];
		@{$hostgroups{$values[1]}{'members'}} = ();
		@{$hostgroups{$values[1]}{'contactgroups'}} = ();
		$sqlstmt = "select hosts.name from hosts where host_id in (select host_id from hostgroup_host where hostgroup_id = '$values[0]')";
		my $sth2 = $dbh->prepare ($sqlstmt);
		$sth2->execute;
		my @members = ();
		while(my @vals = $sth2->fetchrow_array()) { push @{$hostgroups{$values[1]}{'members'}}, $vals[0] }
		$sth2->finish;			
		if ($version eq '1.x') {
#			$sqlstmt = "select contactgroups.name from contactgroups where contactgroup_id in ".
#				"(select contactgroup_id from contactgroup_assign where type = 'hostgroups' and object = '$values[0]')";
			$sqlstmt = "select contactgroups.name from contactgroups where contactgroup_id in ".
				"(select contactgroup_id from contactgroup_hostgroup where hostgroup_id = '$values[0]')";
			$sth2 = $dbh->prepare ($sqlstmt);
			$sth2->execute;
			my @contactgroups = ();
			while(my @vals = $sth2->fetchrow_array()) { push @{$hostgroups{$values[1]}{'contactgroups'}}, $vals[0] }
			$sth2->finish;			
		}
	}
	$sth->finish;			
	return %hostgroups;
}

sub get_hostextinfo_templates() {
	my %hostextinfo_templates = ();
	my $sqlstmt = "select * from extended_host_info_templates";
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		$hostextinfo_templates{$values[1]}{'id'} = $values[0];
		$hostextinfo_templates{$values[1]}{'name'} = $values[1];
		$hostextinfo_templates{$values[1]}{'comment'} = $values[4];
		my %data = parse_xml('',$values[2]);
		foreach my $prop (keys %data) { $hostextinfo_templates{$values[1]}{$prop} = $data{$prop} }
	}
	$sth->finish;
	return %hostextinfo_templates;
}

sub get_serviceextinfo_templates() {
	my %serviceextinfo_templates = ();
	my $sqlstmt = "select * from extended_service_info_templates";
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		$serviceextinfo_templates{$values[1]}{'id'} = $values[0];
		$serviceextinfo_templates{$values[1]}{'name'} = $values[1];
		$serviceextinfo_templates{$values[1]}{'comment'} = $values[4];
		my %data = parse_xml('',$values[2]);
		foreach my $prop (keys %data) { $serviceextinfo_templates{$values[1]}{$prop} = $data{$prop} }
	}
	$sth->finish;
	return %serviceextinfo_templates;
}

sub get_staged_services() {
	my %services = ();
	my $sqlstmt = "select * from stage_other where type = 'service'";
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	my $i = 1;
	while(my @values = $sth->fetchrow_array()) {
		$services{$i}{'name'} = $values[0];
		my %data = parse_xml('',$values[3]);
		foreach my $prop (keys %data) { $services{$i}{$prop} = $data{$prop} }
		$services{$i}{'comment'} = $values[4];
		$i++;
	}
	$sth->finish;
	return %services;
}

sub get_hostid_servicenameid_serviceid() {
	my %hosts_services = ();
	my $sqlstmt = "select host_id, servicename_id, service_id from services";
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		$hosts_services{$values[0]}{$values[1]} = $values[2];
	}
	$sth->finish;
	return %hosts_services;
}

sub get_escalation_templates() {
	my %escalation_templates = ();
	my $sqlstmt = "select * from escalation_templates";
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		$escalation_templates{$values[1]}{'id'} = $values[0];
		$escalation_templates{$values[1]}{'type'} = $values[2];
		$escalation_templates{$values[1]}{'escalation_period'} = $values[5];
		my %data = parse_xml('',$values[3]);
		foreach my $prop (keys %data) { $escalation_templates{$values[1]}{$prop} = $data{$prop} }
	}
	$sth->finish;
	return %escalation_templates;
}

sub get_escalation_trees() {
	my %escalation_trees = ();
	my $sqlstmt = "select * from escalation_trees";
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		$escalation_trees{$values[1]}{'id'} = $values[0];
		$escalation_trees{$values[1]}{'comment'} = $values[2];
		$escalation_trees{$values[1]}{'type'} = $values[3];
		$sqlstmt = "select escalation_templates.template_id, escalation_templates.name from escalation_templates where template_id in ".
			"(select template_id from escalation_tree_template where tree_id = '$values[0]')"; 
		my $sth2 = $dbh->prepare($sqlstmt);
		$sth2->execute;
		while(my @vals = $sth2->fetchrow_array()) {
			@{$escalation_trees{$values[1]}{$vals[1]}} = ();
			$sqlstmt = "select contactgroups.name from contactgroups where contactgroup_id in ".
				"(select contactgroup_id from tree_template_contactgroup where tree_id = '$values[0]' and template_id = '$vals[0]')"; 
			my $sth3 = $dbh->prepare($sqlstmt);
			$sth3->execute;
			while(my @val = $sth3->fetchrow_array()) {
				push @{$escalation_trees{$values[1]}{$vals[1]}}, $val[0];
			}
			$sth3->finish;
		}
		$sth2->finish;
	}
	$sth->finish;
	return %escalation_trees;
}

sub get_staged_escalation_templates(@) {
	my $type = $_[1];
	my %objects = ();
	my $sqlstmt = "select * from stage_other where type = 'serviceescalation_template'";
	if ($type eq 'host') {
		$sqlstmt = "select * from stage_other where type = 'hostescalation_template' or type = 'hostgroupescalation_template'";
	}
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		$objects{$values[0]}{'comment'} = $values[4];		
		my %data = parse_xml('',$values[3]);
		foreach my $prop (keys %data) {
			if ($prop eq 'escalation_options') {
				$data{$prop} =~ s/\s+//g;
				my @opts = split(/,/, $data{$prop});
				@opts = sort @opts;
				foreach my $opt (@opts) { $objects{$values[0]}{'escalation_options'} .= "$opt," }
				chop $objects{$values[0]}{'escalation_options'};
			} elsif ($prop eq 'host_name') {
				my @host_name = split(/,/, $data{$prop});
				foreach (@host_name) { $_ =~ s/^\s+|\s+$//g }
				@host_name = sort @host_name;
				foreach my $host_name (@host_name) { 
					$objects{$values[0]}{'host_name'} .= "$host_name,";
				}
				chop $objects{$values[0]}{'host_name'};
			} elsif ($prop eq 'hostgroup_name') {
				my @hostgroup_name = split(/,/, $data{$prop});
				foreach (@hostgroup_name) { $_ =~ s/^\s+|\s+$//g }
				@hostgroup_name = sort @hostgroup_name;
				foreach my $hostgroup_name (@hostgroup_name) { 
					$objects{$values[0]}{'hostgroup_name'} .= "$hostgroup_name,";
				}
				chop $objects{$values[0]}{'hostgroup_name'};
			} elsif ($prop eq 'servicegroup_name') {
				my @servicegroup_name = split(/,/, $data{$prop});
				foreach (@servicegroup_name) { $_ =~ s/^\s+|\s+$//g }
				@servicegroup_name = sort @servicegroup_name;
				foreach my $servicegroup_name (@servicegroup_name) { 
					$objects{$values[0]}{'servicegroup_name'} .= "$servicegroup_name,";
				}
				chop $objects{$values[0]}{'servicegroup_name'};
			} elsif ($prop eq 'service_description') {
				my @service_description = split(/,/, $data{$prop});
				foreach (@service_description) { $_ =~ s/^\s+|\s+$//g }
				@service_description = sort @service_description;
				foreach my $service_description (@service_description) { 
					$objects{$values[0]}{'service_description'} .= "$service_description,";
				}
				chop $objects{$values[0]}{'service_description'};
			} elsif ($prop eq 'contact_groups') {
				my @contact_groups = split(/,/, $data{$prop});
				@contact_groups = sort @contact_groups;
				foreach my $contact_group (@contact_groups) { 
					$contact_group =~ s/^\s+|\s+$//g;
					$objects{$values[0]}{'contact_groups'} .= "$contact_group,";
				}
				chop $objects{$values[0]}{'contact_groups'};
			} else {
				$objects{$values[0]}{$prop} = $data{$prop} 
			}
		}
		unless ($objects{$values[0]}{'escalation_options'}) { $objects{$values[0]}{'escalation_options'} = 'all' }
		unless ($objects{$values[0]}{'escalation_period'}) { $objects{$values[0]}{'escalation_period'} = '24x7' }
	}
	$sth->finish;
	return %objects;
}

sub get_staged_escalations(@) {
	my $type = $_[1];
	my %objects = ();
	my $sqlstmt = "select * from stage_other where type = 'serviceescalation'";
	if ($type eq 'host') {
		$sqlstmt = "select * from stage_other where type = 'hostescalation' or type = 'hostgroupescalation'";
	}
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		$objects{$values[0]}{'comment'} = $values[4];		
		my %data = parse_xml('',$values[3]);
		foreach my $prop (keys %data) {
			if ($prop eq 'escalation_options') {
				$data{$prop} =~ s/\s+//g;
				my @opts = split(/,/, $data{$prop});
				@opts = sort @opts;
				foreach my $opt (@opts) { $objects{$values[0]}{'escalation_options'} .= "$opt," }
				chop $objects{$values[0]}{'escalation_options'};
			} elsif ($prop eq 'host_name') {
				my @host_name = split(/,/, $data{$prop});
				foreach (@host_name) { $_ =~ s/^\s+|\s+$//g }
				@host_name = sort @host_name;
				foreach my $host_name (@host_name) { 
					$objects{$values[0]}{'host_name'} .= "$host_name,";
				}
				chop $objects{$values[0]}{'host_name'};
			} elsif ($prop eq 'hostgroup_name') {
				my @hostgroup_name = split(/,/, $data{$prop});
				foreach (@hostgroup_name) { $_ =~ s/^\s+|\s+$//g }
				@hostgroup_name = sort @hostgroup_name;
				foreach my $hostgroup_name (@hostgroup_name) { 
					$objects{$values[0]}{'hostgroup_name'} .= "$hostgroup_name,";
				}
				chop $objects{$values[0]}{'hostgroup_name'};
			} elsif ($prop eq 'servicegroup_name') {
				my @servicegroup_name = split(/,/, $data{$prop});
				foreach (@servicegroup_name) { $_ =~ s/^\s+|\s+$//g }
				@servicegroup_name = sort @servicegroup_name;
				foreach my $servicegroup_name (@servicegroup_name) { 
					$objects{$values[0]}{'servicegroup_name'} .= "$servicegroup_name,";
				}
				chop $objects{$values[0]}{'servicegroup_name'};
			} elsif ($prop eq 'service_description') {
				my @service_description = split(/,/, $data{$prop});
				foreach (@service_description) { $_ =~ s/^\s+|\s+$//g }
				@service_description = sort @service_description;
				foreach my $service_description (@service_description) { 
					$objects{$values[0]}{'service_description'} .= "$service_description,";
				}
				chop $objects{$values[0]}{'service_description'};
			} elsif ($prop eq 'contact_groups') {
				my @contact_groups = split(/,/, $data{$prop});
				foreach (@contact_groups) { $_ =~ s/^\s+|\s+$//g }
				@contact_groups = sort @contact_groups;
				foreach my $contact_group (@contact_groups) { 
					$objects{$values[0]}{'contact_groups'} .= "$contact_group,";
				}
				chop $objects{$values[0]}{'contact_groups'};
			} else {
				$objects{$values[0]}{$prop} = $data{$prop};
			}
		}
	}
	$sth->finish;
	return %objects;
}

sub set_default_hostgroup_escalations(@) {
	my $tree_id = $_[1];
	$dbh->do("update hostgroups set host_escalation_id = '$tree_id' where host_escalation_id is null");
}

sub set_default_host_escalations(@) {
	my $tree_id = $_[1];
	$dbh->do("update hosts set host_escalation_id = '$tree_id' where host_escalation_id is null");
}

sub set_default_servicegroup_escalations(@) {
	my $tree_id = $_[1];
	$dbh->do("update servicegroups set escalation_id = '$tree_id' where escalation_id is null");
}

sub set_default_service_escalations(@) {
	my $tree_id = $_[1];
	$dbh->do("update services set escalation_id = '$tree_id' where escalation_id is null");
	$dbh->do("update service_names set escalation = '$tree_id' where escalation is null");
}

sub get_escalation_assigned() {
	my $tree_id = $_[1];
	my $type = $_[2];
	my $obj = $_[3];
	my @objects = ();
	my $sqlstmt = undef;
	if ($obj eq 'services') {
		$sqlstmt = "select name from service_names where escalation = '$tree_id'";
	} elsif ($obj eq 'servicegroups') {
		$sqlstmt = "select name from servicegroups where escalation_id = '$tree_id'";
	} elsif ($obj eq 'hostgroups') {
		$sqlstmt = "select name from hostgroups where $type\_escalation_id = '$tree_id'";
	} elsif ($obj eq 'hosts') {
		$sqlstmt = "select name from hosts where $type\_escalation_id = '$tree_id'";
	}
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) { push @objects, $values[0] }
	$sth->finish;
	return @objects;
}

sub get_host_service_escalation_assigned(@) {
	my $tree_id = $_[1];
	my %host_service = ();
	my $sqlstmt = "select service_id, servicename_id, host_id from services where escalation_id = '$tree_id'";
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) { $host_service{$values[2]}{$values[0]} = $values[1] }
	$sth->finish;
	return %host_service;
}

sub get_service_dependency_templates() {
	my %service_dependency_templates = ();
	my $sqlstmt = "select * from service_dependency_templates";
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		$service_dependency_templates{$values[1]}{'id'} = $values[0];
		$service_dependency_templates{$values[1]}{'servicename_id'} = $values[2];
		my %data = parse_xml('',$values[3]);
		foreach my $prop (keys %data) { $service_dependency_templates{$values[1]}{$prop} = $data{$prop} }
	}
	$sth->finish;
	return %service_dependency_templates;
}



sub get_service_groups() {
	my %service_groups = ();
	my $sqlstmt = "select * from servicegroups";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) { 
		$service_groups{$values[1]}{'id'} = $values[0];
		$service_groups{$values[1]}{'name'} = $values[1];
		$service_groups{$values[1]}{'alias'} = $values[2];
		$service_groups{$values[1]}{'escalation_id'} = $values[3];
		$sqlstmt = "select host_id, service_id from servicegroup_service where servicegroup_id = '$values[0]'";
		my $sth2 = $dbh->prepare ($sqlstmt);
		$sth2->execute;
		while(my @vals = $sth2->fetchrow_array()) { 
			$service_groups{$values[1]}{'hosts'}{$vals[0]}{$vals[1]} = 1;
		}
		$sth2->finish;			
	}
	$sth->finish;
	return %service_groups;	
}

sub get_macros() {
	my %macros = ();
	my $sqlstmt = "select * from monarch_macros";
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		$macros{$values[1]}{'id'} = $values[0];
		$macros{$values[1]}{'description'} = $values[3];
		$macros{$values[1]}{'value'} = $values[2];
	}
	$sth->finish;
	return %macros;
}

sub get_group_macros() {
	my $gid = $_[1];
	my %macros = ();
	my $sqlstmt = "select monarch_macros.macro_id, monarch_macros.name, monarch_macros.description, monarch_group_macro.value ".
		"from monarch_macros left join monarch_group_macro on monarch_group_macro.macro_id = monarch_macros.macro_id ".
		"where monarch_group_macro.group_id = '$gid'";
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		$macros{$values[1]}{'id'} = $values[0];
		$macros{$values[1]}{'description'} = $values[2];
		$macros{$values[1]}{'value'} = $values[3];
	}
	$sth->finish;
	return %macros;
}

sub get_auth_groups(@) {
	my $user_id = $_[1];
	my $sqlstmt = "select distinct name from monarch_groups left join access_list on access_list.object = monarch_groups.group_id ".
		"where access_list.type = 'group_macro' and access_list.usergroup_id in (select usergroup_id from user_group where user_id = '$user_id')";
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	my @groups = ();
	while(my @values = $sth->fetchrow_array()) {
		push @groups, $values[0];
	}
	$sth->finish;
	return @groups;
}

############################################################################

sub get_group_parents_all() {
	my %parents = ();
	my $sqlstmt = "select name, group_id from monarch_groups where group_id in (select distinct group_id from monarch_group_child)";
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		$parents{$values[0]} = $values[1]; 
	}
	$sth->finish;
	return %parents;
}


sub get_groups() {
	my %groups = ();
	my $sqlstmt = "select * from monarch_groups where group_id";
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		$groups{$values[1]}{'description'} = $values[2];
		my $stmt = "select host_id, name from hosts where host_id in (select host_id from monarch_group_host where group_id = '$values[0]') order by name";
		my $sth2 = $dbh->prepare($stmt);
		$sth2->execute;
		while(my @vals = $sth2->fetchrow_array()) {
			$groups{$values[1]}{'hosts'} .= "$vals[1],";
		}
		chop $groups{$values[1]}{'hosts'};
		$sth2->finish;
	}
	$sth->finish;
	return %groups;
}

sub check_group_children(@) {
	my $parent = $_[0];
	my $child = $_[1];
	my $group = $_[2];
	my $children = $_[3];
	my $parents = $_[4];
	my $parents_all = $_[5];
	my $group_names = $_[6];
	my %children = %{ $children };
	my %parents_all = %{ $parents_all };
	my %group_names = %{ $group_names };
	my %g_children = get_group_children($group_names{$group});	
	foreach my $g_child (sort keys %g_children) {
		$parents .= "$parent,$group,";
		$children{$parent}{'children'} .= "$g_child,";
		if ($parent eq $g_child) {
			my @parents = split(/,/, $children{$child}{'parents'});
			delete $children{$child};
			$children{'delete_it'} = 1;
			$parents = undef;
			next;
		} elsif ($parents_all{$g_child}) {
			$parents .= "$group,";
			%children = check_children($parent,$child,$g_child,\%children,$parents,\%parents_all,\%group_names);
			$children{$g_child} = $g_children{$g_child};
			$children{$g_child}{'parents'} = $parents;
			$parents = undef;
		} else {
			$children{$g_child} = $g_children{$g_child};
			$children{$g_child}{'parents'} = $parents;
			$parents = undef;
		} 	
	} 
	return %children;		
}


sub get_children_group(@) {
	my $name = $_[1];
	my %parents_all = StorProc->get_group_parents_all();
	my %group_names = get_table_objects('','monarch_groups');
	my %children = StorProc->get_group_children($group_names{$name});
	foreach my $child (keys %children) {
		$children{$child}{'parents'} .= "$name,";
		if ($parents_all{$child}) {
			my %child = check_group_children($child,$child,$child,\%children,$name,\%parents_all,\%group_names);
			if ($child{'delete_it'}) { 
				delete $children{$child};
			} else {
				%children = %child;
			}
		}
	}
	return %children;
}

sub get_possible_groups(@) {
	my $name = $_[1];
	my %group_names = get_table_objects('','monarch_groups');
	my %groups = get_groups();
	my %parents_all = get_group_parents_all();
	my %group_hosts = ();
	my %group_child = ();
	foreach my $group (keys %groups) {
		my @order = ();
		my ($group_hosts, $order) = StorProc->get_group_hosts($group,\%parents_all,\%group_names,\%group_hosts,\@order,\%group_child);
		%group_hosts = %{$group_hosts};	
		if ($group_hosts{$name}) { 
			delete $groups{$group};
			delete $group_hosts{$name};
		}
	}	
	delete $groups{$name};	
	return %groups;
}

############################################################################

sub fetch_one_group() {
	my $gid = $_[1];
	my $groups = $_[2];
	my %groups = % {$groups };
	my $sqlstmt = "select * from monarch_groups where group_id = '$gid'";
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		my %data = parse_xml('',$values[5]);
		$groups{$values[1]}{'description'} = $values[2];
		$groups{$values[1]}{'location'} = $values[3];
		$groups{$values[1]}{'label_enabled'} = $data{'label_enabled'};
		$groups{$values[1]}{'nagios_etc'} = $data{'nagios_etc'};
		$groups{$values[1]}{'label'} = $data{'label'};
		$groups{$values[1]}{'use_hosts'} = $data{'use_hosts'};
		$groups{$values[1]}{'use_checks'} = $data{'checks_enabled'};
		$groups{$values[1]}{'passive_checks_enabled'} = $data{'passive_checks_enabled'};
		$groups{$values[1]}{'active_checks_enabled'} = $data{'active_checks_enabled'};
		my $stmt = "select host_id, name from hosts where host_id in (select host_id from monarch_group_host where group_id = '$values[0]') order by name";
		my $sth2 = $dbh->prepare($stmt);
		$sth2->execute;
		my %hosts = ();
		while(my @vals = $sth2->fetchrow_array()) {
			$hosts{$vals[1]} = $vals[0];
		}
		%{$groups{$values[1]}{'hosts'}} = %hosts;
		$sth2->finish;
		$stmt = "select hostgroup_id, name from hostgroups where hostgroup_id in (select hostgroup_id from monarch_group_hostgroup where group_id = '$values[0]') order by name";
		$sth2 = $dbh->prepare($stmt);
		$sth2->execute;
		my %hostgroups = ();
		while(my @vals = $sth2->fetchrow_array()) {
			$hostgroups{$vals[1]} = $vals[0];
		}
		%{$groups{$values[1]}{'hostgroups'}} = %hostgroups;
		$sth2->finish;
		$stmt = "select monarch_macros.name, monarch_group_macro.value from monarch_macros left join monarch_group_macro on monarch_macros.macro_id = monarch_group_macro.macro_id where monarch_group_macro.group_id = '$values[0]'";
		$sth2 = $dbh->prepare($stmt);
		$sth2->execute;
		my %macros = ();
		while(my @vals = $sth2->fetchrow_array()) {
			$macros{$vals[0]} = $vals[1];
		}
 		$sth2->finish;
		%{$groups{$values[1]}{'macros'}} = %macros;
#		$stmt = "select contactgroup_id, name from contactgroups where contactgroup_id in (select contactgroup_id from contactgroup_assign where type = 'monarch_group' and object = '$values[0]')";
		$stmt = "select contactgroup_id, name from contactgroups where contactgroup_id in (select contactgroup_id from contactgroup_group where group_id = '$values[0]')";
		$sth2 = $dbh->prepare($stmt);
		$sth2->execute;
		my %contactgroups = ();
		while(my @vals = $sth2->fetchrow_array()) {
			$contactgroups{$vals[1]} = $vals[0];
		}
 		$sth2->finish;
		%{$groups{$values[1]}{'contactgroups'}} = %contactgroups;
	}
	$sth->finish;
	return %groups;
}

sub get_group_children(@) {
	my $gid = $_[1];
	my %groups = ();
	my $sqlstmt = "select * from monarch_groups where group_id in (select child_id from monarch_group_child where group_id = '$gid')";
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		my %data = parse_xml('',$values[5]);
		$groups{$values[1]}{'description'} = $values[2];
		$groups{$values[1]}{'location'} = $values[3];
		$groups{$values[1]}{'nagios_etc'} = $data{'nagios_etc'};
		$groups{$values[1]}{'label_enabled'} = $data{'label_enabled'};
		$groups{$values[1]}{'label'} = $data{'label'};
		$groups{$values[1]}{'use_hosts'} = $data{'use_hosts'};
		$groups{$values[1]}{'use_checks'} = $data{'checks_enabled'};
		$groups{$values[1]}{'passive_checks_enabled'} = $data{'passive_checks_enabled'};
		$groups{$values[1]}{'active_checks_enabled'} = $data{'active_checks_enabled'};
		my $stmt = "select host_id, name from hosts where host_id in (select host_id from monarch_group_host where group_id = '$values[0]') order by name";
		my $sth2 = $dbh->prepare($stmt);
		$sth2->execute;
		my %hosts = ();
		%{$groups{$values[1]}{'hosts'}} = ();
		while(my @vals = $sth2->fetchrow_array()) {
			$hosts{$vals[1]} = $vals[0];
		}
 		$sth2->finish;
		%{$groups{$values[1]}{'hosts'}} = %hosts;
		$stmt = "select hostgroup_id, name from hostgroups where hostgroup_id in (select hostgroup_id from monarch_group_hostgroup where group_id = '$values[0]') order by name";
		$sth2 = $dbh->prepare($stmt);
		$sth2->execute;
		my %hostgroups = ();
		%{$groups{$values[1]}{'hostgroups'}} = ();
		while(my @vals = $sth2->fetchrow_array()) {
			$hostgroups{$vals[1]} = $vals[0];
		}
 		$sth2->finish;
		%{$groups{$values[1]}{'hostgroups'}} = %hostgroups;
		$stmt = "select monarch_macros.name, monarch_group_macro.value from monarch_macros left join monarch_group_macro on monarch_macros.macro_id = monarch_group_macro.macro_id where monarch_group_macro.group_id = '$values[0]'";
		$sth2 = $dbh->prepare($stmt);
		$sth2->execute;
		my %macros = ();
		%{$groups{$values[1]}{'macros'}} = ();
		while(my @vals = $sth2->fetchrow_array()) {
			$macros{$vals[0]} = $vals[1];
		}
 		$sth2->finish;
		%{$groups{$values[1]}{'macros'}} = %macros;
#		$stmt = "select contactgroup_id, name from contactgroups where contactgroup_id in (select contactgroup_id from contactgroup_assign where type = 'monarch_group' and object = '$values[0]')";
		$stmt = "select contactgroup_id, name from contactgroups where contactgroup_id in (select contactgroup_id from contactgroup_group where group_id = '$values[0]')";
		$sth2 = $dbh->prepare($stmt);
		$sth2->execute;
		my %contactgroups = ();
		%{$groups{$values[1]}{'contactgroups'}} = ();
		while(my @vals = $sth2->fetchrow_array()) {
			$contactgroups{$vals[1]} = $vals[0];
		}
 		$sth2->finish;
		%{$groups{$values[1]}{'contactgroups'}} = %contactgroups;
	}
	$sth->finish;
	return %groups;
}

sub get_group_orphans() {
	my $sqlstmt = "select host_id, name from hosts where host_id not in (SELECT host_id FROM monarch_group_host)";
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	my %hosts = ();
	while(my @vals = $sth->fetchrow_array()) {
		$hosts{$vals[1]} = $vals[0];
	}
	$sth->finish;
	$sqlstmt = "select hostgroup_id from monarch_group_hostgroup";
	$sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while(my @vals = $sth->fetchrow_array()) {
		my $stmt = "select name from hosts where host_id in (select host_id from hostgroup_host where hostgroup_id = '$vals[0]')"; 
		my $sth2 = $dbh->prepare($stmt);
		$sth2->execute;
		while(my @val = $sth2->fetchrow_array()) {
			delete $hosts{$val[0]};
		}
		$sth2->finish;
	}
	$sth->finish;
	return %hosts;
}


sub get_group_hosts() {
	my $group = $_[1];
	my $parents_all = $_[2];
	my $group_names = $_[3];
	my $group_hosts =  $_[4];
	my $order = $_[5];
	my $group_child = $_[6];
	my %parents_all = %{ $parents_all };
	my %group_names = %{ $group_names };
	my %group_hosts = %{ $group_hosts };
	my @order = @{ $order };
	my %group_child = %{ $group_child };
	my %children = StorProc->get_group_children($group_names{$group});
	foreach my $child (sort keys %children) {
		$group_hosts{$child} = $children{$child};
		push @order, $child;
		$group_child{$group}{$child} = 1;
		if ($parents_all{$child}) {
			($group_hosts, $order, $group_child) = &get_group_hosts('',$child,\%parents_all,\%group_names,\%group_hosts,\@order,\%group_child);
			%group_hosts = %{ $group_hosts };
			@order = @{ $order };
			%group_child = %{ $group_child };
		}
	}
	return \%group_hosts,\@order,\%group_child;
}


sub get_group_hosts_old(@) {
	my $gid = $_[1];
	my %hosts = ();
	my $sqlstmt = "select host_id from monarch_group_host where group_id = '$gid'";
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		$hosts{$values[0]} = 1;
	}
	$sth->finish;
	my %members = ();
	my %nonmembers = ();
	$sqlstmt = "select * from hosts";
	$sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		if ($hosts{$values[0]}) {
			$members{$values[1]}{'alias'} = $values[2];
			$members{$values[1]}{'address'} = $values[3];
		} else {
			$nonmembers{$values[1]}{'alias'} = $values[2];
			$nonmembers{$values[1]}{'address'} = $values[3];
		}
	}
	$sth->finish;
	return \%nonmembers, \%members;
}

sub get_group_parents_top() {
	my %parents = ();
	my $sqlstmt = "select * from monarch_groups where group_id not in (select distinct child_id from monarch_group_child) order by name";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		$parents{$values[1]} = $values[0]; 
	}
	$sth->finish;
	return %parents;
}


sub get_group_cfg(@) {
	my $gid = $_[1];
	my %objects = ();
	my $sqlstmt = "select name, type, value from monarch_group_props where type = 'nagios_cfg' and group_id = '$gid'";
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		$objects{$values[0]} = [ @values ];
	}
	$sth->finish;
	return %objects;
}

sub get_group_cgi(@) {
	my $gid = $_[1];
	my %objects = ();
	my $sqlstmt = "select name, type, value from monarch_group_props where type = 'nagios_cgi' and group_id = '$gid'";
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		$objects{$values[0]} = [ @values ];
	}
	$sth->finish;
	return %objects;
}


sub get_nagios_values(@) {
	my $gid = $_[1];
	my %nag_values = ();
	my $sqlstmt = "select name, value from setup where type = 'nagios'";
	if ($gid) {
		$sqlstmt = "select name, value from monarch_group_props where type = 'nagios_cfg' and group_id = '$gid'";
	}
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		$nag_values{$values[0]} = $values[1];
	}
	$sth->finish;
	return %nag_values;
}

sub get_resource_values(@) {
	my $gid = $_[1];
	my %user_values = ();
	my $sqlstmt = "select name, value from setup where type = 'resource'";
	if ($gid) {
		$sqlstmt = "select name, value from monarch_group_props where type = 'resource' and group_id = '$gid'";
	}
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		$user_values{$values[0]} = $values[1];
	}
	$sth->finish;
	return %user_values;
}


sub count(@) {
	my $sqlstmt = "select count(*) from $_[1]";
	my $count = $dbh->selectrow_array($sqlstmt);
	return $count;
}

sub count_match {
	my $table  = $_[1];
	my $input  = $_[2]; # optional

	$input =~ s/^\s*//;
	return () if ($input =~ /'/);
	my $field_to_search = 'name';
	if ($input =~ /^\d/) {
		$field_to_search = 'address';
	}
	my $sqlstmt = "select count($field_to_search) from $table";
	if (defined($input) && $input ne '') {
		$input = '%' . $input . '%';
		$sqlstmt .= " where $field_to_search like '$input'";
	}
	my $count = $dbh->selectrow_array($sqlstmt);
	return $count;
}

sub search(@) {
	my $input       = $_[1];
	my $max_to_show = $_[2] || 20;
	$max_to_show = 20 unless ($max_to_show =~ /^-?\d+$/);
	$input =~ s/^\s*(.*?)\s*$/$1/;
	$input = '%' . $input . '%';
	$input =~ s{_}{:_}g;
	return () if ($input =~ /'/ || $input =~ /^\.$/);

	my %hosts = ();
	my $sqlstmt = '';
	# if input contains a period or digit and no letters/-/_, it might be an ip address
	if ($input =~ /[\.\d]/ && $input !~ /[-_a-z]/i) {
		$sqlstmt  = "select name, address from hosts where address like '$input'";
		$sqlstmt .= " limit $max_to_show" unless ($max_to_show < 1);
		my $sth = $dbh->prepare ($sqlstmt);
		$sth->execute;
		while(my @values = $sth->fetchrow_array()) {
				unless ($values[1]) { $values[1] = 1 }
				$hosts{$values[0]} = $values[1]; # [1] is address
		}
		$sth->finish;
	}
	# whether input has a digit or not, need to check hostnames. don't use else here.
	$sqlstmt = "select name, address from hosts where name like '$input' escape ':'";
	$sqlstmt .= " limit $max_to_show" unless ($max_to_show < 1);
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
			unless ($values[1]) { $values[1] = 1 }
			$hosts{$values[0]} = $values[0]; # [0] is host
	}
	$sth->finish;

	return %hosts;
}

sub search_service(@) {
	my $input = $_[1];
	my $max_to_show = $_[2] || 20;
	$max_to_show = 20 unless ($max_to_show =~ /^\d+$/);
	$input =~ s/^\s*(.*?)\s*$/$1/;
	$input = '%' . $input . '%';
	$input =~ s{_}{:_}g;
	return () if ($input =~ /'/ || $input =~ /^\.$/);

	my $sqlstmt = "select name from service_names where name like '$input' escape ':' limit $max_to_show";
	my %services = ();
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		unless ($values[0] eq '*') { $services{$values[0]} = $values[0] }
	}
	$sth->finish;
	return %services;
}

sub get_host_search_matrix() {
	my @host_search = ();
	my %addresses = ();
	my %names = ();
	my @addr = fetch_list('','hosts','address');
	my @hosts = fetch_list('','hosts','name');
	foreach my $add (@addr) {
		if ($add =~ /(\d+)\.(\d+)\.(\d+)\.\d+/) {
			$addresses{"$1.$2.$3.*"} = 1;
		}
	}
	foreach my $name (@hosts) {
		$name = lc($name);
		if ($name =~ /(^\S{1})/) {
			$names{"$1*"} = 1;
		}
		if ($name =~ /(^\S{3})/) {
			$names{"$1*"} = 1;
		}
	}
	foreach my $add (sort keys %addresses) {
		push @host_search, $add;
	}
	foreach my $name (sort { lc($b) cmp lc($a) } keys %names) {
		push @host_search, $name;
	}
	push @host_search, '*';
	return @host_search;
}

sub get_host_service_rrd() {
	my %host_rrd = ();
	my $sqlstmt = "select host_service.host, host_service.service, datatype.location from host_service left join datatype on host_service.datatype_id = datatype.datatype_id";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		$host_rrd{$values[0]}{$values[1]} = $values[2];
	}
	$sth->finish;
	return %host_rrd;
}


sub get_inactive_hosts() {
	my %host_inactive = ();
	my $sqlstmt = "select host_id from monarch_group_host where group_id in (select group_id from monarch_groups where status = '1')";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		$host_inactive{$values[0]} = 1;
	}
	$sth->finish;
	$sqlstmt = "select hostgroup_id from monarch_group_hostgroup where group_id in (select group_id from monarch_groups where status = '1')";
	$sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		my $stmt = "select host_id from hostgroup_host where hostgroup_id = '$values[0]'";  
		my $sth2 = $dbh->prepare ($stmt);
		$sth2->execute;
		while(my @vals = $sth2->fetchrow_array()) {
			$host_inactive{$vals[0]} = 1;
		}
		$sth2->finish;
	}
	$sth->finish;
	return %host_inactive;
}

sub rename_command(@) {
	my %command = %{$_[1]};
	my $new_name = $_[2];
	$dbh->do("update commands set name = '$new_name' where name = '$command{name}'");	
	my $sqlstmt = "select service_id, command_line from services where check_command = '$command{'command_id'}'";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		$values[1] =~ s/$command{'name'}/$new_name/;
		$dbh->do("update services set command_line = '$values[1]' where service_id = '$values[0]'");	
	}
	$sth->finish;
	$sqlstmt = "select servicename_id, command_line from service_names where check_command = '$command{'command_id'}'";
	$sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		$values[1] =~ s/$command{'name'}/$new_name/;
		$dbh->do("update service_names set command_line = '$values[1]' where servicename_id = '$values[0]'");	
	}
	$sth->finish;
	$sqlstmt = "select servicetemplate_id, command_line from service_templates where check_command = '$command{'command_id'}'";
	$sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		$values[1] =~ s/$command{'name'}/$new_name/;
		$dbh->do("update service_templates set command_line = '$values[1]' where servicetemplate_id = '$values[0]'");	
	}
	$sth->finish;
	return 1;
}

sub get_main_cfg_misc(@) { 
	my $gid = $_[1];
	my %misc_vals = ();
	my $sqlstmt = "select name, value from setup where type = 'nagios_cfg_misc'";
	if ($gid) { $sqlstmt = "select prop_id, name, value from monarch_group_props where group_id = '$gid' and type = 'nagios_cfg_misc'" }
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		if ($gid) {
			$misc_vals{$values[0]}{'name'} = $values[1];
			$misc_vals{$values[0]}{'value'} = $values[2];
		} else {
			my $name = $values[0];
			$name =~ s/key\d+.\d+$//;
			$misc_vals{$values[0]}{'name'} = $name;
			$misc_vals{$values[0]}{'value'} = $values[1];
		}
	}
	$sth->finish;
	return %misc_vals;
}

sub nagios_defaults(@) {
	my $nagios_ver = $_[1];

# get from db
	my $nagios_dir = '/usr/local/nagios';
	if ($is_portal) { $nagios_dir = '/usr/local/groundwork/nagios' }
	my %nagios = ();
	$nagios{'log_file'} = $nagios_dir.'/var/nagios.log';
	if ($nagios_ver =~ /^[23]\.x$/) {
		$nagios{'object_cache_file'} = $nagios_dir.'/var/objects.cache';
	}	
	if ($nagios_ver eq '3.x') {
		$nagios{'precached_object_file'} = $nagios_dir.'/var/objects.precache';
	}
	$nagios{'resource_file'} = $nagios_dir.'/etc/private/resource.cfg';
	$nagios{'temp_file'} = $nagios_dir.'/var/nagios.tmp';
	$nagios{'status_file'} = $nagios_dir.'/var/status.log';
	$nagios{'aggregate_status_updates'} = '1';
	$nagios{'status_update_interval'} = '15';
	$nagios{'nagios_user'} = 'nagios';
	$nagios{'nagios_group'} = 'nagios';
	$nagios{'enable_notifications'} = '0';
	$nagios{'execute_service_checks'} = '1';
	$nagios{'accept_passive_service_checks'} = '1';
	if ($nagios_ver =~ /^[23]\.x$/) {
		$nagios{'execute_host_checks'} = '1';
		$nagios{'accept_passive_host_checks'} = '1';
	}
	$nagios{'enable_event_handlers'} = '1';
	$nagios{'log_rotation_method'} = 'd';
	$nagios{'log_archive_path'} = $nagios_dir.'/var/archives';
	$nagios{'check_external_commands'} = '1';
	$nagios{'command_check_interval'} = '1';
	$nagios{'command_file'} = $nagios_dir.'/var/spool/nagios.cmd';	$nagios{'downtime_file'} = $nagios_dir.'/var/nagiosdowntime.log';
	$nagios{'comment_file'} = $nagios_dir.'/var/nagioscomment.log';
	if ($is_portal) {
		$nagios{'lock_file'} = $nagios_dir.'/var/nagios.lock';
		$nagios{'event_broker_options'} = '-1';
		$nagios{'broker_module'} = '/usr/local/groundwork/nagios/modules/libbronx.so';
	} else {
		$nagios{'lock_file'} = '/tmp/nagios.lock';
	}
	$nagios{'retain_state_information'} = '1';
	$nagios{'state_retention_file'} = $nagios_dir.'/var/nagiosstatus.sav';
	$nagios{'retention_update_interval'} = '60';
	$nagios{'use_retained_program_state'} = '1';
	if ($nagios_ver =~ /^[23]\.x$/) {
		$nagios{'use_retained_scheduling_info'} = '1';
	}
	$nagios{'use_syslog'} = '0';
	$nagios{'log_notifications'} = '1';
	$nagios{'log_service_retries'} = '1';
	$nagios{'log_host_retries'} = '1';
	$nagios{'log_event_handlers'} = '1';
	$nagios{'log_initial_states'} = '0';
	$nagios{'log_external_commands'} = '1';
	if ($nagios_ver eq '1.x') {
		$nagios{'log_passive_service_checks'} = '1';
	} else {
		$nagios{'log_passive_checks'} = '1';
	}
	$nagios{'global_host_event_handler'} = '';
	$nagios{'global_service_event_handler'} = '';
	$nagios{'sleep_time'} = '1';
	if ($nagios_ver eq '1.x') {
		$nagios{'inter_check_delay_method'} = 's';
	} else {
		$nagios{'service_inter_check_delay_method'} = 's';
		$nagios{'max_service_check_spread'} = '30';
	}
	$nagios{'service_interleave_factor'} = 's';
	$nagios{'max_concurrent_checks'} = '0';
	if ($nagios_ver eq '3.x') {
		$nagios{'check_result_path'} = $nagios_dir.'/var/checkresults';
	}
	$nagios{'service_reaper_frequency'} = '10';
	if ($nagios_ver =~ /^[23]\.x$/) {
		$nagios{'host_inter_check_delay_method'} = 's';
		$nagios{'max_host_check_spread'} = '30';
	}
	$nagios{'interval_length'} = '60';
	if ($nagios_ver =~ /^[23]\.x$/) {
		$nagios{'auto_reschedule_checks'} = '0';
		$nagios{'auto_rescheduling_interval'} = '30';
		$nagios{'auto_rescheduling_window'} = '180';
	}
	$nagios{'use_agressive_host_checking'} = '0';
	$nagios{'enable_flap_detection'} = '0';
	$nagios{'low_service_flap_threshold'} = '25.0';
	$nagios{'high_service_flap_threshold'} = '50.0';
	$nagios{'low_host_flap_threshold'} = '25.0';
	$nagios{'high_host_flap_threshold'} = '50.0';
	$nagios{'soft_state_dependencies'} = '0';
	$nagios{'service_check_timeout'} = '60';
	$nagios{'host_check_timeout'} = '30';
	$nagios{'event_handler_timeout'} = '30';
	$nagios{'notification_timeout'} = '30';
	$nagios{'ocsp_timeout'} = '5';
	if ($nagios_ver =~ /^[23]\.x$/) {
		$nagios{'ochp_timeout'} = '5';
	}
	$nagios{'perfdata_timeout'} = '5';
	$nagios{'obsess_over_services'} = '0';
	$nagios{'ocsp_command'} = '';
	if ($nagios_ver =~ /^[23]\.x$/) {
		$nagios{'obsess_over_hosts'} = '0';	
		$nagios{'ochp_command'} = '';
	}
	$nagios{'process_performance_data'} = '1';
	$nagios{'host_perfdata_command'} = 'process-host-perfdata';
	$nagios{'service_perfdata_command'} = 'process-service-perfdata';
	if ($nagios_ver =~ /^[23]\.x$/) {
		$nagios{'host_perfdata_file'} = $nagios_dir.'/var/host-perfdata.dat';
		$nagios{'service_perfdata_file'} = $nagios_dir.'/var/service-perfdata.dat';
		$nagios{'host_perfdata_file_template'} = '';
		$nagios{'service_perfdata_file_template'} = '';
		$nagios{'host_perfdata_file_mode'}    = 'w'; # These two lines had been set to 'a' prior to GW 5.2, to work around a Nagios bug introduced
		$nagios{'service_perfdata_file_mode'} = 'w'; # in Nagios 2.5 and fixed as of Nagios 2.10 (possibly earlier). See GWMON-3363.
		$nagios{'host_perfdata_file_processing_interval'} = '';
		$nagios{'service_perfdata_file_processing_interval'} = '';
		$nagios{'host_perfdata_file_processing_command'} = '';
		$nagios{'service_perfdata_file_processing_command'} = '';
	}
	$nagios{'check_for_orphaned_services'} = '0';
	$nagios{'check_service_freshness'} = '0';
	$nagios{'freshness_check_interval'} = '60';
	if ($nagios_ver =~ /^[23]\.x$/) {
		$nagios{'check_host_freshness'} = '0';
		$nagios{'host_freshness_check_interval'} = '60';		
	}
	$nagios{'date_format'} = 'us';
	$nagios{'illegal_object_name_chars'} = q(`~!$%^&*|'"<>?,()'=);
	$nagios{'illegal_macro_output_chars'} = q(`~$&|'"<>);
	$nagios{'admin_email'} = 'nagios@localhost';
	$nagios{'admin_pager'} = 'pagenagios@localhost';
	return %nagios;
}

sub cgi_defaults(@) {
	my $nagios_ver = $_[1];
	my $is_portal = $_[2];
	my $nagios_dir = '/usr/local/nagios';
	if ($is_portal) { $nagios_dir = '/usr/local/groundwork/nagios' }
	my %cgi = ();
	$cgi{'physical_html_path'} = '/usr/local/groundwork/nagios/share';
	$cgi{'url_html_path'} = '/nagios';
	$cgi{'show_context_help'} = '1';
	$cgi{'nagios_check_command'} = q(/usr/local/groundwork/nagios/libexec/check_nagios /usr/local/groundwork/nagios/var/status.log 5 '/usr/local/groundwork/nagios/bin/nagios');
	$cgi{'use_authentication'} = '1';
	$cgi{'default_user_name'} = 'nagiosadmin';
	$cgi{'authorized_for_system_information'} = 'nagiosadmin,theboss,jdoe';
	$cgi{'authorized_for_system_commands'} = 'nagiosadmin';
	$cgi{'authorized_for_configuration_information'} = 'nagiosadmin,jdoe';
	$cgi{'authorized_for_all_hosts'} = 'nagiosadmin,guest';
	$cgi{'authorized_for_all_host_commands'} = 'nagiosadmin';
	$cgi{'authorized_for_all_services'} = 'nagiosadmin,guest';
	$cgi{'authorized_for_all_service_commands'} = 'nagiosadmin';
	$cgi{'statusmap_background_image'} = 'states.png';
	$cgi{'default_statusmap_layout'} = '5';
	$cgi{'default_statuswrl_layout'} = '2';
	$cgi{'refresh_rate'} = '90';
	$cgi{'statuswrl_include'} = 'myworld.wrl';
	$cgi{'ping_syntax'} = '/bin/ping -n -U -c 5 $HOSTADDRESS$';
	$cgi{'host_unreachable_sound'} = '';
	$cgi{'host_down_sound'} = '';
	$cgi{'service_critical_sound'} = '';
	$cgi{'service_warning_sound'} = '';
	$cgi{'service_unknown_sound'} = '';
	if ($nagios_ver eq '1.x') {
		$cgi{'ddb'} = '';
	}
	return %cgi;
}

sub load_nagios_cfg() {
	my $nagios_dir = $_[1];
	my @errors = ();
	my $result = delete_all('','setup','type','nagios');
	if ($result =~ /^Error/) { push @errors, $result }
	my %ddb = ();
	my %nagios = nagios_defaults();
	my %nagios_dir = fetch_one('','setup','name','nagios_home');
	open(FILE, "< $nagios_dir/nagios.cfg") || push @errors, "Error: Unable to open $nagios_dir/nagios.cfg $!";
	while (my $line = <FILE>) {
		if ($line =~ /^#|^cfg_file|^cfg_dir/) { next }
		if ($line =~ /(\S+)\s*=\s*(.*)$/) {
			my $directive = $1;
			my $value = $2;
			$nagios{$directive} = $value;
		} elsif ($line =~ /^x?ddb_/) {
			# $ddb{'ddb'} = $line;
			next;
		}	
	}
	close (FILE);
	foreach my $name (keys %nagios) {
		my @vals = ($name,'nagios',$nagios{$name});
		my $result = insert_obj('','setup',\@vals);
		if ($result =~ /^Error/) { push @errors, $result }
	}
	return @errors;
}

sub import_nagios_cfg() {
	my $gid = $_[1];
	my @errors = ();
	my %nagios = ();
	open(FILE, "< /tmp/nagios.cfg") || push @errors, "Error: Unable to open /tmp/nagios.cfg $!";
	while (my $line = <FILE>) {
		if ($line =~ /^#|^cfg_file|^cfg_dir/) { next }
		if ($line =~ /(\S+)\s*=\s*(.*)$/) {
			my $directive = $1;
			my $value = $2;
			$nagios{$directive} = $value;
		} elsif ($line =~ /^x?ddb_/) {
			next;
		}	
	}
	close (FILE);
	foreach my $name (keys %nagios) {
		my @vals = ('',$gid,$name,'nagios_cfg',$nagios{$name});
		my $result = StorProc->insert_obj('monarch_group_props',\@vals);
		if ($result =~ /^Error/) { push @errors, $result }
	}
	return @errors;
}

sub load_nagios_cgi(@) {
	my $nagios_dir = $_[1];
	my @errors = ();
	my $result = delete_all('','setup','type','nagios_cgi');
	if ($result =~ /^Error/) { push @errors, $result }
	my %nagios = cgi_defaults();
	my %ddb = ();
	open(FILE, "< $nagios_dir/cgi.cfg") || push @errors, "Error: Unable to open $nagios_dir/cgi.cfg $!";
	while (my $line = <FILE>) {
		if ($line =~ /^#|^main_config_file|^cfg_dir/) { next }
		if ($line =~ /(\S+)\s*=\s*(.*)$/) {
			my $directive = $1;
			my $value = $2;
			if ($directive =~ /ddb_/) {
				next;
			} else {
				$nagios{$directive} = $value;
			}
		}
	}
	close (FILE);
	foreach my $name (keys %nagios) {
		my @vals = ($name,'nagios_cgi',$nagios{$name});
		my $result = insert_obj('','setup',\@vals);
		if ($result =~ /^Error/) { push @errors, $result }
	}
	return @errors;
}

sub import_nagios_cgi(@) {
	my $gid = $_[1];
	my @errors = ();
	my %nagios = ();
	open(FILE, "< /tmp/cgi.cfg") || push @errors, "Error: Unable to open /tmp/cgi.cfg $!";
	while (my $line = <FILE>) {
		if ($line =~ /^#|^main_config_file|^cfg_dir/) { next }
		if ($line =~ /(\S+)\s*=\s*(.*)$/) {
			my $directive = $1;
			my $value = $2;
			if ($directive =~ /ddb_/) {
				next;
			} else {
				$nagios{$directive} = $value;
			}
		}
	}
	close (FILE);
	foreach my $name (keys %nagios) {
		my @vals = ('',$gid,$name,'nagios_cgi',$nagios{$name});
		my $result = insert_obj('','monarch_group_props',\@vals);
		if ($result =~ /^Error/) { push @errors, $result }
	}
	return @errors;
}

sub import_resource_cfg(@) {
	my $gid = $_[1];
	my @errors = ();
	my %nagios = ();
	open(FILE, "< /tmp/resource.cfg") || push @errors, "Error: Unable to open /tmp/resource.cfg $!";
	my $comment = undef;
	while (my $line = <FILE>) {
		if ($line =~ /\$USER(\d+)\$\s*=\s*(.*)$/) { 
			my @vals = ('',$gid,'user'.$1,'resource',$2);
			my $result = insert_obj('','monarch_group_props',\@vals);
			if ($result =~ /^Error/) { push @errors, $result }
			@vals = ('',$gid,'resource_label'.$1,'resource',$comment);
			$result = insert_obj('','monarch_group_props',\@vals);
			if ($result =~ /^Error/) { push @errors, $result }
			$comment = undef;
		} else {
			$comment .= $line;
		}
	}
	close(FILE);
	return @errors;
}

#
# Automation subs for MonarchAutomation.pm monarch_auto.cgi added 2007-Jan-16
#
sub get_discovery_groups() {
	my %discover_groups = ();
	my $sqlstmt = "select discover_group.group_id, discover_group.name, discover_group.description, ".
		"discover_group.config, import_schema.schema_id, import_schema.name ". 
		"from discover_group, import_schema ".
		"where discover_group.schema_id = import_schema.schema_id";
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		my $discovery_name = $values[1];
		$discover_groups{$discovery_name}{'id'} = $values[0];
		$discover_groups{$discovery_name}{'description'} = $values[2];
		$discover_groups{$discovery_name}{'schema_id'} = $values[4];
		$discover_groups{$discovery_name}{'schema'} = $values[5];
		my %data = parse_xml('',$values[3]);
		foreach my $key (keys %data) {
			$discover_groups{$discovery_name}{$key} = $data{$key};
		}
		$sqlstmt = "select discover_method.method_id, discover_method.name, discover_method.description, discover_method.config, discover_method.type from discover_method " .
			"left join discover_group_method on discover_method.method_id = discover_group_method.method_id " .
			"where discover_group_method.group_id = '$values[0]'";
		my $sth2 = $dbh->prepare($sqlstmt);
		$sth2->execute;
		while(my @vals = $sth2->fetchrow_array()) {
			$discover_groups{$discovery_name}{'method'}{$vals[1]}{'method_id'} = $vals[0];
			$discover_groups{$discovery_name}{'method'}{$vals[1]}{'description'} = $vals[2];
			$discover_groups{$discovery_name}{'method'}{$vals[1]}{'type'} = $vals[4];
			%data = parse_xml('',$vals[3]);
			foreach my $key (keys %data) {
				$discover_groups{$discovery_name}{'method'}{$vals[1]}{$key} = $data{$key};
			}
			$sqlstmt = "select discover_filter.filter_id, discover_filter.name, discover_filter.type, discover_filter.filter from discover_filter " .
				"left join discover_method_filter on discover_filter.filter_id = discover_method_filter.filter_id " .
				"where discover_method_filter.method_id = '$vals[0]'";
			my $sth3 = $dbh->prepare($sqlstmt);
			$sth3->execute;
			while(my @f_vals = $sth3->fetchrow_array()) {
				$discover_groups{$discovery_name}{'method'}{$vals[1]}{'filter'}{$f_vals[1]}{'filter_id'} = $f_vals[0];
				$discover_groups{$discovery_name}{'method'}{$vals[1]}{'filter'}{$f_vals[1]}{'type'} = $f_vals[2];
				$discover_groups{$discovery_name}{'method'}{$vals[1]}{'filter'}{$f_vals[1]}{'filter'} = $f_vals[3];
			}
			$sth3->finish;

		}
		$sth2->finish;

		$sqlstmt = "select discover_filter.filter_id, discover_filter.name, discover_filter.type, discover_filter.filter from discover_filter " .
			"left join discover_group_filter on discover_filter.filter_id = discover_group_filter.filter_id " .
			"where discover_group_filter.group_id = '$values[0]'";
		$sth2 = $dbh->prepare($sqlstmt);
		$sth2->execute;
		while(my @vals = $sth2->fetchrow_array()) {
			$discover_groups{$discovery_name}{'filter'}{$vals[1]}{'filter_id'} = $vals[0];
			$discover_groups{$discovery_name}{'filter'}{$vals[1]}{'type'} = $vals[2];
			$discover_groups{$discovery_name}{'filter'}{$vals[1]}{'filter'} = $vals[3];
		}
		$sth2->finish;
	}
	$sth->finish;
	return %discover_groups;
	
}

sub get_discovery_methods() {
	my %discover_methods = ();
	my $sqlstmt = "select * from discover_method";
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		$discover_methods{$values[1]}{'id'} = $values[0];
		$discover_methods{$values[1]}{'description'} = $values[2];
		my %data = parse_xml('',$values[3]);
		foreach my $key (keys %data) {
			$discover_methods{$values[1]}{$key} = $data{$key};
		}
		$discover_methods{$values[1]}{'type'} = $values[4];
		$sqlstmt = "select discover_filter.filter_id, discover_filter.name, discover_filter.type, discover_filter.filter from discover_filter " .
			"left join discover_method_filter on discover_filter.filter_id = discover_method_filter.filter_id " .
			"where discover_method_filter.method_id = '$values[0]'";
		my $sth2 = $dbh->prepare($sqlstmt);
		$sth2->execute;
		while(my @vals = $sth2->fetchrow_array()) {
			$discover_methods{$values[1]}{'filter'}{$vals[1]}{'filter_id'} = $vals[0];
			$discover_methods{$values[1]}{'filter'}{$vals[1]}{'type'} = $vals[2];
			$discover_methods{$values[1]}{'filter'}{$vals[1]}{'filter'} = $vals[3];
		}
		$sth2->finish;
	}
	$sth->finish;
	return %discover_methods;
}

sub get_discovery_filters() {
	my %discover_filters = ();
	my $sqlstmt = "select * from discover_filter";
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		$discover_filters{$values[1]}{'id'} = $values[0];
		$discover_filters{$values[1]}{'type'} = $values[2];
		$discover_filters{$values[1]}{'filter'} = $values[3];
	}
	$sth->finish;
	return %discover_filters;
}

sub fetch_schema(@) {
	my $name = $_[1];
	my %host_name = get_table_objects('','hosts','1');
	my %hostgroup_name = get_table_objects('','hostgroups','1');
	my %group_name = get_table_objects('','monarch_groups','1');
	my %contactgroup_name = get_table_objects('','contactgroups','1');
	my %serviceprofile_name = get_table_objects('','profiles_service','1');
	my %service_name = get_table_objects('','service_names','1');

	my %schema = fetch_one('','import_schema','name',$name);
	if ($schema{'hostprofile_id'}) {
		my %profile = fetch_one('','profiles_host','hostprofile_id',$schema{'hostprofile_id'});
		$schema{'default_profile'} = $profile{'name'};
	}
	my $sqlstmt = "select * from import_column where schema_id = '$schema{'schema_id'}'";
	my $sth = $dbh->prepare($sqlstmt);
	$sth->execute;
	while(my @values = $sth->fetchrow_array()) {
		$schema{'column'}{$values[0]}{'name'} = $values[2];
		$schema{'column'}{$values[0]}{'position'} = $values[3];
		$schema{'column'}{$values[0]}{'delimiter'} = $values[4];
		$sqlstmt = "select * from import_match where column_id = $values[0]"; 
		my $sth2 = $dbh->prepare($sqlstmt);
		$sth2->execute;
		while(my @vals = $sth2->fetchrow_array()) {
			$schema{'column'}{$values[0]}{'match'}{$vals[0]}{'name'} = $vals[2];
			$schema{'column'}{$values[0]}{'match'}{$vals[0]}{'order'} = $vals[3];
			$schema{'column'}{$values[0]}{'match'}{$vals[0]}{'match_type'} = $vals[4];
			$schema{'column'}{$values[0]}{'match'}{$vals[0]}{'match_string'} = $vals[5];
			$schema{'column'}{$values[0]}{'match'}{$vals[0]}{'rule'} = $vals[6];
			$schema{'column'}{$values[0]}{'match'}{$vals[0]}{'object'} = $vals[7];
			if ($vals[8]) {
				my %host_profile = fetch_one('','profiles_host','hostprofile_id',$vals[8]);
				$schema{'column'}{$values[0]}{'match'}{$vals[0]}{'hostprofile'} = $host_profile{'name'};
			}
			if ($vals[9]) {
				my %service_name = fetch_one('','service_names','servicename_id',$vals[9]);
				$schema{'column'}{$values[0]}{'match'}{$vals[0]}{'service_name'} = $service_name{'name'};
				$schema{'column'}{$values[0]}{'match'}{$vals[0]}{'arguments'} = $vals[10]
			}

			@{$schema{'column'}{$values[0]}{'match'}{$vals[0]}{'parents'}} = ();
			$sqlstmt = "select parent_id from import_match_parent where match_id = $vals[0]";
			my $sth3 = $dbh->prepare($sqlstmt);
			$sth3->execute;
			while(my @vals2 = $sth3->fetchrow_array()) {
				push @{$schema{'column'}{$values[0]}{'match'}{$vals[0]}{'parents'}}, $host_name{$vals2[0]};
			}
			$sth3->finish;

			@{$schema{'column'}{$values[0]}{'match'}{$vals[0]}{'hostgroups'}} = ();
			$sqlstmt = "select hostgroup_id from import_match_hostgroup where match_id = $vals[0]";
			$sth3 = $dbh->prepare($sqlstmt);
			$sth3->execute;
			while(my @vals2 = $sth3->fetchrow_array()) {
				push @{$schema{'column'}{$values[0]}{'match'}{$vals[0]}{'hostgroups'}}, $hostgroup_name{$vals2[0]};
			}
			$sth3->finish;

			@{$schema{'column'}{$values[0]}{'match'}{$vals[0]}{'groups'}} = ();
			$sqlstmt = "select group_id from import_match_group where match_id = $vals[0]";
			$sth3 = $dbh->prepare($sqlstmt);
			$sth3->execute;
			while(my @vals2 = $sth3->fetchrow_array()) {
				push @{$schema{'column'}{$values[0]}{'match'}{$vals[0]}{'groups'}}, $group_name{$vals2[0]};
			}
			$sth3->finish;

			@{$schema{'column'}{$values[0]}{'match'}{$vals[0]}{'contactgroups'}} = ();
			$sqlstmt = "select contactgroup_id from import_match_contactgroup where match_id = $vals[0]";
			$sth3 = $dbh->prepare($sqlstmt);
			$sth3->execute;
			while(my @vals2 = $sth3->fetchrow_array()) {
				push @{$schema{'column'}{$values[0]}{'match'}{$vals[0]}{'contactgroups'}}, $contactgroup_name{$vals2[0]};
			}
			$sth3->finish;

			@{$schema{'column'}{$values[0]}{'match'}{$vals[0]}{'serviceprofiles'}} = ();
			$sqlstmt = "select serviceprofile_id from import_match_serviceprofile where match_id = $vals[0]";
			$sth3 = $dbh->prepare($sqlstmt);
			$sth3->execute;
			while(my @vals2 = $sth3->fetchrow_array()) {
				push @{$schema{'column'}{$values[0]}{'match'}{$vals[0]}{'serviceprofiles'}}, $serviceprofile_name{$vals2[0]};
			}
			$sth3->finish;
		}
		$sth2->finish;
	}
	$sth->finish;
	return %schema;
}

sub apply_discovery_template(@) {
	my $id = $_[1];
	my $template = $_[2];
	my $source = $_[3];
	my @errors = ();
	my $data = undef;
	open (FILE, "< $source/discover-template-$template.xml") || push @errors, "$source/discover-template-$template.xml $!";
	while (my $line = <FILE>) {
		$line =~ s/\r\n/\n/;
		$data .= $line;
	}
	close(FILE);
	my %schemas = get_table_objects('','import_schema');
	if ($data) {
		my %values = ();
		my $parser = XML::LibXML->new();
		my $doc = $parser->parse_string($data);
		my @nodes = $doc->findnodes( "//prop" );
		foreach my $node (@nodes) {
			if ($node->hasAttributes()) {
				my $property = $node->getAttribute('name');
				my $value = $node->textContent;
				$values{$property} = $value;
			}
		}
		my %group_methods = ();

		my @methods = $doc->findnodes( "//method" );
		foreach my $method (@methods) {
			my $name = undef;
			my %props = ();
			if ($method->hasChildNodes()) {
				my @nodes = $method->getChildnodes();
				foreach my $node (@nodes) {
					if ($node->hasAttributes()) {
						my $property = $node->getAttribute('name');
						my $value = $node->textContent;
						if ($property eq 'name') {
							$name = $value;
						} else {
							$props{$property} = $value;
						}
					}
				}
			}
			%{$group_methods{$name}} =  %props;
#			foreach my $prop (keys %props) {
# next statement was commented out, so commenting out entire loop
#				$group_methods{$name}{$prop} = $props{$prop};
#			}
		}
		if ($schemas{$values{'schema'}}) {
			$values{'schema_id'} = $schemas{$values{'schema'}};
		} else {
			my $data = qq(<?xml version="1.0" ?>
<data>
</data>);
			my @vals = ('',$values{'schema'},'','',$data,'','','','');
			my $schema_id = insert_obj_id('','import_schema',\@vals,'schema_id');
			if ($schema_id =~ /error/i) { 
				push @errors, $schema_id;
			} else {
				my $template = "$values{'schema'}";
				$values{'schema_id'} = $schema_id;
				$template =~ s/\s|\\|\/|\'|\"|\%|\^|\#|\@|\!|\$/-/g;
				if (-e "$source/schema-template-$template.xml") {
					my @errs = apply_automation_template('',$schema_id,$template,$source);
					if (@errs) { push (@errors,@errs) }
				}
			}
		}
		delete $values{'name'};
		delete $values{'auto'};
		delete $values{'schema'};
		
		my $result = update_obj('','discover_group','group_id',$id,\%values);
		my %discover_methods = get_table_objects('','discover_method');
		foreach my $method (keys %group_methods) {
			unless ($discover_methods{$method}) {
				my ($description,$type) = undef;
				my $config = "<?xml version=\"1.0\" ?>\n<data>";
				foreach my $prop (keys %{$group_methods{$method}}) {
					if ($prop eq 'description') {
						$description = $group_methods{$method}{$prop};
					} elsif ($prop eq 'type') {
						$type = $group_methods{$method}{$prop};
					} else {
						$config .= "\n<prop name=\"$prop\"><![CDATA[$group_methods{$method}{$prop}]]></prop>";
					}
				}
				$config .= "\n</data>";
				my @vals = ('',$method,$description,$config,$type);
				$discover_methods{$method} = insert_obj_id('','discover_method',\@vals,'method_id');
				if ($discover_methods{$method} =~ /error/i) { push @errors, $discover_methods{$method} } 
			}
			unless (@errors) {
				my @vals = ($id,$discover_methods{$method});
				my $result = insert_obj('','discover_group_method',\@vals);
				if ($result =~ /error/i) { push @errors, $result }
			}
		}
	}
	return @errors;
}


sub apply_automation_template(@) {
	my $id = $_[1];
	my $template = $_[2];
	my $source = $_[3];
	my @errors = ();
	my $data = undef;
	open (FILE, "< $source/schema-template-$template.xml") || push @errors, "$source/schema-template-$template.xml $!";
	while (my $line = <FILE>) {
		$line =~ s/\r\n/\n/;
		$data .= $line;
	}
	my %serviceprofile_name = get_table_objects('','profiles_service');
	my %hostprofile_name = get_table_objects('','profiles_host');
	my %group_name = get_table_objects('','monarch_groups');
	my %host_name = get_table_objects('','hosts');
	my %contactgroup_name = get_table_objects('','contactgroups');
	my %hostgroup_name = get_table_objects('','hostgroups');
	my %service_name = get_table_objects('','service_names');
	my %columns = ();
	if ($data) {
		use MonarchProfileImport;
		my %values = ();
		my $parser = XML::LibXML->new();
		my $doc = $parser->parse_string($data);
		my @nodes = $doc->findnodes( "//prop" );
		foreach my $node (@nodes) {
			if ($node->hasAttributes()) {
				my $property = $node->getAttribute('name');
				my $value = $node->textContent;
				if ($property eq 'default_profile') {
					unless ($hostprofile_name{$value}) {
						my $folder = '/usr/local/groundwork/profiles';
						my $file = "host-profile-$value.xml";
						if (-e "$folder/$file") {
							my @msgs = ProfileImporter->import_profile($folder,$file,'');
							my %hp = fetch_one('','profiles_host','name',$value);
							$hostprofile_name{$value} = $hp{'hostprofile_id'};
						}
					}
					if ($hostprofile_name{$value}) {
						$values{'hostprofile_id'} = $hostprofile_name{$value};
					}
				} else {
					$values{$property} = $value;
				}
			}
		}	
		my $result = update_obj('','import_schema','schema_id',$id,\%values);
		if ($result =~ /error/i) { push @errors, $result }
		my $column_key = 0;
		my $match_key = 0;
		my @columns = $doc->findnodes( "//column" );
		foreach my $column (@columns) {
			$column_key++;
			if ($column->hasChildNodes()) {
				my @nodes = $column->getChildnodes();
				foreach my $node (@nodes) {
					if ($node->hasAttributes()) {
						my $property = $node->getAttribute('name');
						my $value = $node->textContent;
						$columns{$column_key}{$property} = $value;
					} elsif ($node->hasChildNodes()) {
						my @matches = $node->getChildnodes();
						$match_key++;
						foreach my $match (@matches) {
							if ($match->hasAttributes()) {
								my $property = $match->getAttribute('name');
								my $value = $match->textContent;
								$columns{$column_key}{'match'}{$match_key}{$property} = $value;
							} elsif ($match->hasChildNodes()) {
								my @objs = $match->getChildnodes();
								my @instances = ();
								foreach my $obj (@objs) {
									if ($obj->hasAttributes()) {
										my $property = $obj->getAttribute('name');
										my $value = $obj->textContent;
										if ($property eq 'object_type') {
											if ($value eq 'Host profile') {
												$columns{$column_key}{'match'}{$match_key}{$property} = $value;
											} else {
												$columns{$column_key}{'match'}{$match_key}{$property} = $value;
												@{$columns{$column_key}{'match'}{$match_key}{$columns{$column_key}{'match'}{$match_key}{'object_type'}}} = ();
											}
										} elsif ($property eq 'service_name') {
											$columns{$column_key}{'match'}{$match_key}{'service_name'} = $value;
										} elsif ($property eq 'service_args') {
											$columns{$column_key}{'match'}{$match_key}{'service_args'} = $value;
										} else {
											if ($property eq 'hostprofile') {
												$columns{$column_key}{'match'}{$match_key}{$property} = $value;
											} else {
												push @instances, $value;
											}
										}
									}
								}
								@{$columns{$column_key}{'match'}{$match_key}{$columns{$column_key}{'match'}{$match_key}{'object_type'}}} = @instances;
							}
						}
					}
				}
			}
		}
		foreach my $column_key (keys %columns) {
			my @values = ('',$id,$columns{$column_key}{'name'},$columns{$column_key}{'position'},$columns{$column_key}{'delimiter'});
			my $column_id = insert_obj_id('','import_column',\@values,'column_id');
			if ($column_id =~ /error/i) { 
				push @errors, $column_id;
			} else {
				foreach my $match_key (keys %{$columns{$column_key}{'match'}}) {
					my $hp_name = $columns{$column_key}{'match'}{$match_key}{'hostprofile'};
					unless ($hostprofile_name{$hp_name}) {
						my $folder = '/usr/local/groundwork/profiles';
						my $file = "host-profile-$hp_name.xml";
						if (-e "$folder/$file") {
							my @msgs = ProfileImporter->import_profile($folder,$file,'');
							my %hp = fetch_one('','profiles_host','name',$hp_name);
							$hostprofile_name{$hp_name} = $hp{'hostprofile_id'};
						}
					}

					my @values = ('',$column_id,$columns{$column_key}{'match'}{$match_key}{'name'},
					$columns{$column_key}{'match'}{$match_key}{'order'},
					$columns{$column_key}{'match'}{$match_key}{'match_type'},
					$columns{$column_key}{'match'}{$match_key}{'match_string'},
					$columns{$column_key}{'match'}{$match_key}{'rule'},
					$columns{$column_key}{'match'}{$match_key}{'object_type'},
					$hostprofile_name{$columns{$column_key}{'match'}{$match_key}{'hostprofile'}},
					$service_name{$columns{$column_key}{'match'}{$match_key}{'service_name'}},
					$columns{$column_key}{'match'}{$match_key}{'service_args'});
					my $match_id = insert_obj_id('','import_match',\@values,'match_id');
					if ($match_id =~ /error/i) { 
						push @errors, $match_id;
					} else {
						if ($columns{$column_key}{'match'}{$match_key}{'object_type'} eq 'Contact group') {
							foreach my $obj (@{$columns{$column_key}{'match'}{$match_key}{'Contact group'}}) {
								if ($contactgroup_name{$obj}) {
									my @values = ($match_id,$contactgroup_name{$obj});
									my $result = insert_obj('','import_match_contactgroup',\@values);
									if ($result =~ /error/i) { push @errors, $result }
								}
							}
						}
						if ($columns{$column_key}{'match'}{$match_key}{'object_type'} eq 'Host group') {
							foreach my $obj (@{$columns{$column_key}{'match'}{$match_key}{'Host group'}}) {
								if ($hostgroup_name{$obj}) {
									my @values = ($match_id,$hostgroup_name{$obj});
									my $result = insert_obj('','import_match_hostgroup',\@values);
									if ($result =~ /error/i) { push @errors, $result }
								}
							}
						}
						if ($columns{$column_key}{'match'}{$match_key}{'object_type'} eq 'Group') {
							foreach my $obj (@{$columns{$column_key}{'match'}{$match_key}{'Group'}}) {
								if ($group_name{$obj}) {
									my @values = ($match_id,$group_name{$obj});
									my $result = insert_obj('','import_match_group',\@values);
									if ($result =~ /error/i) { push @errors, $result }
								}
							}
						}
						if ($columns{$column_key}{'match'}{$match_key}{'object_type'} eq 'Service profile') {
							foreach my $obj (@{$columns{$column_key}{'match'}{$match_key}{'Service profile'}}) {
								unless ($serviceprofile_name{$obj}) {
									my $folder = '/usr/local/groundwork/profiles';
									my $file = "service-profile-$obj.xml";
									if (-e "$folder/$file") {
										my @msgs = ProfileImporter->import_profile($folder,$file,'');
										my %sp = fetch_one('','profiles_service','name',$obj);
										$serviceprofile_name{$obj} = $sp{'serviceprofile_id'};
									}
								}
								if ($serviceprofile_name{$obj}) {
									my @values = ($match_id,$serviceprofile_name{$obj});
									my $result = insert_obj('','import_match_serviceprofile',\@values);
									if ($result =~ /error/i) { push @errors, $result }
								}	
							}
						}
						if ($columns{$column_key}{'match'}{$match_key}{'object_type'} eq 'Parent') {
							foreach my $obj (@{$columns{$column_key}{'match'}{$match_key}{'Parent'}}) {
								if ($host_name{$obj}) {
									my @values = ($match_id,$host_name{$obj});
									my $result = insert_obj('','import_match_parent',\@values);
									if ($result =~ /error/i) { push @errors, $result }
								}
							}
						}
					}
				}
			}
		}
	}
	return @errors;
}

sub get_hosts_vitals() {
	my %hosts_vitals = ();
	my $sqlstmt = "select host_id, name, address, alias from hosts";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	while (my @values = $sth->fetchrow_array()) {
		$hosts_vitals{'name'}{$values[1]} = $values[0];
		$hosts_vitals{'address'}{$values[2]} = $values[0];
		$hosts_vitals{'alias'}{$values[3]} = $values[0];
	}
	$sth->finish;
	return %hosts_vitals;
}


sub profile_sync(@) {
	my %import_data = %{$_[1]};
	my %import_host = %{$_[2]};
	my %schema = %{$_[3]}; 
	my $sqlstmt = "select name, host_id from hosts where hostprofile_id = '$schema{'hostprofile_id'}'";
	my $sth = $dbh->prepare ($sqlstmt);
	$sth->execute;
	while (my @values = $sth->fetchrow_array()) {
		unless ($import_host{$values[0]}) {
			my $rec = $values[0];
			$import_data{$rec}{'delete'} = 1;
			$import_data{$rec}{'Name'} = $values[0];
			$import_data{$rec}{'host_id'} = $values[1];
		}
	}
	$sth->finish;
	return %import_data;
}


sub parse_form_xml(@) {
	my $data = $_[1];
	my %externals = $_[2];
	if ($data) {
		my $parser = XML::LibXML->new();
		my $doc = $parser->parse_string($data);
		my @nodes = $doc->findnodes( "//external_checks/external_check" );
		foreach my $node (@nodes) {
			if ($node->hasAttributes()) {
				my $name = $node->getAttribute('name');
				my $description = $node->getAttribute('description');
				my $enable = $node->getAttribute('enable');
				if ($node->hasChildNodes()) {
					my @children = $node->getChildnodes();
					foreach my $child (@children) {
						if ($child->nodeName() eq 'service') {
							$externals{$name}{'service_name'} = $child->getAttribute('name');
						}
						if ($child->nodeName() eq 'command') {
							$externals{$name}{'command'}{'name'} = $child->getAttribute('name');
							if ($child->hasChildNodes()) {
								my @params = $child->getChildnodes();
								foreach my $param (@params) {
									if ($param->hasAttributes()) {
										my $pname = $param->getAttribute('name');
										$externals{$name}{'command'}{$pname}{'value'} = $param->textContent;
										$externals{$name}{'command'}{$pname}{'description'} = $param->getAttribute('description') if $param->hasAttributes();
									}
								}
							}
						}
					}
				}
			}
		}
	} else {
		$externals{'error'} = "Empty String (parse_xml)";
	}
	return %externals;
}


sub backup(@) {
	my $nagios = $_[1];
	my $backup = $_[2];
	my @errors = ();
	use File::Copy;
	my @files = ("$nagios/nagios.cfg");
	my @dirs = ();
	open(FILE, "< $nagios/nagios.cfg") || push @errors, "error: cannot open $nagios/nagios.cfg to read $!";
	while (my $line = <FILE>) {
		if ($line =~ /^\s*cfg_file\s*=\s*(\S+)$/) { push @files, $1 }
		if ($line =~ /^\s*cfg_dir\s*=\s*(\S+)$/) { push @dirs, $1 }
		if ($line =~ /^\s*resource_file\s*=\s*(\S+)$/) { push @files, $1 }
	}
	close(FILE);
	open(FILE, "< $nagios/cgi.cfg") || push @errors, "error: cannot open $nagios/cgi.cfg to read $!";
	while (my $line = <FILE>) {
		if ($line =~ /^\s*xedtemplate_config_file\s*=\s*(\S+)$/) { push @files, $1 }
	}
	close(FILE);
	foreach my $dir (@dirs) {
		opendir(DIR, $dir) || push @errors, "error: cannot open $dir to read $!";
		while (my $file = readdir(DIR)) {
			if ($file =~ /^#/) { next }
			if ($file =~ /(\S+\.cfg$)/) { push @files, "$dir/$1" }
		}
		close(DIR);
	}
	my $dt = StorProc->datetime();
	$dt =~ s/\s/_/g;
	$dt =~ s/:/-/g;
	mkdir("$backup/$dt", 0770) || push @errors, "Error: Unable to create folder $backup/$dt $!";
	foreach my $file (@files) {
		my $fname = undef;
		if ($file =~ /.*\/(.*\.cfg)/) { $fname = $1 }
		copy("$file","$backup/$dt/$fname") || push @errors, "Error: Unable to copy $file to $backup/$dt/$fname $!";
	}

	my $sqlfile = "$backup/$dt/monarch-$dt.sql";
	if (-e '/usr/bin/mysqldump') {
		my $mysqldump_cmd = '/usr/bin/mysqldump';
		my $err = system("$mysqldump_cmd", "--host=$dbhost", "--user=$user", "--password=$passwd", "--quick", "--add-drop-table", "--result-file=$sqlfile", "--databases", "$database");
		if ($err) { push @errors, "$mysqldump_cmd --host=$dbhost --user=$user --password=$passwd --result-file=$sqlfile db $database errno $err"  }
	} elsif (-e '/usr/local/bin/mysqldump') {
		my $mysqldump_cmd = '/usr/local/bin/mysqldump';
		my $err = system("$mysqldump_cmd", "--host=$dbhost", "--user=$user", "--password=$passwd", "--quick", "--add-drop-table", "--result-file=$sqlfile", "--databases", "$database");
		if ($err) { push @errors, "$mysqldump_cmd --host=$dbhost --user=$user --password=$passwd --result-file=$sqlfile db $database errno $err"  }
	} elsif (-e '/usr/local/groundwork/bin/mysqldump') {
		my $mysqldump_cmd = '/usr/local/groundwork/bin/mysqldump';
		my $err = system("$mysqldump_cmd", "--host=$dbhost", "--user=$user", "--password=$passwd", "--quick", "--add-drop-table", "--result-file=$sqlfile", "--databases", "$database");
		if ($err) { push @errors, "$mysqldump_cmd --host=$dbhost --user=$user --password=$passwd --result-file=$sqlfile db $database errno $err"  }
	} else {
		push @errors, "Cannot find mysqldump in /usr/bin! Unable to backup database $database.";
	}
	return "$backup/$dt/", \@errors;
}

sub property_list() {
	my %property_list = ();
	$property_list{'host_templates'} = "name,process_perf_data,retain_status_information,flap_detection_enabled,low_flap_threshold,high_flap_threshold,".
	"retain_nonstatus_information,checks_enabled,active_checks_enabled,passive_checks_enabled,check_period,obsess_over_host,check_freshness,freshness_threshold,".
	"check_command,command_line,max_check_attempts,check_interval,event_handler_enabled,event_handler,notifications_enabled,".
	"notification_interval,notification_period,notification_options,stalking_options,contactgroup";

	$property_list{'host_overrides'} = "process_perf_data,retain_status_information,flap_detection_enabled,low_flap_threshold,high_flap_threshold,".
	"retain_nonstatus_information,checks_enabled,active_checks_enabled,passive_checks_enabled,check_period,obsess_over_host,check_freshness,freshness_threshold,check_command,command_line,max_check_attempts,check_interval,event_handler_enabled,event_handler,notifications_enabled,".
	"notification_interval,notification_period,notification_options,stalking_options";

	$property_list{'hosts'} = "name,alias,address,template,parents,checks_enabled,check_command,command_line,max_check_attempts,event_handler_enabled,event_handler,".
	"flap_detection_enabled,process_perf_data,retain_status_information,retain_nonstatus_information,notifications_enabled,notification_interval,".
	"notification_period,notification_options,stalking_options";

	$property_list{'host_dependencies'} = "dependent_host,parent_host,inherits_parent,execution_failure_criteria,notification_failure_criteria";

	$property_list{'extended_host_info_templates'} = "name,notes,notes_url,action_url,icon_image,icon_image_alt,vrml_image,statusmap_image,2d_coords,3d_coords";
	$property_list{'extended_host_info'} = "host_name,notes,notes_url,action_url,template,2d_coords,3d_coords";
	$property_list{'extended_service_info_templates'} = "name,notes,notes_url,action_url,icon_image,icon_image_alt";
	$property_list{'extended_service_info'} = "template,service_description,host_name,notes,notes_url,action_url";

	$property_list{'hostgroups'} = "name,alias,members,contactgroup,host_escalation_id,service_escalation_id";

	$property_list{'service_templates'} = "name,template,is_volatile,check_period,max_check_attempts,normal_check_interval,retry_check_interval,".
	"active_checks_enabled,passive_checks_enabled,parallelize_check,obsess_over_service,check_freshness,freshness_threshold,notifications_enabled,notification_interval,".
	"notification_period,notification_options,event_handler_enabled,event_handler,flap_detection_enabled,low_flap_threshold,high_flap_threshold,process_perf_data,".
	"retain_status_information,retain_nonstatus_information,check_command,command_line,contactgroup";

	$property_list{'service_overrides'} = "is_volatile,check_period,max_check_attempts,normal_check_interval,retry_check_interval,".
	"active_checks_enabled,passive_checks_enabled,parallelize_check,obsess_over_service,check_freshness,freshness_threshold,notifications_enabled,notification_interval,".
	"notification_period,notification_options,event_handler_enabled,event_handler,flap_detection_enabled,low_flap_threshold,high_flap_threshold,process_perf_data,".
	"retain_status_information,retain_nonstatus_information";


	$property_list{'services'} = "name,template,host_name,is_volatile,check_period,max_check_attempts,normal_check_interval,retry_check_interval,".
	"active_checks_enabled,passive_checks_enabled,parallelize_check,obsess_over_service,check_freshness,freshness_threshold,notifications_enabled,notification_interval,".
	"notification_period,notification_options,event_handler_enabled,event_handler,flap_detection_enabled,low_flap_threshold,high_flap_threshold,process_perf_data,".
	"retain_status_information,retain_nonstatus_information,check_command,contactgroup";

	$property_list{'service_dependency_templates'} = "name,service_name,execution_failure_criteria,notification_failure_criteria";
	$property_list{'service_dependency'} = "service_name,host_name,depend_on_host,template";
	$property_list{'contact_templates'} = "name,host_notification_period,service_notification_period,host_notification_options,service_notification_options,".
	"host_notification_commands,service_notification_commands";
	$property_list{'contacts'} = "name,template,alias,email,pager";
	$property_list{'contactgroups'} = "name,alias,contact";
	$property_list{'hostgroup_escalation_templates'} = "name,contactgroup,type,first_notification,last_notification,notification_interval,escalation_period,escalation_options"; 
	$property_list{'host_escalation_templates'} = "name,type,first_notification,last_notification,notification_interval,escalation_period,escalation_options"; 
	$property_list{'service_escalation_templates'} = "name,type,first_notification,last_notification,notification_interval,escalation_period,escalation_options";
	$property_list{'time_periods'} = "name,alias,sunday,monday,tuesday,wednesday,thursday,friday,saturday";
	$property_list{'commands'} = "name,type,command_line";
	$property_list{'escalation_templates'} = "name,first_notification,last_notification,notification_interval,escalation_period,escalation_options"; 
	$property_list{'servicegroups'} = "name,alias,escalation_id";

	$property_list{'profiles_host'} = "name,description,host_template_id,host_extinfo_id,host_escalation_id,service_escalation_id,serviceprofile_id";
	$property_list{'profiles_service'} = "name,description";
	$property_list{'service_names'} = "name,description,template,check_command,command_line,dependency,escalation,extinfo";
	$property_list{'servicename_overrides'} = "is_volatile,check_period,max_check_attempts,normal_check_interval,retry_check_interval,".
	"active_checks_enabled,passive_checks_enabled,parallelize_check,obsess_over_service,check_freshness,freshness_threshold,notifications_enabled,notification_interval,".
	"notification_period,notification_options,event_handler_enabled,event_handler,flap_detection_enabled,low_flap_threshold,high_flap_threshold,process_perf_data,".
	"retain_status_information,retain_nonstatus_information";


	return %property_list;
}

sub db_values() {
	my %db_values = ();
	$db_values{'time_periods'} = "name,alias,data,comment";
	$db_values{'commands'} = "name,type,data,comment";
	$db_values{'contactgroups'} = "name,alias,comment";
	$db_values{'contact_templates'} = "name,host_notification_period,service_notification_period,data,comment";
	$db_values{'contacts'} = "name,alias,email,pager,contacttemplate_id,status,comment";
	$db_values{'hosts'} = "name,alias,address,os,hosttemplate_id,hostextinfo_id,hostprofile_id,host_escalation_id,service_escalation_id,status,comment";
	$db_values{'host_overrides'} = "check_period,notification_period,check_command,event_handler,data";
	$db_values{'host_templates'} = "name,check_period,notification_period,check_command,event_handler,data,comment";
	$db_values{'hostgroups'} = "name,alias,hostprofile_id,host_escalation_id,service_escalation_id,status,comment";
	$db_values{'service_templates'} = "name,parent_id,check_period,notification_period,check_command,command_line,event_handler,data,comment";
	$db_values{'service_overrides'} = "check_period,notification_period,event_handler,data";
	$db_values{'services'} = "name,host_name,template,data,comment";
	$db_values{'extended_host_info_templates'} = "name,data,script,comment";
	$db_values{'extended_info_coords'} = "data";
	$db_values{'extended_service_info_templates'} = "name,data,script,comment";
	$db_values{'host_dependencies'} = "host_id,parent_id,data,comment";
	$db_values{'service_dependency'} = "servicename_id,host_name,depend_on_host,template,comment";
	$db_values{'service_dependency_templates'} = "name,servicename_id,data,comment";
	$db_values{'stage_hosts'} = "name,userid,type,status,alias,address,os,info";
	$db_values{'stage_host_services'} = "name,userid,type,status,host,info";
	$db_values{'escalation_templates'} = "name,type,data,comment,escalation_period";
	$db_values{'profiles_host'} = "name,description,host_template_id,host_extinfo_id,host_escalation_id,service_escalation_id";
	$db_values{'profiles_service'} = "name,description";
	$db_values{'service_names'} = "name,description,template,check_command,command_line,escalation,extinfo,data";
	$db_values{'servicename_overrides'} = "check_period,notification_period,event_handler,data";
	return %db_values;
}

sub table_by_object(@) {
	my $obj = $_[1];
	my %table_by_object = (
		'hosts'    			=> 'contactgroup_host',
		'monarch_group'    	=> 'contactgroup_group',
		'services'          => 'contactgroup_service',
		'host_templates'  	=> 'contactgroup_host_template',
		'service_templates' => 'contactgroup_service_template',
		'host_profiles'     => 'contactgroup_host_profile',
		'service_names'   	=> 'contactgroup_service_name',
		'hostgroups'       	=> 'contactgroup_hostgroup',
	);
	return $table_by_object{$obj};
}

sub get_obj_id() {
	my %obj_id = (
		'hosts'                           => 'host_id',
		'hostgroups'                      => 'hostgroup_id',
		'host_templates'                  => 'hosttemplate_id',
		'host_dependencies'               => 'host_id',
		'host_escalation_templates'       => 'template_id',
		'hostgroup_escalation_templates'  => 'template_id',
		'extended_host_info_templates'    => 'hostextinfo_id',
		'services'                        => 'service_id',
		'servicegroups'                   => 'servicegroup_id',
		'service_templates'               => 'servicetemplate_id',
		'service_dependency'              => 'id',
		'service_dependency_templates'    => 'id',
		'service_escalation_templates'    => 'template_id',
		'extended_service_info_templates' => 'serviceextinfo_id',
		'commands'                        => 'command_id',
		'time_periods'                    => 'timeperiod_id',
		'contacts'                        => 'contact_id',
		'contactgroups'                   => 'contactgroup_id',
		'contact_templates'               => 'contacttemplate_id',
		'escalation_templates'            => 'template_id',
		'escalation_trees'                => 'tree_id',
		'contactgroup_host'               => 'host_id',
		'contactgroup_group'              => 'group_id',
		'contactgroup_service'            => 'service_id',
		'contactgroup_host_template'      => 'hosttemplate_id',
		'contactgroup_service_template'   => 'servicetemplate_id',
		'contactgroup_host_profile'       => 'hostprofile_id',
		'contactgroup_service_name'       => 'servicename_id',
		'contactgroup_hostgroup'          => 'hostgroup_id');
	return %obj_id;
}

1;


