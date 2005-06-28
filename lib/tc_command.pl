#!/usr/bin/perl
#-
# Copyright (c) 2004-2005 FreeBSD GNOME Team <freebsd-gnome@FreeBSD.org>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions
# are met:
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
# OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
# LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
# OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
# SUCH DAMAGE.
#
# $MCom: portstools/tinderbox/lib/tc_command.pl,v 1.41 2005/06/28 05:47:55 adamw Exp $
#

# This is a hack to make sure we can always find our modules.
BEGIN {
        my $pb = "/space";
        push @INC, "$pb/scripts";
        use lib "/space/scripts";
}

use strict;
use TinderboxDS;
use Getopt::Std;
use vars qw(
    %COMMANDS
    $BUILD_ROOT
    $TINDER_BIN
    $ERROR_DIR
    $LOG_DIR
    $BUILDS_DIR
    $JAILS_DIR
    $PKGS_DIR
    $PORTSTREES_DIR
    $WRKDIRS_DIR
    $SUBJECT
    $SMTP_HOST
    $SERVER_HOST
    $SERVER_PROTOCOL
    $SENDER
    $SHOWBUILD_URI
    $SHOWPORT_URI
    $LOG_URI
);

require "tinderbox.ph";
require "tinderlib.pl";

%COMMANDS = (
        "init" => {
                func  => \&init,
                help  => "Initialize a tinderbox environment",
                usage => "",
        },
        "listJails" => {
                func  => \&listJails,
                help  => "List all jails in the datastore",
                usage => "",
        },
        "listBuilds" => {
                func  => \&listBuilds,
                help  => "List all builds in the datastore",
                usage => "",
        },
        "listPortsTrees" => {
                func  => \&listPortsTrees,
                help  => "List all portstrees in the datastore",
                usage => "",
        },
        "addBuild" => {
                func  => \&addBuild,
                help  => "Add a build to the datastore",
                usage =>
                    "-n <build name> -j <jail name> -p <portstree name> [-d <build description>]",
                optstr => 'n:j:p:d:',
        },
        "addJail" => {
                func  => \&addJail,
                help  => "Add a jail to the datastore",
                usage =>
                    "-n <jail name> -t <jail tag> [-d <jail description>] [-u <jail update command|CVSUP|NONE>]",
                optstr => 'n:t:u:d:',
        },
        "addPortsTree" => {
                func  => \&addPortsTree,
                help  => "Add a portstree to the datastore",
                usage =>
                    "-n <portstree name> [-d <portstree description>] [-u <portstree update command|NONE|CVSUP>] [-w <CVSweb URL>]",
                optstr => 'n:u:d:w:',
        },
        "addPort" => {
                func => \&addPort,
                help =>
                    "Add a port, and optionally, its dependencies, to the datastore",
                usage  => "{-b <build name> | -a} -d <port directory> [-r]",
                optstr => 'ab:d:r',
        },
        "getJailForBuild" => {
                func   => \&getJailForBuild,
                help   => "Get the jail name associated with a given build",
                usage  => "-b <build name>",
                optstr => 'b:',
        },
        "getPortsTreeForBuild" => {
                func  => \&getPortsTreeForBuild,
                help  => "Get the portstree name assoicated with a given build",
                usage => "-b <build name>",
                optstr => 'b:',
        },
        "getTagForJail" => {
                func   => \&getTagForJail,
                help   => "Get the tag for a given jail",
                usage  => "-j <jail name>",
                optstr => 'j:',
        },
        "getSrcUpdateCmd" => {
                func   => \&getSrcUpdateCmd,
                help   => "Get the update command for the given jail",
                usage  => "-j <jail name>",
                optstr => 'j:',
        },
        "getPortsUpdateCmd" => {
                func   => \&getPortsUpdateCmd,
                help   => "Get the update command for the given portstree",
                usage  => "-p <portstree name>",
                optstr => 'p:',
        },
        "rmPort" => {
                func => \&rmPort,
                help =>
                    "Remove a port from the datastore, and optionally its package and logs from the file system",
                usage  => "-d <port directory> [-b <build name>] [-f] [-c]",
                optstr => 'fb:d:c',
        },
        "rmBuild" => {
                func   => \&rmBuild,
                help   => "Remove a build from the datastore",
                usage  => "-b <build name> [-f]",
                optstr => 'b:f',
        },
        "rmPortsTree" => {
                func   => \&rmPortsTree,
                help   => "Remove a portstree from the datastore",
                usage  => "-p <portstree name> [-f]",
                optstr => 'p:f',
        },
        "rmJail" => {
                func   => \&rmJail,
                help   => "Remove a jail from the datastore",
                usage  => "-j <jail name> [-f]",
                optstr => 'j:f',
        },
        "updatePortsTree" => {
                func => \&updatePortsTree,
                help =>
                    "Run the configured update command on the specified portstree",
                usage  => "-p <portstree name> [-l <last built timestamp>]",
                optstr => 'p:l:',
        },
        "updateJailLastBuilt" => {
                func   => \&updateJailLastBuilt,
                help   => "Update the specified jail's last built time",
                usage  => "-j <jail name> [-l <last built timestamp>]",
                optstr => 'j:l:',
        },
        "updatePortLastBuilt" => {
                func => \&updatePortLastBuilt,
                help =>
                    "Update the specified port's last built time for the specified build",
                usage =>
                    "-d <port directory> -b <build name> [-l <last built timestamp>]",
                optstr => 'd:b:l:',
        },
        "updatePortLastSuccessfulBuilt" => {
                func => \&updatePortLastSuccessfulBuilt,
                help =>
                    "Update the specified port's last successful built time for the specified build",
                usage =>
                    "-d <port directory> -b <build name> [-l <last built timestamp>]",
                optstr => 'd:b:l:',
        },
        "updatePortLastStatus" => {
                func => \&updatePortLastStatus,
                help =>
                    "Update the specified port's last build status for the specified build",
                usage =>
                    "-d <port directory> -b <build name> -s <UNKNOWN|SUCCESS|FAIL>",
                optstr => 'd:b:s:',
        },
        "updatePortLastBuiltVersion" => {
                func => \&updatePortLastBuiltVersion,
                help =>
                    "Update the specified port's last built version for the specified build",
                usage =>
                    "-d <port directory> -b <build name> -v <last built version>",
                optstr => 'd:b:v:',
        },
        "updateBuildStatus" => {
                func   => \&updateBuildStatus,
                help   => "Update the current status for the specific build",
                usage  => "-b <build name> -s <IDLE|PORTBUILD>",
                optstr => 'b:s:',
        },
        "getPortLastBuiltVersion" => {
                func => \&getPortLastBuiltVersion,
                help =>
                    "Get the last built version for the specified port and build",
                usage  => "-d <port directory> -b <build name>",
                optstr => 'd:b:',
        },
        "updateBuildCurrentPort" => {
                func => \&updateBuildCurrentPort,
                help =>
                    "Update the port currently being built for the specify build",
                usage  => "-b <build name> [-n <package name>]",
                optstr => 'b:n:',
        },
        "sendBuildCompletionMail" => {
                func => \&sendBuildCompletionMail,
                help =>
                    "Send email to the build interest list when a build completes",
                usage  => "-b <build name>",
                optstr => 'b:',
        },
        "addBuildUser" => {
                func   => \&addBuildUser,
                help   => "Add a user to a given build's interest list",
                usage  => "{-b <build name> | -a} -u <user name> [-c] [-e]",
                optstr => 'ab:ceu:',
                ,
        },
        "addUser" => {
                func   => \&addUser,
                help   => "Add a user to the datastore",
                usage  => "-n <user name> [-e <user email>]",
                optstr => 'n:e:',
        },
        "updateBuildUser" => {
                func => \&updateBuildUser,
                help =>
                    "Update email preferences for the given user for the given build",
                usage  => "{-b <build name> | -a} -u <user name> [-c] [-e]",
                optstr => 'ab:u:ce',
        },
        "rmUser" => {
                func   => \&rmUser,
                help   => "Remove a user from the datastore",
                usage  => "[-b <build name>] -u <user name> [-f]",
                optstr => 'fb:u:',
        },
        "sendBuildErrorMail" => {
                func => \&sendBuildErrorMail,
                help =>
                    "Send email to the build interest list when a port fails to build",
                usage =>
                    "-b <build name> -d <port directory> [-p <package name>]",
                optstr => 'b:d:p:',
        },
        "listUsers" => {
                func  => \&listUsers,
                help  => "List all users in the datastore",
                usage => "",
        },
        "listBuildUsers" => {
                func   => \&listBuildUsers,
                help   => "List all users in the interest list for a build",
                usage  => "-b <build name>",
                optstr => 'b:',
        },
        "tbcleanup" => {
                func => \&tbcleanup,
                help =>
                    "Cleanup old build logs, and prune old database entries for which no package exists",
                usage => "",
        },
);

