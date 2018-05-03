# MonArch - Groundwork Monitor Architect
# MonarchProfileImport.pm
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
use XML::LibXML;

package ProfileImporter;

my $debug          = 0;
my %objects        = ();
my @host_externals = ();
my %db_values      = ();
my %ov             = ( 1 => 'Yes', 2 => 'No' );
my ( $file, $overwrite, $parser, $tree, $root, $monarch_ver ) = 0;
my @messages   = ();
my $empty_data = qq(<?xml version="1.0" ?>
<data>
</data>);

sub data_prep(@) {
  my $obj           = $_[0];
  my %values        = %{ $_[1] };
  my %data_vals     = ();
  my %property_list = StorProc->property_list();
  my @props         = split( /,/, $property_list{$obj} );
  my @db_vals       = split( /,/, $db_values{$obj} );
  foreach my $name ( keys %values ) {
    foreach my $p (@props) {
      if ( $p eq $name ) {
        my $match = undef;
        foreach my $val (@db_vals) {
          if ( $val eq $name ) {
            $data_vals{$val} = $values{$name};
            $match = 1;
            last;
          }
        }
        unless ($match) {
          if ( $values{$p} || $values{$p} eq '0' ) {
            $data_vals{'data'} .=
              "\n  <prop name=\"$name\"><![CDATA[$values{$p}]]>\n  </prop>";
          }
        }
      }
    }
  }
  if ( $data_vals{'data'} ) {
    $data_vals{'data'} = qq(<?xml version="1.0" ?>
<data>$data_vals{'data'}
</data>);
  }
  return %data_vals;
}

#
############################################################################
# Commands
#

sub commands() {
  my @errors     = ();
  my $parser     = XML::LibXML->new();
  my %name_vals  = ();
  my @objs       = $root->findnodes("//command");
  my $cnt        = 0;
  my $add_cnt    = 0;
  my $update_cnt = 0;
  foreach my $obj (@objs) {
    $cnt++;
    my $name     = undef;
    my @siblings = $obj->getChildnodes();
    foreach my $node (@siblings) {
      if ( $node->hasAttributes() ) {
        my $property = $node->getAttribute('name');
        my $value    = $node->textContent;
        $name_vals{$property} = $value;
        if ( $property eq 'name' ) { $name = $value }
        if ( $property eq 'command_line' ) {
          if ( $name_vals{'command_line'} =~ /\$(USER\d+)\$\/(\S+)\s/ ) {
            my ( $res, $file ) = ( $1, $2 );
            $res = lc($res);
            unless ( -e "$objects{'resources'}{$res}/$file" ) {
              push @errors,
"Plugin does not exist $objects{'resources'}{$1}/$2 for command definition $name.";
            }
            unless ( $objects{'resources'}{$res} ) {
              push @errors,
"Resource value $res for plugin does not exist for command definition $name.";
            }
          }
        }
      }
    }

    #		unless ($errors[0]) {
    my %values = data_prep( 'commands', \%name_vals );
    foreach my $val ( keys %{ $objects{'commands'} } ) {
      if ( $val =~ /^$values{'name'}$/i ) {
        $objects{'commands'}{ $values{'name'} } = $objects{'commands'}{$val};
      }
    }
    if ( $objects{'commands'}{ $values{'name'} } ) {
      if ( $overwrite == 1 ) {
        my $result =
          StorProc->update_obj( 'commands', 'name', $values{'name'}, \%values );
        if ( $result =~ /^Error/ ) {
          push @errors, "Error: $result Continue...";
        }
        else {
          $update_cnt++;
        }
      }
    }
    else {
      my @db_vals = split( /,/, $db_values{'commands'} );
      my @values = ('');
      foreach my $val (@db_vals) { push @values, $values{$val} }
      my $id = StorProc->insert_obj_id( 'commands', \@values, 'command_id' );
      if ( $id =~ /^Error/ ) {
        push @errors, "Error: $id\nContinue...;";
      }
      else {
        $objects{'commands'}{ $values{'name'} } = $id;
        $add_cnt++;
      }
    }
  }

  #	}
  push @messages,
    (
"Commands: $cnt read $add_cnt added $update_cnt updated (overwrite existing = $ov{$overwrite})."
    );
  @errors = ();
  return @errors;
}

#
############################################################################
# Time periods
#

