#!/bin/sh

# The script is intended to be run from /usr/local/tinderbox/scripts.

[ ! -x ./tc ] && echo "$(basename ${0}): can't find tc" && exit 1

if ! ./tc listBuilds | grep -q ${1}; then
    echo "$(basename ${0}): cannot find a build called ${1}"
    exit 1
fi

PORTS_LIST="
lang/perl5.12
net-mgmt/net-snmp
security/gnupg
security/sudo
textproc/expat2
security/stunnel
sysutils/syslog-ng
sysutils/socket
comms/conserver-com
net/freevrrpd
net/isc-dhcp31-server
devel/gdb66
devel/gdb
textproc/libxml
net-mgmt/tcpreplay
lang/python26
ftp/wget
devel/valgrind
editors/nano
editors/vim-lite
sysutils/flashrom
shells/zsh
lang/tcl86
net/slurm
sysutils/lsof
devel/google-perftools
sysutils/pciutils
"

for port in $PORTS_LIST; do
    ./tc addPort -b $1 -d $port
done
