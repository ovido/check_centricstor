#!/usr/bin/perl -w
# nagios: -epn

#######################################################
#                                                     #
#  Name:    check_centricstor                         #
#                                                     #
#  Version: 1.0.0                                     #
#  Created: 2012-12-05                                #
#  License: GPL - http://www.gnu.org/licenses         #
#  Copyright: (c)2012 ovido gmbh, http://www.ovido.at #
#  Author:  Rene Koch <r.koch@ovido.at>               #
#  Credits: s IT Solutions AT Spardat GmbH            #
#  URL: https://labs.ovido.at/monitoring              #
#                                                     #
#######################################################

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

# Changelog:
# * 1.0.0 - Sun Jan 06 2013 - Rene Koch <r.koch@ovido.at>
# - Released stable version
# * 0.1.0 - Thu Dec 06 2012 - Rene Koch <r.koch@ovido.at>
# - This is the first public beta release 


use strict;
use Getopt::Long;

# for debugging only
#use Data::Dumper;

# Configuration
# all values can be overwritten via command line options
my $ssh		= "/usr/bin/ssh";	# default path to ssh client

# create performance data
# 0 ... disabled
# 1 ... enabled
my $perfdata	= 1;


# Variables
my $prog	= "check_centricstor";
my $version	= "1.0";
my $projecturl  = "https://labs.ovido.at/monitoring/wiki/check_centricstor";

my $o_verbose	= undef;	# verbosity
my $o_help	= undef;	# help
my $o_version	= undef;	# version
my $o_timeout	= undef;	# timeout
my $o_ssh	= "";		# ssh options
my $o_hostname	= undef;	# hostname
my $o_warn;			# warning
my $o_crit;			# critical
my $o_check	= undef;

my $vlmcmd = "vlmcmd";
my $plmcmd = "plmcmd";

my %status	= ( ok => "OK", warning => "WARNING", critical => "CRITICAL", unknown => "UNKNOWN");
my %ERRORS	= ( "OK" => 0, "WARNING" => 1, "CRITICAL" => 2, "UNKNOWN" => 3);
my $statuscode  = 'unknown';
my $statustext  = undef;


#***************************************************#
#  Function: parse_options                          #
#---------------------------------------------------#
#  parse command line parameters                    #
#                                                   #
#***************************************************#

sub parse_options(){
  Getopt::Long::Configure ("bundling");
  GetOptions(
	'v+'	=> \$o_verbose,		'verbose+'	=> \$o_verbose,
	'h'	=> \$o_help,		'help'		=> \$o_help,
	'V'	=> \$o_version,		'version'	=> \$o_version,
	'l:s'	=> \$o_check,		'check:s'	=> \$o_check,
	's:s'	=> \$o_check,		'subcheck:s'	=> \$o_check,
	'S:s'	=> \$o_ssh,		'ssh:s'		=> \$o_ssh,
	'H:s'	=> \$o_hostname,	'hostname:s'	=> \$o_hostname,
	'P:s'	=> \$plmcmd,		'plmcmd:s'	=> \$plmcmd,
	'L:s'	=> \$vlmcmd,		'vlmcmd:s'	=> \$vlmcmd,
	'w:s'	=> \$o_warn,		'warning:s'	=> \$o_warn,
	'c:s'	=> \$o_crit,		'critical:s'	=> \$o_crit
  );

  # process options
  print_help()		if defined $o_help;
  print_version()	if defined $o_version;
  if (! defined $o_hostname){
    print "Hostname of server is missing.\n";
    print_help();
  }

  $o_verbose = 0	if (! defined $o_verbose);
  $o_verbose = 0	if $o_verbose <= 0;
  $o_verbose = 3	if $o_verbose >= 3;

  $ssh	  .= " " . $o_ssh . " " . $o_hostname;

  $o_warn = "5,8" unless defined $o_warn;
  $o_crit = "8,5" unless defined $o_crit;
}


#***************************************************#
#  Function: print_usage                            #
#---------------------------------------------------#
#  print usage information                          #
#                                                   #
#***************************************************#

sub print_usage(){
  print "Usage: $0 -H <hostname> [-S <ssh>] [-v] [-w <warn>] [-c <critical>] [-V] -l <check> \n";
  print "       [-P <plmcmd>] [-L <vlmcmd>]\n";
}


#***************************************************#
#  Function: print_help                             #
#---------------------------------------------------#
#  print help text                                  #
#                                                   #
#***************************************************#