sub timeperiods() {
  my @errors     = ();
  my $cnt        = 0;
  my $add_cnt    = 0;
  my $update_cnt = 0;
  my $parser     = XML::LibXML->new();
  my $tree       = $parser->parse_file("$file");
  my $root       = $tree->getDocumentElement;
  my %name_vals  = ();
  my @objs       = $root->findnodes("//time_period");
  foreach my $obj (@objs) {
    $cnt++;
    my @siblings = $obj->getChildnodes();
    foreach my $node (@siblings) {
      if ( $node->hasAttributes() ) {
        my $property = $node->getAttribute('name');
        my $value    = $node->textContent;
        $name_vals{$property} = $value;
      }
    }
    my %values = data_prep( 'time_periods', \%name_vals );
    foreach my $val ( keys %{ $objects{'time_periods'} } ) {
      if ( $val =~ /^$values{'name'}$/i ) {
        $objects{'time_periods'}{ $values{'name'} } =
          $objects{'time_periods'}{$val};
      }
    }
    if ( $objects{'time_periods'}{ $values{'name'} } ) {
      if ( $overwrite == 1 ) {
        my $result =
          StorProc->update_obj( 'time_periods', 'name', $values{'name'},
          \%values );
        if ( $result =~ /^Error/ ) {
          push @errors, "Error: $result Continue...";
        }
        else {
          $update_cnt++;
        }
      }
    }
    else {
      my @db_vals = split( /,/, $db_values{'time_periods'} );
      my @values = ('');
      foreach my $val (@db_vals) { push @values, $values{$val} }
      my $id =
        StorProc->insert_obj_id( 'time_periods', \@values, 'timeperiod_id' );
      if ( $id =~ /^Error/ ) {
        push @errors, "Error: $id\nContinue...";
      }
      else {
        $objects{'time_periods'}{ $values{'name'} } = $id;
        $add_cnt++;
      }
    }
  }
  push @messages,
    (
"Time periods: $cnt read $add_cnt added $update_cnt updated (overwrite existing = $ov{$overwrite})."
    );
  return @errors;
}

#
############################################################################
# Host templates
#

sub host_templates() {
  my @errors     = ();
  my $cnt        = 0;
  my $add_cnt    = 0;
  my $update_cnt = 0;
  my $parser     = XML::LibXML->new();
  my $tree       = $parser->parse_file("$file");
  my $root       = $tree->getDocumentElement;
  my %name_vals  = ();
  my @objs       = $root->findnodes("//host_template");
  foreach my $obj (@objs) {
    $cnt++;
    my $name      = undef;
    my $db_update = 1;
    my @siblings  = $obj->getChildnodes();
    foreach my $node (@siblings) {
      if ( $node->hasAttributes() ) {
        my $property = $node->getAttribute('name');
        my $value    = $node->textContent;
        if ( $value eq '0' ) { $value = "-zero-" }
        $name_vals{$property} = $value;
        if ( $property eq 'name' ) { $name = $value }
        if ($value) {
          if ( $property =~ /^check_command$|^event_handler$/ ) {
            if ( $objects{'commands'}{$value} ) {
              $name_vals{$property} = $objects{'commands'}{$value};
            }
            else {
              $db_update = 0;
              push @errors,
"Command definition $value for $property does not exist for host template $name.";
            }
          }
          if ( $property =~ /period/ ) {
            if ( $objects{'time_periods'}{$value} ) {
              $name_vals{$property} = $objects{'time_periods'}{$value};
            }
            else {
              $db_update = 0;
              push @errors,
"Time period definition $value for $property does not exist for host template $name.";
            }
          }
        }
      }
    }
    unless ( $errors[0] ) {
      my %values = data_prep( 'host_templates', \%name_vals );
      foreach my $val ( keys %{ $objects{'host_templates'} } ) {
        if ( $val =~ /^$values{'name'}$/i ) {
          $objects{'host_templates'}{ $values{'name'} } =
            $objects{'host_templates'}{$val};
        }
      }
      if ( $objects{'host_templates'}{ $values{'name'} } ) {
        if ( $overwrite == 1 ) {
          my $result =
            StorProc->update_obj( 'host_templates', 'name', $values{'name'},
            \%values );
          if ( $result =~ /^Error/ ) {
            push @errors, "Error: $result Continue...";
          }
          else {
            $update_cnt++;
          }
        }
      }
      else {
        my @db_vals = split( /,/, $db_values{'host_templates'} );
        my @values = ('');
        foreach my $val (@db_vals) { push @values, $values{$val} }
        my $id = StorProc->insert_obj_id( 'host_templates', \@values,
          'hosttemplate_id' );
        if ( $id =~ /^Error/ ) {
          push @errors, "Error: $id Continue...";
        }
        else {
          $objects{'host_templates'}{ $values{'name'} } = $id;
          $add_cnt++;
        }
      }
    }
  }
  push @messages,
    (
"Host templates: $cnt read $add_cnt added $update_cnt updated (overwrite existing = $ov{$overwrite})."
    );
  return @errors;
}

#
############################################################################
# Extended Host Info
#