if (!scalar(@ARGV)) {
        usage();
}

my $ds = new TinderboxDS();

my $command = $ARGV[0];
shift;

my $opts = {};

if (defined($COMMANDS{$command})) {
        if ($COMMANDS{$command}->{'optstr'}) {
                getopts($COMMANDS{$command}->{'optstr'}, $opts)
                    or usage($command);
        }
        &{$COMMANDS{$command}->{'func'}}();
} else {
        usage();
}

cleanup($ds, 0, undef);

sub init {
        system("mkdir -p $JAILS_DIR");
        system("mkdir -p $BUILDS_DIR");
        system("mkdir -p $PORTSTREES_DIR");
        system("mkdir -p $ERROR_DIR");
        system("mkdir -p $LOG_DIR");
        system("mkdir -p $PKGS_DIR");
        system("mkdir -p $WRKDIRS_DIR");
}

sub listJails {
        my @jails = $ds->getAllJails();

        if (@jails) {
                map { print $_->getName() . "\n" } @jails;
        } elsif (defined($ds->getError())) {
                cleanup($ds, 1,
                        "Failed to list jails: " . $ds->getError() . "\n");
        } else {
                cleanup($ds, 1,
                        "There are no jails configured in the datastore.\n");
        }
}

sub listBuilds {
        my @builds = $ds->getAllBuilds();

        if (@builds) {
                map { print $_->getName() . "\n" } @builds;
        } elsif (defined($ds->getError())) {
                cleanup($ds, 1,
                        "Failed to list builds: " . $ds->getError() . "\n");
        } else {
                cleanup($ds, 1,
                        "There are no builds configured in the datastore.\n");
        }
}

sub listPortsTrees {
        my @portstrees = $ds->getAllPortsTrees();

        if (@portstrees) {
                map { print $_->getName() . "\n" } @portstrees;
        } elsif (defined($ds->getError())) {
                cleanup($ds, 1,
                        "Failed to list portstrees: " . $ds->getError() . "\n");
        } else {
                cleanup($ds, 1,
                        "There are no portstrees configured in the datastore.\n"
                );
        }
}

