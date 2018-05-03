# MonArch - Groundwork Monitor Architect
# MonarchForms.pm
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
use MonarchInstrument;
package Forms;

my $doc_root_monarch = "/monarch";
my $cgi_dir = '/cgi-bin';
my $form_class = 'row1';
my $form_subclass = '$form_class';
my $global_cell_pad = 3;
my $cgi_exe = 'monarch.cgi';
if (-e "/usr/local/groundwork/config/db.properties") {
	$cgi_dir = '/monarch/cgi-bin';
}

my $image_dir = "$doc_root_monarch/images";
my $download_dir = "$doc_root_monarch/download";
my $extend_page = '<br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/><br/>';
sub members(@) {
	my $title = $_[1];
	my $name = $_[2];
	my $members = $_[3];
	my $nonmembers = $_[4];
	my $req = $_[5];
	my $size = $_[6];
	my $doc = $_[7];
	my $override = $_[8];
	my $tab = $_[9];
	if (!$size) { $size = 15 }
	if ($req) {	$req = "<td class=$form_class valign=top><font color=#CC0000>&nbsp;* required</font></td>" }
	my @members = @{$members};
	my @nonmembers = @{$nonmembers};
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>);
	if ($override) {
		if ($override eq 'checked') {
			$detail .= "\n<td class=$form_class width=2% valign=top><input class=$form_class type=checkbox name=$name\_override checked></td>";
		} else {
			$detail .= "\n<td class=$form_class width=2% valign=top><input class=$form_class type=checkbox name=$name\_override></td>";
		}
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<td class=$form_class valign=top width=25%>$title</td>);
	if ($doc) {
		$detail .= "\n<td class=$form_class width=3% valign=top align=center>\n<a class=orange href=#doc title=\"$doc\" tabindex=-1>&nbsp;?&nbsp;</a>";
	} else {
		$detail .= "\n<td class=$form_class width=3% align=center>\n&nbsp;";
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</td>
<td class=$form_class>
<table cellspacing=0 align=left border=0>
<tr>
<td class=$form_class align=left>
<select name=$name id=members size=$size multiple tabindex=@{[$tab++]}>);
	@members = sort { lc($a) cmp lc($b) } @members;
	foreach my $mem (@members) {
		$detail .= "\n<option value=\"$mem\">$mem</option>";
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</select>
</td>
<td class=$form_class cellpadding=$global_cell_pad align=left>
<table cellspacing=0 cellpadding=3 align=center border=0>
<tr>
<td class=$form_class align=center>
<input class=submitbutton type=button value="Remove >>" onclick="delIt();" tabindex=@{[$tab++]}>
</td>
<tr>
<td class=$form_class align=center>
<input class=submitbutton type=button value="&nbsp;&nbsp;<< Add&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;" onclick="addIt();"  tabindex=@{[$tab++]}>
</td>
</tr>
</table>
</td>
<td class=$form_class align=left>
<select name=nonmembers id=nonmembers size=$size multiple tabindex=@{[$tab++]}>);
	my $got_mem = undef;
	@nonmembers = sort { lc($a) cmp lc($b) } @nonmembers;
	foreach my $nmem (@nonmembers) {
		foreach my $mem(@members) {
			if ($nmem eq $mem) { $got_mem = 1 }
		}
		if ($got_mem) {
			$got_mem = undef;
			next;
		} else {
			$detail .= "\n<option value=\"$nmem\">$nmem</option>";
		}
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</select>
</td>
$req	
</td>
</tr>
</table>
</td>
</tr>
</table>
</td>
</tr>);
	return $detail;
}



sub hidden(@) {
	my $hidden = $_[1];
	my %hidden = %{$hidden};
	my $detail = undef;
	foreach my $key (sort keys %hidden) {
		if ($hidden{$key}) {
			$detail .= "\n<input type=hidden name=\"$key\" value=\"$hidden{$key}\">";
		}
	}
	return $detail;
}

sub checkbox(@) {
	my $title = $_[1];
	my $name = $_[2];
	my $value = $_[3];
	my $doc = $_[4];
	my $override = $_[5];
	my $tab = $_[6];
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>);
	if ($override) {
		if ($override eq 'checked') {
			$detail .= "\n<td class=$form_class width=2% valign=top><input class=$form_class type=checkbox name=$name\_override checked></td>";
		} else {
			$detail .= "\n<td class=$form_class width=2% valign=top><input class=$form_class type=checkbox name=$name\_override></td>";
		}
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<td class=$form_class width=25%>$title</td>);
	if ($doc) {
		$detail .= "\n<td class=$form_class width=3% valign=top align=center>\n<a class=orange href=#doc title=\"$doc\" tabindex=-1>&nbsp;?&nbsp;</a>";
	} else {
		$detail .= "</td>\n<td class=$form_class width=3% align=center>\n&nbsp;";
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</td>
<td class=$form_class>);
	if ($value == 1) {
		$detail .= "\n<input class=$form_class type=checkbox name=$name value=1 checked tabindex=$tab>";
	} else {
		$detail .= "\n<input class=$form_class type=checkbox name=$name value=1 tabindex=$tab>";
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</td>
</tr>
</table>
</td>
</tr>);
	return $detail;
}

sub checkbox_override(@) {
	my $title = $_[1];
	my $name = $_[2];
	my $value = $_[3];
	my $doc = $_[4];
	my $tab = $_[5];
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class width=2% align=left>);
	if ($value) {
		$detail .= "\n<input class=$form_class type=checkbox name=$name checked onClick=\"submit()\" tabindex=$tab>";
	} else {
		$detail .= "\n<input class=$form_class type=checkbox name=$name onClick=\"submit()\" tabindex=$tab>";
	} 
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</td>
<td class=$form_class width=23% align=left>$title</td>);
	if ($doc) {
		$detail .= "\n<td class=$form_class valign=top align=left>\n<a class=orange href=#doc title=\"$doc\" tabindex=-1>&nbsp;?&nbsp;</a>";
	} else {
		$detail .= "</td>\n<td class=$form_class width=3% align=left>\n&nbsp;";
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</tr>
</table>
</td>
</tr>);
	return $detail;
}


sub checkbox_left(@) {
	my $title = $_[1];
	my $name = $_[2];
	my $value = $_[3];
	my $override = $_[4];
	my $tab = $_[5];
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class width=25% align=right>);
	if ($value == 1) {
		$detail .= "\n<input class=$form_class type=checkbox name=$name value=1 checked tabindex=$tab>";
	} else {
		$detail .= "\n<input class=$form_class type=checkbox name=$name value=1 tabindex=$tab>";
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</td>
<td class=$form_class>$title</td>
</tr>
</table>
</td>
</tr>);
	return $detail;
}

sub checkbox_list(@) {
	my $title = $_[1];
	my $name = $_[2];
	my $list = $_[3];
	my @list = @{$list};
	my $selected = $_[4];
	my $req = $_[5];
	my $doc = $_[6];
	my $override = $_[7];
	my $tab = $_[8];
	if ($req) {	$req = "<font color=#CC0000>&nbsp;* required</font>" }
	my @selected = @{$selected};
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>);
	if ($override) {
		if ($override eq 'checked') {
			$detail .= "\n<td class=$form_class width=2% valign=top><input class=$form_class type=checkbox name=$name\_override checked tabindex=$tab></td>";
		} else {
			$detail .= "\n<td class=$form_class width=2% valign=top><input class=$form_class type=checkbox name=$name\_override tabindex=$tab></td>";
		}
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<td class=$form_class width=25% valign=top>$title $req</td>);
	if ($doc) {
		$detail .= "\n<td class=$form_class width=3% valign=top align=center>\n<a class=orange href=#doc title=\"$doc\" tabindex=-1>&nbsp;?&nbsp;</a>";
	} else {
		$detail .= "\n<td class=$form_class width=3% align=center>\n&nbsp;";
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</td>
<td class=$form_class>);
	my $got_selected = undef;
	foreach my $item (@list) {
		my $title = $item;
		$title =~ s/_/ /g;
		foreach my $selected(@selected) {
			if ($item eq $selected) { $got_selected = 1 }
		}
		if ($got_selected) {
			$got_selected = undef;
			$detail .= "\n<input class=$form_class type=checkbox name=$name value=\"$item\" checked tabindex=$tab>&nbsp;\u$title<br>";
		} else {
			$detail .= "\n<input class=$form_class type=checkbox name=$name value=\"$item\" tabindex=$tab>&nbsp;\u$title<br>";
		}
		$tab++;
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</td>
</tr>
</table>
</td>
</tr>);	
	return $detail;
}

sub list_box_multiple(@) {
	my $title = $_[1];
	my $name = $_[2];
	my $list = $_[3];
	my @list = @{$list};
	my $selected = $_[4];
	my $req = $_[5];
	my $doc = $_[6];
	my $override = $_[7];
	my $tab = $_[8];
	if ($req) {	$req = "<td class=$form_class valign=top><font color=#CC0000>&nbsp;* required</font></td>" }
	my @selected = @{$selected};
	my $display = $title;
	$display =~ s/://g;
	if ($display =~ /^use$/i) { $display = "template" }
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>);
	if ($override) {
		if ($override eq 'checked') {
			$detail .= "\n<td class=$form_class width=2% valign=top><input class=$form_class type=checkbox name=$name\_override checked></td>";
		} else {
			$detail .= "\n<td class=$form_class width=2% valign=top><input class=$form_class type=checkbox name=$name\_override></td>";
		}
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<td class=$form_class valign=top width=25%>$title</td>);
	if ($doc) {
		$detail .= "\n<td class=$form_class width=3% valign=top align=center>\n<a class=orange href=#doc title=\"$doc\" tabindex=-1>&nbsp;?&nbsp;</a>";
	} else {
		$detail .= "\n<td class=$form_class width=3% align=center>\n&nbsp;";
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<td class=$form_class>
<table cellspacing=0 align=left border=0>
<tr>
<td class=$form_class>
<select name=$name size=7 multiple tabindex=$tab>);
	if (!$list[0]) { 
		$detail .= "\n<option selected value=></option>";
		$detail .= "\n<option value=>-no \L$display"."s-</option>";
	} else {
		if (!$selected[0]) {
			$detail .= "\n<option selected value=></option>";
		} else {
			$detail .= "\n<option value=></option>";
		}
		my $got_selected = undef;
		@list = sort { lc($a) cmp lc($b) } @list;
		foreach my $item (@list) {
			foreach my $selected(@selected) {
				if ($item eq $selected) { $got_selected = 1 }
			}
			if ($got_selected) {
				$got_selected = undef;
				$detail .= "\n<option selected value=\"$item\">$item</option>";
			} else {
				$detail .= "\n<option value=\"$item\">$item</option>";
			}
		}
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</select>
 $req
</td>
</tr>
</table>
</td>
</tr>
</table>
</td>
</tr>);
	return $detail;
}

sub list_box(@) {
	my $title = $_[1];
	my $name = $_[2];
	my $list = $_[3];
	my $selected = $_[4];
	my $req = $_[5];
	my $doc = $_[6];
	my $override = $_[7];
	my $tab = $_[8];
	if ($req) {	$req = "<font color=#CC0000>&nbsp;* required</font>" }
	my @list = @{$list};
	my $display = $title;
	$display =~ s/://g;
	if ($display =~ /^use$/i) { $display = "template" }
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>);
	if ($override) {
		if ($override eq 'checked') {
			$detail .= "\n<td class=$form_class width=2% valign=top><input class=$form_class type=checkbox name=$name\_override checked></td>";
		} else {
			$detail .= "\n<td class=$form_class width=2% valign=top><input class=$form_class type=checkbox name=$name\_override></td>";
		}
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<td class=$form_class width=25%>$title</td>);
	if ($doc) {
		$detail .= "\n<td class=$form_class width=3% valign=top align=center>\n<a class=orange href=#doc title=\"$doc\" tabindex=-1>&nbsp;?&nbsp;</a>";
	} else {
		$detail .= "\n<td class=$form_class width=3% align=center>\n&nbsp;";
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<td class=$form_class align=left>
<select name=$name tabindex=$tab> $req);
	if (!$list[0]) { 
		$detail .= "\n<option selected value=></option>";
		$detail .= "\n<option value=>-no \L$display"."s-</option>";
	} else {
		if ($selected) {
			$detail .= "\n<option value=></option>";
		} else {
			$detail .= "\n<option selected value=></option>";
		}
		@list = sort { lc($a) cmp lc($b) } @list;
		foreach my $item (@list) {
			if ($item eq $selected) {
				$detail .= "\n<option selected value=\"$item\">$item</option>";			
			} else {
				$detail .= "\n<option value=\"$item\">$item</option>";
			}
		}
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</select>$req
</td>
</tr>
</table>
</td>
</tr>);
	return $detail;
}

sub list_box_submit(@) {
	my $title = $_[1];
	my $name = $_[2];
	my $list = $_[3];
	my $selected = $_[4];
	my $req = $_[5];
	my $doc = $_[6];
	my $tab = $_[7];
	if ($req) {	$req = "<font color=#CC0000>&nbsp;* required</font>" }
	my @list = @{$list};
	my $display = $title;
	$display =~ s/://g;
	if ($display =~ /^use$/i) { $display = "template" }
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class width=25%>$title</td>);
	if ($doc) {
		$detail .= "\n<td class=$form_class width=3% valign=top align=center>\n<a class=orange href=#doc title=\"$doc\" tabindex=-1>&nbsp;?&nbsp;</a>";
	} else {
		$detail .= "\n<td class=$form_class width=3% align=center>\n&nbsp;";
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<td class=$form_class align=left>
<select name=$name onChange="submit()" tabindex=$tab> $req);
	if (!$list[0]) { 
		$detail .= "\n<option selected value=></option>";
		$detail .= "\n<option value=>-no \L$display"."s-</option>";
	} else {
		if ($selected) {
			$detail .= "\n<option value=></option>";
		} else {
			$detail .= "\n<option selected value=></option>";
		}
		@list = sort { lc($a) cmp lc($b) } @list;
		foreach my $item (@list) {
			if ($item eq $selected) {
				$detail .= "\n<option selected value=\"$item\">$item</option>";			
			} else {
				$detail .= "\n<option value=\"$item\">$item</option>";
			}
		}
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</select>$req
</td>
</tr>
</table>
</td>
</tr>);
	return $detail;
}

sub command_test() {
	my $results = $_[1];
	my $host = $_[2];
	my $args = $_[3];
	my $service_desc = $_[4];
	my $tab = $_[5];
	unless ($results) { $results = "$args<br/>" }
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=5 cellspacing=0 align=left border=0>
<tr>
<td class=$form_class valign=top width=15%>
Test:
</td>
<td class=$form_class width=84%>
Host:&nbsp;&nbsp;<input type=text size=50 name=host value="$host">
</td>
<td class=$form_class width=1% align=center>&nbsp;</td>
</tr>
<tr>
<td class=$form_class valign=top width=15%>
&nbsp;
</td>
<td class=$form_class width=84%>
Arguments:&nbsp;&nbsp;<input type=text size=60 name=arg_string value="$args">
</td>
<td class=$form_class width=1% align=center>&nbsp;</td>
</tr>
<tr>
<td class=$form_class valign=top width=15%>
&nbsp;
</td>
<td class=$form_class width=84%>
Service description:&nbsp;&nbsp;<input type=text size=60 name=service_desc value="$service_desc">
</td>
<td class=$form_class width=1% align=center>&nbsp;</td>
</tr>
<tr>
<td class=$form_class width=15% align=center>
<input class=submitbutton type=submit name=test_command value="Test">
</td>
<td class=data valign=top width=84% align=left>
$results
</td>
<td class=$form_class width=1%>&nbsp;</td>
</tr>
<tr>
<td class=$form_class colspan=4>
&nbsp;
</td>
</tr>
</table>
</td>
</tr>);
	return $detail;
}

sub test_service_check() {
	my $results = $_[1];
	my $host = $_[2];
	my $args = $_[3];
	my $tab = $_[4];
	unless ($results) { $results = "$args<br/>" }
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=5 cellspacing=0 align=left border=0>
<tr>
<td class=$form_class valign=top width=15%>
Test:
</td>
<td class=$form_class width=84%>
Host:&nbsp;&nbsp;<input type=text size=50 name=host value="$host">
</td>
<td class=$form_class width=1% align=center>&nbsp;</td>
</tr>
<tr>
<td class=$form_class width=15% align=center>
<input class=submitbutton type=submit name=test_command value="Test">
</td>
<td class=data valign=top width=84% align=left>
$results
</td>
<td class=$form_class width=1%>&nbsp;</td>
</tr>
<tr>
<td class=$form_class colspan=4>
&nbsp;
</td>
</tr>
</table>
</td>
</tr>);
	return $detail;
}

sub command_select() {
	my $list = $_[1];
	my $selected = $_[2];
	my $tab = $_[3];
	my @list = @{$list};
	my %selected = %{$selected};

	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>);
	my $temp = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=$form_class width=5%>
<input type=radio class=radio name=task value=new_plugin $selected{'d'}>
</td>
<td class=$form_class>
Install plugin
</td>
<td class=$form_class>
&nbsp;
</td>
</tr>);
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=$form_class width=5%>
<input type=radio class=radio name=task value=resource $selected{'d'}>
</td>
<td class=$form_class>
New comand from an existing plugin
</td>
<td class=$form_class>
&nbsp;
</td>
</tr>
<tr>
<td class=$form_class width=5%>
<input type=radio class=radio name=task value=copy $selected{'d'}>
</td>
<td class=$form_class>
Clone a command:
</td>
<td class=$form_class align=left>
<select name=source>);
	if (!$list[0]) { 
		$detail .= "\n<option selected value=></option>";
		$detail .= "\n<option value=>-no check commands-</option>";
	} else {
		if ($selected) {
			$detail .= "\n<option value=></option>";
		} else {
			$detail .= "\n<option selected value=></option>";
		}
		@list = sort { lc($a) cmp lc($b) } @list;
		foreach my $item (@list) {
			if ($item eq $selected) {
				$detail .= "\n<option selected value=\"$item\">$item</option>";			
			} else {
				$detail .= "\n<option value=\"$item\">$item</option>";
			}
		}
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</select>
</td>
</tr>	


);


	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</tr>
</table>
</td>
</tr>);
	return $detail;

}

sub display_hidden(@) {
	my $title = $_[1];
	my $name = $_[2];
	my $value = $_[3];
	my $doc = $_[4];
	my $parent = $_[5];
	if ($parent) { $form_class = 'parent'}
	my $display = $value;
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class width=25% valign=top>$title</td>);
	if ($doc) {
		$detail .= "\n<td class=$form_class width=3% valign=top align=center>\n<a class=orange href=#doc title=\"$doc\" tabindex=-1>&nbsp;?&nbsp;</a>";
	} else {
		$detail .= "\n<td class=$form_class width=3% align=center>\n&nbsp;";
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</td>
<td class=$form_class>$display
<input type=hidden name=$name value="$value">
</td>
</tr>
</table>
</td>
</tr>);
	return $detail;
}


sub text_box(@) {
	my $title = $_[1];
	my $name = $_[2];
	my $value = $_[3];
	my $size = $_[4];
	my $req = $_[5];
	my $doc = $_[6];
	my $override = $_[7];
	my $tab = $_[8];
	if (!$size) { $size = 50 }
	if ($req) {	$req = "<font color=#CC0000>&nbsp;* required</font>" }
	$value =~ s/</&lt;/g;
	$value =~ s/>/&gt;/g;
	$value =~ s/\"/&quot;/g;
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>);
	if ($override) {
		if ($override eq 'checked') {
			$detail .= "\n<td class=$form_class width=2% valign=top><input class=$form_class type=checkbox name=$name\_override checked></td>";
		} else {
			$detail .= "\n<td class=$form_class width=2% valign=top><input class=$form_class type=checkbox name=$name\_override></td>";
		}
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<td class=$form_class width=25%>$title</td>);
	if ($doc) {
		$detail .= "\n<td class=$form_class width=3% valign=top align=center>\n<a class=orange href=#doc title=\"$doc\" tabindex=-1>&nbsp;?&nbsp;</a>";
	} else {
		$detail .= "\n<td class=$form_class width=3% align=center>\n&nbsp;";
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</td>
<td class=$form_class>
<input type=text size=$size name=$name value="$value" tabindex=$tab>$req
</td>
</tr>
</table>
</td>
</tr>);
	return $detail;
}

sub password_box(@) {
	my $title = $_[1];
	my $name = $_[2];
	my $size = $_[3];
	my $req = $_[4];
	if (!$size) { $size = 50 }
	if ($req) {	$req = "<font color=#CC0000>&nbsp;* required</font>" }
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class width=25%>$title</td>
<td class=$form_class width=3% align=center>&nbsp;</td>
<td class=$form_class>
<input type=password size=$size name=$name value=>$req
</td>
</tr>
</table>
</td>
</tr>);
	return $detail;
}

sub text_area(@) {
	my $title = $_[1];
	my $name = $_[2];
	my $value = $_[3];
	my $rows = $_[4];
	my $size = $_[5];
	my $req = $_[6];
	my $doc = $_[7];
	my $override = $_[8];
	my $tab = $_[9];
	if (!$rows) { $rows = 3 }
	if (!$size) { $size = 40 }
	if ($req) {	$req = "<font color=#CC0000>&nbsp;* required</font>" }
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>);
	if ($override) {
		if ($override eq 'checked') {
			$detail .= "\n<td class=$form_class width=2% valign=top><input class=$form_class type=checkbox name=$name\_override checked></td>";
		} else {
			$detail .= "\n<td class=$form_class width=2% valign=top><input class=$form_class type=checkbox name=$name\_override></td>";
		}
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<td class=$form_class valign=top width=25%>$title</td>);
	if ($doc) {
		$detail .= "\n<td class=$form_class width=3% valign=top align=center>\n<a class=orange href=#doc title=\"$doc\" tabindex=-1>&nbsp;?&nbsp;</a>";
	} else {
		$detail .= "\n<td class=$form_class width=3% align=center>\n&nbsp;";
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</td>
<td class=$form_class>
<textarea name=$name rows=$rows cols=$size wrap=virtual tabindex=$tab>$value</textarea>$req
</td>
</tr>
</table>
</td>
</tr>);
	return $detail;
}