sub hostextinfo_templates() {
  my %name_vals  = ();
  my @errors     = ();
  my $cnt        = 0;
  my $add_cnt    = 0;
  my $update_cnt = 0;
  my @objs       = $root->findnodes("//extended_host_info_template");
  foreach my $obj (@objs) {
    $cnt++;
    my @siblings = $obj->getChildnodes();
    foreach my $node (@siblings) {
      my $name = undef;
      if ( $node->hasAttributes() ) {
        my $property = $node->getAttribute('name');
        my $value    = $node->textContent;
        $name_vals{$property} = $value;
      }
    }
    my %values = data_prep( 'extended_host_info_templates', \%name_vals );
    foreach my $val ( keys %{ $objects{'extended_host_info_templates'} } ) {
      if ( $val =~ /^$values{'name'}$/i ) {
        $objects{'extended_host_info_templates'}{ $values{'name'} } =
          $objects{'extended_host_info_templates'}{$val};
      }
    }
    if ( $objects{'extended_host_info_templates'}{ $values{'name'} } ) {
      if ( $overwrite == 1 ) {
        my $result = StorProc->update_obj( 'extended_host_info_templates',
          'name', $values{'name'}, \%values );
        if ( $result =~ /^Error/ ) {
          push @errors, "Error: $result Continue...";
        }
        else {
          $update_cnt++;
        }
      }
    }
    else {
      my @db_vals = split( /,/, $db_values{'extended_host_info_templates'} );
      my @values = ('');
      foreach my $val (@db_vals) { push @values, $values{$val} }
      my $id = StorProc->insert_obj_id( 'extended_host_info_templates',
        \@values, 'hostextinfo_id' );
      if ( $id =~ /^Error/ ) {
        push @errors, "Error: $id Continue...";
      }
      else {
        $objects{'extended_host_info_templates'}{ $values{'name'} } = $id;
        $add_cnt++;
      }
    }
  }
  push @messages,
    (
"Extended host info templates: $cnt read $add_cnt added $update_cnt updated (overwrite existing = $ov{$overwrite})."
    );
  return @errors;
}

#
############################################################################
# Service Templates
#

sub service_templates() {
  my %child      = ();
  my %name_vals  = ();
  my @errors     = ();
  my $cnt        = 0;
  my $add_cnt    = 0;
  my $update_cnt = 0;
  my @objs       = $root->findnodes("//service_template");
  foreach my $obj (@objs) {
    $cnt++;
    my $name      = undef;
    my $db_update = 1;
    my @siblings  = $obj->getChildnodes();
    foreach my $node (@siblings) {
      if ( $node->hasAttributes() ) {
        my $property = $node->getAttribute('name');
        my $value    = $node->textContent;
        if ( $value eq '0' ) { $value = "-zero-" }
        $name_vals{$property} = $value;
        if ( $property eq 'name' ) { $name = $value }
        if ($value) {
          if ( $property =~ /^check_command$|^event_handler$/ ) {
            if ( $objects{'commands'}{$value} ) {
              $name_vals{$property} = $objects{'commands'}{$value};
            }
            else {
              $db_update = 0;
              delete $child{ $name_vals{'name'} };
              push @errors,
"Command definition $value for $property does not exist for service template $name.";
            }
          }
          if ( $property =~ /period/ ) {
            if ( $objects{'time_periods'}{$value} ) {
              $name_vals{$property} = $objects{'time_periods'}{$value};
            }
            else {
              $db_update = 0;
              delete $child{ $name_vals{'name'} };
              push @errors,
"Time period definition $value for $property does not exist for service template $name.";
            }
          }
        }
        if ( $property eq 'template' && $db_update == 1 ) {
          $child{ $name_vals{'name'} } = $value;
          $name_vals{'parent_id'} = '';
          delete $name_vals{'template'};
        }
      }
    }
    unless ( $errors[0] ) {
      my %values = data_prep( 'service_templates', \%name_vals );
      foreach my $val ( keys %{ $objects{'service_templates'} } ) {
        if ( $val =~ /^$values{'name'}$/i ) {
          $objects{'service_templates'}{ $values{'name'} } =
            $objects{'service_templates'}{$val};
        }
      }
      if ( $objects{'service_templates'}{ $values{'name'} } ) {
        if ( $overwrite == 1 ) {
          my $result =
            StorProc->update_obj( 'service_templates', 'name', $values{'name'},
            \%values );
          if ( $result =~ /^Error/ ) {
            push @errors, "Error: $result Continue...";
          }
          else {
            $update_cnt++;
          }
        }
      }
      else {
        my @db_vals = split( /,/, $db_values{'service_templates'} );
        my @values = ('');
        foreach my $val (@db_vals) { push @values, $values{$val} }
        my $id = StorProc->insert_obj_id( 'service_templates', \@values,
          'servicetemplate_id' );
        if ( $id =~ /^Error/ ) {
          push @errors, "Error: $id Continue...";
        }
        else {
          $objects{'service_templates'}{ $values{'name'} } = $id;
          $add_cnt++;
        }
      }
    }
  }

  foreach my $c ( keys %child ) {
    my %values = ( 'parent_id' => $objects{'service_templates'}{ $child{$c} } );
    my $result =
      StorProc->update_obj( 'service_templates', 'name', $c, \%values );
    if ( $result =~ /^Error/ ) { push @errors, "Error: $result Continue..." }
  }
  push @messages,
    (
"Service templates: $cnt read $add_cnt added $update_cnt updated (overwrite existing = $ov{$overwrite})."
    );
  return @errors;
}

#
############################################################################
# Extended Service Info
#