sub addBuild {
        if (!$opts->{'n'} || !$opts->{'j'} || !$opts->{'p'}) {
                usage("addBuild");
        }

        my $name      = $opts->{'n'};
        my $jail      = $opts->{'j'};
        my $portstree = $opts->{'p'};

        if ($ds->isValidBuild($name)) {
                cleanup($ds, 1,
                        "A build named $name is already in the datastore.\n");
        }

        if (!$ds->isValidJail($jail)) {
                cleanup($ds, 1, "No such jail, \"$jail\", in the datastore.\n");
        }

        if (!$ds->isValidPortsTree($portstree)) {
                cleanup($ds, 1,
                        "No such portstree, \"$portstree\", in the datastore.\n"
                );
        }

        my $jCls = $ds->getJailByName($jail);
        my $pCls = $ds->getPortsTreeByName($portstree);

        my $build = new Build();
        $build->setName($name);
        $build->setJailId($jCls->getId());
        $build->setPortsTreeId($pCls->getId());
        $build->setDescription($opts->{'d'}) if ($opts->{'d'});

        my $rc = $ds->addBuild($build);

        if (!$rc) {
                cleanup($ds, 1,
                              "Failed to add build $name to the datastore: "
                            . $ds->getError()
                            . ".\n");
        }
}

sub addJail {
        if (!$opts->{'n'} || !$opts->{'t'}) {
                usage("addJail");
        }

        my $name = $opts->{'n'};
        my $tag  = $opts->{'t'};

        if ($ds->isValidJail($name)) {
                cleanup($ds, 1,
                        "A jail named $name is already in the datastore.\n");
        }

        if ($name !~ /^\d/) {
                cleanup($ds, 1,
                        "The first character in a jail name must be a FreeBSD major version number.\n"
                );
        }

        my $update_cmd = "CVSUP";
        if ($opts->{'u'}) {
                $update_cmd = $opts->{'u'};
        }

        my $jail = new Jail();

        $jail->setName($name);
        $jail->setTag($tag);
        $jail->setUpdateCmd($update_cmd);
        $jail->setDescription($opts->{'d'}) if ($opts->{'d'});

        my $rc = $ds->addJail($jail);

        if (!$rc) {
                cleanup($ds, 1,
                              "Failed to add jail $name to the datastore: "
                            . $ds->getError()
                            . ".\n");
        }
}

sub addPortsTree {
        if (!$opts->{'n'}) {
                usage("addPortsTree");
        }

        my $name = $opts->{'n'};

        if ($ds->isValidPortsTree($name)) {
                cleanup($ds, 1,
                        "A portstree named $name is already in the datastore.\n"
                );
        }

        my $update_cmd = "CVSUP";
        if ($opts->{'u'}) {
                $update_cmd = $opts->{'u'};
        }

        my $portstree = new PortsTree();

        $portstree->setName($name);
        $portstree->setUpdateCmd($update_cmd);
        $portstree->setDescription($opts->{'d'}) if ($opts->{'d'});
        $portstree->setCVSwebURL($opts->{'w'})   if ($opts->{'w'});
        $portstree->setLastBuilt($ds->getTime());

        my $rc = $ds->addPortsTree($portstree);

        if (!$rc) {
                cleanup($ds, 1,
                              "Failed to add portstree $name to the datastore: "
                            . $ds->getError()
                            . ".\n");
        }
}

sub addPort {
        if (       (!$opts->{'b'} && !$opts->{'a'})
                || ($opts->{'b'} && $opts->{'a'})
                || !$opts->{'d'})
        {
                usage("addPort");
        }

        my $buildname = $opts->{'b'};
        if ($buildname && !$ds->isValidBuild($buildname)) {
                cleanup($ds, 1, "Unknown build, $buildname\n");
        }

        my @builds = ();
        if ($opts->{'a'}) {
                @builds = $ds->getAllBuilds();
        } else {
                push @builds, $ds->getBuildByName($buildname);
        }

        foreach my $build (@builds) {
                my $jail      = $ds->getJailById($build->getJailId());
                my $portstree = $ds->getPortsTreeById($build->getPortsTreeId());
                my $tag       = $jail->getTag();

                if (!$tag) {
                        $tag = $jail->getName();
                }

                buildenv(
                        $BUILD_ROOT,      $build->getName(),
                        $jail->getName(), $portstree->getName()
                );
                $ENV{'LOCALBASE'}  = "/nonexistentlocal";
                $ENV{'X11BASE'}    = "/nonexistentx";
                $ENV{'PKG_DBDIR'}  = "/nonexistentdb";
                $ENV{'PORT_DBDIR'} = "/nonexistentportdb";
                $ENV{'LINUXBASE'}  = "/nonexistentlinux";

                if ($opts->{'r'}) {
                        my @deps = ($opts->{'d'});
                        my %seen = ();
                        while (my $port = shift @deps) {
                                if (!$seen{$port}) {
                                        addPorts($port, $build, \@deps);
                                        $seen{$port} = 1;
                                }
                        }
                } else {
                        addPorts($opts->{'d'}, $build, undef);
                }
        }
}

sub getJailForBuild {
        if (!$opts->{'b'}) {
                usage("getJailForBuild");
        }

        if (!$ds->isValidBuild($opts->{'b'})) {
                cleanup($ds, 1, "Unknown build, " . $opts->{'b'} . "\n");
        }

        my $build = $ds->getBuildByName($opts->{'b'});
        my $jail  = $ds->getJailById($build->getJailId());

        print $jail->getName() . "\n";
}

sub getPortsTreeForBuild {
        if (!$opts->{'b'}) {
                usage("getPortsTreeForBuild");
        }

        if (!$ds->isValidBuild($opts->{'b'})) {
                cleanup($ds, 1, "Unknown build, " . $opts->{'b'} . "\n");
        }

        my $build     = $ds->getBuildByName($opts->{'b'});
        my $portstree = $ds->getPortsTreeById($build->getPortsTreeId());

        print $portstree->getName() . "\n";
}