sub print_help(){
  print "\nFujitsu CentricStor checks for Icinga/Nagios version $version\n";
  print "GPL license, (c)2012 - Rene Koch <r.koch\@ovido.at>\n\n";
  print_usage();
  print <<EOT;

Options:
 -h, --help
    Print detailed help screen
 -V, --version
    Print version information
 -H, --hostname
    Hostname of server with plmcmd and vlmcmd binaries
 -S, --ssh
    SSH options - use '\' to escape ssh options!
    e.g. -S '\\-i ~/.ssh/id_rsa \\-o ConnectTimeout=10 \\-o BatchMode=yes \\-o StrictHostKeyChecking=no'
 -l, --check
    Slot status and Cache Usage Checks
    see $projecturl or README for details
    possible checks:
    caches: caches free and dirty usage
    slots: slot status
 -P, --plmcmd
    Path to plmcmd binary (default: $plmcmd)
 -L, --vlmcmd
    Path to vlmcmd binary (default: $vlmcmd)
 -w, --warning=DOUBLE
    Value to result in warning status
 -c, --critical=DOUBLE
    Value to result in critical status
 -v, --verbose
    Show details for command-line debugging
    (Icinga/Nagios may truncate output)

Send email to r.koch\@ovido.at if you have questions regarding use
of this software. To submit patches of suggest improvements, send
email to r.koch\@ovido.at
EOT

exit $ERRORS{$status{'unknown'}};
}


#***************************************************#
#  Function: print_version                          #
#---------------------------------------------------#
#  Display version of plugin and exit.              #
#                                                   #
#***************************************************#

sub print_version{
  print "$prog $version\n";
  exit $ERRORS{$status{'unknown'}};
}


#***************************************************#
#  Function: main                                   #
#---------------------------------------------------#
#  The main program starts here.                    #
#                                                   #
#***************************************************#

# parse command line options
parse_options();

# ssh commands
my $ssh_cache	= "$vlmcmd cstat";
my $ssh_slots	= "$plmcmd query -D";

# What to check?
&print_unknown("missing") if ! defined $o_check;
&check_cache	if $o_check eq "caches";
&check_slots	if $o_check eq "slots";
&print_unknown($o_check);


#***************************************************#
#  Function check_cache                             #
#---------------------------------------------------#
#  Prints an error message that the given check is  #
#  invalid and prints help page.                    #
#  ARG1: check                                      #
#***************************************************#

sub check_cache{

  # connect to server
  my $return = connect_ssh($ssh_cache);
  my @cache_name = ();
  my %caches;

  # loop through lines
  for (split /^/, $return){
    $_ =~ tr/ //s;
    $_ =~ s/^\s+//;
    chomp $_;

    # get lines which match /cache
    # /cache/100: (floating)
    # used:   0.69%  dirty:   1.45%  clean:  91.70%  free:   6.16%

    # get cache path
    @cache_name = split (/ /, $_) if $_ =~ /^\/cache\/[0-9]/;
    if ($_ =~ /^used:\s+\d+/){
      # get dirty caches and free caches
      my @tmp = split (/ /, $_);
      $caches{$cache_name[0]}{'dirty'} = $tmp[3];
      $caches{$cache_name[0]}{'free'}  = $tmp[7];
      chop $tmp[3];
      chop $tmp[7];

      if (defined $o_warn){
        if ($o_warn =~ /,/){
	  my @tmp_warn = split /,/, $o_warn;
          if ($tmp[3] >= $tmp_warn[0]){
	    $statustext .= "$cache_name[0] $tmp[3]% dirty, ";
            $statuscode = "warning" if $statuscode ne "critical";
          }
          if ($tmp[7] <= $tmp_warn[1]){
	    $statustext .= "$cache_name[0] $tmp[7]% free, ";
            $statuscode = "warning" if $statuscode ne "critical";
          }
        }else{
	  if ($tmp[3] >= $o_warn){
	    $statustext .= "$cache_name[0] $tmp[3]% dirty, ";
            $statuscode = "warning" if $statuscode ne "critical";
          }
          if ($tmp[7] <= $o_warn){
	    $statustext .= "$cache_name[0] $tmp[7]% free, ";
	    $statuscode = "warning" if $statuscode ne "critical";
          }
        }
      }

      if (defined $o_crit){
        if ($o_crit =~ /,/){
	  my @tmp_crit = split /,/, $o_crit;
          if ($tmp[3] >= $tmp_crit[0]){
	    $statustext .= "$cache_name[0] $tmp[3]% dirty, ";
            $statuscode = "critical";
          }
          if ($tmp[7] <= $tmp_crit[1]){
	    $statustext .= "$cache_name[0] $tmp[7]% free, ";
            $statuscode = "critical";
          }
        }else{
	  if ($tmp[3] >= $o_crit){
	    $statustext .= "$cache_name[0] $tmp[3]% dirty, ";
            $statuscode = "critical";
          }
          if ($tmp[7] <= $o_crit){
	    $statustext .= "$cache_name[0] $tmp[7]% free, ";
	    $statuscode = "critical";
          }
        }
      }

    }
    
  }

  $statuscode = "ok" if (( $statuscode ne "critical" ) && ($statuscode ne "warning"));
  $statustext = "Cache checks are below threshold" if (! defined $statustext);
  my $perf = "|";

  # overwrite output if verbose argument is given
  $statustext = "" if $o_verbose >= 1;
  foreach my $cachedir (keys %caches){
    $statustext .= " Cache $cachedir" if $o_verbose >= 1;
    foreach my $value (keys %{ $caches{$cachedir} }){
      $statustext .= " $value: $caches{$cachedir}{$value}," if $o_verbose >= 1;
      my $tmp = $cachedir;
      chop $tmp;
      $perf .= "'" . $tmp . "_" . $value . "'=$caches{$cachedir}{$value} ";
    }
  }
  chop $statustext if $o_verbose >= 1;
  chop $statustext if $o_verbose >= 1;

  exit_plugin($statuscode, $statustext . $perf);

}