sub serviceextinfo_templates() {
  my @errors     = ();
  my %name_vals  = ();
  my $cnt        = 0;
  my $add_cnt    = 0;
  my $update_cnt = 0;
  my @objs       = $root->findnodes("//extended_service_info_template");
  foreach my $obj (@objs) {
    $cnt++;
    my @siblings = $obj->getChildnodes();
    foreach my $node (@siblings) {
      my $name = undef;
      if ( $node->hasAttributes() ) {
        my $property = $node->getAttribute('name');
        my $value    = $node->textContent;
        $name_vals{$property} = $value;
      }
    }
    my %values = data_prep( 'extended_service_info_templates', \%name_vals );
    foreach my $val ( keys %{ $objects{'extended_service_info_templates'} } ) {
      if ( $val =~ /^$values{'name'}$/i ) {
        $objects{'extended_service_info_templates'}{ $values{'name'} } =
          $objects{'extended_service_info_templates'}{$val};
      }
    }
    if ( $objects{'extended_service_info_templates'}{ $values{'name'} } ) {
      if ( $overwrite == 1 ) {
        my $result = StorProc->update_obj( 'extended_service_info_templates',
          'name', $values{'name'}, \%values );
        if ( $result =~ /^Error/ ) {
          push @errors, "Error: $result Continue...";
        }
        else {
          $update_cnt++;
        }
      }
    }
    else {
      my @db_vals = split( /,/, $db_values{'extended_service_info_templates'} );
      my @values = ('');
      foreach my $val (@db_vals) { push @values, $values{$val} }
      my $id = StorProc->insert_obj_id( 'extended_service_info_templates',
        \@values, 'serviceextinfo_id' );
      if ( $id =~ /^Error/ ) {
        push @errors, "Error: $id Continue...";
      }
      else {
        $objects{'extended_service_info_templates'}{ $values{'name'} } = $id;
        $add_cnt++;
      }
    }
  }
  push @messages,
    (
"Extended service info templates: $cnt read $add_cnt added $update_cnt updated (overwrite existing = $ov{$overwrite})."
    );
  return @errors;
}

#
############################################################################
# Services
#

sub services() {
  my @errors     = ();
  my $cnt        = 0;
  my $add_cnt    = 0;
  my $update_cnt = 0;
  my @objs       = $root->findnodes("//service_name");
  foreach my $obj (@objs) {
    my @externals = ();
    my %name_vals = ();
    $cnt++;
    my $name     = undef;
    my @siblings = $obj->getChildnodes();
    foreach my $node (@siblings) {
      if ( $node->hasAttributes() ) {
        my $property = $node->getAttribute('name');
        my $value    = $node->textContent;
        if ( $value eq '0' ) { $value = "-zero-" }
        $name_vals{$property} = $value;
        if ( $property eq 'name' ) { $name = $value }
        if ($value) {
          if ( $property =~ /check_command|event_handler/ ) {
            if ( $objects{'commands'}{$value} ) {
              $name_vals{$property} = $objects{'commands'}{$value};
            }
            else {
              push @errors,
"Command definition $value for $property does not exist for service $name.";
            }
          }
          elsif ( $property eq 'template' ) {
            if ( $objects{'service_templates'}{$value} ) {
              $name_vals{$property} = $objects{'service_templates'}{$value};
            }
            else {
              push @errors,
                "Service template $value does not exist for service $name.";
            }
          }
          elsif ( $property =~ /check_period|notification_period/ ) {
            if ( $objects{'time_periods'}{$value} ) {
              $name_vals{$property} = $objects{'time_periods'}{$value};
            }
            else {
              push @errors,
"Time periods definition $value for $property does not exist for service $name.";
            }
          }
          elsif ( $property eq 'extinfo' ) {
            if ( $objects{'extended_service_info_templates'}{$value} ) {
              $name_vals{$property} =
                $objects{'extended_service_info_templates'}{$value};
            }
            else {
              push @errors,
"Extended info definition $value does not exist for service $name.";
            }
          }
          elsif ( $property eq 'service_external' ) {
            if ( $objects{'externals'}{$value} ) {
              push @externals, $objects{'externals'}{$value};
            }
            else {
              push @errors,
                "External definition $value does not exist for service $name.";
            }
          }
        }
      }
    }
    unless ( $name_vals{'command_line'} ) {
      $name_vals{'command_line'} = 'NULL';
    }
    unless ( $errors[0] ) {
      my %values          = data_prep( 'service_names',         \%name_vals );
      my %override_values = data_prep( 'servicename_overrides', \%name_vals );
      foreach my $val ( keys %{ $objects{'service_names'} } ) {
        if ( $val =~ /^$values{'name'}$/i ) {
          $objects{'service_names'}{ $values{'name'} } =
            $objects{'service_names'}{$val};
        }
      }
      if ( $objects{'service_names'}{ $values{'name'} } ) {
        if ( $overwrite == 1 ) {
          $update_cnt++;
          my $result =
            StorProc->update_obj( 'service_names', 'name', $values{'name'},
            \%values );
          if ( $result =~ /^Error/ ) {
            push @errors, "Error: $result Continue...";
          }
          elsif (%override_values) {
            my %service =
              StorProc->fetch_one( 'service_names', 'name', $values{'name'} );
            my %service_override =
              StorProc->fetch_one( 'servicename_overrides', 'servicename_id',
              $service{'servicename_id'} );
            if ( $service_override{'servicename_id'} ) {
              $result = StorProc->update_obj(
                'servicename_overrides',    'servicename_id',
                $service{'servicename_id'}, \%override_values
              );
              if ( $result =~ /^Error/ ) {
                push @errors, "Error: $result Continue...";
              }
            }
            else {
              my @db_vals = split( /,/, $db_values{'servicename_overrides'} );
              my @values = ( $service{'servicename_id'} );
              foreach my $val (@db_vals) {
                push @values, $override_values{$val};
              }
              my $result =
                StorProc->insert_obj( 'servicename_overrides', \@values );
              if ( $result =~ /^Error/ ) {
                push @errors, "Error: $result Continue...";
              }
            }
          }
          $result =
            StorProc->delete_all( 'external_service_names', 'servicename_id',
            $objects{'service_names'}{ $values{'name'} } );
          if ( $result =~ /^Error/ ) { push @errors, $result }
          foreach my $eid (@externals) {
            my @values = ( $eid, $objects{'service_names'}{ $values{'name'} } );
            my $result =
              StorProc->insert_obj( 'external_service_names', \@values );
            if ( $result =~ /^Error/ ) {
              push @errors, "Error: $result Continue...";
            }
          }

        }
      }
      else {
        my @db_vals = split( /,/, $db_values{'service_names'} );
        my @values = ('');
        foreach my $val (@db_vals) { push @values, $values{$val} }
        unless ( $monarch_ver eq '0.97a' ) {
          pop @values;
          push @values, $empty_data;
        }
        my $id = StorProc->insert_obj_id( 'service_names', \@values,
          'servicename_id' );
        if ( $id =~ /^Error/ ) {
          push @errors, "Error: $id Continue...$db_values{'service_names'}";
        }
        else {
          if (%override_values) {
            my @db_vals = split( /,/, $db_values{'servicename_overrides'} );
            @values = ($id);
            foreach my $val (@db_vals) { push @values, $override_values{$val} }
            my $result =
              StorProc->insert_obj( 'servicename_overrides', \@values );
            if ( $result =~ /^Error/ ) {
              push @errors, "Error: $result Continue...";
            }
          }
          $objects{'service_names'}{ $values{'name'} } = $id;
          $add_cnt++;
          foreach my $eid (@externals) {
            my @values = ( $eid, $id );
            my $result =
              StorProc->insert_obj( 'external_service_names', \@values );
            if ( $result =~ /^Error/ ) {
              push @errors, "Error: $result Continue...";
            }
          }
        }
      }
    }
  }
  push @messages,
    (
"Services: $cnt read $add_cnt added $update_cnt updated (overwrite existing = $ov{$overwrite})."
    );
  return @errors;
}