sub getTagForJail {
        if (!$opts->{'j'}) {
                usage("getTagForJail");
        }

        if (!$ds->isValidJail($opts->{'j'})) {
                cleanup($ds, 1, "Unknown jail, " . $opts->{'j'} . "\n");
        }

        my $jail = $ds->getJailByName($opts->{'j'});

        print $jail->getTag() . "\n";
}

sub getSrcUpdateCmd {
        if (!$opts->{'j'}) {
                usage("getSrcUpdateCmd");
        }

        my $jail_name = $opts->{'j'};

        if (!$ds->isValidJail($jail_name)) {
                cleanup($ds, 1, "Unknown jail, $jail_name\n");
        }

        my $jail = $ds->getJailByName($jail_name);

        my $update_cmd = $jail->getUpdateCmd();

        if ($update_cmd eq "CVSUP") {
                $update_cmd =
                    "/usr/local/bin/cvsup -g $BUILD_ROOT/jails/$jail_name/src-supfile";
        } elsif ($update_cmd eq "NONE") {
                $update_cmd = "";
        } else {
                $update_cmd = "$BUILD_ROOT/scripts/$update_cmd $jail_name";
        }

        print $update_cmd . "\n";
}

sub getPortsUpdateCmd {
        if (!$opts->{'p'}) {
                usage("getPortsUpdateCmd");
        }

        my $portstree_name = $opts->{'p'};

        if (!$ds->isValidPortsTree($portstree_name)) {
                cleanup($ds, 1, "Unknown portstree, $portstree_name\n");
        }

        my $portstree = $ds->getPortsTreeByName($portstree_name);

        my $update_cmd = $portstree->getUpdateCmd();

        if ($update_cmd eq "CVSUP") {
                $update_cmd =
                    "/usr/local/bin/cvsup -g $BUILD_ROOT/portstrees/$portstree_name/ports-supfile";
        } elsif ($update_cmd eq "NONE") {
                $update_cmd = "";
        } else {
                $update_cmd = "$BUILD_ROOT/scripts/$update_cmd $portstree_name";
        }

        print $update_cmd . "\n";
}

sub rmPort {
        if (!$opts->{'d'}) {
                usage("rmPort");
        }

        if ($opts->{'b'}) {
                if (!$ds->isValidBuild($opts->{'b'})) {
                        cleanup($ds, 1,
                                "Unknown build, " . $opts->{'b'} . "\n");
                }
        }

        my $port = $ds->getPortByDirectory($opts->{'d'});

        if (!defined($port)) {
                cleanup($ds, 1, "Unknown port, " . $opts->{'d'} . "\n");
        }

        unless ($opts->{'f'}) {
                if ($opts->{'b'}) {
                        print "Really remove port "
                            . $opts->{'d'}
                            . " for build "
                            . $opts->{'b'} . "? ";
                } else {
                        print "Really remove port " . $opts->{'d'} . "? ";
                }
                my $response = <STDIN>;
                print "\n";
                cleanup($ds, 0, undef) unless ($response =~ /^y/i);
        }

        my @builds = ();
        my $rc;
        if ($opts->{'c'} && !$opts->{'b'}) {
                @builds = $ds->getAllBuilds();
        } elsif ($opts->{'c'} && $opts->{'b'}) {
                push @builds, $ds->getBuildByName($opts->{'b'});
        }
        foreach my $build (@builds) {
                if (my $version = $ds->getPortLastBuiltVersion($port, $build)) {
                        my $jail    = $ds->getJailById($build->getJailId());
                        my $sufx    = $ds->getPackageSuffix($jail);
                        my $pkgdir  = join("/", $PKGS_DIR, $build->getName());
                        my $logpath =
                            join("/", $LOG_DIR, $build->getName(), $version);
                        my $errpath =
                            join("/", $ERROR_DIR, $build->getName(), $version);
                        if (-d $pkgdir) {
                                print
                                    "Removing all packages matching ${version}${sufx} starting from $pkgdir.\n";
                                system(
                                        "/usr/bin/find -H $pkgdir -name ${version}${sufx} -delete"
                                );
                        }
                        if (-f $logpath . ".log") {
                                print "Removing ${logpath}.log.\n";
                                unlink($logpath . ".log");
                        }
                        if (-f $errpath . ".log") {
                                print "Removing ${errpath}.log.\n";
                                unlink($errpath . ".log");
                        }
                }
        }

        if ($opts->{'b'}) {
                $rc =
                    $ds->removePortForBuild($port,
                        $ds->getBuildByName($opts->{'b'}));
        } else {
                $rc = $ds->removePort($port);
        }

        if (!$rc) {
                cleanup($ds, 1,
                        "Failed to remove port: " . $ds->getError() . "\n");
        }
}

sub rmBuild {
        if (!$opts->{'b'}) {
                usage("rmBuild");
        }

        if (!$ds->isValidBuild($opts->{'b'})) {
                cleanup($ds, 1, "Unknown build " . $opts->{'b'} . "\n");
        }

        unless ($opts->{'f'}) {
                print "Really remove build " . $opts->{'b'} . "? ";
                my $response = <STDIN>;
                cleanup($ds, 0, undef) unless ($response =~ /^y/i);
        }

        my $rc = $ds->removeBuild($ds->getBuildByName($opts->{'b'}));

        if (!$rc) {
                cleanup($ds, 1,
                              "Failed to remove build "
                            . $opts->{'b'} . ": "
                            . $ds->getError()
                            . "\n");
        }
}

