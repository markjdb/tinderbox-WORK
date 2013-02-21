#!/bin/sh

# These variables get filled in by the preJailUpdate hook.
ARCH=%%
JAILDIR=%%
OSNAME=%%
OSTYPE=%%

OSVERSION=
FTP_PATH=images/${OSNAME}/${OSTYPE}/

log()
{
    echo "$(basename $0): $1" >&2
}

latestPkgVersion()
{
    local flist vlist latest excludes

    case $OSNAME in
    SVOS)
        excludes='svos-install-9\.21\.0002'
        ;;
    esac

    flist=$(ftp -a -V wtllab-ftp-1 <<__EOF__ | \
            awk '/ svos-install-.*/ || / svbsd-install-.*/ {print $NF}'
ls $FTP_PATH
__EOF__
)

    for pat in $excludes; do
        flist=$(echo "$flist" | grep -v -e "$pat")
    done

    vlist=$(echo "$flist" | sort | tail -n 1)

    if [ -z "$latest" ]; then
        return
    fi

    # Get the version number; e.g. svbsd-install-8.82.0022.tar -> 8.82.0022.
    latest=${latest##*-install-}
    latest=${latest%%.tar}
    echo $latest
}

fetchPkgs()
{
    local installPkg undecimatePkg

    case $OSTYPE in
    SVOS)
        installPkg=svos-install-${1}.tar
        undecimatePkg=svos-undecimate-${1}.tbz
        ;;
    FREEBSD)
        installPkg=svbsd-install-${1}.tar
        undecimatePkg=svbsd-undecimate-${1}.tbz
        ;;
    *)
        log "unknown OS type $OSTYPE"
        exit 1
    esac

    fetch -o $JAILDIR ftp://fbsd-ftp/${FTP_PATH}/$installPkg
    if [ $? -ne 0 ]; then
        log "error fetching $installPkg from fbsd-ftp/images"
        exit 1
    fi

    fetch -o $JAILDIR ftp://fbsd-ftp/${FTP_PATH}/$undecimatePkg
    if [ $? -ne 0 ]; then
        log "error fetching $undecimatePkg from fbsd-ftp/images"
        exit 1
    fi
}

OSVERSION=$(latestPkgVersion)
if [ -z "$OSVERSION" ]; then
    log "error finding the latest OS install package"
    exit 1
fi

VERSION=$(echo $OSVERSION | tr '.' '\0')

# Get the version number of the currently unpacked OS (if this isn't the
# initial update.
if [ -r ${JAILDIR}/VERSION ]; then
    CURR_VERSION=$(cat ${JAILDIR}/VERSION)
else
    CURR_VERSION=0
fi

# Determine whether a new build is ready to be downloaded.
[ $VERSION -gt $CURR_VERSION ] || exit 0

# Update the version.
echo $VERSION > ${JAILDIR}/VERSION

fetchPkgs $OSVERSION