sub stalking_options(@) {
	my $selected = $_[1];
	my $req = $_[2];
	my $doc = $_[3];
	my $override = $_[4];
	my $tab = $_[5];
	if ($req) {	$req = "<font color=#CC0000>&nbsp;* required</font>" }
	my @selected = @{$selected};
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>);
	if ($override) {
		if ($override eq 'checked') {
			$detail .= "\n<td class=$form_class width=2% valign=top><input class=$form_class type=checkbox name=stalking_options_override value=1 checked></td>";
		} else {
			$detail .= "\n<td class=$form_class width=2% valign=top><input class=$form_class type=checkbox name=stalking_options\_override value=1></td>";
		}
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<td class=$form_class width=25% valign=top>Stalking options: $req</td>);
	if ($doc) {
		$detail .= "\n<td class=$form_class width=3% valign=top align=center>\n<a class=orange href=#doc title=\"$doc\" tabindex=-1>&nbsp;?&nbsp;</a>";
	} else {
		$detail .= "\n<td class=$form_class width=3% align=center>\n&nbsp;";
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</td>
<td class=$form_class>);
	my @opts = ('d','o','u');
	my $desc = undef;
	foreach my $opt (@opts) {
		if ($opt =~ 'd') {
			$desc = 'down';
		} elsif ($opt =~ 'o') {
			$desc = 'up';
		} elsif ($opt =~ 'u') {
			$desc = 'unreachable';
		}
		my $got_opt = undef;
		foreach my $sel (@selected) {
			if ($sel eq $opt) {	$got_opt = 1 }	
		}
		if ($got_opt) {
			$detail .= "\n<input class=$form_class type=checkbox name=stalking_options value=$opt checked>&nbsp;\u$desc $req<br>";
		} else {
			$detail .= "\n<input class=$form_class type=checkbox name=stalking_options value=$opt>&nbsp;\u$desc $req<br>";
		}
		$req = undef;
		$tab++;
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</td>
</tr>
</table>
</td>
</tr>);
	return $detail;
}

sub notification_options(@) {
	my $obj = $_[1];
	my $name = $_[2];
	my $selected = $_[3];
	my $req = $_[4];
	my $nagios_ver = $_[5];
	my $doc = $_[6];
	my $override = $_[7];
	my $tab = $_[8];
	if ($req) {	$req = "<font color=#CC0000>&nbsp;* required</font>" }
	my @selected = @{$selected};
	my $title = $name;
	$title =~ s/_/ /g;
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>);
	if ($override) {
		if ($override eq 'checked') {
			$detail .= "\n<td class=$form_class width=2% valign=top><input class=$form_class type=checkbox name=$name\_override checked></td>";
		} else {
			$detail .= "\n<td class=$form_class width=2% valign=top><input class=$form_class type=checkbox name=$name\_override></td>";
		}
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<td class=$form_class width=25% valign=top>\u$title:</td>);
	if ($doc) {
		$detail .= "\n<td class=$form_class width=3% valign=top align=center>\n<a class=orange href=#doc title=\"$doc\" tabindex=-1>&nbsp;?&nbsp;</a>";
	} else {
		$detail .= "\n<td class=$form_class width=3% align=center>\n&nbsp;";
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</td>
<td class=$form_class>);
	my @opts = ();
	if ($obj =~ /service_escalation/) {
		@opts = ('r','w','u','c');
	} elsif ($obj =~ /escalation/) {
		@opts = ('r','d','u');
	} elsif ($obj =~ /contact/ && $name =~ /service/) {
		@opts = ('u','c','w','r','n');
		if ($nagios_ver =~ /^[23]\.x$/) { push @opts, 'f' }
	} elsif ($obj =~ /contact/ && $name =~ /host/) {
		@opts = ('d','u','r','n');
		if ($nagios_ver =~ /^[23]\.x$/) { push @opts, 'f' }
	} elsif ($obj =~ /service/) {
		@opts = ('u','c','w','r','n');
		if ($nagios_ver =~ /^[23]\.x$/) { push @opts, 'f' }
	} elsif ($obj =~ /host/) {
		@opts = ('d','u','r');
		if ($nagios_ver =~ /^[23]\.x$/) { push @opts, 'f' }
	}
	my $desc = undef;
	foreach my $opt (@opts) {
		if ($opt =~ 'd') {
			$desc = 'down';
		} elsif ($opt eq 'u') {
			$desc = 'unreachable';
			if ($obj  =~ /service/) { $desc = 'unknown' }
			if ($obj =~ /contact/ && $name =~ /service/) { $desc = 'unknown' }
		} elsif ($opt eq 'r') {
			$desc = 'recovery';
		} elsif ($opt eq 'c') {
			$desc = 'critical';
		} elsif ($opt eq 'w') {
			$desc = 'warning';
		} elsif ($opt eq 'n') {
			$desc = 'none';
		} elsif ($opt eq 'f') {
			$desc = 'flapping';
		}
		my $got_opt = undef;
		foreach my $sel (@selected) {
			if ($sel eq $opt) {	$got_opt = 1 }	
		}
		if ($got_opt) {
			$detail .= "\n<input class=$form_class type=checkbox name=$name value=$opt checked>&nbsp;\u$desc $req<br>";
		} else {
			$detail .= "\n<input class=$form_class type=checkbox name=$name value=$opt>&nbsp;\u$desc $req<br>";
		}
		$req = undef;
		$tab++;
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</td>
</tr>
</table>
</td>
</tr>);
	return $detail;
}

sub failure_criteria(@) {
	my $name = $_[1];
	my $selected = $_[2];
	my $req = $_[3];
	my $type = $_[4];
	my $doc = $_[5];
	my $override = $_[6];
	my $tab = $_[7];
	if ($req) {	$req = "<font color=#CC0000>&nbsp;* required</font>" }
	my @selected = @{$selected};
	my $title = $name;
	$title =~ s/_/ /g;
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>);
	if ($override) {
		if ($override eq 'checked') {
			$detail .= "\n<td class=$form_class width=2% valign=top><input class=$form_class type=checkbox name=$name\_override checked></td>";
		} else {
			$detail .= "\n<td class=$form_class width=2% valign=top><input class=$form_class type=checkbox name=$name\_override></td>";
		}
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<td class=$form_class width=25% valign=top>\u$title:</td>);
	if ($doc) {
		$detail .= "\n<td class=$form_class width=3% valign=top align=center>\n<a class=orange href=#doc title=\"$doc\" tabindex=-1>&nbsp;?&nbsp;</a>";
	} else {
		$detail .= "\n<td class=$form_class width=3% align=center>\n&nbsp;";
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</td>
<td class=$form_class>);
	my @opts = ('o','w','u','c','n');
	if ($type eq 'host_dependencies') { @opts = ('o','d','u','p','n') }
	my $desc = undef;
	foreach my $opt (@opts) {
		if ($opt eq 'o' && $type eq 'host_dependencies') {
			$desc = 'up';
		} elsif ($opt eq 'o') {
			$desc = 'okay';
		} elsif ($opt eq 'u' && $type eq 'host_dependencies') {
			$desc = 'unreachable';
		} elsif ($opt eq 'u') {
			$desc = 'unknown';
		} elsif ($opt eq 'd') {
			$desc = 'down';
		} elsif ($opt eq 'r') {
			$desc = 'recovery';
		} elsif ($opt eq 'c') {
			$desc = 'critical';
		} elsif ($opt eq 'w') {
			$desc = 'warning';
		} elsif ($opt eq 'p') {
			$desc = 'pending';
		} elsif ($opt eq 'n') {
			$desc = 'none';
		}
		my $got_opt = undef;
		foreach my $sel (@selected) {
			if ($sel eq $opt) {	$got_opt = 1 }	
		}
		if ($got_opt) {
			$detail .= "\n<input class=$form_class type=checkbox name=$name value=$opt checked>&nbsp;\u$desc $req<br>";
		} else {
			$detail .= "\n<input class=$form_class type=checkbox name=$name value=$opt>&nbsp;\u$desc $req<br>";
		}
		$req = undef;
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</td>
</tr>
</table>
</td>
</tr>);
	return $detail;
}

sub submit_button(@) {
	my $name = $_[1];
	my $value = $_[2];
	my $tab = $_[3];
	return qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>	
<td valign=top class=data align=left>
<table cellpadding=5 cellspacing=1 border=0>
<tr>
<td class=$form_class>
<input class=submitbutton type=submit name=$name value="$value">
</td>
</tr>
</table>
</td>
</tr>);
}

sub form_top(@) {
	my $caption = $_[1];
	my $onsubmit_action = $_[2];
	my $ez = $_[3];
	my $width = '75%';
	my $align = 'left';
	if ($ez eq '1') { $cgi_exe = 'monarch_ez.cgi' }
	if ($ez eq '2') { $cgi_exe = 'monarch_auto.cgi' }
	return qq(@{[&$Instrument::show_trace_as_html_comment()]}
<table class=data width=90% cellpadding=0 cellspacing=1 border=0>
<form name=form action=$cgi_dir/$cgi_exe method=post $onsubmit_action generator=form_top>
<tr>
<td class=data>
<table width=100% cellpadding=3 cellspacing=0 align=left border=0>
<tr>
<td class=head colspan=3>&nbsp;$caption</td>
</tr>
</table>
</td>
</tr>);
}

sub form_top_file(@) {
	my $caption = $_[1];
	my $onsubmit_action = $_[2];
	my $ez = $_[3];
	my $width = '75%';
	my $align = 'left';
	# next line commented out because now the caller provides the ' onsubmit=' along with the action
	#if ($onsubmit_action) { $onsubmit_action = qq(@{[&$Instrument::show_trace_as_html_comment()]} onsubmit="$onsubmit_action") }
	if ($ez) { $cgi_exe = 'monarch_ez.cgi' }
	return qq(@{[&$Instrument::show_trace_as_html_comment()]}
<table class=data width=90% cellpadding=0 cellspacing=1 border=0>
<form name=form ENCTYPE="multipart/form-data" action=$cgi_dir/$cgi_exe method=post $onsubmit_action generator=form_top_file>
<tr>
<td class=data>
<table width=100% cellpadding=3 cellspacing=0 align=left border=0>
<tr>
<td class=head colspan=3>&nbsp;$caption</td>
</tr>
</table>
</td>
</tr>);
}

sub form_errors(@) {
	my $errors = $_[1];
	my @errors = @{$errors};
	my $errstr = undef;
	foreach my $err (@errors) {
		$errstr .= "$err<br>";
	}
	$errstr =~ s/<br>$//;
	return qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=error valign=top width=25%><b>Error(s):</b></td>
<td class=error width=5%>&nbsp;</td>
<td class=error>
Please correct the following:<br>
$errstr
</td>
</tr>
</table>
</td>
</tr>);
}

sub profile_import_status(@) {
	my @messages = @{$_[1]};
	my $status_table = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<table width=100% cellpadding=3 cellspacing=0 align=left border=0>);

	foreach my $message (@messages) {
		if ($message =~ /^Importing/) {
			$status_table .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=$form_class colspan=5 valign=top>$message</td>
</tr><tr>
<td class=$form_class valign=top>&nbsp;</td>
<td class=$form_class valign=top>Read</td>
<td class=$form_class valign=top>Added</td>
<td class=$form_class valign=top>Updated</td>
<td class=$form_class valign=top>Overwrite</td>);

		} elsif ($message =~ /^Performance/) {
			$status_table .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</tr><tr>
<td class=$form_class colspan=5 valign=top>$message</td>);
		} elsif ($message =~ /^-----/) {
			$status_table .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</tr><tr>
<td class=$form_class colspan=5 valign=top><hr/></td>);

		} elsif ($message =~ /^(\S+)\s*(\d+)\s*read\s*(\d+)\s*added\s*(\d+)\s*updated\s*\(overwrite existing = (Y|N)\S+\)/) {
			$status_table .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</tr><tr>
<td class=$form_class valign=top>$1</td>
<td class=$form_class valign=top>$2</td>
<td class=$form_class valign=top>$3</td>
<td class=$form_class valign=top>$4</td>
<td class=$form_class valign=top>$5</td>);
		} elsif ($message =~ /^(.*\S+)\s*(\d+)\s*read\s*(\d+)\s*added\s*(\d+)\s*updated\s*\(overwrite existing = (Y|N)\S+\)/) {
			$status_table .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</tr><tr>
<td class=$form_class valign=top>$1</td>
<td class=$form_class valign=top>$2</td>
<td class=$form_class valign=top>$3</td>
<td class=$form_class valign=top>$4</td>
<td class=$form_class valign=top>$5</td>);
		}
	}
	$status_table .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</tr>
</table>);

	return qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=wizard_title valign=top>Import Status:</td>
</tr>
<tr>
<td class=wizard_body>
<table width=100% cellpadding=7 cellspacing=0 align=left border=0>
<tr>
<td class=wizard_body>$status_table</td>
</tr>
</table>
</td>
</tr>
</table>
</td>
</tr>);	

}

sub form_message(@) {
	my $title = $_[1];
	my $message = $_[2];
	my $class = $_[3];
	my @message = @{$message};
	my $msg = undef;
	foreach my $str (@message) {
		$msg .= "$str<br>";
	}
	$msg =~ s/<br>$//;
	return qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class valign=top width=25%>$title</td>
<td class=$form_class width=3%>&nbsp;</td>
<td class=$form_class>
$msg
</td>
</tr>
</table>
</td>
</tr>);
}

sub form_doc(@) {
	my $message = $_[1];
	return qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class valign=top width=100%>
$message
</td>
</tr>
</table>
</td>
</tr>);
}

sub form_status(@) {
	my $title = $_[1];
	my $message = $_[2];
	my $class = $_[3];
	return qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$class valign=top width=25%>$title</td>
<td class=$class colspan=2>
$message
</td>
</tr>
</table>
</td>
</tr>);
}

sub form_bottom_buttons(@) {
    my $self_discard = shift;
    my @args = @_;
    my $tab = 0;
    if (ref($args[$#args]) ne 'HASH') {
        $tab  = pop(@args);
    }
    my $html = qq(@{[&$Instrument::show_trace_as_html_comment()]}
    </table>
    <tr>
    <td>
    <table width=100% cellpadding=0 cellspacing=1 border=0>
    <tr>
    <td style=border:0 align=left>);
        
    foreach my $button (@args) {
        $html .= qq(    <input class=submitbutton type=submit name=$button->{name} value="$button->{value}" tabindex=@{[++$tab]}>&nbsp;\n);
    }
	unindent($html);

    my $html_end = qq(@{[&$Instrument::show_trace_as_html_comment()]}
    </td>
    </tr>
    </form>
    </table>
    </td>);
	unindent($html_end);

    return $html . $html_end;
}

sub form_file(@) {
	my $tab = $_[1];
	return qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class>Upload file:
</td>
<td class=$form_class>
<input type=file name=file size=70 maxlength=100>
</td>
</tr>
</table>
</td>
</tr>);
}

sub table_download_links(@) {
	my $doc_folder = $_[1];
	my @source = @{$_[2]};
	my $server = $_[3];
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<table width=75% cellpadding=3 cellspacing=0 border=0>
<br/><h2>Files in $doc_folder</h2>);
	foreach my $name (@source) {
		if ($name =~ /tar$/) {
			my $url = qq(<a class=left href=$doc_root_monarch/download/$name>$name&nbsp;</a>);			
			$detail .= qq(\n<tr>\n<td>$url\n</td>\n</tr>);
		} else {
			my $url = qq(<a class=left href=$doc_root_monarch/download/$name target="_blank">$name&nbsp;</a>);			
			$detail .= qq(\n<tr>\n<td>$url\n</td>\n</tr>);
		}
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</table>);
	return $detail;
}


sub success(@) {
	my $caption = $_[1];
	my $message = $_[2];
	my $task = $_[3];
	my $hidden = $_[4];
	my %hidden = %{$hidden};
	my $hiddenstr = undef;
	foreach my $name (keys %hidden) {
		unless ($name =~ /HASH/) {
			$hiddenstr .= "\n<input type=hidden name=$name value=\"$hidden{$name}\">";
		}
	}
	return qq(@{[&$Instrument::show_trace_as_html_comment()]}
<td valign=top>
<table class=form width=75% cellpadding=0 cellspacing=1 border=0>
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=head>$caption</td>
<form action=$cgi_dir/$cgi_exe generator=success>
$hiddenstr
</tr>
</table>
</td>
</tr>
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class>$message</td> 
</tr>
</table>
</td>
</tr>
</table>
<tr>
<td>
<table width=100% cellpadding=0 cellspacing=0 border=0>
<tr>
<td style=border:0 align=left>
<input class=submitbutton type=submit name=$task value="Continue">&nbsp;&nbsp;
</td>
</tr>
</form>
</table>
</td>);
}

sub are_you_sure(@) {
	my $caption = $_[1];
	my $message = $_[2];
	my $task = $_[3];
	my $hidden = $_[4];
	my $bail = $_[5];
	if ($_[6]) { $cgi_exe = 'monarch_auto.cgi' }
	my %hidden = %{$hidden};
	my $hiddenstr = undef;
	unless ($bail) { $bail = 'task'}
	foreach my $name (keys %hidden) {
		unless ($name =~ /HASH/) {
			$hiddenstr .= "\n<input type=hidden name=$name value=\"$hidden{$name}\">";
		}
	}
	return qq(@{[&$Instrument::show_trace_as_html_comment()]}
<td valign=top>
<table class=form width=75% cellpadding=0 cellspacing=1 border=0>
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=head>$caption</td>
<form action=$cgi_dir/$cgi_exe generator=are_you_sure>
$hiddenstr
</tr>
</table>
</td>
</tr>
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class>$message</td> 
</tr>
</table>
</table>
<tr>
<td>
<table width=100% cellpadding=0 cellspacing=0 border=0>
<tr>
<td style=border:0 align=left>
<input class=submitbutton type=submit name=$task value="Yes">&nbsp;
<input class=submitbutton type=submit name=$bail value="No">
</td>
</tr>
</form>
</table>
</td>
</tr>
</table>
</td>);
}

sub display($) {
	my $name = shift;
	my @words = split(/_/, $name);
	my $display = undef;
	foreach my $word (@words) { $display .= "\u$word " }
	chop $display;
	return $display;
}

sub frame(@) {
	my $session_id = $_[1];
	my $top_menu = $_[2];
	my $is_portal = $_[3];
	my $ez = $_[4];
	if ($is_portal) {
		return qq(@{[&$Instrument::show_trace_as_html_comment()]}
<html>
<head>
<title>Monarch</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<script type="text/javascript" src="/monarch/DataFormValidator.js"></script>
</head>
  <frameset cols="25%,75%" frameborder=yes border=1 framespacing=0> 
    <frame name="monarch_left" scrolling=yes src="$cgi_dir/monarch_tree.cgi?CGISESSID=$session_id&top_menu=$top_menu&ez=$ez">
    <frame name="monarch_main" scrolling=yes src="/monarch/blank.html">
  </frameset>
</html>);
	} else {
		return qq(@{[&$Instrument::show_trace_as_html_comment()]}
<html>
<head>
<title>Monarch</title>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
<script type="text/javascript" src="/monarch/DataFormValidator.js"></script>
</head>
<frameset rows="65,*" cols="*" frameborder=no border=0 framespacing=0> 
  <frame name="monarch_top" scrolling=no noresize src="$cgi_dir/$cgi_exe?update_top=1&CGISESSID=$session_id&top_menu=hosts&ez=$ez&login=1">
  <frameset cols="25%,85%" frameborder=yes border=1 framespacing=0> 
    <frame name="monarch_left" scrolling=yes src="$cgi_dir/monarch_tree.cgi?CGISESSID=$session_id&top_menu=hosts&ez=$ez">
    <frame name="monarch_main" scrolling=yes src="/monarch/blank.html">
  </frameset>
</frameset>
</html>);
	}
}

sub top_frame(@) {
	my $session_id = $_[1];
	my $top_menu = $_[2];
	my @menus = @{$_[3]};
	my $auth_level = $_[4];
	my $ver = $_[5];
	my $enable_ez = $_[6];
	my $ez = $_[7];
	my %auth_add = %{$_[8]};
	my $login = $_[9];
	my $title = "GroundWork Monitor Architect";
	my $class = 'submenu';
	my $links = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<td align=left>);
	my $colspan = 2;
	my $menuspan = 2;
	my $width = 70;
	my $m = 0;
	my $first_menu = $menus[0];
	foreach (@menus) { $m++ }
	if ($m) { $width = $width/$m }
	$width = sprintf("%.0f", $width);
	my $javascript = undef;
	my $ez_main = undef;
	my %selected = ();
	if ($ez) { 
		$selected{'ez'} = 'selected';
		$javascript = qq(parent.monarch_left.location='$cgi_dir/monarch_tree.cgi?CGISESSID=$session_id&top_menu=$top_menu&ez=1';);
	} else {
		$selected{'main'} = 'selected';
		$javascript = qq(parent.monarch_left.location='$cgi_dir/monarch_tree.cgi?CGISESSID=$session_id&top_menu=$top_menu';);
	}
	if ($login) { $javascript = undef } # don't want the page to load twice if new login
	if ($enable_ez && ($auth_add{'ez'} || $auth_add{'ez_main'} || $auth_add{'main_ez'})) {
		$ez_main = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<form name=form action=$cgi_dir/$cgi_exe method=post generator=top_frame>
<input type=hidden name=CGISESSID value=$session_id>
<input type=hidden name=top_menu value=$top_menu>
<input type=hidden name=update_top value=1>
<td class=top align=left width=5%>
<select name=ez onChange="submit()">
<option $selected{'main'} value=0>Main</option>
<option $selected{'ez'} value=1>EZ</option>
</select>
</td>
</form>);
	}
	foreach my $menu (@menus) {
		$colspan++;
		$menuspan++;
		my $display = "\u$menu";
		if ($menu =~ /_/) {
			$display = undef;
			my @disp = split(/_/, $menu);
			foreach (@disp) { $display .= "\u$_ " }
			chop $display;
		}
		$class = 'top_menu_menu';
		if ($menu eq 'help') {
			$links .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<a class=top_frame href=$doc_root_monarch/doc/index.html target="_blank">$display</a>);
		} else {
			$links .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<a class=top_frame href=$cgi_dir/monarch_tree.cgi?CGISESSID=$session_id&top_menu=$menu&ez=$ez target="monarch_left" onclick="load_main_frame()">$display</a>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;);
		}
	}
	$links .= "\n</td>";
	$width = "$width"."%";
	my $logout = undef;
	if ($auth_level == 2) {
		$colspan--;
		$logout = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<td class=head align=right>
<a class=head href=$cgi_dir/monarch.cgi?CGISESSID=$session_id&view=logout target=_top>Logout</a>
</td>);
	}

	my $detail = qq(
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
<head>@{[&$Instrument::show_trace_as_html_comment()]}
<title>Monarch Menus</title>
<META HTTP-EQUIV="CONTENT-TYPE" CONTENT="text/html; charset=utf-8">
<META HTTP-EQUIV="Pragma" CONTENT="no-cache">
<META HTTP-EQUIV="Expires" CONTENT="-1">
<link rel="stylesheet" type="text/css" href="$doc_root_monarch/monarch.css" />
<SCRIPT language="JavaScript">
	function load_frames() {
		$javascript
		parent.monarch_main.location.href = '/monarch/blank.html';

		return false;
	}
</SCRIPT>
</head>
<body bgcolor=#f0f0f0 onload=load_frames()>
<!-- generated by: MonarchForms::top_frame() -->
<table width=100% cellpadding=0 cellspacing=1 border=0>
<tr>
<td>
<table width=100% cellpadding=5 cellspacing=0 align=left border=0>
<tr>
<td class=head colspan=$colspan>&nbsp;<img src=$doc_root_monarch/images/smgwbuttondk.png>&nbsp;&nbsp;$title $ver</td>
$logout
</tr>
</table>
</td>
</tr>
<tr>
<td>
<table width=100% cellpadding=3 cellspacing=0 border=0>
<tr>
$ez_main
$links
</tr>
</table>
</td>
</tr>
</body>
</table>
<script type="text/javascript" src="/monarch/DataFormValidator.js"></script>
</html>);
	return $detail;
}


