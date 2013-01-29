#!/bin/sh

ARCH=%%
JAILDIR=%%
OSNAME=%%
OSTYPE=%%

case $OSTYPE in
SVOS)
    PREFIX=svos
    ;;
FREEBSD)
    PREFIX=svbsd
    ;;
esac

cd $JAILDIR

INSTALL_PKG=$(ls ${PREFIX}-install-*)
UNDECIMATE_PKG=$(ls ${PREFIX}-undecimate-*)

mkdir -p tmp

tar -C tmp -xvf $INSTALL_PKG
tar -C tmp -xvf $UNDECIMATE_PKG

for tarball in tmp/sandvine/undecimate/*; do
    tar -C tmp -xvf $tarball
done

mkdir -p src
tar --strip-components 1 -xvf tmp/sandvine/undecimate/src.tar
