#!/bin/sh

cat <<EOF >> ${PB}/${BUILD}/etc/make.conf
WITHOUT_X11=yes
WITHOUT_PERL_MODULE=yes
WITHOUT_GLIB=yes
WITHOUT_XCB=yes
EOF