sub header(@) {
	my $title = $_[1];
	my $session_id = $_[2];
	my $top_menu = $_[3];
	my $refresh_url = $_[4];
	my $refresh_left = $_[5];
	my $ez = $_[6];
	my $load_event = $_[7];
	if ($ez eq 1) { $cgi_exe = 'monarch_ez.cgi' }
	if ($ez eq 2) { $cgi_exe = 'monarch_auto.cgi' }
	my $meta = qq(<META HTTP-EQUIV="Expires" CONTENT="-1">);
	if ($refresh_url) {
		$meta = qq(<META HTTP-EQUIV="Refresh" CONTENT="0; URL=$refresh_url">);
	}
	my $javascript = undef;
	my $now = time;
	if ($refresh_left) {
		my $ezstr = undef;
		if ($ez) { $ezstr = '&ez=1' }
		$top_menu =~ s/\s/_/g; # refresh left time Periods to time_periods
		$top_menu = lc($top_menu);
		$javascript = "onload=\"parent.monarch_left.location='$cgi_dir/monarch_tree.cgi?CGISESSID=$session_id&nocache=$now&refresh_left=1&top_menu=$top_menu$ezstr';\"";
	}
	if ($load_event == 1) {
		$javascript = "onload=\"scan_host();\"";
	}
	if ($load_event == 2) {
		$javascript = "onload=\"check_status();\"";
	}
	return qq(
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
<head>@{[&$Instrument::show_trace_as_html_comment()]}
<title>$title</title>
<META HTTP-EQUIV="CONTENT-TYPE" CONTENT="text/html; charset=utf-8">
<META HTTP-EQUIV="Pragma" CONTENT="no-cache">
$meta
<link rel="stylesheet" type="text/css" href="$doc_root_monarch/monarch.css" />
<SCRIPT language=javascript1.1 src="$doc_root_monarch/monarch.js"></SCRIPT>
<script src="$doc_root_monarch/nicetitle.js" type="text/javascript"></script>
<script type="text/javascript" src="/monarch/DataFormValidator.js"></script>
</head>
<body bgcolor=#f0f0f0 $javascript>);
}


sub footer(@) {
	my $debug = $_[1];
	return qq(@{[&$Instrument::show_trace_as_html_comment()]}
</tr>
<tr>
<td>
$debug
$extend_page
</td>
</tr>
</table>
</body>
</html>);
}


############################################################################
# Special Forms
#

sub access_checkbox_list(@) {
	my $title = $_[1];
	my $name = $_[2];
	my @list = @{$_[3]};
	my @selected = @{$_[4]};
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<script language=JavaScript>
function doCheckAll()
{
  with (document.form) {
    for (var i=0; i < elements.length; i++) {
        if (elements[i].type == 'checkbox' && (elements[i].id == 'asset_checked'))
           elements[i].checked = true;
    }
  }
}
function doUnCheckAll()
{
  with (document.form) {
    for (var i=0; i < elements.length; i++) {
        if (elements[i].type == 'checkbox' && (elements[i].id == 'asset_checked'))
           elements[i].checked = false;
    }
  }
}
</script>
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class width=25% valign=top>$title</td>
<td class=$form_class>);
	my $got_selected = undef;
	foreach my $item (@list) {
		my $title = $item;
		$title =~ s/_/ /g;
		foreach my $selected(@selected) {
			if ($item eq $selected) { $got_selected = 1 }
		}
		if ($got_selected) {
			$got_selected = undef;
			$detail .= "\n<input class=$form_class type=checkbox name=$name id=asset_checked value=\"$item\" checked>&nbsp;\u$title<br>";
		} else {
			$detail .= "\n<input class=$form_class type=checkbox name=$name id=asset_checked value=\"$item\">&nbsp;\u$title<br>";
		}
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</td>
</tr>
</table>
</td>
</tr>
<tr>
<td>
<table width=100% cellpadding=0 cellspacing=0 align=left border=0>
<tr>
<td>
<input type=submit class=submitbutton name=update_access value="Save">&nbsp;&nbsp;
<input class=submitbutton type=button value="Check All" onclick=doCheckAll()>&nbsp;&nbsp;
<input class=submitbutton type=button value="Uncheck All" onclick=doUnCheckAll()>&nbsp;&nbsp;
<input type=submit class=submitbutton name=close value="Close">
</td>
</tr>
</form>
</table>
</td>
</tr>);	
	return $detail;
}

sub access_settings_ez(@) {
	my %view = %{$_[1]};
	if ($view{'enable_ez'}) { $view{'enable_ez'} = 'checked' }
	if ($view{'ez_main'}) { $view{'ez_main_checked'} = 'checked' }
	if ($view{'main_ez'}) { $view{'main_ez_checked'} = 'checked' }
	if ($view{'ez'}) { $view{'ez_checked'} = 'checked' }
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class width=25% valign=top>Enable EZ:</td>
<td class=$form_class>
<input class=$form_class type=checkbox name=enable_ez value=enable_ez $view{'enable_ez'}>&nbsp;Enable<br>
</td>
</tr>
<tr>
<td class=top_border width=100% colspan=5>
<table width=100% cellpadding=0 cellspacing=0 border=0>
<tr>	
<td class=$form_class width=25% valign=top>View option:</td>
<td class=$form_class>
<input class=$form_class type=radio name=ez_view value=ez_main $view{'ez_main_checked'}>&nbsp;EZ-Main<br>
<input class=$form_class type=radio name=ez_view value=main_ez $view{'main_ez_checked'}>&nbsp;Main-EZ<br>
<input class=$form_class type=radio name=ez_view value=ez $view{'ez_checked'}>&nbsp;EZ<br>
</td>
</tr>
</table>
</td>
</tr>
</table>
</td>
</tr>);	
	return $detail;
}


sub access_list(@) {
	my $title = $_[1];
	my $assets = $_[2];
	my @assets = @{$assets};
	my $assets_selected = $_[3];
	my %assets_selected = %{$assets_selected};
	my $type = $_[4];
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<script language=JavaScript>
function doCheckAll()
{
  with (document.form) {
    for (var i=0; i < elements.length; i++) {
        if (elements[i].type == 'checkbox' && (elements[i].id == 'asset_checked'))
           elements[i].checked = true;
    }
  }
}
function doUnCheckAll()
{
  with (document.form) {
    for (var i=0; i < elements.length; i++) {
        if (elements[i].type == 'checkbox' && (elements[i].id == 'asset_checked'))
           elements[i].checked = false;
    }
  }
}
</script>

<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=row2 align=left>$title</td>
<td class=row2 align=center width=10%>Add</td>
<td class=row2 align=center width=10%>Modify</td>
<td class=row2 align=center width=10%>Delete</td>
<td class=row2 width=20%>&nbsp;</td>
</tr>);
	foreach my $asset (@assets) {
		my %selected = {};
		my @perms = split(/,/, $assets_selected{$asset});
		foreach (@perms) { $selected{$_} = " checked" }
		my $title = $asset;
		$title =~ s/_/ /g;
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>	
<td class=$form_class>\u$title:</td>
<td class=$form_class align=center width=10%>
<input class=$form_class type=checkbox name=$type-add-$asset id=asset_checked value=1$selected{'add'}>
</td>
<td class=$form_class align=center width=10%>
<input class=$form_class type=checkbox name=$type-modify-$asset id=asset_checked value=1$selected{'modify'}>
</td>
<td class=$form_class align=center width=10%>
<input class=$form_class type=checkbox name=$type-delete-$asset id=asset_checked value=1$selected{'delete'}>
</td>
<td class=$form_class width=20%>&nbsp;</td>
</tr>);
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</table>
</td>
</tr>
<tr>
<td>
<table width=100% cellpadding=0 cellspacing=0 align=left border=0>
<tr>
<td>
<input type=submit class=submitbutton name=update_access value="Save">&nbsp;&nbsp;
<input class=submitbutton type=button value="Check All" onclick=doCheckAll()>&nbsp;&nbsp;
<input class=submitbutton type=button value="Uncheck All" onclick=doUnCheckAll()>&nbsp;&nbsp;
<input type=submit class=submitbutton name=close value="Close">
</td>
</tr>
</form>
</table>
</td>
</tr>);
	return $detail;
}

sub add_file() {
	my $name = $_[1];
	my $type = $_[2];
	my $path = $_[3];
	my $files = $_[4];
	my $file = $_[5];
	my $required = $_[6];
	my $doc = $_[7];
	if ($required) { $required = "<font color=#CC0000>&nbsp;* required</font></td>" }

	my @files = @{$files};
	my	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=5 cellspacing=0 align=left border=0>
<tr>
<td class=$form_class align=left width=10%>File:</td>

<td class=$form_class align=left>
<select name=file>);
	if (!$files[0]) { 
		$detail .= "\n<option selected value=></option>";
		$detail .= "\n<option value=>-no check commands-</option>";
	} else {
		if ($name) {
			$detail .= "\n<option value=></option>";
		} else {
			$detail .= "\n<option selected value=></option>";
		}
		foreach my $item (@files) {
			if ($item eq $name) {
				$detail .= "\n<option selected value=\"$item\">$item</option>";			
			} else {
				$detail .= "\n<option value=\"$item\">$item</option>";
			}
		}
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</select>$required
</td>
<td class=$form_class width=1%>&nbsp;</td>

<tr>
<input type=hidden name=type value=$type>
<td class=$form_class width=10%>&nbsp;</td>
<td class=$form_class>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class align=left width=15%><input class=submitbutton type=submit name=add_file value="Add New File">
<td class=$form_class align=left width=10%>File:</td>
<td class=$form_class align=left width=75%><input type=text size=60 name=new_file value="$file">$required</td>
</tr>
<tr>
<td class=$form_class align=left width=15%>&nbsp;</td>
<td class=$form_class align=left width=10%>Path:</td>
<td class=$form_class align=left width=75%><input type=text size=80 name=path value="$path">$required</td>
</tr>
</table>
<td class=$form_class width=1%>&nbsp;</td>
</td>
</tr>
<tr>
<td class=$form_class colspan=3>&nbsp;</td>
</tr>
</table>
</td>
</tr>);
	return $detail;
}


sub external_list(@) {
	my $session_id = $_[1];
	my $name = $_[2];
	my $externals = $_[3];
	my $list = $_[4];
	my $type = $_[5];
	my $service_id = $_[6];
	my $service_name = $_[7];
	my $obj_view = 'host_externals';
	if ($type eq 'service') { $obj_view = 'service_externals' }
	my %externals = %{$externals};
	my @list = @{$list};
	my $detail = undef; 

	
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=5 cellspacing=0 align=left border=0>
<tr>
<td class=$form_class colspan=3>\u$type Externals:</td>
</tr>);
	my $row = 1;
	foreach my $external (sort keys %externals) {
		my $class = undef;
		if ($row == 1) {
			$class = 'row_lt';
			$row = 2;
		} elsif ($row == 2) {
			$class = 'row_lt';
			$row = 1;
		}
		if ($external =~ /HASH/) { next }
		my $lexternal = $external;
		$lexternal =~ s/\s/+/g;
		if ($type eq 'service_name') {
			$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=$class width=80% align=left>
$external
</td>);
		} else {
			$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=$class width=80% align=left>
<input class=removebutton type=submit name=select_external value="$external"><img src=$doc_root_monarch/images/arrow_$class.png border=0>
</td>);
	} 	
			$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<td class=$class align=center>
<input class=removebutton type=submit name=remove_external_$externals{$external} value="remove">
</td>
</tr>);
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</table>
</td>
</tr>
<tr>
<td class=data>
<table width=100% cellpadding=5 cellspacing=0 align=left border=0>
<tr>
<td class=$form_class colspan=3>
<table width=100% cellpadding=3 cellspacing=0 border=0>
<tr>
<td class=$form_class width=30% align=right><input class=submitbutton type=submit name=external_add value="Add External">
</td>
<td class=$form_class align=left>
<select name=external size=4>);
	if (!$list[0]) { 
		$detail .= "\n<option value=>-no external names to add-</option>";
	}
	$detail .= "\n<option selected value=></option>";
	@list = sort { lc($a) cmp lc($b) } @list;
	foreach my $item (@list) {
		$detail .= "\n<option value=\"$item\">$item</option>";
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</select>&nbsp;&nbsp;
</td>
</tr>
</table>
</td>
</tr>
</table>
</td>
</tr>);
	return $detail;
}

sub external_xml_list(@) {
	my %externals = %{$_[1]};
	my @externals = @{$_[2]};
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>);

	foreach my $ext (sort keys %externals) {
		if ($ext =~ /^HASH/) { next }
		my $checked = undef;
		if ($externals{$ext}{'enable'} eq 'ON') { $checked = 'checked' }
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=$form_class width=20% colspan=2><b>$ext</b></td>
<td class=$form_class>Enabled:</td>
<td class=$form_class colspan=4><input type=checkbox name=enabled value=$externals{$ext}{'id'} $checked></td>
</tr>);

		if ($externals{$ext}{'description'}) {
			$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=$form_class width=10%>&nbsp;</td>
<td class=$form_class>Enabled:</td>
<td class=$form_class colspan=5>$externals{$ext}{'description'}</td>
</tr>);

		}
		if ($externals{$ext}{'service_name'}) {
			$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=$form_class width=10%>&nbsp;</td>
<td class=$form_class colspan=4>$externals{$ext}{'service_name'}</td>
</tr>);

		}		
		if ($externals{$ext}{'command'}) {
			$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=$form_class width=10%>&nbsp;</td>
<td class=$form_class width=10%>Command:</td>
<td class=$form_class colspan=4>$externals{$ext}{'command'}{'name'}</td>
</tr>);
			foreach my $param (sort keys %{$externals{$ext}{'command'}}) {
				if ($param eq 'name') { next }
				$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=$form_class width=10%>&nbsp;</td>
<td class=$form_class width=10%>&nbsp;&nbsp;Param:</td>
<td class=$form_class>$param</td>);
				if ($externals{$ext}{'command'}{$param}{'description'}) {
					$detail .= "\n<td class=$form_class valign=top align=left>\n<a class=orange href=#doc title=\"$externals{$ext}{'command'}{$param}{'description'}\">&nbsp;?&nbsp;</a>";
				} else {
					$detail .= "</td>\n<td class=$form_class width=3% align=left>\n&nbsp;</td>";
				}
				$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<td class=$form_class><input type=text size=50 name=param_value value="$externals{$ext}{'command'}{$param}{'value'}"></td>
</tr>);
			}

		}

	}

	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</table>
</td>
</tr>
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class align=right><input class=submitbutton type=submit name=submit value="Add External(s)">
</td>
<td class=$form_class align=left>
<select name=external size=4 multiple>);
	if (!$externals[0]) { 
		$detail .= "\n<option value=>-no service names to add-</option>";
	}
	$detail .= "\n<option selected value=></option>";
	@externals = sort { lc($a) cmp lc($b) } @externals;
	foreach my $item (@externals) {
		$detail .= "\n<option value=\"$item\">$item</option>";
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</select>&nbsp;&nbsp;
</td>
</tr>
</table>
</td>
</tr>);
	return $detail;
}


sub service_list(@) {
	my $session_id = $_[1];
	my $name = $_[2];
	my $services = $_[3];
	my $list = $_[4];
	my $selected = $_[5];
	my %services = %{$services};
	my @list = @{$list};
	my $now = time;
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class colspan=2>Service Name</td>
</tr>
</table>
</td>
</tr>
<tr>
<td class=data2>
<table width=100% cellspacing=0 cellpadding=3 align=left border=0>);
	my $row = 1;
	use URI::Escape;
	$name = uri_escape($name);
	foreach my $service (sort keys %services) {
		my $class = undef;
		if ($row == 1) {
			$class = 'row_lt';
			$row = 2;
		} elsif ($row == 2) {
			$class = 'row_dk';
			$row = 1;
		}
		if ($service =~ /HASH/) { next }
		my $display = $service;
		$display =~ s/\+/ /g;
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=$class align=left>
<a class=left href=$cgi_dir/$cgi_exe?update_main=1&CGISESSID=$session_id&top_menu=hosts&nocache=$now&selected=$name&view=manage_host&obj=hosts&obj_view=service_detail&name=$name&service_name=$service&service_id=$services{$service}>
$display&nbsp;&middot;&nbsp;details&nbsp;<img src=$doc_root_monarch/images/arrow_$class.png border=0></a>
</td>
<td class=$class align=center>
<a class=left href=$cgi_dir/$cgi_exe?update_main=1&CGISESSID=$session_id&top_menu=hosts&nocache=$now&selected=$name&view=manage_host&obj=hosts&obj_view=services&name=$name&service_id=$services{$service}&submit=remove_service><img src=$doc_root_monarch/images/x_$class.png border=0>&nbsp;remove</a>
</td>
</tr>
);
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</table>
</td>
</tr>
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class align=right><input class=submitbutton type=submit name=submit value="Add Service(s)">
</td>
<td class=$form_class align=left>
<select name=add_service size=15 multiple>);
	if (!$list[0]) { 
		$detail .= "\n<option value=>-no service names to add-</option>";
	}
	$detail .= "\n<option selected value=></option>";
	@list = sort { lc($a) cmp lc($b) } @list;
	foreach my $item (@list) {
		$detail .= "\n<option value=\"$item\">$item</option>";
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</select>&nbsp;&nbsp;
</td>
</tr>
</table>
</td>
</tr>);
	return $detail;
}


sub service_select(@) {
	my $services = $_[1];
	my $selected = $_[2];
	my %services = %{$services};
	my %selected = %{$selected};
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=row2 align=center colspan=3>Include/Modify/Discard</td>
<td class=row2 align=left>Service Name</td>
<td class=row2 align=left>Template</td>
<td class=row2 align=left>Extended Info</td>
</tr>);
	my $row = 1;
	foreach my $service (sort keys %services) {
		my $class = undef;
		if ($row == 1) {
			$class = 'row_dk';
			$row = 2;
		} elsif ($row == 2) {
			$class = 'row_lt';
			$row = 1;
		}

		if ($service =~ /HASH/) { next }
		my %checked = ();
		if ($selected{$service} eq 'add') {
			$checked{'add'} = 'checked';
		} elsif ($selected{$service} eq 'edit') {
			$checked{'edit'} = 'checked';
		} else {
			$checked{'discard'} = 'checked';
		}
		my $title = $service;

		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=$class rowspan=2 align=center width=5%>
<input type=radio class=$class name="$service" value=add $checked{'add'}>
</td>
<td class=$class rowspan=2 align=center width=5%>
<input type=radio class=$class name="$service" value=edit $checked{'edit'}>
</td>
<td class=$class rowspan=2 align=center width=5%>
<input type=radio class=$class name="$service" value=discard $checked{'discard'}>
</td>
<td class=$class align=left>$title
</td>
<td class=$class align=left>$services{$service}{'template'}
</td>
<td class=$class align=left>$services{$service}{'extinfo'}
</td>
</tr>
<tr>
<td class=$class colspan=4 align=left>Check command: $services{$service}{'command'}
</td>
</tr>);
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=row3 colspan=2 align=left>&nbsp;</td>
</tr>
</table>
</td>
</tr>);
	return $detail;
}

sub profile_list(@) {
	my $session_id = $_[1];
	my $host = $_[2];
	my $profiles = $_[3];
	my $tab = $_[4];
	my @profiles = @{$profiles};
	my $now = time;
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class colspan=2>Service Profiles:</td>
</tr>
<tr>
<td class=row_lt>
<table width=100% cellspacing=0 cellpadding=3 align=left border=0>);
	my $row = 1;
	if ($profiles[0]) {
		foreach my $profile (@profiles) {
			my $class = undef;
			if ($row == 1) {
				$class = 'row_lt';
				$row = 2;
			} elsif ($row == 2) {
				$class = 'row_lt';
				$row = 1;
			}
			my $display = $profile;
			$profile = uri_escape($profile);
			$display =~ s/\+/ /g;
			$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=$class align=left>
$display
</td>
<td class=$class align=center>
<input type=hidden name=profiles value=$profile>
<input class=removebutton type=submit name=remove_$profile value="x ">remove
</td>
</tr>
);
		} 
	} else {
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=row_lt align=left>
None selected
</td>
<td class=row_lt align=center>
&nbsp;
</td>
</tr>
);
		
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</table>
</td>
</tr>
<tr>
<td class=$form_class align=center>&nbsp;</td>
</tr>
</table>
</td>
</tr>);
	return $detail;

}


sub add_service_profile(@) {
	my $list = $_[1];
	my @list = @{$list};
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class colspan=3 width=25% align=center>Select service profile:
</td>
<td class=$form_class colspan=4 rowspan=2 valign=top align=left>
<select name=profiles>);
	if (!$list[0]) { 
		$detail .= "\n<option value=>-no service profiles to add-</option>";
	}
	$detail .= "\n<option selected value=></option>";
	@list = sort { lc($a) cmp lc($b) } @list;
	foreach my $item (@list) {
		$detail .= "\n<option value=\"$item\">$item</option>";
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</select>&nbsp;&nbsp;
</td>
</tr>
<tr>
<td class=$form_class colspan=3 width=25% align=center><input class=submitbutton type=submit name=add_profile value="Add Profile">
</td>
</tr>
<tr>
<td class=row3 colspan=2 align=left>&nbsp;</td>
</tr>
</table>
</td>
</tr>);
	return $detail;
}


