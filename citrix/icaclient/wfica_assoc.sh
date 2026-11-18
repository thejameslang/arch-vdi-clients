#!/bin/sh
export ICAROOT=/opt/Citrix/ICAClient
# Citrix calls X11 directly; GTK on Wayland makes PrimaryAuthManager segfault.
export GDK_BACKEND=x11
exec ${ICAROOT}/wfica -associate -fileparam "$1"