#
############################################################################
# Service Profiles
#

sub service_profiles() {
  my %name_vals  = ();
  my @errors     = ();
  my @services   = ();
  my $cnt        = 0;
  my $add_cnt    = 0;
  my $update_cnt = 0;
  my @objs       = $root->findnodes("//service_profile");
  foreach my $obj (@objs) {
    $cnt++;
    my $name     = undef;
    my %services = ();
    my $spid     = undef;
    my @siblings = $obj->getChildnodes();
    foreach my $node (@siblings) {
      if ( $node->hasAttributes() ) {
        my $property = $node->getAttribute('name');
        my $value    = $node->textContent;
        $name_vals{$property} = $value;
        if ( $property eq 'name' ) { $name = $value }
        if ( $property eq 'service' ) {
          if ( $objects{'service_names'}{$value} ) {
            $services{ $objects{'service_names'}{$value} } = 1;
          }
          else {
            push @messages,
"Service definition $value does not exist for service profile $name.";
          }
        }
      }
    }
    foreach my $val ( keys %{ $objects{'profiles_service'} } ) {
      if ( $val =~ /^$name_vals{'name'}$/i ) {
        $objects{'profiles_service'}{ $name_vals{'name'} } =
          $objects{'profiles_service'}{$val};
      }
    }
    if ( $objects{'profiles_service'}{ $name_vals{'name'} } ) {
      push @messages, "Service profile $name exists.";
      if ( $overwrite == 1 ) {
        my %vals = ( 'description' => $name_vals{'description'} );
        my $result =
          StorProc->update_obj( 'profiles_service', 'name', $name_vals{'name'},
          \%vals );
        if ( $result =~ /^Error/ ) {
          push @errors, "Error: $result Continue...";
        }
        else {
          $update_cnt++;
        }
      }
    }
    else {
      my @values = ( '', $name_vals{'name'}, $name_vals{'description'} );
      unless ( $monarch_ver eq '0.97a' ) { push @values, $empty_data }
      my $id = StorProc->insert_obj_id( 'profiles_service', \@values,
        'serviceprofile_id' );
      if ( $id =~ /^Error/ ) {
        push @errors, "Error: $id Continue...";
      }
      else {
        $add_cnt++;
        $objects{'profiles_service'}{ $name_vals{'name'} } = $id;
      }
    }
    my %where =
      ( 'serviceprofile_id' =>
        $objects{'profiles_service'}{ $name_vals{'name'} } );
    my @snids =
      StorProc->fetch_list_where( 'serviceprofile', 'servicename_id', \%where );
    foreach my $service ( keys %services ) {
      my $exists = 0;
      foreach (@snids) {
        if ( $_ eq $service ) { $exists = 1 }
      }
      unless ($exists) {
        my @vals =
          ( $service, $objects{'profiles_service'}{ $name_vals{'name'} } );
        my $result = StorProc->insert_obj( 'serviceprofile', \@vals );
        if ( $result =~ /^Error/ ) {
          push @errors, "Error: $result Continue...";
        }
      }
    }
  }
  push @messages,
    (
"Service profiles: $cnt read $add_cnt added $update_cnt updated (overwrite existing = $ov{$overwrite})."
    );
  return @errors;
}