sub add_service(@) {
	my $list = $_[1];
	my @list = @{$list};
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class colspan=3 width=25% align=center>Select other<br>service(s):
</td>
<td class=$form_class colspan=4 rowspan=2 valign=top align=left>
<select name=services size=5 multiple>);
	if (!$list[0]) { 
		$detail .= "\n<option value=>-no services to add-</option>";
	}
	$detail .= "\n<option selected value=></option>";
	@list = sort { lc($a) cmp lc($b) } @list;
	foreach my $item (@list) {
		$detail .= "\n<option value=\"$item\">$item</option>";
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</select>&nbsp;&nbsp;
</td>
</tr>
<tr>
<td class=$form_class colspan=3 width=25% align=center><input class=submitbutton type=submit name=add_service value="Add to list">
</td>
</tr>
<tr>
<td class=row3 colspan=2 align=left>&nbsp;</td>
</tr>
</table>
</td>
</tr>);
	return $detail;
}


sub manage_escalation_tree(@) {
	my $session_id = $_[1];
	my $view = $_[2];
	my $type = $_[3];
	my $name = $_[4];
	my $tree_id = $_[5];
	my $ids = $_[6];
	my $members = $_[7];
	my $nonmembers = $_[8];
	my $contact_groups = $_[9];
	my $first_notify = $_[10];
	my @members = @{$members};
	my @nonmembers = @{$nonmembers};
	@nonmembers = sort { lc($a) cmp lc($b) } @nonmembers;
	my %ids = %{$ids};
	my %contact_groups = %{$contact_groups};
	my %first_notify = %{$first_notify};
	my $errstr = undef;
	my $now = time;
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class width=40% colspan=2 align=left>
<table class=form cellspacing=1 cellpadding=3 width=100% align=left border=0>
<tr>	
<td class=row2>Escalations</td>
<td class=row2>First Notify</td>
<td class=row2>Contact Groups</td>
<td class=row2 colspan=2>&nbsp;</td>
</tr>);
	foreach my $escalation (@members) {
		my $sname = $name;
		$sname =~ s/\s/+/g;
		my $fn = $first_notify{$ids{$escalation}};
		$fn =~ s/-zero-/0/;
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>	
<td class=row_dk valign=top>
$escalation
</td>
<td class=row_dk valign=top>
$fn
</td>
<td class=row_dk>$contact_groups{$ids{$escalation}}
</td>
<td class=row_dk align=center valign=top>
<input type=submit class=escbutton name=assign_contactgroups_$ids{$escalation} value="modify groups">	
</td>
<td class=row_dk align=center valign=top>
<input type=submit class=escbutton name=remove_escalation_$ids{$escalation} value="remove">	
</td>
</tr>);		
	}

	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=$form_class colspan=5>
<table width=100% cellpadding=0 cellspacing=0 border=0>
<tr>
<td class=$form_class align=center><input class=submitbutton type=submit name=add_escalation value="Add Escalation">
</td>
<td class=$form_class rowspan=2 valign=top align=left>
<select name=escalation size=10>);
	my $options = undef;
	$detail .= "\n<option selected value=></option>";
	foreach my $nmem (@nonmembers) {
		my $got_mem = undef;
		foreach my $mem(@members) {
			if ($nmem eq $mem) { $got_mem = 1 }
		}
		if ($got_mem) {
			$got_mem = undef;
			next;
		} else {
			$options .= "\n<option value=\"$nmem\">$nmem</option>";
		}
	}
	if (!$options) { $options = "\n<option value=>-no escalation templates-</option>" }
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
$options
</select>&nbsp;&nbsp;
</td>
<td class=$form_class width=10% rowspan=2 valign=top align=left>&nbsp;
</tr>
</table>
</td>
</tr>
</table>
</td>
</tr>
</table>
</td>
</tr>);
}

sub host_top(@) {
	my $name = $_[1];
	my $session_id = $_[2];
	my $obj_view = $_[3];
	my $externals = $_[4];
	my $selected = $_[5];
	my $form_service = $_[6];
	my $now = time;
	my $colspan = 6;
	my $cnt = 0;
	my @menus = ();
	if ($form_service) {
		@menus = ('service_detail','service_check','service_dependencies');
		$colspan = 6;
		$cnt = 4;
		if ($externals) { push @menus, 'service_externals'; $colspan = 8; $cnt = 5 }
		if ($obj_view eq 'service_external_detail') { push @menus, 'service_external_detail'; $colspan = 9; $cnt = 6 }
	} else {
		push @menus, 'host_detail';
		if ($obj_view =~ /service_detail|service_dependencies|service_externals|service_check/) {
			push (@menus,('services','service_detail','service_check','service_dependencies'));
			$colspan = 7;
			$cnt = 5;
			if ($externals) { push @menus, 'service_externals'; $colspan = 9; $cnt = 6 }
		} elsif ($obj_view eq 'service_external_detail') {
			push (@menus,('services','service_detail','service_externals','service_external_detail'));
			$cnt = 4;
		} elsif ($obj_view eq 'host_external_detail') {
			push (@menus,('profile','services','host_externals','host_external_detail'));
			$colspan = 7;
			$cnt = 4;
		} else {
			push (@menus,('profile','parents','hostgroups','escalations','services') );
			$cnt = 6;
			if ($externals) { push @menus, 'host_externals'; $colspan = 7; $cnt = 7 }
		}
	}
	my $width = 100/$cnt.'%';
	my $title = 'Manage Host';
	if ($form_service) { $title .= ' Service'}
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>	
<td valign=top align=left>
<table width=90% cellpadding=0 cellspacing=1 border=0>
<tr>
<td>
<table width=100% cellpadding=5 cellspacing=0 align=left border=0>
<tr>
<td class=head colspan=$colspan>&nbsp;$title</td>
</tr>
</table>
</td>
</tr>
<tr>
<td>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>);
	if ($obj_view =~ /profile|parents|hostgroups|host_detail|service_detail/) {
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<form name=form action=$cgi_dir/$cgi_exe onsubmit="selIt();" method=post generator=host_top1>);
	} else {
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<form name=form action=$cgi_dir/$cgi_exe method=post generator=host_top2>);
	}
	my $class = undef;
	my $bclass = undef;
	my @lmenus = @menus;
	my $last_menu = pop @lmenus;
	my $first_menu = $menus[0];
	foreach my $view (@menus) {
		if ($obj_view eq $view) { 
			$class = 'top_menu_selected';
			$bclass = 'topbuttonselected';
			if ($view eq $last_menu) {
				$class = 'top_menu_selected_right';
			}
			if ($view eq $first_menu) {
				$class = 'top_menu_selected_left';
			}
		} else {
			$class = 'top_menu_menu';
			$bclass = 'topbutton';
			if ($view eq $last_menu) {
				$class = 'top_menu_right';
			}
		}
		my $menu = $view;
		$menu = undef;
		my @menu = split(/_/, $view);
		foreach (@menu) { $menu .= "\u$_ " }
		chop $menu;
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<td class=$class width=$width align=center>
<input type=submit class=$bclass name=$view value="$menu">	
</td>);
	}


	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</tr>
<tr>
<td class=top_menu_selected_bar colspan=$colspan>&nbsp;</td>
</tr>
</table>
<tr>
<td class=data colspan=$colspan>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class width=25%>Host name:</td>
<td class=$form_class width=3%>&nbsp;</td>
<td class=$form_class>$name</td>
<input type=hidden name=name value="$name">
</tr>
</table>
</td>
</tr>);
	return $detail;
}

sub host_profile_top(@) {
	my $name = $_[1];
	my $session_id = $_[2];
	my $obj_view = $_[3];
	my $externals = $_[4];
	my $objs = $_[5];
	my %objs = ();
	my $urlstr = undef;
	my $now = time;
	if ($objs) {
		%objs = %{$objs};
		foreach my $key (keys %objs) {
			if ($objs{$key}) { $urlstr .= '&'.$key.'='.$objs{$key} }
		}
	}
	my $colspan = 9;
	my @menus = ('host_detail','parents','hostgroups','escalations');
	if ($externals) {
		push (@menus,('externals','service_profiles','assign_hosts','assign_hostgroups','apply'));
		$colspan = 10;
	} else {
		push (@menus,('service_profiles','assign_hosts','assign_hostgroups','apply'));
	}
	my $width = 100/$colspan.'%';
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>	
<td valign=top align=left>
<table width=90% cellpadding=0 cellspacing=1 border=0>
<tr>
<td>
<table width=100% cellpadding=5 cellspacing=0 align=left border=0>
<tr>
<td class=head colspan=$colspan>&nbsp;Host Profile</td>
</tr>
</table>
</td>
</tr>
<tr>
<td>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>);
	my $class = undef;
	my @lmenus = @menus;
	my $last_menu = pop @lmenus;
	my $first_menu = $menus[0];
	foreach my $view (@menus) {
		if ($obj_view eq $view) { 
			$class = 'top_menu_selected';
			if ($view eq $last_menu) {
				$class = 'top_menu_selected_right';
			}
			if ($view eq $first_menu) {
				$class = 'top_menu_selected_left';
			}
		} else {
			$class = 'top_menu_menu';
			if ($view eq $last_menu) {
				$class = 'top_menu_right';
			}
		}
		my $menu = $view;
		$menu = undef;
		my @menu = split(/_/, $view);
		foreach (@menu) { $menu .= "\u$_ " }
		my $cname = $name;
		$cname =~ s/\s/+/g;
		chop $menu;
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<td class=$class width=$width align=center>
<a class=top href=$cgi_dir/$cgi_exe?update_main=1&CGISESSID=$session_id&top_menu=profiles&nocache=$now&view=host_profile&obj_view=$view&name=$cname$urlstr>\u$menu</a>
</td>);
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</tr>
<tr>
<td class=top_menu_selected_bar colspan=$colspan>&nbsp;</td>
</tr>);
	if ($obj_view =~ /parents|host|externals|service_profiles/) {
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<form name=form action=$cgi_dir/$cgi_exe onsubmit="selIt();" method=post generator=host_profile_top1>);
	} else {
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<form name=form action=$cgi_dir/$cgi_exe method=post generator=host_profile_top2>);
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</tr>
</table>
</td>
</tr>
<tr>
<td class=data colspan=$colspan>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class width=30%>Name:</td>
<input type=hidden name=name value="$name">
<td class=$form_class>$name</td>
</tr>
</table>
</td>
</tr>);

	return $detail;
}

sub apply_select() {
	my $view = $_[1];
	my $selected = $_[2];
	my $nagios_ver = $_[3];
	my %selected = %{$selected};
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>);
	unless ($view =~ /service$|manage_host/) {
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<td class=$form_class align=right width=25%>Hostgroups:</td>
<td class=$form_class align=left colspan=2>
<input class=$form_class type=checkbox name=hostgroups_select $selected{'hostgroups_select'}>&nbsp;Apply to Hostgroups.
</td>
</tr>
<tr>
<td class=$form_class align=right width=25%>Hosts:</td>
<td class=$form_class align=left>
<input class=$form_class type=checkbox name=hosts_select $selected{'hosts_select'}>&nbsp;Apply to hosts.
</td>
</tr>
<tr>
<tr>
<td class=$form_class align=left colspan=2><hr/></td>
</tr>);
	}

	if ($view =~ /host_profile/) {
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<td class=$form_class align=right width=25%>Host properties:</td>
<td class=$form_class align=left>
<input type=checkbox class=radio name=apply_parents $selected{'apply_parents'}>&nbsp;Apply parents to hosts. 
</td>
</tr>
<tr>
<td class=$form_class align=left width=25%>&nbsp;</td>
<td class=$form_class align=left>
<input type=checkbox class=radio name=apply_hostgroups value=replace $selected{'apply_hostgroups'}>&nbsp;Apply hostgroups to hosts. 
</td>
</tr>
<tr>
<td class=$form_class align=left width=25%>&nbsp;</td>
<td class=$form_class align=left>
<input type=checkbox class=radio name=apply_escalations $selected{'apply_escalations'}>&nbsp;Apply escalations to hosts. 
</td>
</tr>);
		if ($nagios_ver =~ /^[23]\.x$/) {
			$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=$form_class align=left width=25%>&nbsp;</td>
<td class=$form_class align=left>
<input type=checkbox class=radio name=apply_contactgroups $selected{'apply_contactgroups'}>&nbsp;Apply contact groups to hosts. 
</td>
</tr>);
		}
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=$form_class align=left width=25%>&nbsp;</td>
<td class=$form_class align=left>
<input type=checkbox class=radio name=apply_detail $selected{'apply_detail'}>&nbsp;Apply detail to hosts. 
</td>
</tr>
<tr>
<td class=$form_class align=left colspan=2><hr/></td>
</tr>);
	}
	if ($view eq 'service') {
		if ($selected{'apply_services'} eq 'replace') {
			$selected{'replace'} = 'checked';
		} else {
			$selected{'merge'} = 'checked';
		}

		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<td class=$form_class align=right width=25%>Services:</td>
<td class=$form_class align=left>
<input class=$form_class type=checkbox name=apply_check $selected{'apply_check'}>&nbsp;Apply service check
</td>
</tr>
<tr>
<td class=$form_class align=left width=25%>&nbsp;</td>
<td class=$form_class align=left>
<input class=$form_class type=checkbox name=apply_contact_service $selected{'apply_contact_service'}>&nbsp;Apply contact groups
</td>
</tr>
<tr>
<td class=$form_class align=left width=25%>&nbsp;</td>
<td class=$form_class align=left>
<input class=$form_class type=checkbox name=apply_extinfo_service $selected{'apply_extinfo_service'}>&nbsp;Apply service extended info
</td>
</tr>
<tr>
<td class=$form_class align=left width=25%>&nbsp;</td>
<td class=$form_class align=left>
<input class=$form_class type=checkbox name=apply_escalation_service $selected{'apply_escalation_service'}>&nbsp;Apply service escalation
</td>
</tr>
<tr>
<td class=$form_class align=left width=25%>&nbsp;</td>
<td class=$form_class align=left>
<input class=$form_class type=checkbox name=apply_dependencies $selected{'apply_dependencies'}>&nbsp;Apply dependencies
</td>
</tr>
<tr>
<td class=$form_class align=left width=25%>&nbsp;</td>
<td class=$form_class align=left>
<input type=radio class=radio name=apply_services value=replace $selected{'replace'}>&nbsp;Replace existing service properties (force inheritance). 
</td>
</tr>
<tr>
<td class=$form_class align=left width=25%>&nbsp;</td>
<td class=$form_class align=left>
<input type=radio class=radio name=apply_services value=merge $selected{'merge'}>&nbsp;Merge existing services properties (preserve overrides). 
</td>
</tr>);
	}
	unless ($view eq 'service') {
		if ($selected{'apply_services'} eq 'replace') {
			$selected{'replace'} = 'checked';
		} else {
			$selected{'merge'} = 'checked';
		}
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=$form_class align=right width=25%>Services:</td>
<td class=$form_class align=left>
<input type=radio class=radio name=apply_services value=replace $selected{'replace'}>&nbsp;Replace existing services. 
</td>
</tr>
<tr>
<td class=$form_class align=left width=25%>&nbsp;</td>
<td class=$form_class align=left>
<input type=radio class=radio name=apply_services value=merge $selected{'merge'}>&nbsp;Merge with existing services. 
</td>
</tr>);
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=$form_class align=left colspan=2>&nbsp;</td>
</tr>
</table>
</td>
</tr>);
	return $detail;
}

sub service_template_top(@) {
	my $name = $_[1];
	my $session_id = $_[2];
	my $obj_view = $_[3];
	my $objs = $_[4];
	my $selected = $_[5];
	my %objs = ();
	my $urlstr = undef;
	my $now = time;
	if ($objs) {
		%objs = %{$objs};
		foreach my $key (keys %objs) {
			if ($objs{$key}) { $urlstr .= '&'.$key.'='.$objs{$key} }
		}
	}
	my $colspan = 3;
	$urlstr =~ s/ /+/g;
	my @menus = ('service_detail','service_check');
	
	my $width = 100/$colspan.'%';
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>	
<td valign=top align=left>
<table width=90% cellpadding=0 cellspacing=1 border=0>
<tr>
<td colspan=3>
<table width=100% cellpadding=5 cellspacing=0 align=left border=0>
<tr>
<td class=head>&nbsp;Manage Service Template</td>
</tr>
</table>
</td>
</tr>
<tr>
<td colspan=3>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>);
	my $class = undef;
	my @lmenus = @menus;
	my $last_menu = pop @lmenus;
	my $first_menu = $menus[0];
	foreach my $view (@menus) {
		if ($obj_view eq $view) { 
			$class = 'top_menu_selected';
			if ($view eq $last_menu) {
				$class = 'top_menu_selected_right';
			}
			if ($view eq $first_menu) {
				$class = 'top_menu_selected_left';
			}
		} else {
			$class = 'top_menu_menu';
			if ($view eq $last_menu) {
				$class = 'top_menu_right';
			}
		}
		my $menu = $view;
		$menu = undef;
		my @menu = split(/_/, $view);
		foreach (@menu) { $menu .= "\u$_ " }
		chop $menu;
		my $ename = uri_escape($name);
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<td class=$class width=15% align=center>
<a class=top href=$cgi_dir/$cgi_exe?update_main=1&CGISESSID=$session_id&nocache=$now&top_menu=services&selected=$selected&view=service_template&obj=service_templates&obj_view=$view&name=$ename$urlstr>\u$menu</a>
</td>);
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<td class=top_menu_fill>&nbsp;</td>
</tr>
<tr>
<td class=top_menu_selected_bar colspan=3>&nbsp;</td>
</tr>
</table>);
	if ($obj_view =~ /service_detail|service_profiles/) {
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<form name=form action=$cgi_dir/$cgi_exe onsubmit="selIt();" method=post generator=service_template_top1>);
	} else {
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<form name=form action=$cgi_dir/$cgi_exe method=post generator=service_template_top2>);
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</tr>
<tr>
<td class=data colspan=$colspan>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class width=25%>Name:</td>
<td class=$form_class width=3%>&nbsp;</td>
<td class=$form_class>$name</td>
</tr>
</table>
</td>
</tr>);
	return $detail;
}


sub service_top(@) {
	my $name = $_[1];
	my $session_id = $_[2];
	my $obj_view = $_[3];
	my $objs = $_[4];
	my $externals = $_[5];
	my $selected = $_[6];
	my $host_id = $_[7];
	my %objs = ();
	my $urlstr = undef;
	my $now = time;
	if ($objs) {
		%objs = %{$objs};
		foreach my $key (keys %objs) {
			if ($objs{$key}) { $urlstr .= '&'.$key.'='.$objs{$key} }
		}
	}
	my $colspan = 5;
	$urlstr =~ s/ /+/g;
	my @menus = ('service_detail','service_check','service_dependencies');
	unless ($host_id) { push @menus, 'service_profiles' }
	if ($externals) { push @menus, 'service_externals'; $colspan = 6; }
	unless ($host_id) { push @menus, 'apply_hosts' }
	
	my $width = 100/$colspan.'%';
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>	
<td valign=top align=left>
<table width=90% cellpadding=0 cellspacing=1 border=0>
<tr>
<td>
<table width=100% cellpadding=5 cellspacing=0 align=left border=0>
<tr>
<td class=head colspan=$colspan>&nbsp;Manage Service</td>
</tr>
</table>
</td>
</tr>
<tr>
<td>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>);
	my $class = undef;
	my @lmenus = @menus;
	my $last_menu = pop @lmenus;
	my $first_menu = $menus[0];
	foreach my $view (@menus) {
		if ($obj_view eq $view) { 
			$class = 'top_menu_selected';
			if ($view eq $last_menu) {
				$class = 'top_menu_selected_right';
			}
			if ($view eq $first_menu) {
				$class = 'top_menu_selected_left';
			}
		} else {
			$class = 'top_menu_menu';
			if ($view eq $last_menu) {
				$class = 'top_menu_right';
			}
		}
		my $menu = $view;
		$menu = undef;
		my @menu = split(/_/, $view);
		foreach (@menu) { $menu .= "\u$_ " }
		chop $menu;
		my $ename = $name;
		$ename = uri_escape($ename);
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<td class=$class width=$width align=center>
<a class=top href=$cgi_dir/$cgi_exe?update_main=1&CGISESSID=$session_id&nocache=$now&top_menu=services&selected=$selected&view=service&obj=services&obj_view=$view&name=$ename&host_id=$host_id$urlstr>\u$menu</a>
</td>);
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</tr>
<tr>
<td class=top_menu_selected_bar colspan=$colspan>&nbsp;</td>
</tr>
</table>);
	if ($obj_view =~ /service_detail|service_profiles/) {
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<form name=form action=$cgi_dir/$cgi_exe onsubmit="selIt();" method=post generator=service_top1>);
	} else {
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<form name=form action=$cgi_dir/$cgi_exe method=post generator=service_top2>);
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data colspan=$colspan>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class width=25%>Name:</td>
<td class=$form_class width=3%>&nbsp;</td>
<td class=$form_class>$name</td>
</tr>
</table>
</td>
</tr>);
	return $detail;
}

sub service_profile_top(@) {
	my $name = $_[1];
	my $session_id = $_[2];
	my $obj_view = $_[3];
	my $objs = $_[4];
	my $selected = $_[5];
	my %objs = ();
	my $urlstr = undef;
	my $now = time;
	if ($objs) {
		%objs = %{$objs};
		foreach my $key (keys %objs) {
			if ($objs{$key}) { $urlstr .= '&'.$key.'='.$objs{$key} }
		}
	}
	my $colspan = 5;
	$urlstr =~ s/ /+/g;
	my @menus = ('services','assign_hosts','assign_hostgroups','host_profiles','apply');
	my $width = 100/$colspan.'%';
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>	
<td valign=top align=left>
<table width=90% cellpadding=0 cellspacing=1 border=0>
<tr>
<td>
<table width=100% cellpadding=5 cellspacing=0 align=left border=0>
<tr>
<td class=head colspan=$colspan>&nbsp;Service Profile</td>
</tr>
</table>
</td>
</tr>
<tr>
<td>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>);
	my $class = undef;
	my @lmenus = @menus;
	my $last_menu = pop @lmenus;
	my $first_menu = $menus[0];
	foreach my $view (@menus) {
		if ($obj_view eq $view) { 
			$class = 'top_menu_selected';
			if ($view eq $last_menu) {
				$class = 'top_menu_selected_right';
			}
			if ($view eq $first_menu) {
				$class = 'top_menu_selected_left';
			}
		} else {
			$class = 'top_menu_menu';
			if ($view eq $last_menu) {
				$class = 'top_menu_right';
			}
		}
		my $menu = $view;
		$menu = undef;
		my @menu = split(/_/, $view);
		foreach (@menu) { $menu .= "\u$_ " }
		my $ename = $name;
		$ename = uri_escape($ename);
		chop $menu;
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<td class=$class width=$width align=center>
<a class=top href=$cgi_dir/$cgi_exe?update_main=1&CGISESSID=$session_id&top_menu=profiles&nocache=$now&selected=$selected&view=service_profile&obj=profile&obj_view=$view&name=$ename$urlstr>\u$menu</a>
</td>);
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</tr>
<tr>
<td class=top_menu_selected_bar colspan=$colspan>&nbsp;</td>
</tr>
</table>);
	if ($obj_view =~ /services|assign_hosts|assign_hostgroups|host_profiles/) {
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<form name=form action=$cgi_dir/$cgi_exe onsubmit="selIt();" method=post generator=service_profile_top1>);
	} else {
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<form name=form action=$cgi_dir/$cgi_exe method=post generator=service_profile_top2>);
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data colspan=$colspan>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class width=25%>Name:</td>
<td class=$form_class width=3%>&nbsp;</td>
<input type=hidden name=name value="$name">
<td class=$form_class>$name</td>
</tr>
</table>
</td>
</tr>);
	return $detail;
}