sub rmJail {
        if (!$opts->{'j'}) {
                usage("rmJail");
        }

        if (!$ds->isValidJail($opts->{'j'})) {
                cleanup($ds, 1, "Unknown jail " . $opts->{'j'} . "\n");
        }

        my $jail   = $ds->getJailByName($opts->{'j'});
        my @builds = $ds->findBuildsForJail($jail);

        unless ($opts->{'f'}) {
                if (@builds) {
                        print
                            "Removing this jail will also remove the following builds:\n";
                        foreach my $build (@builds) {
                                print "\t" . $build->getName() . "\n";
                        }
                }
                print "Really remove jail " . $opts->{'j'} . "? ";
                my $response = <STDIN>;
                cleanup($ds, 0, undef) unless ($response =~ /^y/i);
        }

        my $rc;
        foreach my $build (@builds) {
                $rc = $ds->removeBuild($build);
                if (!$rc) {
                        cleanup($ds, 1,
                                "Failed to remove build $build as part of removing jail "
                                    . $opts->{'j'} . ": "
                                    . $ds->getError()
                                    . "\n");
                }
        }

        $rc = $ds->removeJail($jail);

        if (!$rc) {
                cleanup($ds, 1,
                              "Failed to remove jail "
                            . $opts->{'j'} . ": "
                            . $ds->getError()
                            . "\n");
        }
}

sub rmPortsTree {
        if (!$opts->{'p'}) {
                usage("rmPortsTree");
        }

        if (!$ds->isValidPortsTree($opts->{'p'})) {
                cleanup($ds, 1, "Unknown portstree " . $opts->{'p'} . "\n");
        }

        my $portstree = $ds->getPortsTreeByName($opts->{'p'});
        my @builds    = $ds->findBuildsForPortsTree($portstree);

        unless ($opts->{'f'}) {
                if (@builds) {
                        print
                            "Removing this portstree will also remove the following builds:\n";
                        foreach my $build (@builds) {
                                print "\t" . $build->getName() . "\n";
                        }
                }
                print "Really remove portstree " . $opts->{'p'} . "? ";
                my $response = <STDIN>;
                cleanup($ds, 0, undef) unless ($response =~ /^y/i);
        }

        my $rc;
        foreach my $build (@builds) {
                $rc = $ds->removeBuild($build);
                if (!$rc) {
                        cleanup($ds, 1,
                                "Failed to remove build $build as part of removing portstree "
                                    . $opts->{'p'} . ": "
                                    . $ds->getError()
                                    . "\n");
                }
        }

        $rc = $ds->removePortsTree($portstree);

        if (!$rc) {
                cleanup($ds, 1,
                              "Failed to remove portstree "
                            . $opts->{'p'} . ": "
                            . $ds->getError()
                            . "\n");
        }
}

sub rmUser {
        if (!$opts->{'u'}) {
                usage("rmUser");
        }

        if ($opts->{'b'}) {
                if (!$ds->isValidBuild($opts->{'b'})) {
                        cleanup($ds, 1,
                                "Unknown build, " . $opts->{'b'} . "\n");
                }
        }

        my $user = $ds->getUserByName($opts->{'u'});

        if (!defined($user)) {
                cleanup($ds, 1, "Unknown user, " . $opts->{'u'} . "\n");
        }

        unless ($opts->{'f'}) {
                if ($opts->{'b'}) {
                        print "Really remove user "
                            . $opts->{'u'}
                            . " for build "
                            . $opts->{'b'} . "? ";
                } else {
                        print "Really remove user " . $opts->{'u'} . "? ";
                }
                my $response = <STDIN>;
                print "\n";
                cleanup($ds, 0, undef) unless ($response =~ /^y/i);
        }

        my $rc;
        if ($opts->{'b'}) {
                $rc =
                    $ds->removeUserForBuild($user,
                        $ds->getBuildByName($opts->{'b'}));
        } else {
                $rc = $ds->removeUser($user);
        }

        if (!$rc) {
                cleanup($ds, 1,
                        "Failed to remove user: " . $ds->getError() . "\n");
        }
}

sub updatePortsTree {
        if (!$opts->{'p'}) {
                usage("updatePortsTree");
        }

        my $name = $opts->{'p'};

        if (!$ds->isValidPortsTree($name)) {
                cleanup($ds, 1, "Unknown portstree $name\n");
        }

        my $portstree  = $ds->getPortsTreeByName($name);
        my $update_cmd = $portstree->getUpdateCmd();

        $portstree->setLastBuilt($opts->{'l'});

        if ($update_cmd eq "CVSUP") {
                if (!-x "/usr/local/bin/cvsup") {
                        cleanup($ds, 1,
                                "Failed to find executable cvsup in /usr/local/bin.\n"
                        );
                }
                $update_cmd =
                    "/usr/local/bin/cvsup -g $BUILD_ROOT/portstrees/$name/ports-supfile";
        } elsif ($update_cmd eq "NONE") {
                $update_cmd = "";
        } else {
                $update_cmd .= " $name";
        }

        my $rc = 0;    # Allow null update commands to succeed.
        if ($update_cmd) {
                $rc = system($update_cmd);
        }

        if (!$rc) {

                # The command completed successfully, so update the
                # Last_Built time.
                $ds->updatePortsTreeLastBuilt($portstree)
                    or cleanup($ds, 1,
                        "Failed to update last built value in the datastore: "
                            . $ds->getError()
                            . "\n");
        } else {
                cleanup($ds, 1,
                        "Failed to update the portstree.  See output above.\n");
        }
}

sub updateJailLastBuilt {
        if (!$opts->{'j'}) {
                usage("updateJailLastBuilt");
        }

        if (!$ds->isValidJail($opts->{'j'})) {
                cleanup($ds, 1, "Unknown jail, " . $opts->{'j'} . "\n");
        }

        my $jail = $ds->getJailByName($opts->{'j'});

        $jail->setLastBuilt($opts->{'l'});

        $ds->updateJailLastBuilt($jail)
            or cleanup($ds, 1,
                      "Failed to update last built value in the datastore: "
                    . $ds->getError()
                    . "\n");
}