#
############################################################################
# Import Externals - used for both host or service externals
#

sub import_externals($) {
  my $obj_type    = shift;
  my @objs        = ();
  my @errors      = ();
  my %name_vals   = ();
  my $read_cnt    = 0;
  my $added_cnt   = 0;
  my $updated_cnt = 0;

  if ($obj_type =~ /^(?:host|service)$/) {
	my $node_str = '//' . $obj_type . '_external';
  	@objs        = $root->findnodes($node_str);
  	$read_cnt    = scalar @objs;
  }
  else {
  	push @errors, "Error: invalid object type [$obj_type] passed to import_externals(). Continue...";
  }

  foreach my $obj (@objs) {
    my @siblings = $obj->getChildnodes();
    foreach my $node (@siblings) {
      my $name = undef;
      if ( $node->hasAttributes() ) {
        my $property = $node->getAttribute('name');
        my $value    = $node->textContent;
        $name_vals{$property} = $value;
      }
    }
    my %values =
      ( 'type' => $name_vals{'type'}, 'display' => $name_vals{'data'} );
    if ( $objects{'externals'}{ $name_vals{'name'} } ) {
      if ( $overwrite == 1 ) {
        my $result = StorProc->update_obj( 'externals', 'name', $name_vals{'name'}, \%values );
        if ( $result =~ /^Error/ ) {
          push @errors, "Error: $result Continue...";
        }
        else {
          $updated_cnt++;
          if ($obj_type eq 'host') {
            push @host_externals, $objects{'externals'}{ $values{'name'} };
          }
        }
      }
    }
    else {
      my @values = (
        '', $name_vals{'name'}, '', $name_vals{'type'}, $name_vals{'data'}, ''
      );
      my $id = StorProc->insert_obj_id( 'externals', \@values, 'external_id' );
      if ( $id =~ /^Error/ ) {
        push @errors, "Error: $id\nContinue...";
      }
      else {
        $objects{'externals'}{ $name_vals{'name'} } = $id;
        $added_cnt++;
        push (@host_externals, $id) if ($obj_type eq 'host');
      }
    }
  }
  push @messages,
    (
"\u$obj_type externals: $read_cnt read $added_cnt added $updated_cnt updated (overwrite existing = $ov{$overwrite})."
    );
  return @errors;
}

#
############################################################################
# Host Profiles
#

sub host_profiles() {
  my %name_vals  = ();
  my @errors     = ();
  my $cnt        = 0;
  my $add_cnt    = 0;
  my $update_cnt = 0;
  my @objs       = $root->findnodes("//host_profile");
  foreach my $obj (@objs) {
    $cnt++;
    my $name             = undef;
    my %service_profiles = ();
    my $insert_obj       = 0;
    my @siblings         = $obj->getChildnodes();
    foreach my $node (@siblings) {
      if ( $node->hasAttributes() ) {
        my $property = $node->getAttribute('name');
        my $value    = $node->textContent;
        $name_vals{$property} = $value;
        if ( $property eq 'name' ) { $name = $value }
        if ( $property eq 'host_template' ) {
          if ( $objects{'host_templates'}{$value} ) {
            $name_vals{'host_template_id'} = $objects{'host_templates'}{$value};
          }
          else {
            push @errors,
"Host template definition $value does not exist for host profile $name.";
          }
          delete $name_vals{$property};
        }
        unless ( $errors[0] ) {
          if ( $property eq 'extended_host_info_templates' ) {
            if ( $objects{'extended_host_info_templates'}{$value} ) {
              $name_vals{$property} =
                $objects{'extended_host_info_templates'}{$value};
            }
            else {
              push @messages,
"Extended info definition $value does not exist for host profile $name.";
              push @messages, "Action: $value ignored.";
            }
            delete $name_vals{$property};
          }
          if ( $property eq 'service_profile' ) {
            if ( $objects{'profiles_service'}{$value} ) {
              if ( $monarch_ver eq '0.97a' ) {
                $name_vals{'serviceprofile_id'} =
                  $objects{'profiles_service'}{$value};
              }
              else {
                $service_profiles{ $objects{'profiles_service'}{$value} } = 1;
              }
            }
            else {
              push @messages,
"Service profile definition $value does not exist for host profile $name.";
              push @messages, "Action: $value ignored.";
            }
            delete $name_vals{$property};
          }
        }
      }
    }
    unless ( $errors[0] ) {
      my %values = data_prep( 'profiles_host', \%name_vals );
      foreach my $val ( keys %{ $objects{'profiles_host'} } ) {
        if ( $val =~ /^$values{'name'}$/i ) {
          $objects{'profiles_host'}{ $values{'name'} } =
            $objects{'profiles_host'}{$val};
        }
      }
      if ( $objects{'profiles_host'}{ $values{'name'} } ) {
        if ( $overwrite == 1 ) {
          my $result =
            StorProc->update_obj( 'profiles_host', 'name', $values{'name'},
            \%values );
          if ( $result =~ /^Error/ ) {
            push @errors, "Error: $result Continue...";
          }
          else {
            $update_cnt++;
            my $result =
              StorProc->delete_all( 'external_host_profile', 'hostprofile_id',
              $objects{'profiles_host'}{ $values{'name'} } );
            if ( $result =~ /^Error/ ) { push @errors, $result }
            foreach my $eid (@host_externals) {
              my @values =
                ( $eid, $objects{'profiles_host'}{ $values{'name'} } );
              my $result =
                StorProc->insert_obj( 'external_host_profile', \@values );
              if ( $result =~ /^Error/ ) {
                push @errors, "Error: $result Continue...";
              }
            }

          }
        }
      }
      else {
        my @db_vals = split( /,/, $db_values{'profiles_host'} );
        my @values = ('');
        foreach my $val (@db_vals) { push @values, $values{$val} }
        unless ( $monarch_ver eq '0.97a' ) { push @values, $empty_data }
        my $id = StorProc->insert_obj_id( 'profiles_host', \@values,
          'hostprofile_id' );
        if ( $id =~ /^Error/ ) {
          push @errors, "Error: $id Continue...";
        }
        else {
          $objects{'profiles_host'}{ $values{'name'} } = $id;
          $add_cnt++;
          foreach my $eid (@host_externals) {
            my @values = ( $eid, $id );
            my $result =
              StorProc->insert_obj( 'external_host_profile', \@values );
            if ( $result =~ /^Error/ ) {
              push @errors, "Error: $result Continue...";
            }
          }
        }
      }
      unless ( $monarch_ver eq '0.97a' ) {
        my %where =
          ( 'hostprofile_id' => $objects{'profiles_host'}{ $values{'name'} } );
        my @snids = StorProc->fetch_list_where( 'profile_host_profile_service',
          'serviceprofile_id', \%where );
        foreach my $service ( keys %service_profiles ) {
          my $exists = 0;
          foreach (@snids) {
            if ( $_ eq $service ) { $exists = 1 }
          }
          unless ($exists) {
            my @vals =
              ( $objects{'profiles_host'}{ $name_vals{'name'} }, $service );
            my $result =
              StorProc->insert_obj( 'profile_host_profile_service', \@vals );
            if ( $result =~ /^Error/ ) {
              push @errors, "Error: $result Continue...";
            }
          }
        }
      }

    }
  }
  push @messages,
    (
"Host profile: $cnt read $add_cnt added $update_cnt updated (overwrite existing = $ov{$overwrite})."
    );
  return @errors;
}