#***************************************************#
#  Function check_slots                             #
#---------------------------------------------------#
#  Prints an error message that the given check is  #
#  invalid and prints help page.                    #
#  ARG1: check                                      #
#***************************************************#

sub check_slots{
 
  # connect to server
  my $return = connect_ssh($ssh_slots);
  my @tl = ();
  my %slots;
  my %crit_slots;
  
  # loop through lines
  for (split /^/, $return){
    $_ =~ tr/ //s;
    $_ =~ s/^\s+//;
    chomp $_;

    # get tape library name
    if ($_ =~ /^Tapelibrary:/){
      @tl = split (/ /, $_, 0);
    }

    # get lines which match PDS* - e.g.
    # pos  PDS    state         PV     PVG      job-state              timestamp
    #   1  PDS1   occupied      410509 GBSB2    ======             12-11-09 09:19:39

    if ($_ =~ /^\d+\s{1}PDS/){
      my @tmp = split (/ /, $_);
      $slots{$tl[1]}{$tmp[1]} = $tmp[2];
      # critical if status not unused or occupied
      if ( ($tmp[2] !~ /unused/) && ($tmp[2] !~ /occupied/) ){
        $crit_slots{$tmp[1]} = $tmp[2];
      }
    }
  }

  if (keys (%crit_slots) > 0){ 
    foreach my $cs (keys %crit_slots){
      $statustext .= "$cs $crit_slots{$cs}, ";
    }
    chop $statustext;
    chop $statustext;
    $statuscode = 'critical';
  }else{
    $statustext = "All slots are in state occupied or unused"; 
    $statuscode = 'ok';
  }

  # overwrite output if verbose argument is given
  if ($o_verbose >= 1){
    $statustext = "";
    foreach my $tapelib (keys %slots){
      $statustext .= "Tapelibrary $tapelib: ";
      foreach my $slot (keys %{ $slots{$tapelib} }){
        $statustext .= "Slot $slot: $slots{$tapelib}{$slot}, ";
      }
    }
    chop $statustext;
    chop $statustext;
  }

  exit_plugin($statuscode, $statustext);

}


#***************************************************#
#  Function connect_ssh                             #
#---------------------------------------------------#
#  Connect to server via ssh and execute predefined #
#  command.                                         #
#  ARG1: command                                    #
#***************************************************#

sub connect_ssh{
  my $command = $_[0];
  # execute command
  my $result = `$ssh "$command"; echo $?`;
  exit_plugin("unknown", "Error executing $ssh_slots") if $result =~ /^[0-9]$/;
  return $result;
}


#***************************************************#
#  Function print_unknown                           #
#---------------------------------------------------#
#  Prints an error message that the given check is  #
#  invalid and prints help page.                    #
#  ARG1: check                                      #
#***************************************************#

sub print_unknown{
  print "CentricStor $status{'unknown'}: Unknown check ($_[0]) is given.\n" if $_[0] ne "missing";
  print "CentricStor $status{'unknown'}: Missing check.\n" if $_[0] eq "missing";
  print_help;
  exit $ERRORS{$status{'unknown'}};
}


#***************************************************#
#  Function exit_plugin                             #
#---------------------------------------------------#
#  Prints plugin output and exits with exit code.   #
#  ARG1: status code (ok|warning|cirtical|unknown)  #
#  ARG2: additional information                     #
#***************************************************#

sub exit_plugin{
  print "CentricStor $status{$_[0]}: $_[1]\n";
  exit $ERRORS{$status{$_[0]}};
}


exit $ERRORS{$status{'unknown'}};