sub updatePortLastBuilt {
        if (!$opts->{'d'} || !$opts->{'b'}) {
                usage("updatePortLastBuilt");
        }

        my $port = $ds->getPortByDirectory($opts->{'d'});
        if (!defined($port)) {
                cleanup($ds, 1,
                              "Port, "
                            . $opts->{'d'}
                            . " is not in the datastore.\n");
        }

        if (!$ds->isValidBuild($opts->{'b'})) {
                cleanup($ds, 1, "Unknown build, " . $opts->{'b'} . "\n");
        }

        my $build = $ds->getBuildByName($opts->{'b'});

        if (!$ds->isPortForBuild($port, $build)) {
                cleanup($ds, 1,
                              "Port, "
                            . $opts->{'d'}
                            . " is not a valid port for build, "
                            . $opts->{'b'}
                            . "\n");
        }

        $ds->updatePortLastBuilt($port, $build, $opts->{'l'})
            or cleanup($ds, 1,
                      "Failed to update last built value in the datastore: "
                    . $ds->getError()
                    . "\n");
}

sub updatePortLastSuccessfulBuilt {
        if (!$opts->{'d'} || !$opts->{'b'}) {
                usage("updatePortLastSuccessfulBuilt");
        }

        my $port = $ds->getPortByDirectory($opts->{'d'});
        if (!defined($port)) {
                cleanup($ds, 1,
                              "Port, "
                            . $opts->{'d'}
                            . " is not in the datastore.\n");
        }

        if (!$ds->isValidBuild($opts->{'b'})) {
                cleanup($ds, 1, "Unknown build, " . $opts->{'b'} . "\n");
        }

        my $build = $ds->getBuildByName($opts->{'b'});

        if (!$ds->isPortForBuild($port, $build)) {
                cleanup($ds, 1,
                              "Port, "
                            . $opts->{'d'}
                            . " is not a valid port for build, "
                            . $opts->{'b'}
                            . "\n");
        }

        $ds->updatePortLastSuccessfulBuilt($port, $build, $opts->{'l'})
            or cleanup(
                $ds,
                1,
                "Failed to update last successful built value in the datastore: "
                    . $ds->getError() . "\n"
            );
}

sub updatePortLastStatus {
        if (!$opts->{'d'} || !$opts->{'b'} || !$opts->{'s'}) {
                usage("updatePortLastStatus");
        }

        my $port = $ds->getPortByDirectory($opts->{'d'});
        if (!defined($port)) {
                cleanup($ds, 1,
                              "Port, "
                            . $opts->{'d'}
                            . " is not in the datastore.\n");
        }

        if (!$ds->isValidBuild($opts->{'b'})) {
                cleanup($ds, 1, "Unknown build, " . $opts->{'b'} . "\n");
        }

        my $build = $ds->getBuildByName($opts->{'b'});

        if (!$ds->isPortForBuild($port, $build)) {
                cleanup($ds, 1,
                              "Port, "
                            . $opts->{'d'}
                            . " is not a valid port for build, "
                            . $opts->{'b'}
                            . "\n");
        }

        $ds->updatePortLastStatus($port, $build, $opts->{'s'})
            or cleanup(
                $ds,
                1,
                "Failed to update last status value in the datastore: "
                    . $ds->getError() . "\n"
            );
}

sub updatePortLastBuiltVersion {
        if (!$opts->{'d'} || !$opts->{'b'} || !$opts->{'v'}) {
                usage("updatePortLastBuiltVersion");
        }

        my $port = $ds->getPortByDirectory($opts->{'d'});
        if (!defined($port)) {
                cleanup($ds, 1,
                              "Port, "
                            . $opts->{'d'}
                            . " is not in the datastore.\n");
        }

        if (!$ds->isValidBuild($opts->{'b'})) {
                cleanup($ds, 1, "Unknown build, " . $opts->{'b'} . "\n");
        }

        my $build = $ds->getBuildByName($opts->{'b'});

        if (!$ds->isPortForBuild($port, $build)) {
                cleanup($ds, 1,
                              "Port, "
                            . $opts->{'d'}
                            . " is not a valid port for build, "
                            . $opts->{'b'}
                            . "\n");
        }

        $ds->updatePortLastBuiltVersion($port, $build, $opts->{'v'})
            or cleanup(
                $ds,
                1,
                "Failed to update last built version value in the datastore: "
                    . $ds->getError() . "\n"
            );
}

sub updateBuildStatus {
        my %status_hash = (
                IDLE      => 0,
                PREPARE   => 1,
                PORTBUILD => 2,
        );

        if (!$opts->{'b'}) {
                usage("updateBuildStatus");
        }

        if (!$ds->isValidBuild($opts->{'b'})) {
                cleanup($ds, 1, "Unknown build, " . $opts->{'b'} . "\n");
        }

        my $build = $ds->getBuildByName($opts->{'b'});

        my $build_status;
        if (!defined($status_hash{$opts->{'s'}})) {
                $build_status = "IDLE";
        } else {
                $build_status = $opts->{'s'};
        }
        $build->setStatus($build_status);

        $ds->updateBuildStatus($build)
            or cleanup($ds, 1,
                "Failed to update last build status value in the datastore: "
                    . $ds->getError()
                    . "\n");
}