#
# Performance configuration
#

sub parse_perfconfig_xml(@) {
  my $xmlfile   = $_[0];
  my $overwrite = $_[1];
  my @errors    = ();
  open( XMLFILE, "$xmlfile" ) || push @errors,
    "ERROR: Can't open XML file $xmlfile $!";
  my $data       = undef;
  my $end_config = undef;
  while ( my $line = <XMLFILE> ) {
    chomp $line;
    $data .= $line;
  }
  my (
    $host,            $service,         $type,     $enable,
    $parseregx_first, $service_regx,    $label,    $rrdname,
    $rrdcreatestring, $rrdupdatestring, $graphcgi, $perfidstring,
    $parseregx
  ) = ();
  if ($data) {
    push @messages, "Performance configuration $xmlfile found.";
    eval {
      my $parser = XML::LibXML->new();
      my $doc    = $parser->parse_string($data);
      my @nodes  = $doc->findnodes("groundwork_performance_configuration");
      foreach my $node (@nodes) {
        foreach my $servprof ( $node->getChildnodes ) {
          foreach my $childnode ( $servprof->findnodes("graph") ) {
            foreach my $key ( $childnode->findnodes("host") ) {
              $host = $key->textContent;
            }
            foreach my $key ( $childnode->findnodes("service") ) {
              $service = $key->textContent;
              if ( $key->hasAttributes() ) {
                $service_regx = $key->getAttribute('regx');
              }
            }
            foreach my $key ( $childnode->findnodes("type") ) {
              $type = $key->textContent;
            }
            foreach my $key ( $childnode->findnodes("enable") ) {
              $enable = $key->textContent;
            }
            foreach my $key ( $childnode->findnodes("label") ) {
              $label = $key->textContent;
            }
            foreach my $key ( $childnode->findnodes("rrdname") ) {
              $rrdname = $key->textContent;
            }
            foreach my $key ( $childnode->findnodes("rrdcreatestring") ) {
              $rrdcreatestring = $key->textContent;
            }
            foreach my $key ( $childnode->findnodes("rrdupdatestring") ) {
              $rrdupdatestring = $key->textContent;
            }
            foreach my $key ( $childnode->findnodes("graphcgi") ) {
              $graphcgi = $key->textContent;
            }
            foreach my $key ( $childnode->findnodes("perfidstring") ) {
              $perfidstring = $key->textContent;
            }
            foreach my $key ( $childnode->findnodes("parseregx") ) {
              $parseregx = $key->textContent;
              if ( $key->hasAttributes() ) {
                $parseregx_first = $key->getAttribute('first');
              }
            }
            my %where = ( 'host' => $host, 'service' => $service );
            my %perf_config =
              StorProc->fetch_one_where( 'performanceconfig', \%where );
            unless ($perfidstring) { $perfidstring = ' ' }
            unless ($parseregx)    { $parseregx    = ' ' }
            if ( $perf_config{'performanceconfig_id'} ) {
              if ( $overwrite == 1 ) {
                my %values = (
                  'host'            => $host,
                  'service'         => $service,
                  'type'            => $type,
                  'enable'          => $enable,
                  'parseregx_first' => $parseregx_first,
                  'service_regx'    => $service_regx,
                  'label'           => $label,
                  'rrdname'         => $rrdname,
                  'rrdcreatestring' => $rrdcreatestring,
                  'rrdupdatestring' => $rrdupdatestring,
                  'graphcgi'        => $graphcgi,
                  'perfidstring'    => $perfidstring,
                  'parseregx'       => $parseregx
                );
                my $result =
                  StorProc->update_obj_where( 'performanceconfig', \%values,
                  \%where );
                if ( $result =~ /error/i ) {
                  push @errors, $result;
                }
                else {
                  push @messages,
"Performance configuration for host $host service $service updated (overwrite existing = $ov{$overwrite}).";
                }
              }
              else {
                push @messages,
"Performance configuration for host $host service $service exists (overwrite existing = $ov{$overwrite}).";

              }
            }
            else {
              unless ($graphcgi) { $graphcgi = '/' }
              my @values = (
                '',               $host,            $service,
                $type,            $enable,          $parseregx_first,
                $service_regx,    $label,           $rrdname,
                $rrdcreatestring, $rrdupdatestring, $graphcgi,
                $perfidstring,    $parseregx
              );
              my $result =
                StorProc->insert_obj( 'performanceconfig', \@values );
              if ( $result =~ /error/i ) {
                push @errors, $result;
              }
              else {
                push @messages,
"Performance configuration created for host $host service $service.";
              }
            }
          }
        }
      }    # end eval
    };
  }
  if ($@) { push @errors, $@ }
  return @errors;
}