sub group_top(@) {
	my $name = $_[1];
	my $obj_view = $_[2];
	my $now = time;
	my $colspan = 4;
	my @menus = ('detail','hosts','sub_groups','macros');

	my $width = '25%';
	my $title = 'Manage Group';
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>	
<td valign=top align=left>
<table width=90% cellpadding=0 cellspacing=1 border=0>
<tr>
<td>
<table width=100% cellpadding=5 cellspacing=0 align=left border=0>
<tr>
<td class=head colspan=$colspan>&nbsp;$title</td>
</tr>
</table>
</td>
</tr>
<tr>
<td>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>);
	if ($obj_view =~ /detail|hosts/) {
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<form name=form action=$cgi_dir/$cgi_exe onsubmit="selIt();" method=post generator=group_top1>);
	} else {
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<form name=form action=$cgi_dir/$cgi_exe method=post generator=group_top2>);
	}
	my $class = undef;
	my $bclass = undef;
	my @lmenus = @menus;
	my $last_menu = pop @lmenus;
	my $first_menu = $menus[0];
	foreach my $view (@menus) {
		if ($obj_view eq $view) { 
			$class = 'top_menu_selected';
			$bclass = 'topbuttonselected';
			if ($view eq $last_menu) {
				$class = 'top_menu_selected_right';
			}
			if ($view eq $first_menu) {
				$class = 'top_menu_selected_left';
			}
		} else {
			$class = 'top_menu_menu';
			$bclass = 'topbutton';
			if ($view eq $last_menu) {
				$class = 'top_menu_right';
			}
		}
		my $menu = $view;
		$menu = undef;
		my @menu = split(/_/, $view);
		foreach (@menu) { $menu .= "\u$_ " }
		chop $menu;
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<td class=$class width=$width align=center>
<input type=submit class=$bclass name=$view value="$menu">	
</td>);
	}

	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</tr>
<tr>
<td class=top_menu_selected_bar colspan=$colspan>&nbsp;</td>
</tr>
</table>
<tr>
<td class=data colspan=$colspan>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class width=25%>Name:</td>
<td class=$form_class width=3%>&nbsp;</td>
<td class=$form_class>$name</td>
<input type=hidden name=name value="$name">
</tr>
</table>
</td>
</tr>);
	return $detail;
}


sub access_top(@) {
	my $groupid = $_[1];
	my $session_id = $_[2];
	my $obj_view = $_[3];
	my @menus = @{$_[4]};
	my $urlstr = undef;
	my $now = time;
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>	
<td valign=top align=left>
<table class width=75% cellpadding=0 cellspacing=1 border=0>
<tr>
<td>
<table width=100% cellpadding=5 cellspacing=0 align=left border=0>
<tr>
<td class=head>Access Values User Group: $groupid</td>
</tr>
</table>
</td>
</tr>
<tr>
<td>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>);
	my $class = undef;
	foreach my $view (@menus) {
		if ($obj_view eq $view) { 
			$class = 'top_menu_selected';
		} else {
			$class = 'top_menu_menu';
		}
		my $menu = $view;
		$menu = undef;
		my @menu = split(/_/, $view);
		foreach (@menu) { $menu .= "\u$_ " }
		chop $menu;
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<td class=$class align=center>
<a class=top href=$cgi_dir/$cgi_exe?update_main=1&CGISESSID=$session_id&top_menu=control&nocache=$now&view=control&obj=user_groups&groupid=$groupid&access_set=$view>\u$menu</a>
</td>);
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</tr>
</table>
</td>
</tr>
<form name=form action=$cgi_dir/$cgi_exe method=post generator=access_top>);
	return $detail;
}

sub escalation_top() {
	my $name = $_[1];
	my $session_id = $_[2];
	my $obj_view = $_[3];
	my $type = $_[4];
	my $nagios_ver = $_[5];
	my $colspan = 4;	
	my @menus = ('detail');
	if ($obj_view eq 'assign_contactgroups') {
		push @menus, 'assign_contactgroups';
	} else {
		push (@menus,('assign_hostgroups','assign_hosts'));
		if ($type eq 'service') {
			if ($nagios_ver =~ /^[23]\.x$/) {
				push (@menus,('assign_service_groups','assign_services'));
				$colspan = 5;
			} else {
				push @menus, 'assign_services';
				$colspan = 4;
			}
		}
	}
	my $width = 100/$colspan.'%';
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>	
<td valign=top align=left>
<table width=90% cellpadding=0 cellspacing=1 border=0>
<tr>
<td>
<table width=100% cellpadding=5 cellspacing=0 align=left border=0>
<tr>
<td class=head colspan=$colspan>&nbsp;Escalation Tree</td>
</tr>
</table>
</td>
</tr>
<tr>
<td>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>);
	my $class = undef;
	my $bclass = undef;
	my @lmenus = @menus;
	my $last_menu = pop @lmenus;
	my $first_menu = $menus[0];
	my $menu_str = undef;
	foreach my $view (@menus) {
		if ($obj_view eq $view) { 
			$class = 'top_menu_selected';
			$bclass = 'topbuttonselected';
			if ($view eq $last_menu) {
				$class = 'top_menu_selected_right';
			}
			if ($view eq $first_menu) {
				$class = 'top_menu_selected_left';
			}
		} else {
			$class = 'top_menu_menu';
			$bclass = 'topbutton';
			if ($view eq $last_menu) {
				$class = 'top_menu_right';
			}
		}
		my $menu = $view;
		$menu = undef;
		my @menu = split(/_/, $view);
		foreach (@menu) { $menu .= "\u$_ " }
		chop $menu;
		$menu_str .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<td class=$class width=$width align=center>
<input type=submit class=$bclass name=$view value="$menu">	
</td>);
	}
	$menu_str .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</tr>
<tr>
<td class=top_menu_selected_bar colspan=$colspan>&nbsp;</td>
</tr>);
	unless ($obj_view =~ /detail/) {
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<form name=form action=$cgi_dir/$cgi_exe onsubmit="selIt();" method=post generator=escalation_top1>);
	} else {
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<form name=form action=$cgi_dir/$cgi_exe method=post generator=escalation_top2>);
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
$menu_str
</tr>
</table>
</td>
</tr>
<tr>
<td class=data colspan=$colspan>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class width=25%>\u$type escalation tree:</td>
<td class=$form_class>$name</td>
<input type=hidden name=name value="$name">
<input type=hidden name=name value="$type">
</tr>
</table>
</td>
</tr>);
	return $detail;
}

sub escalation_tree(@) {
	my $ranks = $_[1];
	my $templates = $_[2];
	my $obj_view = $_[3];
	my %ranks = %{$ranks};
	my %templates = %{$templates};
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class valign=top width=25%>Escalation detail:</td>
<td class=$form_class width=5%>&nbsp;</td>
<td class=$form_class>
<ol>);
	foreach my $rank (sort {$a <=> $b} keys %ranks ) {
		$detail .= "\n<li>$templates{$ranks{$rank}}{'name'}</li>\n<ul>";
		if ($templates{$ranks{$rank}}{'service_description'}) {
			unless ($obj_view eq 'service_detail' || $obj_view eq 'service_names') {
				$detail .= "\n<li>service_description: $templates{$ranks{$rank}}{'service_description'}</li>";
			}
		}
		if ($templates{$ranks{$rank}}{'notification_interval'}) {
			my $val = $templates{$ranks{$rank}}{'notification_interval'};
			$val =~ s/-zero-/0/g;
			$detail .= "\n<li>notification_interval: $val</li>";
		}
		if ($templates{$ranks{$rank}}{'first_notification'}) {
			my $val = $templates{$ranks{$rank}}{'first_notification'};
			$val =~ s/-zero-/0/g;
			$detail .= "\n<li>first_notification: $val</li>";
		}
		if ($templates{$ranks{$rank}}{'last_notification'}) {
			my $ln = $templates{$ranks{$rank}}{'last_notification'};
			$ln =~ s/-zero-/0/g;
			$detail .= "\n<li>last_notification: $ln</li>";
		}
		if ($templates{$ranks{$rank}}{'contactgroups'}) {
			$detail .= "\n<li>contactgroups: $templates{$ranks{$rank}}{'contactgroups'}</li></ul>";
		}
		$detail .= "<br />";
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</ol>
</td>
</tr>
</table>
</td>
</tr>);
	return $detail;

}

sub show_list(@) {
	my $ranks = $_[1];
	my $templates = $_[2];
	my $obj_view = $_[3];
	my %ranks = %{$ranks};
	my %templates = %{$templates};
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=$form_class valign=top width=25%>Escalation detail:
</td>
<td class=$form_class>
<ol>);
	foreach my $rank (sort {$a <=> $b} keys %ranks ) {
		$detail .= "\n<li>$templates{$ranks{$rank}}{'name'}</li>\n<ul>";
		if ($templates{$ranks{$rank}}{'service_description'}) {
			unless ($obj_view eq 'service_detail') {
				$detail .= "\n<li>service_description: $templates{$ranks{$rank}}{'service_description'}</li>";
			}
		}
		if ($templates{$ranks{$rank}}{'notification_interval'}) {
			$detail .= "\n<li>notification_interval: $templates{$ranks{$rank}}{'notification_interval'}</li>";
		}
		if ($templates{$ranks{$rank}}{'first_notification'}) {
			$detail .= "\n<li>first_notification: $templates{$ranks{$rank}}{'first_notification'}</li>";
		}
		if ($templates{$ranks{$rank}}{'last_notification'}) {
			my $ln = $templates{$ranks{$rank}}{'last_notification'};
			$ln =~ s/-zero-/0/g;
			$detail .= "\n<li>last_notification: $ln</li>";
		}
		if ($templates{$ranks{$rank}}{'contactgroups'}) {
			$detail .= "\n<li>contactgroups: $templates{$ranks{$rank}}{'contactgroups'}</li></ul>";
		}
		$detail .= "<br />";
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</ol>
</td>
</tr>);
	return $detail;

}

sub service_instances(@) {
	my %instances = %{$_[1]};
	my $doc = $_[2];
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td>
<table width=100% cellspacing=0 align=left border=0>
<tr>
<td class=wizard_title colspan=4 valign=top colspan=3>Multiple Instances (optional)</td>
</tr>
<tr>
<td class=wizard_body colspan=6>
<table width=100% cellpadding=7 cellspacing=0 align=left border=0>
<tr>
<td>
$doc
</td>
</tr>
</table>
</td>
</tr>
<tr>
<td class=top_border width=100% colspan=5>
<table width=100% cellpadding=0 cellspacing=0 border=0>
<tr>	
<td width=10%>Name:</td>
<td width=20%><input type=text size=20 name=inst value="" tabindex=></td>
<td width=45%>&nbsp;or enter a numbered range:&nbsp;
<input type=text size=4 name=range_from value="">
&nbsp;&ndash;&nbsp;&nbsp;<input type=text size=4 name=range_to value="" tabindex=></td>
<td width=25%>&nbsp;</td>
</tr>
</table>
</td>
</tr>
<tr>
<td class=top_border colspan=7 valign=top colspan=4>
<input class=submitbutton type=submit name=add_instance value="Add Instance(s)"
</td>
</tr>);
	if (%instances) {
		my @alph_sorted = ();
		my @num_sorted = ();
		my %instance_sort = ();
		foreach my $instance (keys %instances) {
			my $inst = $instance;
			$inst =~ s/^_//;
			$inst .= rand();
			if ($inst =~ /^\d+/) {
				push @num_sorted, $inst;
			} else {
				push @alph_sorted, $inst;
			}
			$instance_sort{$inst} = $instances{$instance};
			$instance_sort{$inst}{'name'} = $instance;
		}
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<script language=JavaScript>
function doCheckAll()
{
  with (document.form) {
    for (var i=0; i < elements.length; i++) {
        if (elements[i].type == 'checkbox' && (elements[i].name == 'rem_inst'))
           elements[i].checked = true;
    }
  }
}
function doUnCheckAll()
{
  with (document.form) {
    for (var i=0; i < elements.length; i++) {
        if (elements[i].type == 'checkbox' && (elements[i].name == 'rem_inst'))
           elements[i].checked = false;
    }
  }
}
</script>
<tr>
<td class=top_border valign=top width=3%>&nbsp;</td>
<td class=top_border align=left valign=top width=20%><b>Instance</b></td>
<td class=top_border valign=top width=13% colspan=2><b>Status</b></td>
<td class=top_border align=left valign=top width=50%><b>Arguments</b></td>
</tr>);
		my $row = 1;

		foreach my $instance (sort { $a <=> $b } @num_sorted) {
			my $class = undef;
			if ($row == 1) {
				$class = 'row_lt';
				$row = 2;
			} elsif ($row == 2) {
				$class = 'row_dk';
				$row = 1;
			}
			my $checked = undef;
			if ($instance_sort{$instance}{'status'}) { $checked = 'checked' }
			$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=$class valign=top width=3%>
<input type=checkbox name=rem_inst value=$instance_sort{$instance}{'id'}>
</td>
<td class=$class align=left valign=top width=20%>
<input type=text name=instance_$instance_sort{$instance}{'id'} value="$instance_sort{$instance}{'name'}">
</td>
<td class=$class valign=top width=3%>
<input type=checkbox name=status_$instance_sort{$instance}{'id'} $checked value="$instance_sort{$instance}{'name'}" $checked>
</td>
<td class=$class align=left valign=top width=10%>Active</td>
<td class=$class align=left valign=top width=64%>
<input type=text size=70 name=args_$instance_sort{$instance}{'id'} value="$instance_sort{$instance}{'args'}">
</td>
</tr>);
		}
		foreach my $instance (sort { lc($a) cmp lc($b) } @alph_sorted) {
			my $class = undef;
			if ($row == 1) {
				$class = 'row_lt';
				$row = 2;
			} elsif ($row == 2) {
				$class = 'row_dk';
				$row = 1;
			}
			my $checked = undef;
			if ($instance_sort{$instance}{'status'}) { $checked = 'checked' }
			$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=$class valign=top width=3%>
<input type=checkbox name=rem_inst value=$instance_sort{$instance}{'id'}>
</td>
<td class=$class align=left valign=top width=20%>
<input type=text name=instance_$instance_sort{$instance}{'id'} value="$instance_sort{$instance}{'name'}">
</td>
<td class=$class valign=top width=3%>
<input type=checkbox name=status_$instance_sort{$instance}{'id'} $checked value="$instance_sort{$instance}{'name'}" $checked>
</td>
<td class=$class align=left valign=top width=10%>Active</td>
<td class=$class align=left valign=top width=64%>
<input type=text size=70 name=args_$instance_sort{$instance}{'id'} value="$instance_sort{$instance}{'args'}">
</td>
</tr>);
		}
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=top_border colspan=5>
<input class=submitbutton type=submit name=remove_instance value="Remove Instance(s)">&nbsp;&nbsp;
<input class=submitbutton type=button value="Check All" onclick=doCheckAll()>&nbsp;&nbsp;
<input class=submitbutton type=button value="Uncheck All" onclick=doUnCheckAll()>
</td>
</tr>);
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</table>
</td>
</tr>);	

	return $detail
}

sub dependency_list(@) {
	my $name = $_[1];
	my $obj = $_[2];
	my $service_id = $_[3];
	my $session_id = $_[4];
	my $dependencies = $_[5];
	my %dependencies = %{$dependencies};
	my $view = 'manage_host';
	if ($obj eq 'services') { $view = 'service' }
	my $now = time;
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data2>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=row2 width=25% align=left>Dependency
</td>
<td class=row2 width=50% align=left>Parent Host 
</td>
<td class=row2 width=20% align=left>&nbsp;
</td>
</tr>);
	my $body = undef;
	$name =~ s/ /+/g;
	foreach my $dep (sort {$a <=> $b} keys %dependencies) {
		$body .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=row_lt align=left>$dependencies{$dep}[0]
</td>
<td class=row_lt align=left>$dependencies{$dep}[1]
</td>
<td class=row_lt align=center>
<a class=left href=$cgi_dir/$cgi_exe?update_main=1&CGISESSID=$session_id&top_menu=$obj&nocache=$now&view=$view&obj=$obj&obj_view=service_dependencies&name=$name&service_id=$service_id&dependency_id=$dep&remove_dependency=1>
<img src=$doc_root_monarch/images/x_row_lt.png border=0>&nbsp;remove</a>
</td>
</tr>);
	}
	if (!$body) {
		$body .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=row_lt align=left colspan=3>no dependencies defined
</td>
</tr>);
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
$body
</table>
</td>
</tr>);
	return $detail;
}

sub dependency_add(@) {
	my $dep_template = $_[1];
	my $dep_templates = $_[2];
	my $hosts = $_[3];
	my $docs = $_[4];
	my @dep_templates = @{$dep_templates};
	my @hosts = @{$hosts};
	my %docs = %{$docs};
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class width=25% align=left valign=top>Dependency:
</td>
<td class=$form_class width=3% valign=top align=center><a class=orange href=#doc title="$docs{'dependency'}">&nbsp;?&nbsp;</a>
<td class=$form_class align=left valign=top>
<select name=dep_template onChange="submit()">);
	if (!$dep_templates[0]) { 
		$detail .= "\n<option value=>-no service names to add-</option>";
	}
	$detail .= "\n<option selected value=></option>";
	foreach my $item (@$dep_templates) {
		if ($item eq $dep_template) {
			$detail .= "\n<option selected value=\"$item\">$item</option>";
		} else {
			$detail .= "\n<option value=\"$item\">$item</option>";
		}
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</select>&nbsp;&nbsp;
</td>
</tr>
<tr>
<td class=$form_class width=10% align=left valign=top>Parent host:
</td>
<td class=$form_class width=3% valign=top align=center><a class=orange href=#doc title="$docs{'parent_host'}">&nbsp;?&nbsp;</a>
<td class=$form_class valign=top align=left>
<select name=depend_on_host size=5>);
	if (!$hosts[0]) { 
		$detail .= "\n<option value=>-no service names to add-</option>";
	}
	$detail .= "\n<option selected value=></option>";
	foreach my $item (@hosts) {
		$detail .= "\n<option value=\"$item\">$item</option>";
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</select>&nbsp;&nbsp;
</td>
</tr>
</table>
</td>
</tr>);
	return $detail;
}


sub display_template(@) {
	my $template = $_[1];
	my $plist = $_[2];
	my %template = %{$template};
	my @props = split(/,/, $plist);
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class valign=top width=25%>Detail:</td>
<td class=$form_class width=5%>&nbsp;</td>
<td class=$form_class align=left>
<table width=100% cellpadding=2 cellspacing=0 border=0>);
	foreach my $p (@props) {
		if ($p eq 'name') { next }
		$template{$p} =~ s/-zero-/0/g;
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=$form_class width=50%>$p</td>
<td class=$form_class align=left>$template{$p}
</td>
</tr>);		
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</table>
</td>
</tr>
</table>
</td>
</tr>);		
	return $detail;
}

sub form_files(@) {
	my $upload_dir = $_[1];
	my $files = $_[2];
	my @files = @{$files};
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>);
	unless ($files[0]) {
		$detail .= "There are no eligible files in $upload_dir.";
	} else {
		foreach my $file (sort @files) {
			$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=$form_class width=10% align=right>
<input type=checkbox name=file value="$file"></td>
<td class=$form_class>$file</td>
</tr>);
		}
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</table>
</td>
</tr>);		
	return $detail
}

sub service_group(@) {
	my $session_id = $_[1];
	my $view = $_[2];
	my $name = $_[3];
	my $host_services = $_[4];
	my $host = $_[5];
	my $host_nonmembers = $_[6];
	my $hosts = $_[7];
	my $service = $_[8];
	my $service_nonmembers = $_[9];
	my $services = $_[10];

	my %host_services = %{$host_services};
	my @hosts = @{$hosts};
	my @host_nonmembers = @{$host_nonmembers};
	my @services = @{$services};
	my @service_nonmembers = @{$service_nonmembers};
	my $now = time;
	$name =~ s/\s/+/g;
	my $hostn = $host;
	$hostn =~ s/\s/+/g;
	my $servicen = $service;
	$servicen =~ s/\s/+/g;
	my $detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class width=40% colspan=2 align=left>
<table class=form cellspacing=1 cellpadding=3 width=100% align=left border=0>
<tr>	
<td class=row2>Host</td>
<td class=row2>Service</td>
<td class=row2 colspan=2>&nbsp;</td>
</tr>);
	unless (%host_services) {
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>	
<td class=row_lt valign=top>
&nbsp;
</td>
<td class=row_lt valign=top>
&nbsp;
</td>
<td class=row_lt align=center valign=top>
&nbsp;
</td>
</tr>);	
	}
	foreach my $host (sort keys %host_services) {
		my $hname = $host;
		$hname =~ s/\s/+/g;
		foreach my $service (@{$host_services{$host}}) {
			my $sname = $service;
			$sname =~ s/\s/+/g;
			$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>	
<td class=row_lt valign=top>
$host
</td>
<td class=row_lt valign=top>
$service
</td>
<td class=row_lt align=center valign=top>
<a class=left href=$cgi_dir/$cgi_exe?update_main=1&CGISESSID=$session_id&top_menu=services&nocache=$now&view=$view&obj=servicegroups&name=$name&host=$hostn&service=$servicen&del_host=$hname&del_service=$sname&remove_service=1><img src=$doc_root_monarch/images/x_row_lt.png border=0>&nbsp;remove</a>
</td>
</tr>);	
		}
	}

	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</table>