sub getPortLastBuiltVersion {
        if (!$opts->{'d'} || !$opts->{'b'}) {
                usage("getPortLastBuiltVersion");
        }

        my $port = $ds->getPortByDirectory($opts->{'d'});
        if (!defined($port)) {
                cleanup($ds, 1,
                              "Port, "
                            . $opts->{'d'}
                            . " is not in the datastore.\n");
        }

        if (!$ds->isValidBuild($opts->{'b'})) {
                cleanup($ds, 1, "Unknown build, " . $opts->{'b'} . "\n");
        }

        my $build = $ds->getBuildByName($opts->{'b'});

        if (!$ds->isPortForBuild($port, $build)) {
                cleanup($ds, 1,
                              "Port, "
                            . $opts->{'d'}
                            . " is not a valid port for build, "
                            . $opts->{'b'}
                            . "\n");
        }

        my $version = $ds->getPortLastBuiltVersion($port, $build);
        if (!defined($version) && $ds->getError()) {
                cleanup($ds, 1,
                              "Failed to get last update version for port "
                            . $opts->{'d'}
                            . " for build "
                            . $opts->{'b'} . ": "
                            . $ds->getError()
                            . "\n");
        }

        print $version . "\n";
}

sub updateBuildCurrentPort {
        if (!$opts->{'b'}) {
                usage("updateBuildCurrentPort");
        }

        if (!$ds->isValidBuild($opts->{'b'})) {
                cleanup($ds, 1, "Unknown build, " . $opts->{'b'} . "\n");
        }

        my $build = $ds->getBuildByName($opts->{'b'});

        $ds->updateBuildCurrentPort($build, $opts->{'n'})
            or cleanup($ds, 1,
                      "Failed to get last update build current port for build "
                    . $opts->{'b'} . ": "
                    . $ds->getError()
                    . "\n");
}

sub sendBuildErrorMail {
        if (!$opts->{'b'} || !$opts->{'d'}) {
                usage("sendBuildErrorMail");
        }

        my $buildname = $opts->{'b'};
        my $portdir   = $opts->{'d'};

        if (!$ds->isValidBuild($buildname)) {
                cleanup($ds, 1, "Unknown build, $buildname\n");
        }

        my $build = $ds->getBuildByName($buildname);
        my $port  = $ds->getPortByDirectory($portdir);

        my $version = $opts->{'p'};
        if (!$version) {
                $version = $ds->getPortLastBuiltVersion($port, $build);
        }

        my $subject = $SUBJECT . " Port $portdir failed for build $buildname";
        my $now     = scalar localtime;
        my $data    = <<EOD;
Port $portdir failed for build $buildname on $now.  The error log can be
found at:

${SERVER_PROTOCOL}://${SERVER_HOST}${LOG_URI}/$buildname/${version}.log

EOD
        if (defined($port)) {
                my $portid = $port->getId();
                $data .= <<EOD;
More details can be found at:

${SERVER_PROTOCOL}://${SERVER_HOST}${SHOWPORT_URI}?id=$portid

EOD
        }

        $data .= <<EOD;
Please do not reply to this email.
EOD

        my @users = $ds->getBuildCompletionUsers($build);

        if (scalar(@users)) {

                my @addrs = ();
                foreach my $user (@users) {
                        push @addrs, $user->getEmail();
                }

                my $rc =
                    sendMail($SENDER, \@addrs, $subject, $data, $SMTP_HOST);

                if (!$rc) {
                        cleanup($ds, 1, "Failed to send email.");
                }
        }
}

sub sendBuildCompletionMail {
        if (!$opts->{'b'}) {
                usage("sendBuildCompletionMail");
        }

        my $buildname = $opts->{'b'};

        if (!$ds->isValidBuild($buildname)) {
                cleanup($ds, 1, "Unknown build, $buildname\n");
        }

        my $build = $ds->getBuildByName($buildname);

        my $subject = $SUBJECT . " Build $buildname completed";
        my $now     = scalar localtime;
        my $data    = <<EOD;
Build $buildname completed on $now.  Details can be found at:

${SERVER_PROTOCOL}://${SERVER_HOST}${SHOWBUILD_URI}?name=$buildname

Please do not reply to this email.
EOD
        my @users = $ds->getBuildCompletionUsers($build);

        if (scalar(@users)) {

                my @addrs = ();
                foreach my $user (@users) {
                        push @addrs, $user->getEmail();
                }

                my $rc =
                    sendMail($SENDER, \@addrs, $subject, $data, $SMTP_HOST);

                if (!$rc) {
                        cleanup($ds, 1, "Failed to send email.");
                }
        }
}

sub addUser {
        if (!$opts->{'n'}) {
                usage("addUser");
        }

        my $user = new User();

        $user->setName($opts->{'n'});
        $user->setEmail($opts->{'e'}) if ($opts->{'e'});

        my $rc = $ds->addUser($user);

        if (!$rc) {
                cleanup($ds, 1,
                              "Failed to add user to the datastore: "
                            . $ds->getError()
                            . "\n");
        }
}

sub addBuildUser {
        return _updateBuildUser($opts, "addBuildUser");
}

sub updateBuildUser {
        return _updateBuildUser($opts, "updateBuildUser");
}

sub listUsers {
        my @users = $ds->getAllUsers();

        if (@users) {
                map { print $_->getName() . "\n" } @users;
        } elsif (defined($ds->getError())) {
                cleanup($ds, 1,
                        "Failed to list users: " . $ds->getError() . "\n");
        } else {
                cleanup($ds, 1,
                        "There are no users configured in the datastore.\n");
        }
}

sub listBuildUsers {
        if (!$opts->{'b'}) {
                usage("listBuildUsers");
        }

        if (!$ds->isValidBuild($opts->{'b'})) {
                cleanup($ds, 1, "Unknown build, " . $opts->{'b'} . "\n");
        }

        my $build = $ds->getBuildByName($opts->{'b'});
        my @users = $ds->getUsersForBuild($build);

        if (@users) {
                map { print $_->getName() . "\n" } @users;
        } elsif (defined($ds->getError())) {
                cleanup($ds, 1,
                        "Failed to list users: " . $ds->getError() . "\n");
        } else {
                cleanup($ds, 1,
                        "There are no users configured for this build.\n");
        }
}

