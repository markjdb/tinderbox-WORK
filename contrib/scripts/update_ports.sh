#!/bin/sh

PORTSTREE=%%

if [ -d $PORTSTREE/ports ]; then
    cd $PORTSTREE/ports
    git pull origin svports
else
    cd $PORTSTREE
    URL=git@wtllab-bsdbuild-5:/d2/git/base/svports.git
    git clone --branch svports $URL ports
fi