</td>
</tr>
</table>
</td>
</tr>
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class colspan=5>
<table width=100% cellpadding=3 cellspacing=0 border=0>
<tr>
<td class=$form_class align=left width=10% valign=top>Host:
<td class=$form_class align=left width=45% valign=top>
<select name=host onChange="submit()">);
	unless (@hosts) { 
		$detail .= "\n<option selected value=></option>";
		$detail .= "\n<option value=>-no hosts-</option>";
	} else {
		if ($host) {
			$detail .= "\n<option value=></option>";
		} else {
			$detail .= "\n<option selected value=></option>";
		}
		foreach my $h (@hosts) {
			if ($host eq $h) {
				$detail .= "\n<option selected value=\"$host\">$host</option>";			
			} else {
				$detail .= "\n<option value=\"$h\">$h</option>";
			}
		}
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</select>
</td>
<td class=$form_class rowspan=3 width=45% valign=top align=left>
<select name=services size=10 multiple>);
	my $options = undef;
	$detail .= "\n<option selected value=></option>";
	foreach my $nmem (@host_nonmembers) {
		my $got_service = 0;
		foreach (@{$host_services{$host}}) { 
			if ($_ eq $nmem) { $got_service = 1 }
		}
		unless ($got_service) {
			$options .= "\n<option value=\"$nmem\">$nmem</option>";
		}
	}
	unless ($options) { $options = "\n<option value=>-no services-</option>" }
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
$options
</select>
</td>
</tr>
<tr>
<td class=$form_class align=left width=10% valign=top>&nbsp;
<td class=$form_class align=left width=45% valign=top><input class=submitbutton type=submit name=add_services value="Add Service(s)">
</td>
</tr>
<tr>
<td class=$form_class align=left width=10% valign=top>&nbsp;
<td class=$form_class align=left width=45% valign=top>&nbsp;
</td>
</tr>
</table>
</td>
</tr>
</table>
</td>
</tr>
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<tr>
<td class=$form_class colspan=5>
<table width=100% cellpadding=3 cellspacing=0 border=0>
<tr>
<td class=$form_class align=left width=10% valign=top>Service:
<td class=$form_class align=left width=45% valign=top>
<select name=service onChange="submit()">);
	unless (@services) { 
		$detail .= "\n<option selected value=></option>";
		$detail .= "\n<option value=>-no hosts-</option>";
	} else {
		if ($host) {
			$detail .= "\n<option value=></option>";
		} else {
			$detail .= "\n<option selected value=></option>";
		}
		foreach my $s (@services) {
			if ($service eq $s) {
				$detail .= "\n<option selected value=\"$service\">$service</option>";			
			} else {
				$detail .= "\n<option value=\"$s\">$s</option>";
			}
		}
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</select>
</td>
<td class=$form_class rowspan=3 valign=top width=45%>
<select name=hosts size=10 multiple>);
	$options = undef;
	$detail .= "\n<option selected value=></option>";
	foreach my $nmem (@service_nonmembers) {
		my $got_host = 0;
		foreach my $host(keys %host_services) { 
			if ($host_services{$host} eq $service) { $got_host = 1 }
		}
		unless ($got_host) {
			$options .= "\n<option value=\"$nmem\">$nmem</option>";
		}
	}
	if (!$options) { $options = "\n<option value=>-no hosts-</option>" }
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
$options
</select>
</td>
</tr>
<tr>
<td class=$form_class align=left width=10% valign=top>&nbsp;
<td class=$form_class align=left width=45% valign=top><input class=submitbutton type=submit name=add_hosts value="Add Host(s)">
</td>
</tr>
<tr>
<td class=$form_class align=left width=10% valign=top>&nbsp;
<td class=$form_class align=left width=45% valign=top>&nbsp;
</td>
</tr>
</table>
</td>
</tr>
</table>
</td>
</tr>);
	return $detail;
}

sub resource_select() {
	my $res = $_[1];
	my $selected = $_[2];
	my $view = $_[3];
	my %resources = %{$res};
	my %selected = %{$selected};
	my $user = $selected{'name'};
	$user =~ s/user//;
	my $comment = $resources{"resource_label$user"};
	my $detail = undef;
	if ($selected{'name'}) {
		$detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class align=left colspan=2 width=13%><input type=hidden name=resource value="$selected{'name'}">$selected{'name'}</td>
<td class=$form_class align=left width=70%><input type=text size=70 name=resource_value value="$selected{'value'}"></td>
<td class=$form_class align=left width=17%><input class=submitbutton type=submit name=update_resource value="Update"></td>
</tr>
<tr>
<td class=$form_class align=left colspan=2 width=13%>Comment:</td>
<td class=$form_class align=left width=70%><input type=text size=80 name=comment value="$comment"></td>
</tr>
</table>
</tr>);
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class align=left width=17%></td>
</tr>
<tr>
<td class=top_menu_selected_bar align=left colspan=5>Select resource macro:</td>
</tr>);
	for (my $i = 1;$i < 33; $i++) {
		my $password = 0;
		if ($view eq 'commands' && $resources{"resource_label$i"} =~ /password/i) { $password = 1 }
		unless ($selected{'name'} eq  "user$i" || $password) {
			$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=$form_class align=left width=3% valign=top>
<input class=$form_class type=checkbox name=resource_user$i onClick="submit()"></td>
<td class=$form_class align=left width=10% valign=top>user$i
<td class=$form_class align=left width=70% valign=top>$resources{"user$i"});
		if ($resources{"resource_label$i"}) {
			my $doc = $resources{"resource_label$i"};
			$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<a class=orange href=#doc title="$doc">&nbsp;?&nbsp;</a>);
		}
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</td>
<td class=$form_class width=17% align=center>&nbsp;
</td>
</tr>);			
		}
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</tr>
</table>
</td>
</td>);
	return $detail;
}

sub table_script_links(@) {
	my $session_id = $_[1];
	my $type = $_[2];
	my $script = $_[3];
	my %script = %{$script};
	my $now = time;
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>	
<td valign=top>
<table width=75% cellpadding=3 cellspacing=0 border=0>
<tr>
<td>\u$type Scripts</td>
</tr>);
	foreach my $name (sort keys %script) {
		unless ($name =~ /HASH/) {
			my $url = undef;
			if ($script{$name} =~ /Error/) { 
				$url = qq(@{[&$Instrument::show_trace_as_html_comment()]}<h2>$name - $script{$name}</h2>);
			} else {
				$url = qq(@{[&$Instrument::show_trace_as_html_comment()]}<a class=left href=$cgi_dir/$cgi_exe?update_main=1&CGISESSID=$session_id&top_menu=control&nocache=$now&view=control&obj=run_external_scripts&ext_info=$name&type=$type>$name $script{$name}&nbsp;<img src=$doc_root_monarch/images/arrow.gif border=0></a>);			
			}
			$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}\n<tr>\n<td>$url\n</td>\n</tr>);
		}
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</table>
</td>
</tr>);
	return $detail;
}

sub radio_options(@) {
	my $title = $_[1];
	my $name = $_[2];
	my $value = $_[3];
	my $doc = $_[4];
	my $other = 'Use an interleave factor of:';
	my %selected = ();
	my $text_val = undef;
	if ($value eq 's') {
		$selected{'s'} = 'checked';
	} elsif ($value eq 'd') {
		$selected{'d'} =  'checked';
	} elsif ($value eq 'n') {
		$selected{'n'} =  'checked';
	} else {
		$selected{'other'} =  'checked';
		$text_val = $value;
	}
	$title =~ s/_/ /g;
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class width=25% valign=top>\u$title</td>);
	if ($doc) {
		$detail .= "\n<td class=$form_class width=3% valign=top align=center>\n<a class=orange href=#doc title=\"$doc\" tabindex=-1>&nbsp;?&nbsp;</a>";
	} else {
		$detail .= "\n<td class=$form_class width=3% align=center>\n&nbsp;";
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<td class=$form_class>
<table width=100% cellpadding=3 cellspacing=0 border=0>);
	if ($name =~ /inter_check_delay_method|service_inter_check_delay_method|host_inter_check_delay_method/) {
		$other = 'Use an inter-check delay of:';
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=$form_class width=5%>
<input type=radio class=radio name=radio_option_$name value=n $selected{'n'}>
</td>
<td class=$form_class>
None
</td>
<td class=$form_class>
&nbsp;
</td>
</tr>
<tr>
<td class=$form_class width=5%>
<input type=radio class=radio name=radio_option_$name value=d $selected{'d'}>
</td>
<td class=$form_class>
Dumb
</td>
<td class=$form_class>
&nbsp;
</td>
</tr>);
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=$form_class width=5%>
<input type=radio class=radio name=radio_option_$name value=s $selected{'s'}>
</td>
<td class=$form_class>
Smart
</td>
<td class=$form_class>
&nbsp;
</td>
</tr>
<tr>
<td class=$form_class width=5%>
<input type=radio class=radio name=radio_option_$name value=other $selected{'other'}>
</td>
<td class=$form_class align=center width=35%>
$other
</td>
<td class=$form_class>
<input type=text size=5 name=other_$name value="$text_val">
</td>
</tr>
</table>);
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</td>
</tr>
</table>
</td>
</tr>);
	return $detail;
}

sub log_rotation(@) {
	my $title = $_[1];
	my $name = $_[2];
	my $value = $_[3];
	my $doc = $_[4];
	my %selected = ();
	if ($value eq 'n') {
		$selected{'n'} = 'checked';
	} elsif ($value eq 'h') {
		$selected{'h'} = 'checked';
	} elsif ($value eq 'd') {
		$selected{'d'} = 'checked';
	} elsif ($value eq 'w') {
		$selected{'w'} = 'checked';
	} elsif ($value eq 'm') {
		$selected{'m'} = 'checked';
	}
	$title =~ s/_/ /g;
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class width=25% valign=top>\u$title</td>);
	if ($doc) {
		$detail .= "\n<td class=$form_class width=3% valign=top align=center>\n<a class=orange href=#doc title=\"$doc\" tabindex=-1>&nbsp;?&nbsp;</a>";
	} else {
		$detail .= "\n<td class=$form_class width=3% align=center>\n&nbsp;";
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<td class=$form_class>
<table width=100% cellpadding=3 cellspacing=0 border=0>
<tr>
<td class=$form_class width=5%>
<input type=radio class=radio name=log_rotation_method value=n $selected{'n'}>
</td>
<td class=$form_class>
None
</td>
</tr>
<tr>
<td class=$form_class width=5%>
<input type=radio class=radio name=log_rotation_method value=h $selected{'h'}>
</td>
<td class=$form_class>
Hourly
</td>
</tr>
<tr>
<td class=$form_class width=5%>
<input type=radio class=radio name=log_rotation_method value=d $selected{'d'}>
</td>
<td class=$form_class>
Daily
</td>
</tr>
<tr>
<td class=$form_class width=5%>
<input type=radio class=radio name=log_rotation_method value=w $selected{'w'}>
</td>
<td class=$form_class>
Weekly
</td>
</tr>
<tr>
<td class=$form_class width=5%>
<input type=radio class=radio name=log_rotation_method value=m $selected{'m'}>
</td>
<td class=$form_class>
Monthly
</td>
</tr>
</table>
</td>
</tr>
</table>
</td>
</tr>);
	return $detail;
}

sub date_format(@) {
	my $value = $_[1];
	my $doc = $_[2];
	my %selected = ();
	if ($value eq 'us') {
		$selected{'us'} = 'checked';
	} elsif ($value eq 'euro') {
		$selected{'euro'} = 'checked';
	} elsif ($value eq 'iso8601') {
		$selected{'iso8601'} = 'checked';
	} elsif ($value eq 'strict-iso8601') {
		$selected{'strict-iso8601'} = 'checked';
	}

	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class width=25% valign=top>Date format:</td>);
	if ($doc) {
		$detail .= "\n<td class=$form_class width=3% valign=top align=center>\n<a class=orange href=#doc title=\"$doc\" tabindex=-1>&nbsp;?&nbsp;</a>";
	} else {
		$detail .= "\n<td class=$form_class width=3% align=center>\n&nbsp;";
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<td class=$form_class>
<table width=100% cellpadding=3 cellspacing=0 border=0>
<tr>
<td class=$form_class width=5%>
<input type=radio class=radio name=date_format value=us $selected{'us'}>
</td>
<td class=$form_class>
USA
</td>
<td class=$form_class>
(MM-DD-YYYY HH:MM:SS)
</td>
</tr>
<tr>
<td class=$form_class width=5%>
<input type=radio class=radio name=date_format value=euro $selected{'euro'}>
</td>
<td class=$form_class>
International
</td>
<td class=$form_class>
(DD-MM-YYYY HH:MM:SS)
</td>
</tr>
<tr>
<td class=$form_class width=5%>
<input type=radio class=radio name=date_format value=iso8601 $selected{'iso8601'}>
</td>
<td class=$form_class>
ISO-8601
</td>
<td class=$form_class>
(YYYY-MM-DD HH:MM:SS)
</td>
</tr><tr>
<td class=$form_class width=5%>
<input type=radio class=radio name=date_format value=strict-iso8601 $selected{'strict-iso8601'}>
</td>
<td class=$form_class>
strict-ISO-8601
</td>
<td class=$form_class>
(YYYY-MM-DDTHH:MM:SS)
</td>
</tr>
</table>
</td>
</tr>
</table>
</td>
</tr>);
	return $detail;
}

sub search_results(@) {
	my $objects    = $_[1];
	my $session_id = $_[2];
	my $type       = $_[3];
	my $num_more   = $_[4];
	use URI::Escape;
	my $now = time;
	my %objects = %{$objects};
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
);
	if (%objects) {
		my @objects = ();
		if ($objects{'sort_num'}) {
			delete $objects{'sort_num'};
			@objects = sort { $objects{$a} cmp $objects{$b} } keys %objects;
		} else {
			my @sorted = sort keys %objects;
			@objects = sort { lc($a) cmp lc($b) } (@sorted);
		}
		my $row = 1;
		foreach my $object (@objects) {
			my $class = undef;
			if ($row == 1) {
				$class = 'row_dk';
				$row = 2;
			} elsif ($row == 2) {
				$class = 'row_lt';
				$row = 1;
			}	
			my $name = $object;
			$name =~ s/\s/+/g;
			$name = uri_escape($name);

			if ($type eq 'service') {	
				$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=$class>
<a class=left href=$cgi_dir/$cgi_exe?update_main=1&CGISESSID=$session_id&nocache=$now&top_menu=services&view=service&obj=services&obj_view=service_detail&name=$name title="$object">
<img src=$doc_root_monarch/images/service-blue.gif border=0>&nbsp;$objects{$object}</a>
</td>
</tr>);
			} elsif ($type eq 'ez') {	
				$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=$class>
<a class=left href=$cgi_dir/monarch_ez.cgi?update_main=1&CGISESSID=$session_id&nocache=$now&top_menu=hosts&view=hosts&obj=hosts&name=$name title="$object">
<img src=$doc_root_monarch/images/server.gif border=0>&nbsp;$objects{$object}</a>
</td>
</tr>);			
			} elsif ($type eq 'delete_hosts') {	
				$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=$class>
<input type=checkbox name=delete_host value=$name>&nbsp;
<img src=$doc_root_monarch/images/server.gif border=0>&nbsp;$objects{$object}</a>
</td>
</tr>);					
			} else {
				$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=$class>
<a class=left href=$cgi_dir/$cgi_exe?update_main=1&CGISESSID=$session_id&nocache=$now&top_menu=hosts&view=manage_host&obj=hosts&name=$name title="$object">
<img src=$doc_root_monarch/images/server.gif border=0>&nbsp;$objects{$object}</a>
</td>
</tr>);
			}
		}

	} else {
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=row_lt>
&nbsp;Nothing found
</td>
</tr>);
	}
	if ($num_more > 0) {
		$detail .= "\n<tr><td>($num_more more)</td></tr>";
	}
	$detail .= "\n</table>";
	return $detail;
}
	
sub mas_delete(@) {
	my %hosts = %{ $_[1] };
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<script language=JavaScript>
function doCheckAll()
{
  with (document.form) {
    for (var i=0; i < elements.length; i++) {
        if (elements[i].type == 'checkbox' && (elements[i].name == 'delete_host'))
           elements[i].checked = true;
    }
  }
}
function doUnCheckAll()
{
  with (document.form) {
    for (var i=0; i < elements.length; i++) {
        if (elements[i].type == 'checkbox' && (elements[i].name == 'delete_host'))
           elements[i].checked = false;
    }
  }
}
</script>
<tr>
<td width=100% align=center>
<div class="scroll" style="height: 400px;">
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>);
	my $row = 1;
	my $sort_num = $hosts{'sort_num'};
	delete $hosts{'sort_num'};
	foreach my $host (sort keys %hosts) {
		my $class = undef;
		if ($row == 1) {
			$class = 'row_dk';
			$row = 2;
		} elsif ($row == 2) {
			$class = 'row_lt';
			$row = 1;
		}	
		my $name = uri_escape($host);
		if ($sort_num) {
			$name = uri_escape($hosts{$host});
		} else {
			$hosts{$host} = '&nbsp;';
		}
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=$class>
<input type=checkbox name=delete_host value=$name>&nbsp;
<img src=$doc_root_monarch/images/server.gif border=0>&nbsp;$host</a>
</td>
<td class=$class>
$hosts{$host} &nbsp;
</td>
</tr>);		
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</table>
</div>
</td>
</tr>);	
	return $detail;
}


sub search(@) {
	my $session_id = $_[1];
	my $type = $_[2];
	my $value = $_[3];
	my $caption = "Input any part of a host name or address:";
	if ($type eq 'services') { $caption = "Input any part of a service name:" }
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class width=25%>$caption</td>
<td class=$form_class>
<input type=hidden id=CGISESSID name=CGISESSID value=$session_id>);
	if ($type eq 'services') {
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<input type=hidden id=service name=service value=service>
<input type=text name=input id="val1" size=60 onkeyup="get_services( ['service','val1','CGISESSID'], ['resultdiv'] );">);
	} elsif ($type eq 'ez') {
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<input type=hidden id=ez name=ez value=ez>
<input type=text name=input id="val1" size=60 onkeyup="get_hosts( ['ez','val1','CGISESSID'], ['resultdiv'] );">);
	} else {
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<input type=text name=input id="val1" size=60 onkeyup="get_hosts( ['val1','CGISESSID'], ['resultdiv'] );">);
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</td>
</tr>
</table>
</td>
</tr>
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=row2>Search results:
</td>
</tr>
<tr>
<td class=$form_class>
<div id="resultdiv">
</div>
</td>
</tr>
</table>
</td>
</tr>);
	return $detail;
}

sub toggle_delete() {
	my $detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td>
<table width=100% cellpadding=0 cellspacing=0 align=left border=0>
<tr>
<td><input class=submitbutton type=submit name=remove_host value="Delete">&nbsp;&nbsp;
<input class=submitbutton type=button value="Check All" onclick=doCheckAll()>&nbsp;&nbsp;
<input class=submitbutton type=button value="Uncheck All" onclick=doUnCheckAll()>&nbsp;&nbsp;
<input type=submit class=submitbutton name=close value="Close">
</td>
</tr>
</form>
</table>
</td>
</tr>);
	return $detail;
}


sub wizard_doc(@) {
	my $title = $_[1];
	my $body = $_[2];
	return qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=wizard_title valign=top>$title</td>
</tr>
<tr>
<td class=wizard_body>
<table width=100% cellpadding=7 cellspacing=0 align=left border=0>
<tr>
<td class=wizard_body>$body</td>
</tr>
</table>
</td>
</tr>
</table>
</td>
</tr>);	
}

sub process_load(@) {
	my $load_option = $_[1];
	my $escalation = $_[2];
	my $nagios_etc = $_[3];
	my $abort = $_[4];
	my $continue = $_[5];
	my $now = time;
	my $input_tags = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<input type=hidden id="nocache" name=nocache value=$now>
<input type=hidden id="end" name=end value=end>
<input type=hidden id="process_load" name=process_load value=process_load>
<input type=hidden id="load_option" name=load_option value=$load_option>
<input type=hidden id="escalation" name=escalation value=$escalation>
<input type=hidden id="nagios_etc" name=nagios_etc value=$nagios_etc>
<input type=hidden id="process_service_escalations" name=process_service_escalations value=process_service_escalations>
<input type=hidden id="process_host_escalations" name=process_host_escalations value=process_host_escalations>
<input type=hidden id="services" name=services value=services>
<input type=hidden id="hosts" name=hosts value=hosts>
<input type=hidden id="contacts" name=contacts value=contacts>
<input type=hidden id="timeperiods" name=timeperiods value=timeperiods>
<input type=hidden id="commands" name=commands value=commands>
<input type=hidden id="stage" name=stage value=stage>
<input type=hidden id="purge" name=purge value=purge>);
	my @steps = ('end');
	if ($escalation || $load_option =~ /purge/) { push (@steps,('process_service_escalations','process_host_escalations')) }
	push (@steps,('services','hosts','contacts','timeperiods','commands','stage','purge'));
	my $i = 0;
	my $array_str = undef;
	foreach my $step (@steps) {
		$array_str .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
steps[$i]="$step";);
		$i++;
	}
	my $javascript = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<SCRIPT language="JavaScript">
var steps= new Array($i)
$array_str
function check_status() {
	var step = steps.pop()
	if (step==undefined) {
		document.getElementById("status").innerHTML = "Finished";
		document.getElementById("continue_abort").value="$continue";
	}
	else {
		var str = '';
		if (step=='process_service_escalations') str = 'Processing service escalations...';
		if (step=='process_host_escalations') str = 'Processing host escalations...';
		if (step=='services') str = 'Processing services...';
		if (step=='hosts') str = 'Processing hosts...';
		if (step=='contacts') str = 'Processing contacts...';
		if (step=='timeperiods') str = 'Processing timeperiods...';
		if (step=='commands') str = 'Processing commands...';
		if (step=='stage') str = 'Reading files...';
		if (step=='purge') str = 'Preparing load...';
		document.getElementById("continue_abort").value="$abort";
		document.getElementById("status").innerHTML = str;
		process_load( ['process_load',step,'nagios_etc','load_option','escalation'], [report_status] )
	}
}

function report_status(id) {
	var args = arguments[0].split('|')
	var items = args.length
	for (i=0; i<items; i++) {
		var fields = args[i].split('::')
		var tbody = document.getElementById("reportTable").getElementsByTagName("TBODY")[0];
		var row = document.createElement("TR")
		var td1 = document.createElement("TD")
		td1.appendChild(document.createTextNode(fields[0]))
		var td2 = document.createElement("TD")
		td2.appendChild (document.createTextNode(fields[1]))
		var td3 = document.createElement("TD")
		td3.appendChild (document.createTextNode(fields[2]))
		row.appendChild(td1);
		row.appendChild(td2);
		row.appendChild(td3);
		tbody.appendChild(row);
	}
	check_status()
}
</SCRIPT>
);

	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class valign=top width=25%>Status:</td>