sub _updateBuildUser {
        my $opts     = shift;
        my $function = shift;

        if (       (!$opts->{'b'} && !$opts->{'a'})
                || ($opts->{'b'} && $opts->{'a'})
                || !$opts->{'u'})
        {
                usage($function);
        }

        my $buildname = $opts->{'b'};
        if ($buildname && !$ds->isValidBuild($buildname)) {
                cleanup($ds, 1, "Unknown build, $buildname\n");
        }

        my $username = $opts->{'u'};
        if (!$ds->isValidUser($username)) {
                cleanup($ds, 1, "Unknown user, $username\n");
        }

        my $user = $ds->getUserByName($username);

        if (!$user->getEmail()) {
                cleanup($ds, 1,
                        "User, $username, does not have an email address\n");
        }

        my @builds = ();
        if ($opts->{'a'}) {
                @builds = $ds->getAllBuilds();
        } else {
                push @builds, $ds->getBuildByName($buildname);
        }

        foreach my $build (@builds) {
                if ($ds->isUserForBuild($user, $build)) {
                        $ds->updateBuildUser($build, $user, $opts->{'c'},
                                $opts->{'e'});
                } else {
                        $ds->addUserForBuild($user, $build, $opts->{'c'},
                                $opts->{'e'});
                }
        }
}

sub usage {
        my $cmd = shift;

        print STDERR "usage: $0 ";

        if (!defined($cmd)) {
                my $max = 0;
                foreach (keys %COMMANDS) {
                        if ((length $_) > $max) {
                                $max = length $_;
                        }
                }
                print STDERR "<command>\n";
                print STDERR "Where <command> is one of:\n";
                foreach my $key (sort keys %COMMANDS) {
                        printf STDERR "  %-${max}s: %s\n", $key,
                            $COMMANDS{$key}->{'help'};
                }
        } else {
                print STDERR "$cmd " . $COMMANDS{$cmd}->{'usage'} . "\n";
        }

        cleanup($ds, 1, undef);
}

sub addPorts {
        my $port  = shift;
        my $build = shift;
        my $deps  = shift;

        my ($portname, $portmaintainer, $portcomment);

        my $portdir = $ENV{'PORTSDIR'} . "/" . $port;
        next if (!-d $portdir);

        if (defined($deps)) {

                # We need to add all ports on which this port depends
                # recursively.

                my $descr = `cd $portdir && make describe`;
                chomp $descr;
                my @f = split(/\|/, $descr);
                $f[0] =~ s/\-[^\-]+$//;
                $portname       = $f[0];
                $portcomment    = $f[3];
                $portmaintainer = $f[5];
                my @deplist =
                    split(/ /, join(" ", $f[7], $f[8], $f[9], $f[10], $f[11]));

                foreach my $dep (@deplist) {
                        next unless $dep;
                        $dep =~ s|^$ENV{'PORTSDIR'}/||;
                        push @{$deps}, $dep;
                }
        } else {
                ($portname, $portmaintainer, $portcomment) =
                    `cd $portdir && make -V PORTNAME -V MAINTAINER -V COMMENT`;
                chomp $portname;
                chomp $portmaintainer;
                chomp $portcomment;
        }

        my $pCls = new Port();

        $pCls->setDirectory($port);
        $pCls->setName($portname);
        $pCls->setMaintainer($portmaintainer);
        $pCls->setComment($portcomment);

        # Only add the port if it isn't already in the datastore.
        my $rc;
        if (!$ds->isPortInDS($pCls)) {
                $rc = $ds->addPort(\$pCls);
                if (!$rc) {
                        warn "WARN: Failed to add port "
                            . $pCls->getDirectory() . ": "
                            . $ds->getError() . "\n";
                }
        } else {
                $rc = $ds->updatePort(\$pCls);
                if (!$rc) {
                        warn "WARN: Failed to update port "
                            . $pCls->getDirectory() . ": "
                            . $ds->getError() . "\n";
                }
        }

        if (!$ds->isPortInBuild($pCls, $build)) {
                $rc = $ds->addPortForBuild($pCls, $build);
                if (!$rc) {
                        warn "WARN: Failed to add port for build, "
                            . $build->getName() . ": "
                            . $ds->getError() . "\n";
                }
        }
}

sub tbcleanup {
        my @builds = $ds->getAllBuilds();

        foreach my $build (@builds) {
                print $build->getName() . "\n";
                my $jail           = $ds->getJailById($build->getJailId());
                my $package_suffix = $ds->getPackageSuffix($jail);

                # Delete unreferenced log files.
                my $dir = join("/", $LOG_DIR, $build->getName());
                opendir(DIR, $dir) || die "Failed to open $dir: $!\n";

                while (my $file_name = readdir(DIR)) {
                        if ($file_name =~ /\.log$/) {
                                my $result =
                                    $ds->isLogCurrent($build, $file_name);
                                if (!$result) {
                                        print
                                            "Deleting stale log $dir/$file_name\n";
                                        unlink "$dir/$file_name";
                                }
                        }
                }

                closedir(DIR);

                # Delete database records for nonexistent packages.
                my @ports = $ds->getPortsForBuild($build);
                foreach my $port (@ports) {
                        if ($ds->getPortLastBuiltVersion($port, $build)) {
                                my $path = join(
                                        "/",
                                        $PKGS_DIR,
                                        $build->getName(),
                                        "All",
                                        $ds->getPortLastBuiltVersion($port,
                                                $build)
                                            . $package_suffix
                                );
                                if (!-e $path) {
                                        print
                                            "Removing database entry for nonexistent package "
                                            . $build->getName() . "/"
                                            . $ds->getPortLastBuiltVersion(
                                                $port, $build)
                                            . "\n";
                                        $ds->removePortForBuild($port, $build);
                                }
                        }
                }
        }
}
