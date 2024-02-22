package pf::Firewalld::policies;

=head1 NAME

pf::Firewalld::policies

=cut

=head1 DESCRIPTION

Module to get basic configuration about firewalld policies configurations

=cut


use strict;
use warnings;

use Exporter;
use pf::log;
use pf::Firewalld::services;
use pf::Firewalld::icmptypes;
use pf::Firewalld::ipsets;
use pf::Firewalld::zones;
use pf::Firewalld::util;
use pf::util::system_protocols;
use pf::config::util;
use pf::config qw(
    %Config
    $management_network
    %ConfigFirewalld
    @listen_ints
);


# need a function that return a structured content of the config file
sub generate_policy_config {
  my $conf = prepare_config( $ConfigFirewalld{"firewalld_policies"} );
  foreach my $k ( keys %{ $conf } ) {
    if ( length($k) <= 17 ){
      create_policy_config_file( $conf->{ $k }, $k );
      apply_policy( $k , $conf->{ $k }{"priority"} );
    } else {
      get_logger->error( "$k can not be bigger than 17 chars" );
    }
  }
}

# need a function that is creating the xml file from the config
# need a function that add interfaces in the config file
sub create_policy_config_file {
  my $conf = shift;
  my $policy = shift;
  util_prepare_version($conf);
  policy_target($conf); 
  policy_interface($conf);
  policy_sources($conf);
  policy_services($conf);
  policy_ports($conf);
  policy_protocols($conf);
  policy_icmp_blocks($conf);
  policy_forward_ports($conf);
  policy_source_ports($conf);
  policy_rules($conf);
  parse_template( $conf, "$Config_path_default_template/policy.xml", "$Config_path_default/policies/$policy.xml" );
}

sub apply_policy {
  my $policy = shift;
  my $priority = shift;
  my $set_priority = "";
  if ( $priority ){
    $set_priority = "--set-proprity $priority";
  }
  my $fd_cmd = get_firewalld_cmd();
  if ( $fd_cmd ) {
    `/bin/cp  $pf_dir/firewalld/policies/$policy.xml $generated_conf_dir/firewalld/policies/$policy.xml`;
    `$fd_cmd --permanent --policy $policy $set_priority`;
    if ( $set_priority ne ""){
      $set_priority = "with the priority $priority";
    }
    get_logger->info( "$policy has been applied permanently $set_priority" );
  }
}

# need a function that add services according to interface usage (see how lib/pf/iptables.pm is working)
# need a function that return a structured content of the config file
sub policy_version {
  my $c = shift;
  if (exists $c->{"version"} ) {
    my $v = $c->{"version"};
    if ( length $v ) {
      $c->{"version_xml"} = create_string_for_xml("version","$v");
    } else {
      $c->{"version_xml"} = "";
    }
  }
}

sub policy_target {
  my $c = shift;
  my $b = 0;
  if ( exists $c->{"target"} ) {
    my %policy_target_option=qw(accept 0
                  reject 1
                  drop 2
                  default 3);
    my $v = lc($c->{"target"});
    if ( exists $policy_target_option{$v} ) {
      get_logger->info("Target policy is $v");
      if ( $v eq "reject" ) {
        $c->{"target_xml"} = create_string_for_xml("target","%%REJECT%%");
      } else {
        $c->{"target_xml"} = create_string_for_xml("target",$v);
      }
    } else {
      $b = 1;
    }
  } else {
    $b = 1;
  }
  if ( $b ==1 ){
    get_logger->error("Unknown target policy. ==> Apply %%REJECT%%");
    $c->{"target_xml"} = create_string_for_xml("target","%%REJECT%%");
  }
}

