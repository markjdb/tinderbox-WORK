#!/bin/sh
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
# $MCom: portstools/tinderbox/upgrade/mig_shlib.sh,v 1.1 2005/07/19 06:58:12 marcus Exp $
#

pb=$0
[ -z "$(echo "${pb}" | sed 's![^/]!!g')" ] && \
pb=$(type "$pb" | sed 's/^.* //g')
pb=$(realpath $(dirname $pb))
pb=${pb%%/scripts}

. ${pb}/scripts/setup_shlib.sh

mig_rawenv2db() {

	rawenv=$1
	header=$2

	if [ ! -s "${rawenv}" ] ; then
		return 0
	else
	    	first_line=$(head -1 "${rawenv}")

		if [ x"${first_line}" = x"${header}" ]; then
		    	return 0
		fi

		echo -n "INFO: Migrating ${rawenv} ..."

		while read line ; do
			var=${line%=*}
			value=$(echo ${line#*=} | sed 's/"//g')

			case "${var}" in
				CCACHE_ENABLED)		call_tc configCcache -e;;
				CCACHE_DIR)		call_tc configCcache -c "${value}";;
				CCACHE_MAX_SIZE)	call_tc configCcache -s "${value}";;
				CCACHE_LOGFILE)		call_tc configCcache -l "${value}";;
				CCACHE_JAIL)		call_tc configCcache -j;;
				DISTFILE_CACHE)		call_tc configDistfile -c "${value}";;
				\#TINDERD_SLEEPTIME)	call_tc configTinderd -t "${value}";;
				\#MOUNT_PORTSTREE*)	name=${var#*_*_}
							call_tc setPortsMount -p "${name}" -m "${value}";;
				\#MOUNT_JAIL*)		name=${var#*_*_}
							call_tc setSrcMount -j "${name}" -m "${value}";;
			esac
		done < "${rawenv}"

		cp -p "${rawenv}" "${rawenv}.bak"
		rm -f "${rawenv}"

		echo "DONE."
	fi

	return 0
}

mig_db() {
    version=$1

    dbversion=$(call_tc dsversion)

    if [ -f "${pb}/upgrade/mig_tinderbox-${dbversion}_to_${version}.sql" ]; then
	echo "INFO: Migrating database schema from ${dbversion} to ${version} ..."
	rc=$(load_schema "${pb}/upgrade/mig_tinderbox-${dbversion}_to_${version}.sql")
	if [ ${rc} != 0 ]; then
	    echo "ERROR: Failed to load upgrade database schema."
	    return 1
	fi

	echo "DONE."
    fi

    return 0
}

mig_files() {
    rawenv=$1

    echo -n "INFO: Migrating files ..."

    if [ ! -f "${rawenv}" ]; then
	cp "${rawenv}.dist" "${rawenv}"
	echo "DONE."
	return 0
    fi

    if ! cmp -s "${rawenv}.dist" "${rawenv}" ; then
	cp -p "${rawenv}" "${rawenv}.bak"
	cp "${rawenv}.dist" "${rawenv}"
    fi

    echo "DONE."

    return 0
}