#!/bin/sh
#
# $FreeBSD$
#   $MCom: portstools/tinderbox/etc/rc.d/tinderd.sh,v 1.5 2008/09/13 20:43:30 marcus Exp $
#

# PROVIDE: tinderd
# REQUIRE: LOGIN mysql postgresql
# KEYWORD: shutdown

# Add the following line to /etc/rc.conf to enable `tinderd':
#
#tinderd_enable="YES"
#

. "/etc/rc.subr"

name="tinderd"
rcvar=`set_rcvar`

# read settings, set default values
load_rc_config "$name"
: ${tinderd_enable="NO"}
: ${tinderd_directory="/space/scripts"}
: ${tinderd_flags=""}

# path to your executable, might be libexec, bin, sbin, ...
command="${tinderd_directory}/tinderd"

# needed when your daemon is a shell script
command_interpreter="/bin/sh"

# extra required arguments
command_args=">/dev/null &"

run_rc_command "$1"