sub policy_egress {
  my $c = shift;
  my $b = 0 ;
  if ( exists $c->{"egress_policies"} ) {
    my @t;
    my $vl = $c->{"egress_policies"};
    my $zones_hash = firewalld_zones_hash();
    $zones_hash->{"ANY"} = 1;
    $zones_hash->{"HOST"} = 1;
    foreach my $v ( @{ $vl } ) {
      if ( exists $zones_hash->{ $v->{"name"} } ) {
        get_logger->info("Egress policy ($v->{"name"}) is added");
        push( @t, $v} );
      } else {
        get_logger->error("Egress Policy ($v->{"name"}) does not exist.");
      }
    }
    $c->{"all_egress_policies"} = \@t;
  }
}

sub policy_ingress {
  my $c = shift;
  my $b = 0 ;
  if ( exists $c->{"ingress_policies"} ) {
    my @t;
    my $vl = $c->{"ingress_policies"};
    my $zones_hash = firewalld_zones_hash();
    $zones_hash->{"ANY"} = 1;
    $zones_hash->{"HOST"} = 1;
    foreach my $v ( @{ $vl } ) {
      if ( exists $zones_hash->{ $v->{"name"} } ) {
        get_logger->info("Ingress policy ($v->{"name"}) is added");
        push( @t, $v} );
      } else {
        get_logger->error("Ingress Policy ($v->{"name"}) does not exist.");
      }
    }
    $c->{"all_ingress_policies"} = \@t;
  }
}

sub policy_services {
  my $c = shift;
  if ( exists $c->{"services"} ) {
    my @t;
    my @vl = split(',', $c{"services"});
    foreach my $k ( @vl ) {
      if ( is_service_available($k) ) {
        push(@t, $k);
      } else {
        get_logger->error("==> Service is removed.");
      }
    }
    $c->{"all_services"} = \@t;
  }
}

sub policy_ports {
  my $c = shift;
  if ( exists $c->{"ports"} ) {
    my @t;
    my $vl = $c->{"ports"};
    foreach my $k ( @{ $vl } ) {
      if ( exists $k->{"protocol"} && exists $k->{"portid"} ) {
        if ( is_fd_protocol($k->{"protocol"}) ) {
          push(@t, $k);
        }
      } else {
        get_logger->error("==> Port is removed.");
      }
    }
    $c->{"all_ports"} = \%t;
  }
}

sub policy_protocols {
  my $c = shift;
  if ( exists $c->{"protocols"} ) {
    my @t;
    my @vl = split(',', $c->{"protocols"});
    foreach my $k ( @vl ) {
      if ( is_protocol_available($k) ) {
        push(@t, $k);
      } else {
        get_logger->error("==> Protocol ($k) is removed.");
      }
    }
    $c->{"all_protocols"} = \@t;
  }
}

sub policy_icmp_blocks {
  my $c = shift;
  if ( exists $c->{"icmpblocks"} ) {
    my @t;
    my @vl = split(',', $c{"icmpblocks"});
    foreach $k ( @vl ) {
      if ( is_icmptypes_available($k) ) {
        push(@t, $k);
      } else {
        get_logger->error("==> Icmpblocks ($k) is removed.");
      }
    }
    $c->{"all_icmpblocks"} = \@t;
  }
}

sub policy_forward_ports {
  my $c = shift;
  if ( exists $c->{"forwardports"} ) {
    my @t;
    my $vl = $c->{"forwardports"};
    foreach my $k ( @{ $vl } ) {
      if ( exists $k->{"protocol"} && exists $k->{"portid"} ) {
        if ( is_fd_protocol( $k->{"protocol"} ) ) {
          push(@t, $k);
          if ( exists $k->{"to_port"} ) {
            my $to_port = $k->{"to_port"};
            if ( length $to_port ) {
              $k->{"to_port_xml"} = create_string_for_xml("to-port",$to_port);
            }
          }
          if ( exists $k->{"to_addr"} ) {
            my $to_addr = $k->{"to_addr"};
            if ( length $to_addr ) {
              $k->{"to_addr_xml"} = create_string_for_xml("to-addr",$to_addr);
            }
          }
        } else {
          get_logger->error("==> Forward Port is removed.");
        }
      } else {
        get_logger->error("Forward Port needs a valid Protocol type and Portid ==> Forward Port is removed.");
      }
    }
    $c->{"all_forwardports"} = \@t;
  }
}