<td class=$form_class><div id="status"></div>
</td>
</tr>
</table>
</td>
</tr>
<tr>
<td>
$javascript
$input_tags
<div class="scroll">
<table id="reportTable" width=100% cellpadding=7 cellspacing=0 align=left border=0>
<tbody>
</tbody>
</table>
</div>
</td>
</tr>
<tr>
<td>
<table width=100% cellpadding=0 cellspacing=1 border=0>
<tr>
<td style=border:0 align=left>
<input class=submitbutton id="continue_abort" type=submit name=continue value=>
</td>
</tr>
</form>
</table>
</td>
</tr>);

}

sub load_options(@) {
	return qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=wizard_title valign=top>Load Options</td>
</tr>
<tr>
<td class=wizard_body>
<table width=100% cellpadding=7 cellspacing=0 align=left border=0>
<tr>
<td class=wizard_body width=3% valign=top>
<input class=radio type=radio name=load_option value=update checked tabindex=></td>
</td>
<td class=wizard_body>Update (default): Add and update objects from the file definitions. Note: Escalations are excluded unless you select 'Load escalations' below. Please note that profile file associations revert to default values. Host profiles: hosts.cfg. Service profiles: services.cfg.
</td>
</tr>
<tr>
<td class=wizard_body width=3% valign=top>
<input class=checkbox type=checkbox name=purge_escalations tabindex=></td>
</td>
<td class=wizard_body>Load escalations: Replace escalations from the file definitions. There is no option to update escalations.</td>
</tr>
<tr>
<td class=wizard_body width=3% valign=top>
<input class=radio type=radio name=load_option value=purge_all tabindex=></td>
</td>
<td class=wizard_body>Purge all: Completely clear all Nagios records, including profiles and their associations, from the database. This option will repopulate the database from the file definitions.</td>
</tr>
<tr>
<td class=wizard_body width=3% valign=top>
<input class=radio type=radio name=load_option value=purge_nice tabindex=></td>
</td>
<td class=wizard_body>Purge nice: Clear Nagios service related records, including services, service dependencies, service templates, and escalations, but preserve hosts, commands, time periods, contacts and profiles (including service profiles). This option will update hosts, commands, time periods and contacts from the file definitions. Service profiles remain as empty vessels. Please note that profile file associations revert to default values. Host profiles: hosts.cfg. Service profiles: services.cfg.
</td>
</tr>
</table>
</td>
</tr>
</table>
</td>
</tr>);	
}

sub form_process_hosts(@) {
	my $unsorted_hosts = $_[1];
	my $host_data = $_[2];
	my $delimiter = $_[3];
	my $fields = $_[4];
	my $exists = $_[5];
	my $profiles = $_[6];
	my $default_profile = $_[7];
	my $sort = $_[8];
	my $ascdesc = $_[9];
	my @unsorted_hosts = @{$unsorted_hosts};
	my %host_data = %{$host_data};
	my %fields = %{$fields};
	my %exists = %{$exists};
	my %profiles = %{$profiles};
	my @hosts = ();
	my %checked = ();
	my %sorted = ();
	my %sort_order = (
		'exception' => 'asc',
		'exists' => 'asc',
		'good' => 'asc',
		'name' => 'asc',
		'alias' => 'asc',
		'address' => 'asc',
		'os' => 'asc',
		'profile' => 'asc',
		'other' => 'asc');
	if ($sort) {
		@{$sorted{'os'}} = ();
		@{$sorted{'address'}} = ();
		@{$sorted{'alias'}} = ();
		@{$sorted{'profile'}} = ();
		@{$sorted{'other'}} = ();
		@{$sorted{'exception'}} = ();
		@{$sorted{'exists'}} = ();
		@{$sorted{'good'}} = ();
		foreach my $host (@unsorted_hosts) {
			my @values = split(/$delimiter/, $host_data{$host});
			if ($delimiter eq 'tab') { @values = split(/\t/, $host_data{$host}) }
			if ($sort eq 'os') {
				unless ($values[$fields{'os'}]) { $values[$fields{'os'}] = "&nbsp;---&nbsp;" }
				push @{$sorted{$values[$fields{'os'}]}}, $values[$fields{'name'}]; 
			} elsif ($sort eq 'address') {
				push @{$sorted{$values[$fields{'address'}]}}, $values[$fields{'name'}]; 
			} elsif ($sort eq 'alias') {
				unless ($values[$fields{'alias'}]) { $values[$fields{'alias'}] = $values[$fields{'name'}] }
				push @{$sorted{$values[$fields{'alias'}]}}, $values[$fields{'name'}]; 
			} elsif ($sort eq 'profile') {
				my $profile = '&nbsp;---&nbsp;';
				if ($profiles{$values[$fields{'profile'}]}) { $profile = $values[$fields{'profile'}] }
				push @{$sorted{$profile}}, $values[$fields{'name'}]; 
			} elsif ($sort eq 'other') {
				push @{$sorted{$values[$fields{'other'}]}}, $values[$fields{'name'}]; 
			} elsif ($sort eq 'exception' || $sort eq 'exists' || $sort eq 'good') {
				unless ($values[$fields{'alias'}]) { $values[$fields{'alias'}] = $values[$fields{'name'}] }
				if ($values[$fields{'name'}] && $values[$fields{'address'}]) { 
					if ($exists{$values[$fields{'name'}]}) { 
						push @{$sorted{'exists'}}, $values[$fields{'name'}]; 
						if ($sort eq 'exists') { $checked{$host} = 'checked' }
					} else {
						push @{$sorted{'good'}}, $values[$fields{'name'}]; 
						if ($sort eq 'good') { $checked{$host} = 'checked' }
					}
				} else { 
					push @{$sorted{'exception'}}, $values[$fields{'name'}]; 
					if ($sort eq 'exception') { $checked{$host} = 'checked' }
				}
			}
		}
		if ($sort eq 'exception' || $sort eq 'exists' || $sort eq 'good') {
			my @order = ();
			if ($sort eq 'exception') {
				@order = ('exception','exists','good');
			} elsif ($sort eq 'exists') {
				@order = ('exists','good','exception');
			} else {
				@order = ('good','exception','exists');
			}
			foreach my $key (@order) {
				@{$sorted{$key}} = sort { lc($a) cmp lc($b) } @{$sorted{$key}};		
				push (@hosts,@{$sorted{$key}});
			}		
			$sort_order{$sort} = 'asc';
		} else {
			if ($ascdesc eq 'asc') {
				foreach my $key (sort { lc($a) cmp lc($b) } keys %sorted) {
					@{$sorted{$key}} = sort { lc($a) cmp lc($b) } @{$sorted{$key}};		
					push (@hosts,@{$sorted{$key}});
				}		
				$sort_order{$sort} = 'desc';
			} else {
				foreach my $key (sort { lc($b) cmp lc($a) } keys %sorted) {
					@{$sorted{$key}} = sort { lc($a) cmp lc($b) } @{$sorted{$key}};		
					push (@hosts,@{$sorted{$key}});
				}		
				$sort_order{$sort} = 'asc';
			}
		}
	} else {
		if ($ascdesc eq 'asc') {
			@hosts = sort { lc($a) cmp lc($b) } @unsorted_hosts;
			$sort_order{'name'} = 'desc';
		} else {
			@hosts = sort { lc($b) cmp lc($a) } @unsorted_hosts;
			$sort_order{'name'} = 'asc';
		}
	}
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<script language=JavaScript>
function doCheckAll()
{
  with (document.form) {
    for (var i=0; i < elements.length; i++) {
        if (elements[i].type == 'checkbox' && (elements[i].name == 'host_checked' || elements[i].name == 'host_checked'))
           elements[i].checked = true;
    }
  }
}
function doUnCheckAll()
{
  with (document.form) {
    for (var i=0; i < elements.length; i++) {
        if (elements[i].type == 'checkbox' && (elements[i].name == 'host_checked' || elements[i].name == 'host_checked'))
           elements[i].checked = false;
    }
  }
}
</script>

<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class width=15%>Sort keys:</td>
<td class=$form_class align=left width=1%>
<div style="width:8px; height:8px; border:1px solid #000099; background-color:#F3B50F;"></div>
</td>
<td class=$form_class align=left width=20%><input class=row1button type=submit name=sort_exception_$sort_order{'exception'} value="&nbsp;Exception: Missing data, unable to import.&nbsp;&nbsp;">
</td>
<td class=$form_class align=left width=1%>
<div style="width:8px; height:8px; border:1px solid #000099; background-color:#8DD9E0;"></div>
</td>
<td class=$form_class align=left width=10%><input class=row1button type=submit name=sort_exists_$sort_order{'exists'} value="&nbsp;Host exists.&nbsp;&nbsp;">
</td>
<td class=$form_class align=left width=1%>
<div style="width:8px; height:8px; border:1px solid #000099; background-color:#FFFFFF;"></div>
</td>
<td class=$form_class align=left width=10%><input class=row1button type=submit name=sort_good_$sort_order{'good'} value="&nbsp;Good.">
</td>
<td class=$form_class align=left>&nbsp;
</td>
</tr>
</table>
</td>
</tr>
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class allign=left>Sort columns:&nbsp;
<input class=row1button type=submit name=sort_name_$sort_order{'name'} value=Name>&nbsp;
<input class=row1button type=submit name=sort_alias_$sort_order{'alias'} value=Alias>&nbsp;
<input class=row1button type=submit name=sort_address_$sort_order{'address'} value=Address>&nbsp;
<input class=row1button type=submit name=sort_os_$sort_order{'os'} value=OS>&nbsp;
<input class=row1button type=submit name=sort_profile_$sort_order{'profile'} value=Profile>&nbsp;
<input class=row1button type=submit name=sort_other_$sort_order{'other'} value=Other>&nbsp;
</td>
</tr>
</table>
</td>
</tr>
<tr>
<td>
<div class="scroll" style="height: 250px;">
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>);
	my $class = undef;
	foreach my $host (@hosts) {
		unless ($host) { next }
		my @values = split(/$delimiter/, $host_data{$host});
		if ($delimiter eq 'tab') { @values = split(/\t/, $host_data{$host}) }
		unless ($values[$fields{'alias'}]) { $values[$fields{'alias'}] = $values[$fields{'name'}] }
		if ($values[$fields{'name'}] && $values[$fields{'address'}]) { 
			$class = 'row_good';
			if ($exists{$values[$fields{'name'}]}) { $class = 'row_exists' }
		} else { 
			$class = 'row_exception';
		}
		my $profile = '&nbsp;---&nbsp;';
		if ($profiles{$values[$fields{'profile'}]}) { $profile = $values[$fields{'profile'}] }
		$host =~ s/^\s+|\s+$//;
		$values[$fields{'alias'}] =~ s/^\s+|\s+$//;
		$values[$fields{'address'}] =~ s/^\s+|\s+$//;
		$values[$fields{'os'}] =~ s/^\s+|\s+$//;
		$values[$fields{'other'}] =~ s/^\s+|\s+$//;
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=$class width=15px>
<input type=checkbox name=host_checked value="$host" $checked{$host}>
</td>
<td class=$class width=100px>$host
<input type=hidden name=host value="$host">
</td>
<td class=$class width=200px>$values[$fields{'alias'}]
<input type=hidden name="alias_$host" value="$values[$fields{'alias'}]">
</td>
<td class=$class width=110px>$values[$fields{'address'}]
<input type=hidden name="address_$host" value="$values[$fields{'address'}]">
</td>
<td class=$class width=150px>$values[$fields{'os'}]</td>
<input type=hidden name="os_$host" value="$values[$fields{'os'}]">
<td class=$class width=100px>$profile</td>
<input type=hidden name="profile_$host" value="$profile">
<td class=$class width=100px>$values[$fields{'other'}]</td>
</tr>);
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</table>
</td>
</tr>
</td>
</tr>
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td>
<input class=submitbutton type=button value="Check All" onclick=doCheckAll()>&nbsp;&nbsp;
<input class=submitbutton type=button value="Uncheck All" onclick=doUnCheckAll()>
</td>
</tr>
</table>
</td>
</tr>);	
	return $detail;

}

sub form_profiles(@) {
	my $default = $_[1];
	my $selected = $_[2];
	my $profiles = $_[3];
	my $profiles_detail = $_[4];
	my $doc = $_[5];
	my @profiles = @{$profiles};
	my %profiles_detail = %{$profiles_detail};
	my %checked = ();
	my $checked = undef;
	unless ($selected) { $selected = $default }
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td>
<div class="scroll" style="height: 150px;">
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=row2 colspan=3>Host profile:</td>
<td class=row2>Host groups:</td>
<td class=row2 colspan=2>Service profiles:</td>
</tr>);
	my $row = 1;
	foreach my $profile (@profiles) {
		my $class = undef;
		if ($row == 1) {
			$class = 'row_lt';
			$row = 2;
		} elsif ($row == 2) {
			$class = 'row_dk';
			$row = 1;
		}
		$checked = undef;
		if ($selected eq $profile) { $checked = 'checked' }
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=$class width=3% valign=top>
<input class=radio type=radio name=host_profile value="$profile" $checked tabindex=></td>
<td class=$class valign=top>$profile</td>
<td class=$class valign=top>$profiles_detail{$profile}{'description'}</td>
<td class=$class valign=top>);
		if ($profiles_detail{$profile}{'hostgroups'}) {
			foreach my $hg (sort { $a <=> $b } @{$profiles_detail{$profile}{'hostgroups'}}) {
				$detail .= "$hg <br />\n";
			}
		} else {
				$detail .= "&nbsp;\n";
		}
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</td>
<td class=$class valign=top>);
		delete $profiles_detail{$profile}{'hostgroups'};
		delete $profiles_detail{$profile}{'description'};
		foreach my $sp (sort keys %{$profiles_detail{$profile}}) {
			$detail .= "$sp <br />\n";
		}
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</td>
<td class=$class valign=top>);
		foreach my $sp (sort keys %{$profiles_detail{$profile}}) {
			$detail .= "$profiles_detail{$profile}{$sp}<br />\n";
		}
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</td>
</tr>);
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</table>
</div>);
	return $detail;
}


sub form_discover() {
	my $oct1 = $_[1];
	my $oct2 = $_[2];
	my $oct3 = $_[3];
	my $oct4 = $_[4];
	my $oct5 = $_[5];
	unless ($oct4) { $oct4 = '*' }
	return qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class width=25%>Enter address, range or subnet:</td>
<td class=$form_class>
<input type=text size=4 name=oct1 value=$oct1>&nbsp;.&nbsp;<input type=text size=4 name=oct2 value=$oct2>&nbsp;.&nbsp;<input type=text size=4 name=oct3 value=$oct3>&nbsp;.&nbsp;<input type=text size=4 name=oct4 value=$oct4>&nbsp;-&nbsp;<input type=text size=4 name=oct5 value=$oct5></td>
</tr>
</table>
</td>
</tr>);	
}


sub get_ajax_url() {
	my $nocache = time;
	return "$cgi_dir/monarch_ajax.cgi?nocache=$nocache";
}

sub get_scan_url() {
	my $nocache = time;
	return "$cgi_dir/monarch_scan.cgi?nocache=$nocache";
}

sub scan(@) {
	my $addresses = $_[1];
	my $elements = $_[2];
	my $file = $_[3];
	my $monarch_home = $_[4];
	my @addresses = @{$addresses};
	my $input_tags = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<input type=hidden id=file name=file value=$file>
<input type=hidden id=monarch_home name=file value=$monarch_home>);
	my $javascript = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<SCRIPT language="JavaScript">
var ips= new Array($elements));
	@addresses = reverse @addresses;
	my $i = 0;
	foreach my $ip (@addresses) {
		$javascript .= qq(
ips[$i]="$ip";);
		$input_tags .= qq(
<input type=hidden id="$ip" name=ip value=$ip>);
		$i++;
	}
	$javascript .= qq(
function scan_host() {
	var host = ips.pop()
	if (host==undefined) {
		document.getElementById("status").innerHTML = "Finished";
	}
	else {
		document.getElementById("status").innerHTML = host + '...';
		get_host( ['file',host,'monarch_home'], [addRow] )
	}
}

function addRow() {
	var args = arguments[0].split('|')
	var tbody = document.getElementById("reportTable").getElementsByTagName("TBODY")[0];
	var row = document.createElement("TR")
	var td1 = document.createElement("TD")
	td1.appendChild(document.createTextNode(args[0]))
	var td2 = document.createElement("TD")
	td2.appendChild(document.createTextNode(args[1]))
	var td3 = document.createElement("TD")
	td3.appendChild(document.createTextNode(args[2]))
	var td4 = document.createElement("TD")
	td4.appendChild(document.createTextNode(args[3]))
	var td5 = document.createElement("TD")
	td5.appendChild(document.createTextNode(args[4]))
	row.appendChild(td1);
	row.appendChild(td2);
	row.appendChild(td3);
	row.appendChild(td4);
	row.appendChild(td5);
	tbody.appendChild(row);
	scan_host()
}
</SCRIPT>
);

	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class valign=top width=25%>Scanning:</td>
<td class=$form_class><div id="status"></div>
</td>
</tr>
</table>
</td>
</tr>
<tr>
<td>
$javascript
$input_tags
<div class="scroll">
<table id="reportTable" width=100% cellpadding=7 cellspacing=0 align=left border=0>
<tr>
<tbody>
</tbody>
</table>
</tr>
</table>
</div>
</td>
</tr>);

}

sub inheritance(@) {
	my $title = $_[1];
	my $body = $_[2];
	my $objects = $_[3];
	my %objects = %{$objects};
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=wizard_title valign=top>$title</td>
</tr>
<tr>
<td class=wizard_body>
<table width=100% cellpadding=7 cellspacing=0 align=left border=0>
<tr>
<td class=wizard_body>
<input class=submitbutton type=submit name=select_all value="Set Inheritance">
</td>
<td class=wizard_body>$body</td>
</tr>
</table>
</td>
</tr>
</table>
</td>
</tr>);	
	return $detail;
}

sub group_main(@) {
	my %group = %{$_[1]};
	my %docs = %{$_[2]};
	my @members = @{$_[3]};
	my @nonmembers = @{$_[4]};
	my $tab = $_[5];
	my %checked = ();
	if ($group{'status'}) { $checked{'status'} = 'checked' }
	if ($group{'use_hosts'}) { $checked{'use_hosts'} = 'checked' }
	if ($group{'active_checks_enabled'} eq '1') { $checked{'active_checks_enabled'} = 'checked' }
	if ($group{'passive_checks_enabled'} eq '1') { $checked{'passive_checks_enabled'} = 'checked' }
	if ($group{'checks_enabled'}) { $checked{'checks_enabled'} = 'checked' }
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=wizard_title valign=top colspan=2>Contact groups</td>
</tr>
<tr>
<td class=$form_class valign=top width=40%>$docs{'contactgroups'}</td>
</td>
<td class=$form_class>
<table cellspacing=0 align=left border=0>
<tr>
<td class=$form_class align=left>
<select name=contactgroups id=members size=10 multiple tabindex=@{[$tab++]}>);
	@members = sort { lc($a) cmp lc($b) } @members;
	foreach my $mem (@members) {
		$detail .= "\n<option value=\"$mem\">$mem</option>";
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</select>
</td>
<td class=$form_class cellpadding=$global_cell_pad align=left>
<table cellspacing=0 cellpadding=3 align=center border=0>
<tr>
<td class=$form_class align=center>
<input class=submitbutton type=button value="Remove >>" onclick="delIt();" tabindex=@{[$tab++]}>
</td>
<tr>
<td class=$form_class align=center>
<input class=submitbutton type=button value="&nbsp;&nbsp;<< Add&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;" onclick="addIt();"  tabindex=@{[$tab++]}>
</td>
</tr>
</table>
</td>
<td class=$form_class align=left>
<select name=nonmembers id=nonmembers size=10 multiple tabindex=@{[$tab++]}>);
	my $got_mem = undef;
	@nonmembers = sort { lc($a) cmp lc($b) } @nonmembers;
	foreach my $nmem (@nonmembers) {
		foreach my $mem(@members) {
			if ($nmem eq $mem) { $got_mem = 1 }
		}
		if ($got_mem) {
			$got_mem = undef;
			next;
		} else {
			$detail .= "\n<option value=\"$nmem\">$nmem</option>";
		}
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</select>
</td>
</td>
</tr>
</table>
</td>
</tr>
</table>
</td>
</tr>
<td class=data>
<table width=100% cellpadding=3 cellspacing=0 align=left border=0>
<tr>
<td class=wizard_title valign=top colspan=2>Group Status</td>
</tr>
<tr>
<td class=wizard_body colspan=2>$docs{'status'}
</td>
</tr>
<tr>
<td class=top_border width=25%>Set group inactive:</td></td>
<td class=top_border>
<input class=row1 type=checkbox name=inactive value=1 $checked{'status'} tabindex=>
</td>
</tr>
</table>
</td>
</tr>
<tr>
<td class=data>
<table width=100% cellpadding=3 cellspacing=0 align=left border=0>
<tr>
<td class=wizard_title valign=top colspan=3>Build Instance Properties</td>
</tr>
<tr>
<td class=wizard_body colspan=3>$docs{'build_instance_properties'}
<br>
</td>
</tr>
<tr>
<td class=top_border width=25%>Build folder:</td>
<td class=top_border width=3% align=center>
<a class=orange href=#doc title=\"$docs{'location'}\">&nbsp;?&nbsp;</a>
</td>
<td class=top_border>
<input type=text size=75 name=location value="$group{'location'}" tabindex=>
</td>
</tr>
<tr>
<td class=top_border width=25%>Nagios etc folder:</td>
<td class=top_border width=3% align=center>
<a class=orange href=#doc title=\"$docs{'nagios_etc'}\">&nbsp;?&nbsp;</a>
</td>
<td class=top_border>
<input type=text size=75 name=nagios_etc value="$group{'nagios_etc'}" tabindex=>
</td>
</tr>
<tr>
<td class=top_border width=25%>Force hosts:</td></td>
<td class=top_border width=3% align=center>
<a class=orange href=#doc title=\"$docs{'use_hosts'}\">&nbsp;?&nbsp;</a>
</td>
<td class=top_border>
<input class=row1 type=checkbox name=use_hosts value=1 $checked{'use_hosts'} tabindex=>
</td>
</tr>
<tr>
<td class=top_border width=25%>Force checks:</td></td>
<td class=top_border width=3% align=center>
<a class=orange href=#doc title=\"$docs{'checks_enabled'}\">&nbsp;?&nbsp;</a>
</td>
<td class=top_border>
<input class=row1 type=checkbox name=checks_enabled value=1 $checked{'checks_enabled'} tabindex=>
</td>
</tr>
<tr>
<td class=row1 width=25% align=right>
<input class=row1 type=checkbox name=passive_checks_enabled value=1 $checked{'passive_checks_enabled'} tabindex=>
</td>
<td class=row1 colspan=2>Passive checks enabled</td>
</tr>
<tr>
<td class=row1 width=25% align=right>
<input class=row1 type=checkbox name=active_checks_enabled value=1 $checked{'active_checks_enabled'} tabindex=>
</td>
<td class=row1 colspan=2>Active checks enabled</td>
</tr>
</table>
</td>);
	return $detail;
}