sub import_profile(@) {
  my $folder  = $_[1];
  my $xmlfile = $_[2];
  $overwrite = $_[3];
  unless ($overwrite) { $overwrite = 2 }
  $file = "$folder/$xmlfile";
  my @errors = ();
  @messages = ();
  my $parser = XML::LibXML->new();
  eval { $tree = $parser->parse_file("$file") };
  push @errors, "Error: $file is not a valid file type: $@" if $@;

  unless ( $errors[0] ) {
    $root    = $tree->getDocumentElement;
    %objects = StorProc->get_objects();
    if ( $objects{'error'} ) {
      foreach my $table ( keys %{ $objects{'error'} } ) {
        push @errors, $objects{'error'}{$table};
      }
    }
    unless ( $errors[0] ) {
      %db_values = StorProc->db_values();
      my %monarch_ver =
        StorProc->fetch_one( 'setup', 'name', 'monarch_version' );
      $monarch_ver = $monarch_ver{'value'};
      @errors      = commands();
    }
  }
  unless ( $errors[0] ) {
    @errors = timeperiods();
  }
  unless ( $errors[0] ) {
    @errors = host_templates();
  }
  unless ( $errors[0] ) {
    @errors = hostextinfo_templates();
  }
  unless ( $errors[0] ) {
    @errors = service_templates();
  }
  unless ( $errors[0] ) {
    @errors = serviceextinfo_templates();
  }
  unless ( $errors[0] ) {
    @errors = import_externals('service');
  }
  unless ( $errors[0] ) {
    @errors = import_externals('host');
  }
  unless ( $errors[0] ) {
    @errors = services();
  }
  unless ( $errors[0] ) {
    @errors = service_profiles();
  }
  unless ( $errors[0] ) {
    @errors = host_profiles();
  }
  unless ( $errors[0] ) {
    $xmlfile =~ s/^(?:host-profile-|service-profile-|service-)//;
    my $perfcfg_file = undef;
    opendir( DIR, $folder )
      || ( push @errors, "Error: cannot open $folder to read $!" );
    while ( my $file = readdir(DIR) ) {
      if ( $file =~ /perfconfig-$xmlfile/i ) { $perfcfg_file = $file; last }
    }
    close(DIR);
    if ($perfcfg_file) {
      @errors = parse_perfconfig_xml( "$folder/$perfcfg_file", $overwrite );
    }
  }
  if (@errors) {
    push( @messages, @errors );
    push @messages, "Profile import halted. Make corrections and try again.";
    return @messages;
  }
  else {
    return @messages;
  }
}

if ($debug) {
  my $path      = $ARGV[1];
  my $file      = $ARGV[2];
  my $overwrite = $ARGV[3];
  my @result    = ( my $result ) = StorProc->dbconnect();

  my @res = import_profile( '', $path, $file, $overwrite );
  push( @result, @res );
  $result = StorProc->dbdisconnect();
  print "\nFile: $file\n";
  print "Monarch ver: $monarch_ver\n";
  print
"\nResults:\n========================================================================\n";
  foreach my $line (@res) {
    print "\n\t$line";
  }
  print
"\n\nEnd=============================================================================\n";
}

1;