sub policy_source_ports {
  my $c = shift;
  if ( exists $c->{"sourceports"} ) {
    my @t;
    my $vl = $c->{"sourceports"};
    foreach my $k ( @{ $vl } ) {
      if ( exists $k->{"protocol"} && exists $k->{"portid"} ) {
        if ( is_fd_protocol($k->{"protocol"}) ) {
          push(@t, $k);
        } else {
          get_logger->error("==> Source Port is removed.");
        }
      } else {
        get_logger->error("Source Port needs a valid Protocol type and Portid ==> Source Port is removed.");
      }
    }
    $c->{"all_sourceports"} = \@t;
  }
}

sub policy_rules {
  my $c = shift;
  if ( exists $c->{"rules"} ) {
    my @t;
    my $vl   = $c->{"rules"};
    my $flag = 0;
    foreach my $h ( @{ $vl } ) {
      if ( exists $h->{"family"} ) {
        $h->{"family_xml"} = create_string_for_xml( "family", $h->{"family"} );
      } else {
        $h->{"family_xml"} = "";
      }
      if ( exists $h->{"priority"} ) {
        $h->{"priority_xml"} = create_string_for_xml( "priority", $h->{"priority"} );
      } else {
        $h->{"priority_xml"} = "";
      }
      if ( exists $h->{"source"} ) {
        my $source = $h->{"source"};
        my $st = source_or_destination_validation( $source );
        if ( $st ne "" ) {
          $flag=undef;
          get_logger->error( "$st ==> Source ($source->{"name"}) is removed." );
        }
        if ( exists $source->{"invert"} ) {
          $source->{"invert_xml"} = create_string_for_xml( "invert",$source->{"invert"} );
        }
      }
      if ( exists $h->{"destination"} ) {
        my $dest = $h->{"destination"};
        my $st = source_or_destination_validation( $destination );
        if ( $st ne "" ) {
          $flag=undef;
          get_logger->error( "$st ==> Destination ($destination->{"name"}) is removed." );
        }
        if ( exists $destination->{"invert"} ) {
          $destination->{"invert_xml"} = create_string_for_xml( "invert",$destination->{"invert"} );
        }
      }

      if ( exists $h->{"matchrules"} ) {
        my $match_rules = $h->{"matchrules"};
        foreach my $h2 ( keys %{ $match_rules } ) {
          my $match_rule = $match_rules->{$h2};
          if ( $match_rule->{"name"} eq "service" ) {
            if ( not is_service_available( $match_rule->{"service"} ) ) {
              $flag=undef;
            }
          } elsif ( $match_rule->{"name"} eq "port" ) {
            if ( exists $match_rule->{"portid"} && exists $match_rule->{"port_protocol"} ) {
              if ( not is_fd_protocol( $match_rule->{"port_protocol"} ) ) {
                $flag=undef;
              }
            } else {
              get_logger->error( "Port needs a protocol and a portid." );
              $flag=undef;
            }
          } elsif ( $match_rule->{"name"} eq "protocol" ) {
           if ( not is_fd_protocol( $match_rule->{"protocol"} ) ) {
              $flag=undef;
            }
          } elsif ( $match_rule->{"name"} eq "forward_port" ) {
            if ( exists $match_rule->{"portid"} && exists $match_rule->{"protocol"} ) {
              if ( is_fd_protocol($match_rule->{"protocol"} ) ) {
                if ( exists $match_rule->{"to_port"} ) {
                  $match_rule->{"to_port_xml"} = create_string_for_xml( "to-port", $match_rule->{"to_port"} );
                }
                if ( exists $match_rule->{"to_addr"} ) {
                  $match_rule->{"to_addr_xml"} = create_string_for_xml( "to-addr", $match_rule->{"to_addr"} );
                }
              } else {
                get_logger->error( "Match forward port not used." );
                $flag=undef;
              }
            } else {
              get_logger->error( "Match forward port rule needs a portid and a protocol" );
              $flag=undef;
            }
          } elsif ( ( $match_rule{"name"}-> eq "icmp_block" || $match_rule->{"name"} eq "icmp_type" ) {
            if ( not is_icmptypes_available( $match_rule->{"icmp_type"} ) ) {
              $flag=undef;
            }
          } elsif ( $match_rule->{"name"} ne "masquerade" ) {
            get_logger->error("Unknown match rule.");
            $flag=undef;
          }
        }
      }
      if ( exists $h->{"log_rule"} ) {
        my $log_rule = $h->{"log_rule"};
        if ( $log_rule->{"name"} eq "log" ) {
          if ( exists $log_rule->{"prefix"} ) {
            $log_rule->{"prefix_xml"} = create_string_for_xml( "prefix", $log_rule->{"prefix"} );
          }
          if ( exists $log_rule->{"level"} ) {
            $log_rule->{"level_xml"} = create_string_for_xml( "level", $log_rule->{"level"} );
          }
          if ( exists $log_rule->{"limit_value"} ) {
            $log_rule->{"limit_value_xml"} = create_limit_for_xml( $log_rule->{"limit_value"} );
          }
        } elsif ( $log_rule->{"name"} eq "nflog" ) {
          if ( exists $log_rule->{"group"} ) {
            $log_rule->{"group_xml"} = create_string_for_xml( "group", $log_rule->{"group"} );
          }
          if ( exists $log_rule->{"prefix"} ) {
            $log_rule->{"prefix_xml"} = create_string_for_xml( "prefix", $log_rule->{"prefix"} );
          }
          if ( exists $log_rule->{"level"} ) {
            $log_rule->{"queue_size_xml"} = create_string_for_xml( "queue size", $log_rule->{"queue_size"} );
          }
          if ( exists $log_rule->{"limit_value"} ) {
            $log_rule->{"limit_value_xml"} = create_limit_for_xml( $log_rule->{"limit_value"} );
          }
        } else {
          print "Unknown log rule.";
          $flag=undef;
        }
      }
      if ( exists $h->{"audit"} ){
        $h->{"audit_xml"} = create_limit_for_xml( $h->{"audit"} );
      }
      if ( exists $h->{"action"} ){
        my $action = $h->{"action"};
        if ( $action->{"name"} eq "accept" ) {
          if ( exists $action->{"limit_value"} ) {
            $action->{"limit_value_xml"} = create_limit_for_xml( $action->{"limit_value"} );
          }
        } elsif ( $action->{"name"} eq "reject" ) {
          if ( exists $action->{"type"} ) {
            $action->{"type_xml"} = create_string_for_xml( "type", $action->{"type"} );
          }
          if ( exists $action->{"limit_value"} ) {
            $action->{"limit_value_xml"} = create_limit_for_xml( $action->{"limit_value"} );
          }
        } elsif ( $action->{"name"} eq "drop" ) {
          if ( exists $action->{"limit_value"} ) {
            $action->{"limit_value_xml"} = create_limit_for_xml( $action->{"limit_value"} );
          }
        } elsif ( $action->{"name"} eq "mark" ) {
          if ( exists $action->{"set"} ) {
            $action->{"set_xml"} = create_string_for_xml( "set", $action->{"set"} );
          }
          if ( exists $action->{"limit_value"} ) {
            $action->{"limit_value_xml"} = create_limit_for_xml( $action->{"limit_value"} );
          }
        } elsif ( $action->{"name"} ne "" ) {
          print "Unknown action rule.";
          $flag=undef;
        }
      }
      if ( $flag ){
        push(@t, $h);
      } else {
        get_logger->error(" Rule $h->{"name"} is not correct and has been removed." );
      }
    }
    $c->{"all_rules"} = \@t;
  }
}


=head1
Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2023 Inverse inc.

=head1 LICENSE

This program is free software; you can redistribute it and::or
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