sub group_hosts(@) {
	my $members = $_[1];
	my $nonmembers = $_[2];
	my $hostgroup_members = $_[3];
	my $hostgroup_nonmembers = $_[4];
	my %members = %{ $members };
	my %nonmembers = %{ $nonmembers };
	my %hostgroup_members = %{ $hostgroup_members };
	my %hostgroup_nonmembers = %{ $hostgroup_nonmembers };
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<script language=JavaScript>
function doCheckAll()
{
  with (document.form) {
    for (var i=0; i < elements.length; i++) {
        if (elements[i].type == 'checkbox' && (elements[i].name == 'rem_host_checked' || elements[i].name == 'rem_hostgroup_checked'))
           elements[i].checked = true;
    }
  }
}
function doUnCheckAll()
{
  with (document.form) {
    for (var i=0; i < elements.length; i++) {
        if (elements[i].type == 'checkbox' && (elements[i].name == 'rem_host_checked' || elements[i].name == 'rem_hostgroup_checked'))
           elements[i].checked = false;
    }
  }
}
</script>

<tr>
<td width=100% align=center>
<div class="scroll" style="height: 200px;">
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>);
	my $row = 1;
	foreach my $host (sort { lc($a) cmp lc($b) } keys %members) {
		my $class = undef;
		if ($row == 1) {
			$class = 'row_lt';
			$row = 2;
		} elsif ($row == 2) {
			$class = 'row_dk';
			$row = 1;
		}

		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=$class valign=top width=3%>
<input type=checkbox name=rem_host_checked value="$host">
</td>
<td class=$class align=left valign=top width=20% colspan=2><b>$host</b></td>
<td class=$class align=left valign=top width=10%>host &nbsp;</td>
<td class=$class align=left valign=top width=70%>$members{$host}{'alias'} &nbsp;</td>
</tr>);

	}
	foreach my $hostgroup (sort { lc($a) cmp lc($b) } keys %hostgroup_members) {
		my $class = undef;
		if ($row == 1) {
			$class = 'row_lt';
			$row = 2;
		} elsif ($row == 2) {
			$class = 'row_dk';
			$row = 1;
		}
		my $host_text = undef;
		foreach my $host (@{$hostgroup_members{$hostgroup}}) {
			$host_text .= "$host,";
		}
		chop $host_text;

		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=$class valign=top width=3%>
<input type=checkbox name=rem_hostgroup_checked value="$hostgroup">
</td>
<td class=$class align=left valign=top width=20% colspan=2><b>$hostgroup</b></td>
<td class=$class align=left valign=top width=10%>hostgroup &nbsp;</td>
<td class=$class align=left valign=top width=70%>$host_text &nbsp;</td>
</tr>);

	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</table>
</div>
</td>
</tr>
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td><input class=submitbutton type=submit name=remove_host value="Remove">&nbsp;&nbsp;
<input class=submitbutton type=button value="Check All" onclick=doCheckAll()>&nbsp;&nbsp;
<input class=submitbutton type=button value="Uncheck All" onclick=doUnCheckAll()>
</td>
</tr>
</table>
</td>
</tr>
<tr>
<td width=100% align=center>
<div class="scroll" style="height: 100px;">
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>);
	$row = 1;
	foreach my $host (sort { lc($a) cmp lc($b) } keys %nonmembers) {
		my $class = undef;
		if ($row == 1) {
			$class = 'row_lt';
			$row = 2;
		} elsif ($row == 2) {
			$class = 'row_dk';
			$row = 1;
		}

		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=$class valign=top width=3%>
<input type=checkbox name=add_host_checked value="$host">
</td>
<td class=$class align=left valign=top width=20% colspan=2><b>$host</b></td>
<td class=$class align=left valign=top width=77%>$nonmembers{$host}{'alias'}&nbsp;</td>
<td class=$class align=left valign=top width=37%>$nonmembers{$host}{'address'}&nbsp;</td>
</tr>);

	}

	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</table>
</div>
</td>
</tr>
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td align=left width=20%>
<input class=submitbutton type=submit name=add_host value="Add Host(s)">
</td>
</tr>
</table>
</td>
</tr>
<tr>
<td width=100% align=center>
<div class="scroll" style="height: 100px;">
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>);
	$row = 1;
	foreach my $hostgroup (sort { lc($a) cmp lc($b) } keys %hostgroup_nonmembers) {
		my $class = undef;
		if ($row == 1) {
			$class = 'row_lt';
			$row = 2;
		} elsif ($row == 2) {
			$class = 'row_dk';
			$row = 1;
		}
		my $host_text = undef;
		foreach my $host (@{$hostgroup_nonmembers{$hostgroup}}) {
			$host_text .= "$host,";
		}
		chop $host_text;
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=$class valign=top width=3%>
<input type=checkbox name=add_hostgroup_checked value="$hostgroup">
</td>
<td class=$class align=left valign=top width=20% colspan=2><b>$hostgroup</b></td>
<td class=$class align=left valign=top width=77%>$host_text &nbsp;</td>
</tr>);
	}

	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</table>
</div>
</td>
</tr>
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td align=left width=20%>
<input class=submitbutton type=submit name=add_hostgroup value="Add Hostgroup(s)">
</td>
</tr>
</table>
</td>
</tr>);	


	return $detail;
}

sub group_children(@) {
	my $group_hosts = $_[1];
	my $order = $_[2];
	my $group_child = $_[3];
	my $nonmembers = $_[4];
	my %group_hosts = %{ $group_hosts };
	my @order = @{ $order };
	my %group_child = %{ $group_child  };
	my %nonmembers = %{ $nonmembers };
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td width=100% align=center>
<div class="scroll" style="height: 200px;">
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>);
	my %child_parent = ();
	my $space = undef;
	my $p_group = 1;
	my $row = 1;
	my $class = undef;
	my %used = ();
	foreach my $grp (@order) {
		my $childstr = undef;
		my $childdesc = undef;
		delete $nonmembers{$grp};
		foreach my $child (keys %{$group_child{$grp}}) { 
			$child_parent{$child} = $grp;
				$childstr .= "$child<br/>";
				$childdesc .= "$group_hosts{$child}{'description'}<br/>";
				$used{$child} = 1;
				delete $nonmembers{$child};
		} 
		if ($child_parent{$grp} eq $p_group && $childstr ) {
			$space = "&nbsp;";
			$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=$class width=3%>
&nbsp
<td class=$class\_top valign=top>
$space<b>&bull;</b>&nbsp;$grp
</td>
<td class=$class\_top valign=top>
&nbsp;
</td>
<td class=$class\_top valign=top>
$childstr
</td>
<td class=$class\_top valign=top>
$childdesc
</td>
</tr>);
		} else {
			if ($row == 1) {
				$class = 'row_lt';
				$row = 2;
			} elsif ($row == 2) {
				$class = 'row_dk';
				$row = 1;
			}
			unless ($used{$grp}) { 
				$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=$class width=3% valign=top>
<input type=checkbox name=rem_group_checked value="$grp">
<td class=$class colspan=1 valign=top>
$grp
</td>
<td class=$class colspan=1 valign=top>
$group_hosts{$grp}{'description'}
</td>
<td class=$class valign=top>
$childstr
</td>
<td class=$class valign=top>
$childdesc
</td>
</tr>);
			}
			$space = undef;
		}
		$p_group = $grp;
	}



	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</table>
</div>
</td>
</tr>
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td><input class=submitbutton type=submit name=remove_group value="Remove"></td>
</tr>
</table>
</td>
</tr>
<tr>
<td width=100% align=center>
<div class="scroll" style="height: 200px;">
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>);
	$row = 1;
	foreach my $child (sort { lc($a) cmp lc($b) } keys %nonmembers) {
		my $class = undef;
		if ($row == 1) {
			$class = 'row_lt';
			$row = 2;
		} elsif ($row == 2) {
			$class = 'row_dk';
			$row = 1;
		}

		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=$class width=3%>
<input type=checkbox name=add_group_checked value="$child">
</td>
<td class=$class align=left valign=top width=20% colspan=2><b>$child</b></td>
<td class=$class align=left valign=top width=37%>$nonmembers{$child}{'description'}&nbsp;</td>
<td class=$class align=left valign=top width=40%>$nonmembers{$child}{'hosts'}&nbsp;</td>
</tr>);

	}

	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</table>
</div>
</td>
</tr>
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td align=left width=20%>
<input class=submitbutton type=submit name=add_group value="Add Group(s)">
</td>
</tr>
</table>
</td>
</tr>);	
	return $detail;
}

sub group_macros(@) {
	my $macros = $_[1];
	my $group_macros = $_[2];
	my $label_enabled = $_[3];
	my $label = $_[4];
	my %macros = %{ $macros };
	my %group_macros = %{ $group_macros };
	if ($label_enabled) { $label_enabled = 'checked' }
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class width=3%>
<input type=checkbox name=label_enabled $label_enabled>
</td>
<td class=$form_class align=left width=10%>Enable label.</td>
<td class=$form_class align=right width=10%>Value:</td>
<td class=$form_class align=left width=77%>
<input type=text name=label size=50 value="$label">	
</td>
</tr>
</table>
</td>
</tr>
<tr>
<td>
<div class="scroll" style="height: 200px;">
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>);
	my $row = 1;
	foreach my $macro (sort { lc($a) cmp lc($b) } keys %group_macros) {
		my $class = undef;
		if ($row == 1) {
			$class = 'row_lt';
			$row = 2;
		} elsif ($row == 2) {
			$class = 'row_dk';
			$row = 1;
		}
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=$class width=3%>
<input type=checkbox name=rem_macro_checked value="$macro">
</td>
<td class=$class align=left width=20%><b>$macro</b></td>
<td class=$class align=left width=77%>$group_macros{$macro}{'description'}</td>
</tr>
<tr>
<td class=$class width=3%>&nbsp;</td>
<td class=$class align=left width=20% valign=top>Value:</td>
<td class=$class align=left width=77%><textarea rows=3 cols=70 name=value_$macro>$group_macros{$macro}{'value'}</textarea></td></tr>
</tr>);
	}

	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</table>
</div>
</td>
</tr>
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td><input class=submitbutton type=submit name=set_values value="Save">&nbsp;&nbsp;
<input class=submitbutton type=submit name=remove_macro value="Remove"></td>
</tr>
</table>
</td>
</tr>);	

	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td width=100% align=center>
<div class="scroll" style="height: 200px;">
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>);
	$row = 1;
	foreach my $macro (sort { lc($a) cmp lc($b) } keys %macros) {
		my $class = undef;
		if ($row == 1) {
			$class = 'row_lt';
			$row = 2;
		} elsif ($row == 2) {
			$class = 'row_dk';
			$row = 1;
		}

		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=$class width=3%>
<input type=checkbox name=add_macro_checked value="$macro">
</td>
<td class=$class align=left width=20% colspan=2><b>$macro</b></td>
<td class=$class align=left width=77%>$macros{$macro}{'description'}</td>
</tr>);

	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</table>
</div>
</td>
</tr>
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td align=left width=20%>
<input class=submitbutton type=submit name=add_macro value="Add Macro(s)">
</td>
</tr>
</table>
</td>
</tr>);	
	return $detail;
}

sub macros(@) {
	my $macros = $_[1];
	my %macros = %{ $macros };
	
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td>
<div class="scroll" style="height: 400px;">
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>);
	my $row = 1;
	foreach my $macro (sort { lc($a) cmp lc($b) } keys %macros) {
		my $class = undef;
		if ($row == 1) {
			$class = 'row_lt';
			$row = 2;
		} elsif ($row == 2) {
			$class = 'row_dk';
			$row = 1;
		}

		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=$class width=3%>
<input type=checkbox name=macro_checked value="$macro">
</td>
<td class=$class align=left width=85% colspan=2><b>$macro</b></td>
<td class=$class align=left width=12% rowspan=3><input class=submitbutton type=submit name=rename_$macro value="Rename">
<tr>
<td class=$class width=3%>&nbsp;</td>
<td class=$class align=left width=10%>Description:</td>
<td class=$class align=left width=75%><input type=text size=70 name=description_$macro value="$macros{$macro}{'description'}"></td></tr>
<tr>
<td class=$class width=3%>&nbsp;</td>
<td class=$class align=left width=10% valign=top>Value:</td>
<td class=$class align=left width=75%><textarea rows=3 cols=70 name=value_$macro>$macros{$macro}{'value'}</textarea></td></tr>
</tr>);

	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</table>
</td>
</tr>
		
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td class=$form_class align=left width=10%>&nbsp;</td>
<td class=$form_class align=left width=10% colspan=2><b>New Macro</b></td></tr>
<tr>
<td class=$form_class align=left width=10%>Name:</td>
<td class=$form_class align=left width=55%><input type=text size=50 name=name value=></td>
<td class=$form_class align=center width=35% rowspan=3><input class=submitbutton type=submit name=add value="Add New Macro">
<tr>
<td class=$form_class align=left width=10%>Description:</td>
<td class=$form_class align=left width=75%><input type=text size=70 name=description value=></td></tr>
<tr>
<td class=$form_class align=left width=10% valign=top>Value:</td>
<td class=$form_class align=left width=75%><textarea rows=3 cols=70 name=value value=></textarea></td></tr>
</tr>
</table>
</td>
</tr>);	
	return $detail;

}


sub main_cfg_misc(@) {
	my %misc_vals = %{$_[1]};
	my $doc = $_[2];
	my $detail = qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=data>
<table width=100% cellpadding=$global_cell_pad cellspacing=0 align=left border=0>
<tr>
<td>
<table width=100% cellspacing=0 align=left border=0>
<tr>
<td class=wizard_title colspan=4 valign=top colspan=3>Misc directives (optional)</td>
</tr>
<tr>
<td class=wizard_body colspan=6>
<table width=100% cellpadding=7 cellspacing=0 align=left border=0>
<tr>
<td>
$doc
</td>
</tr>
</table>
</td>
</tr>
<tr>
<td class=top_border width=100% colspan=5>
<table width=100% cellpadding=0 cellspacing=0 border=0>
<tr>	
<td width=10%>Name:</td>
<td width=20%><input type=text size=20 name=misc_name value="" tabindex=></td>
<td width=60%>&nbsp;Value:&nbsp;
<input type=text size=50 name=misc_value value="">
<td width=10%>&nbsp;</td>
</tr>
</table>
</td>
</tr>
<tr>
<td class=top_border colspan=7 valign=top colspan=4>
<input class=submitbutton type=submit name=add_misc value="Add Directive"
</td>
</tr>);

	if (%misc_vals) {
		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<script language=JavaScript>
function doCheckAll()
{
  with (document.form) {
    for (var i=0; i < elements.length; i++) {
        if (elements[i].type == 'checkbox' && (elements[i].name == 'rem_inst'))
           elements[i].checked = true;
    }
  }
}
function doUnCheckAll()
{
  with (document.form) {
    for (var i=0; i < elements.length; i++) {
        if (elements[i].type == 'checkbox' && (elements[i].name == 'rem_inst'))
           elements[i].checked = false;
    }
  }
}
</script>
<tr>
<td class=top_border valign=top width=3%>&nbsp</td>
<td class=top_border align=left valign=top width=20%><b>Name</b></td>
<td class=top_border align=left valign=top width=77%><b>Value</b></td>
</tr>);
		my $row = 1;
		foreach my $key (sort {$a <=> $b} keys %misc_vals) {
			my $class = undef;
			if ($row == 1) {
				$class = 'row_lt';
				$row = 2;
			} elsif ($row == 2) {
				$class = 'row_dk';
				$row = 1;
			}
			$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=$class valign=top width=3%>
<input type=checkbox name=rem_key value=$key>
</td>
<td class=$class align=left valign=top width=20%>$misc_vals{$key}{'name'}</td>
<td class=$class align=left valign=top width=77%>
<input type=text size=70 name="$key" value="$misc_vals{$key}{'value'}">
</td>
</tr>);
			}

		$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
<tr>
<td class=top_border colspan=5>
<input class=submitbutton type=submit name=rem_misc value="Remove Directive(s)">&nbsp;&nbsp;
<input class=submitbutton type=button value="Check All" onclick=doCheckAll()>&nbsp;&nbsp;
<input class=submitbutton type=button value="Uncheck All" onclick=doUnCheckAll()>
</td>
</tr>);
	}
	$detail .= qq(@{[&$Instrument::show_trace_as_html_comment()]}
</table>
</td>
</tr>);	


	return $detail
}

#
#############################
# NMS Integration
#############################
#



sub login_redirect() {
	return qq(
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<html>
<head>
<title>Monarch</title>
<META HTTP-EQUIV="CONTENT-TYPE" CONTENT="text/html; charset=utf-8">
<META HTTP-EQUIV="Pragma" CONTENT="no-cache">
<META HTTP-EQUIV="Expires" CONTENT="-1">
<link rel="stylesheet" type="text/css" href="/monarch/monarch.css" />
<link rel="StyleSheet" href="/monarch/dtree.css" type="text/css" />
</head>
<body bgcolor=#f0f0f0 >
<!-- generated by: MonarchForms::login_redirect() -->
<table class=form width=75% cellpadding=0 cellspacing=1 border=0>
<tr>
<td class=data>
<table width=100% cellpadding=3 cellspacing=0 align=left border=0>
<tr>
<td class=head>Session Timeout</td>
</tr>
</table>
</td>
</tr>
<tr>
<td class=data>
<table width=100% cellpadding=3 cellspacing=0 align=left border=0>
<tr>
<td class=row1>Please <a href=$cgi_dir/monarch.cgi?view=logout target=_top>login</a>.</td> 
</tr>
</table>
</td>
</tr>
</table>
</body>
<SCRIPT language=javascript1.1 src="/monarch/monarch.js"></SCRIPT>
<script src="/monarch/nicetitle.js" type="text/javascript"></script>
<script type="text/javascript" src="/monarch/DataFormValidator.js"></script>
</html>
);

}

sub login(@) {
	my $title = $_[1];
	my $message = $_[2];
	if ($message) { 
		$message = "&dagger;&nbsp;<b>$message</b><br><br>";
	} else {
		$message = undef;
	}
	return qq(
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.0 Transitional//EN">
<HTML>
<HEAD>
<title>Monarch</title>
<META HTTP-EQUIV="CONTENT-TYPE" CONTENT="text/html; charset=utf-8">
<META HTTP-EQUIV="Pragma" CONTENT="no-cache">
<META HTTP-EQUIV="Expires" CONTENT="-1">
<link rel="stylesheet" type="text/css" href="/monarch/monarch.css" />
<script type="text/javascript" src="/monarch/DataFormValidator.js"></script>
</HEAD>

<BODY bgcolor=#999999>
<!-- generated by: MonarchForms::login() -->
<table align=center width=800px cellspacing=0 cellpadding=0 border=0 bgcolor=#EEEEEE>
<tr>
<td><img src=/monarch/images/logo5.png border=0 align=left></td>
</tr>
<tr>
<td><img src=/monarch/images/home.jpg border=0></td>
</tr>
<tr>
<td>
<table align=center width=800px cellspacing=3 cellpadding=5 border=0 bgcolor=#EEEEEE>
<tr>
<td width=500px valign=top><br/>
<h1>About GroundWork Monitor Architect</h1>
GroundWork Monitor Architect is a web based configuration tool for Nagios. Features in version 2.5 include:<ul>
<li>Multiple Nagios instance support</li>
<li>Improved navigation with Ajax</li>
<li>Multiple checks per service</li>
<li>Alternate EZ interface with Nmap Discovery</li>
</li>
</ul>
<h1>Support:</h1>Visit GroundWork's support forums at at: 
<a href="http://www.groundworkopensource.com/community/forums/">www.groundworkopensource.com/community/forums</a>
</td>
<td valign=top>			  
<form name=form action=$cgi_dir/monarch.cgi method=post generator=login>
<table border="0" cellpadding="0" cellspacing="0">
<tr>
<td class="columnSpan01"><br><h1>Please log in</h1>
If you do not have an account, contact your Administrator.<br /><br />$message
</td>
</tr>
<tr>
<td>
<span class="formHeader">Username</span></td></tr>
<tr><td><input type="text" size="30" name="user_acct" value="" /></td>
</tr>
<tr>
<td><br /><span class="formHeader">Password</span></td></tr>
<tr><td><input type="password" size="30" name="password" /></td>
<input type=hidden name=process_login value=1>
</tr>
<tr>
<td>
<br /><input class="submitbutton" type="submit" value="Login" /></td>
</tr>
</table>
</form>
</td>
</tr>
</table>
</td>
</tr>

<table align=center width=800px cellspacing=0 cellpadding=0 border=0 bgcolor=#EEEEEE>
<tr>
<td>
<hr>
</td>
</tr>
</table>
</td>
</tr>
<tr>
<td>
<table align=center width=800px cellspacing=3 cellpadding=5 border=0 bgcolor=#EEEEEE>
<tr>
<td nowrap="nowrap" class="login_footer" valign="top">
<span class="login_footerHeader">GroundWork
	Open Source</span><br />
	139 Townsend Street, Suite 100<br />
	San Francisco, CA 94107 USA
</td>

 
<td nowrap="nowrap" class="login_footer" valign="top">
phone 415.992.4500<br />
fax 415.947.0684<br />
<a href="http://www.groundworkopensource.com/">www.groundworkopensource.com</a>
</td>

<td nowrap="nowrap" class="login_footer" valign="top">
2006 GroundWork<br />

Open Source<br />
All rights reserved.
</td>
<tr>
<td colspan=3>
&nbsp;
</td>
</tr>
</table>
</td>
</tr>
</table>
</BODY>
</HTML>);



}

sub unindent {
    $_[0] =~ s/^[\n\r]*//;
    my ($indent) = ($_[0] =~ /^([ \t]+)/);
    $_[0] =~ s/^$indent//gm;
}


1;

